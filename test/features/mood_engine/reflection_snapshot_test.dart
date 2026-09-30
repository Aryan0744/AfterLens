import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/insights/application/behavioral_insights_service.dart';
import 'package:afterlens/features/insights/data/drift_behavioral_insights_repository.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_result.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_service.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/application/transaction_management_service.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  late TransactionManagementService management;

  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
    management = TransactionManagementService(
      transactionRepository: f.transactions,
      checkinRepository: f.checkins,
      eligibilityPolicy: RegretEligibilityPolicy(),
      runInTransaction: f.database.transaction,
    );
  });

  tearDown(() => f.database.close());

  Future<TransactionUpdateResult> edit(
    String transactionId, {
    MoodTag mood = MoodTag.impulse,
    int cents = 2500,
    String? categoryId,
    String? description,
    DateTime? date,
  }) => management.updateExpense(
    profileId: f.profile.id,
    transactionId: transactionId,
    categoryId: categoryId ?? f.categoryId,
    amountCents: cents,
    moodTag: mood,
    transactionDate: date ?? f.now.subtract(const Duration(days: 3)),
    description: description,
  );

  Future<void> answer(String id) => f.service.answerPrompt(
    profileId: f.profile.id,
    checkinId: id,
    response: RegretResponse.regret,
    asOf: f.now,
  );

  test(
    'ledger corrections and category renames never rewrite insights',
    () async {
      final purchase = await f.expense(amountCents: 8000);
      final prompt = (await f.select()).prompt!;
      await answer(prompt.checkin.id);
      final original =
          (await f.database.select(f.database.regretCheckins).get()).single;

      final essentials = await DriftCategoryRepository(f.database)
          .createCustomCategory(profileId: f.profile.id, name: 'Essentials');
      final correctedDate = purchase.transactionDate.subtract(
        const Duration(days: 1),
      );
      final edited = await edit(
        purchase.id,
        cents: 9000,
        mood: MoodTag.need,
        categoryId: essentials.id,
        description: 'Work headphones',
        date: correctedDate,
      );
      expect(edited.regretStatus, RegretReconciliationStatus.preserved);
      final ledger = (await f.transactions.getTransactionById(
        transactionId: purchase.id,
      ))!;
      expect(ledger.amountCents, 9000);
      expect(ledger.categoryId, essentials.id);
      expect(ledger.moodTag, MoodTag.need);
      expect(ledger.description, 'Work headphones');
      expect(ledger.transactionDate, correctedDate);

      await (f.database.update(f.database.categories)
            ..where((row) => row.id.equals(f.categoryId)))
          .write(const CategoriesCompanion(name: Value('Renamed shopping')));

      final reflections = await DriftBehavioralInsightsRepository(f.database)
          .getCompletedReflections(profileId: f.profile.id);
      final reflection = reflections.single;
      expect(reflection.amountCents, 8000);
      expect(reflection.moodTag, MoodTag.impulse);
      expect(reflection.categoryId, f.categoryId);
      expect(reflection.categoryName, 'Shopping');
      expect(reflection.description, 'Headphones');
      expect(reflection.transactionDate, purchase.transactionDate);
      expect(reflection.response, RegretResponse.regret);
      expect(reflection.answeredAt, f.now);

      final insights = const BehavioralInsightsService().analyze(reflections);
      expect(insights.answeredCount, 1);
      expect(insights.totalReflectedSpendCents, 8000);
      expect(insights.regrettedSpendCents, 8000);
      expect(insights.moodInsights.single.mood, MoodTag.impulse);
      expect(insights.moodInsights.single.regretCount, 1);
      expect(insights.categoryInsights.single.categoryName, 'Shopping');

      await edit(purchase.id, mood: MoodTag.impulse, cents: 9000);
      expect((await f.select()).status, RegretPromptStatus.noDueCheckins);
      final rows = await f.database.select(f.database.regretCheckins).get();
      expect(rows, [original]);
      final stored = (await f.checkins.getCheckinById(checkinId: original.id))!;
      expect(stored.snapshot!.amountCents, 8000);
      expect(stored.snapshot!.description, 'Headphones');
    },
  );

  test('eligible edit resets delivery and rejects a stale answer', () async {
    final purchase = await f.expense();
    final original = (await f.select()).prompt!.checkin;
    final result = await edit(purchase.id, mood: MoodTag.want, date: f.now);
    expect(result.regretStatus, RegretReconciliationStatus.rescheduled);
    final pending = (await f.checkins.getCheckinForTransaction(
      transactionId: purchase.id,
    ))!;
    expect(pending.id, original.id);
    expect(pending.createdAt, original.createdAt);
    expect(pending.promptedAt, isNull);
    expect(pending.snapshot, isNull);
    expect(pending.dueAt, f.now.add(const Duration(days: 2)));
    await expectLater(answer(original.id), throwsStateError);
    expect((await f.select()).status, RegretPromptStatus.noDueCheckins);
    expect((await f.select(at: pending.dueAt)).prompt!.checkin.id, original.id);
    await f.service.answerPrompt(
      profileId: f.profile.id,
      checkinId: original.id,
      response: RegretResponse.worthIt,
      asOf: pending.dueAt,
    );
    final answered = (await f.checkins.getCheckinById(checkinId: original.id))!;
    expect(answered.snapshot!.moodTag, MoodTag.want);
    expect(answered.snapshot!.transactionDate, f.now);
  });

  test(
    'pending eligibility can cycle until the first answer becomes permanent',
    () async {
      final purchase = await f.expense(mood: MoodTag.need);
      expect(
        await f.checkins.getCheckinForTransaction(transactionId: purchase.id),
        isNull,
      );
      expect(
        (await edit(purchase.id)).regretStatus,
        RegretReconciliationStatus.scheduled,
      );
      final first = (await f.select()).prompt!.checkin;
      expect(
        (await edit(purchase.id, mood: MoodTag.need)).regretStatus,
        RegretReconciliationStatus.removed,
      );
      expect(await f.checkins.getCheckinById(checkinId: first.id), isNull);
      await expectLater(answer(first.id), throwsStateError);
      expect(
        (await edit(purchase.id)).regretStatus,
        RegretReconciliationStatus.scheduled,
      );
      final second = (await f.select()).prompt!.checkin;
      expect(second.id, isNot(first.id));
      await answer(second.id);
      await edit(purchase.id, mood: MoodTag.need);
      await edit(purchase.id);
      expect((await f.select()).status, RegretPromptStatus.noDueCheckins);
      expect(
        (await f.checkins.getCheckinForTransaction(transactionId: purchase.id))!
            .id,
        second.id,
      );
    },
  );

  test('repository operations cannot alter an answered reflection', () async {
    final pending = await f.scheduled();
    await f.select();
    await answer(pending.id);
    final before =
        (await f.database.select(f.database.regretCheckins).get()).single;
    await expectLater(
      f.checkins.rescheduleUnansweredCheckin(
        checkinId: pending.id,
        dueAt: f.now,
      ),
      throwsStateError,
    );
    await expectLater(
      f.checkins.deleteUnansweredCheckin(checkinId: pending.id),
      throwsStateError,
    );
    await expectLater(
      f.checkins.markPrompted(checkinId: pending.id, promptedAt: f.now),
      throwsStateError,
    );
    await expectLater(answer(pending.id), throwsStateError);
    await expectLater(
      f.checkins.scheduleCheckin(
        transactionId: pending.transactionId,
        dueAt: f.now,
      ),
      throwsStateError,
    );
    expect(
      (await f.database.select(f.database.regretCheckins).get()).single,
      before,
    );
  });

  test(
    'database rejects duplicate check-ins and incomplete snapshot states',
    () async {
      final pending = await f.scheduled();
      await expectLater(
        f.database
            .into(f.database.regretCheckins)
            .insert(
              RegretCheckinsCompanion.insert(
                id: 'duplicate',
                transactionId: pending.transactionId,
                dueAt: pending.dueAt,
              ),
            ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        f.database
            .update(f.database.regretCheckins)
            .write(
              RegretCheckinsCompanion(
                promptedAt: Value(f.now),
                answeredAt: Value(f.now),
                response: const Value(RegretResponse.regret),
              ),
            ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        f.database
            .update(f.database.regretCheckins)
            .write(
              const RegretCheckinsCompanion(snapshotAmountCents: Value(2500)),
            ),
        throwsA(isA<Exception>()),
      );
      final stored = (await f.checkins.getCheckinById(checkinId: pending.id))!;
      expect(stored.isAnswered, false);
      expect(stored.snapshot, isNull);
    },
  );

  test(
    'failed answer rolls back both response and every snapshot field',
    () async {
      final checkin = await f.scheduled();
      await f.select();
      final service = RegretPromptService(
        checkinRepository: _FailAfterAnswerRepository(f.database),
        transactionRepository: f.transactions,
        runInTransaction: f.database.transaction,
      );
      await expectLater(
        service.answerPrompt(
          profileId: f.profile.id,
          checkinId: checkin.id,
          response: RegretResponse.regret,
          asOf: f.now,
        ),
        throwsStateError,
      );
      final row =
          (await f.database.select(f.database.regretCheckins).get()).single;
      expect(row.response, isNull);
      expect(row.answeredAt, isNull);
      expect(row.snapshotAmountCents, isNull);
      expect(row.snapshotCategoryId, isNull);
      expect(row.snapshotCategoryName, isNull);
      expect(row.snapshotMoodTag, isNull);
      expect(row.snapshotDescription, isNull);
      expect(row.snapshotTransactionDate, isNull);
      await answer(checkin.id);
      expect(
        (await f.checkins.getCheckinById(checkinId: checkin.id))!.snapshot,
        isNotNull,
      );
    },
  );

  test('repository verifies ownership before capturing a snapshot', () async {
    final checkin = await f.scheduled();
    await f.select();
    await expectLater(
      f.checkins.answerCheckin(
        profileId: 'other-profile',
        checkinId: checkin.id,
        response: RegretResponse.regret,
        answeredAt: f.now,
      ),
      throwsStateError,
    );
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.snapshot,
      isNull,
    );

    await f.database
        .into(f.database.profiles)
        .insert(
          ProfilesCompanion.insert(id: 'other-profile', currencyCode: 'CAD'),
        );
    final category = await DriftCategoryRepository(f.database)
        .createCustomCategory(profileId: 'other-profile', name: 'Other');
    await f.database
        .update(f.database.transactions)
        .write(TransactionsCompanion(categoryId: Value(category.id)));
    await expectLater(answer(checkin.id), throwsStateError);
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.snapshot,
      isNull,
    );
  });
}

class _FailAfterAnswerRepository extends DriftRegretCheckinRepository {
  _FailAfterAnswerRepository(super.database);

  @override
  Future<void> answerCheckin({
    required String profileId,
    required String checkinId,
    required RegretResponse response,
    required DateTime answeredAt,
  }) async {
    await super.answerCheckin(
      profileId: profileId,
      checkinId: checkinId,
      response: response,
      answeredAt: answeredAt,
    );
    throw StateError('Simulated failure after saving the answer.');
  }
}
