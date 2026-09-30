import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/insights/application/behavioral_insights_service.dart';
import 'package:afterlens/features/insights/data/drift_behavioral_insights_repository.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:afterlens/features/transactions/application/transaction_management_service.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/app_transaction.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late DriftTransactionRepository transactionRepository;
  late DriftRegretCheckinRepository checkinRepository;

  late TransactionManagementService service;

  late AppProfile profile;
  late String categoryId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);

    categoryRepository = DriftCategoryRepository(database);

    transactionRepository = DriftTransactionRepository(database);

    checkinRepository = DriftRegretCheckinRepository(database);

    service = TransactionManagementService(
      transactionRepository: transactionRepository,
      checkinRepository: checkinRepository,
      eligibilityPolicy: RegretEligibilityPolicy(),
      runInTransaction: database.transaction,
    );

    profile = await profileRepository.createLocalProfile(currencyCode: 'CAD');

    final category = await categoryRepository.createCustomCategory(
      profileId: profile.id,
      name: 'Shopping',
    );

    categoryId = category.id;
  });

  tearDown(() async {
    await database.close();
  });

  Future<AppTransaction> createExpense({
    required int amountCents,
    required MoodTag mood,
    DateTime? transactionDate,
    String? description,
  }) {
    return transactionRepository.createExpense(
      profileId: profile.id,
      categoryId: categoryId,
      amountCents: amountCents,
      moodTag: mood,
      transactionDate: transactionDate ?? DateTime(2026, 9, 20),
      description: description,
    );
  }

  Future<void> expectSoftDeleted(String transactionId) async {
    final row = await database.select(database.transactions).getSingle();
    expect(row.id, transactionId);
    expect(row.deletedAt, isNotNull);
    expect(row.updatedAt, row.deletedAt);
    expect(
      await transactionRepository.getTransactionById(
        transactionId: transactionId,
      ),
      isNull,
    );
    expect(
      await transactionRepository.getTransactions(profileId: profile.id),
      isEmpty,
    );
    expect(
      await transactionRepository
          .watchTransactions(profileId: profile.id)
          .first,
      isEmpty,
    );
  }

  group('TransactionManagementService', () {
    test('eligible edit schedules check-in when none exists', () async {
      final transaction = await createExpense(
        amountCents: 1000,
        mood: MoodTag.need,
      );

      final result = await service.updateExpense(
        profileId: profile.id,
        transactionId: transaction.id,
        categoryId: categoryId,
        amountCents: 2500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
        description: 'Headphones',
      );

      expect(result.regretStatus, RegretReconciliationStatus.scheduled);

      expect(result.transaction.amountCents, 2500);

      expect(result.transaction.moodTag, MoodTag.impulse);

      final checkin = await checkinRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(checkin, isNotNull);

      expect(checkin!.dueAt, DateTime(2026, 9, 22));
    });

    test(
      'ineligible edit without check-in leaves regret state unchanged',
      () async {
        final transaction = await createExpense(
          amountCents: 1000,
          mood: MoodTag.need,
        );

        final result = await service.updateExpense(
          profileId: profile.id,
          transactionId: transaction.id,
          categoryId: categoryId,
          amountCents: 1200,
          moodTag: MoodTag.social,
          transactionDate: DateTime(2026, 9, 21),
        );

        expect(result.regretStatus, RegretReconciliationStatus.unchanged);

        final checkin = await checkinRepository.getCheckinForTransaction(
          transactionId: transaction.id,
        );

        expect(checkin, isNull);
      },
    );

    test('eligible edit reschedules existing unprompted check-in', () async {
      final transaction = await createExpense(
        amountCents: 2500,
        mood: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final originalCheckin = await checkinRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      final result = await service.updateExpense(
        profileId: profile.id,
        transactionId: transaction.id,
        categoryId: categoryId,
        amountCents: 3000,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 25),
      );

      expect(result.regretStatus, RegretReconciliationStatus.rescheduled);

      final updatedCheckin = await checkinRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(updatedCheckin, isNotNull);

      expect(updatedCheckin!.id, originalCheckin.id);

      expect(updatedCheckin.dueAt, DateTime(2026, 9, 27));
    });

    test('ineligible edit removes existing unprompted check-in', () async {
      final transaction = await createExpense(
        amountCents: 2500,
        mood: MoodTag.impulse,
      );

      await checkinRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      final result = await service.updateExpense(
        profileId: profile.id,
        transactionId: transaction.id,
        categoryId: categoryId,
        amountCents: 1000,
        moodTag: MoodTag.need,
        transactionDate: DateTime(2026, 9, 20),
      );

      expect(result.regretStatus, RegretReconciliationStatus.removed);

      final checkin = await checkinRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(checkin, isNull);
    });

    test('ineligible edit removes a prompted, unanswered check-in', () async {
      final transaction = await createExpense(
        amountCents: 2500,
        mood: MoodTag.impulse,
      );

      final checkin = await checkinRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await checkinRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: DateTime(2026, 9, 22, 10),
      );

      final result = await service.updateExpense(
        profileId: profile.id,
        transactionId: transaction.id,
        categoryId: categoryId,
        amountCents: 1000,
        moodTag: MoodTag.need,
        transactionDate: DateTime(2026, 9, 20),
      );

      expect(result.regretStatus, RegretReconciliationStatus.removed);

      final preserved = await checkinRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(preserved, isNull);
    });

    for (final prompted in [false, true]) {
      test(
        'deleting a transaction removes its ${prompted ? 'prompted' : 'unprompted'} unanswered check-in',
        () async {
          final transaction = await createExpense(
            amountCents: 2500,
            mood: MoodTag.impulse,
          );

          final checkin = await checkinRepository.scheduleCheckin(
            transactionId: transaction.id,
            dueAt: DateTime(2026, 9, 22),
          );
          if (prompted) {
            await checkinRepository.markPrompted(
              checkinId: checkin.id,
              promptedAt: DateTime(2026, 9, 22, 10),
            );
          }

          await service.deleteTransaction(
            profileId: profile.id,
            transactionId: transaction.id,
          );

          await expectSoftDeleted(transaction.id);
          expect(
            await checkinRepository.getCheckinById(checkinId: checkin.id),
            isNull,
          );
          expect(await database.select(database.regretCheckins).get(), isEmpty);
        },
      );
    }

    test(
      'deleting a transaction preserves its completed snapshot and Insights',
      () async {
        final transactionDate = DateTime(2026, 9, 20);
        final answeredAt = DateTime(2026, 9, 22, 10, 5);
        final transaction = await createExpense(
          amountCents: 8000,
          mood: MoodTag.impulse,
          transactionDate: transactionDate,
          description: 'Headphones',
        );
        final checkin = await checkinRepository.scheduleCheckin(
          transactionId: transaction.id,
          dueAt: DateTime(2026, 9, 22),
        );
        await checkinRepository.markPrompted(
          checkinId: checkin.id,
          promptedAt: DateTime(2026, 9, 22, 10),
        );
        await checkinRepository.answerCheckin(
          profileId: profile.id,
          checkinId: checkin.id,
          response: RegretResponse.regret,
          answeredAt: answeredAt,
        );
        final original = await database
            .select(database.regretCheckins)
            .getSingle();

        await service.deleteTransaction(
          profileId: profile.id,
          transactionId: transaction.id,
        );

        await expectSoftDeleted(transaction.id);
        // Compare the entire stored row, including all snapshot fields and timestamps.
        expect(
          await database.select(database.regretCheckins).getSingle(),
          original,
        );
        final preserved = (await checkinRepository.getCheckinById(
          checkinId: checkin.id,
        ))!;
        expect(preserved.isAnswered, isTrue);
        expect(preserved.snapshot, isNotNull);

        final insightsRepository = DriftBehavioralInsightsRepository(database);
        final reflections = await insightsRepository.getCompletedReflections(
          profileId: profile.id,
        );
        final reflection = reflections.single;
        expect(reflection.transactionId, transaction.id);
        expect(reflection.amountCents, 8000);
        expect(reflection.moodTag, MoodTag.impulse);
        expect(reflection.categoryId, categoryId);
        expect(reflection.categoryName, 'Shopping');
        expect(reflection.description, 'Headphones');
        expect(reflection.transactionDate, transactionDate);
        expect(reflection.response, RegretResponse.regret);
        expect(reflection.answeredAt, answeredAt);

        final watched = await insightsRepository
            .watchCompletedReflections(profileId: profile.id)
            .first;
        expect(watched.single.transactionId, transaction.id);
        final insights = const BehavioralInsightsService().analyze(watched);
        expect(insights.answeredCount, 1);
        expect(insights.regretCount, 1);
        expect(insights.totalReflectedSpendCents, 8000);
        expect(insights.regrettedSpendCents, 8000);
      },
    );

    test('cannot update transaction owned by another profile', () async {
      final transaction = await createExpense(
        amountCents: 2500,
        mood: MoodTag.impulse,
      );

      expect(
        () => service.updateExpense(
          profileId: 'another-profile',
          transactionId: transaction.id,
          categoryId: categoryId,
          amountCents: 3000,
          moodTag: MoodTag.want,
          transactionDate: DateTime(2026, 9, 20),
        ),
        throwsStateError,
      );
    });
  });
}
