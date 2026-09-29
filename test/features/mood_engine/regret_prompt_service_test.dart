import 'dart:io';

import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_result.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_service.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/app_transaction.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
  });
  tearDown(() => f.database.close());

  test('no due check-ins has an explicit result', () async {
    expect((await f.select()).status, RegretPromptStatus.noDueCheckins);
  });

  test('future check-ins are not delivered', () async {
    final checkin = await f.scheduled(
      dueAt: f.now.add(const Duration(seconds: 1)),
    );
    expect((await f.select()).status, RegretPromptStatus.noDueCheckins);
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.promptedAt,
      isNull,
    );
    expect((await f.select(at: checkin.dueAt)).prompt!.checkin.id, checkin.id);
  });

  test(
    'oldest due item is selected and persisted with purchase context',
    () async {
      await f.scheduled();
      final oldest = await f.scheduled(
        dueAt: f.now.subtract(const Duration(days: 5)),
      );
      final result = await f.select();
      expect(result.status, RegretPromptStatus.available);
      expect(result.prompt!.checkin.id, oldest.id);
      expect(result.prompt!.transaction.id, oldest.transactionId);
      expect(result.prompt!.checkin.promptedAt, f.now);
      expect(
        (await f.checkins.getCheckinById(checkinId: oldest.id))!.promptedAt,
        f.now,
      );
    },
  );

  test('answered check-ins are excluded even when they are oldest', () async {
    final answered = await f.scheduled(
      dueAt: f.now.subtract(const Duration(days: 5)),
    );
    final yesterday = f.now.subtract(const Duration(days: 1));
    await f.checkins.markPrompted(
      checkinId: answered.id,
      promptedAt: yesterday,
    );
    await f.checkins.answerCheckin(
      checkinId: answered.id,
      response: RegretResponse.worthIt,
      answeredAt: yesterday,
    );
    final candidate = await f.scheduled();
    expect((await f.select()).prompt!.checkin.id, candidate.id);
  });

  test('same-day refresh returns the same unanswered delivery', () async {
    await f.scheduled();
    await f.scheduled();
    final first = (await f.select()).prompt!;
    final refreshed = (await f.select(at: f.now.add(const Duration(hours: 2))))
        .prompt!;
    expect(refreshed.checkin.id, first.checkin.id);
    expect(refreshed.checkin.promptedAt, first.checkin.promptedAt);
    expect(
      await f.checkins.getCheckinsPromptedOnDate(
        profileId: f.profile.id,
        date: f.now,
      ),
      hasLength(1),
    );
  });

  test('answering does not unlock a second delivery that day', () async {
    await f.scheduled();
    await f.scheduled();
    final first = (await f.select()).prompt!;
    await f.service.answerPrompt(
      profileId: f.profile.id,
      checkinId: first.checkin.id,
      response: RegretResponse.regret,
      asOf: f.now,
    );
    expect((await f.select()).status, RegretPromptStatus.dailyLimitReached);
    final tomorrow = await f.select(at: f.now.add(const Duration(days: 1)));
    expect(tomorrow.status, RegretPromptStatus.available);
    expect(tomorrow.prompt!.checkin.id, isNot(first.checkin.id));
  });

  test('ignored deliveries are not re-prompted on later days', () async {
    await f.scheduled();
    final first = (await f.select()).prompt!;
    final tomorrow = f.now.add(const Duration(days: 1));
    expect(
      (await f.select(at: tomorrow)).status,
      RegretPromptStatus.noDueCheckins,
    );
    final next = await f.scheduled();
    expect((await f.select(at: tomorrow)).prompt!.checkin.id, next.id);
    final original = (await f.checkins.getCheckinById(
      checkinId: first.checkin.id,
    ))!;
    expect(original.promptedAt, f.now);
    expect(original.answeredAt, isNull);
  });

  test(
    'daily allowance resets at local midnight, not after 24 hours',
    () async {
      await f.scheduled();
      await f.scheduled();
      final late = DateTime(2026, 9, 29, 23, 59, 59);
      final first = (await f.select(at: late)).prompt!;
      final midnight = DateTime(2026, 9, 30);
      final next = (await f.select(at: midnight)).prompt!;
      expect(next.checkin.id, isNot(first.checkin.id));
      expect(
        await f.checkins.getCheckinsPromptedOnDate(
          profileId: f.profile.id,
          date: late.toUtc(),
        ),
        hasLength(1),
      );
      expect(
        await f.checkins.getCheckinsPromptedOnDate(
          profileId: f.profile.id,
          date: midnight.toUtc(),
        ),
        hasLength(1),
      );
    },
  );

  for (final day in [DateTime(2026, 3, 8), DateTime(2026, 11, 1)]) {
    test(
      'calendar bounds include the full local day at DST boundary $day',
      () async {
        final checkin = await f.scheduled(
          dueAt: day.subtract(const Duration(days: 2)),
        );
        final lastSecond = DateTime(day.year, day.month, day.day, 23, 59, 59);
        await f.checkins.markPrompted(
          checkinId: checkin.id,
          promptedAt: lastSecond,
        );
        expect(
          await f.checkins.getCheckinsPromptedOnDate(
            profileId: f.profile.id,
            date: day,
          ),
          hasLength(1),
        );
        expect(
          await f.checkins.getCheckinsPromptedOnDate(
            profileId: f.profile.id,
            date: DateTime(day.year, day.month, day.day + 1),
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'profile isolation applies to selection, daily cap and answering',
    () async {
      await f.database
          .into(f.database.profiles)
          .insert(
            ProfilesCompanion.insert(id: 'other-profile', currencyCode: 'CAD'),
          );
      await f.scheduled();
      final first = (await f.select()).prompt!;
      expect(
        (await f.select(profileId: 'other-profile')).status,
        RegretPromptStatus.noDueCheckins,
      );
      await expectLater(
        f.service.answerPrompt(
          profileId: 'other-profile',
          checkinId: first.checkin.id,
          response: RegretResponse.regret,
          asOf: f.now,
        ),
        throwsStateError,
      );
      expect(
        (await f.checkins.getCheckinById(checkinId: first.checkin.id))!
            .answeredAt,
        isNull,
      );
      await f.database
          .into(f.database.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'other-purchase',
              amountCents: 2500,
              profileId: const Value('other-profile'),
              transactionDate: f.now.subtract(const Duration(days: 3)),
            ),
          );
      await f.checkins.scheduleCheckin(
        transactionId: 'other-purchase',
        dueAt: f.now.subtract(const Duration(days: 1)),
      );
      expect(
        (await f.select(profileId: 'other-profile'))
            .prompt!
            .transaction
            .profileId,
        'other-profile',
      );
    },
  );

  test('concurrent service instances deliver only one check-in', () async {
    for (var i = 0; i < 5; i++) {
      await f.scheduled();
    }
    final results = await Future.wait(
      List.generate(
        10,
        (_) => RegretPromptService(
          checkinRepository: DriftRegretCheckinRepository(f.database),
          transactionRepository: DriftTransactionRepository(f.database),
          runInTransaction: f.database.transaction,
        ).getPrompt(profileId: f.profile.id, asOf: f.now),
      ),
    );
    expect(
      results.map((result) => result.prompt!.checkin.id).toSet(),
      hasLength(1),
    );
    expect(
      await f.checkins.getCheckinsPromptedOnDate(
        profileId: f.profile.id,
        date: f.now,
      ),
      hasLength(1),
    );
  });

  test(
    'failed delivery rolls back promptedAt and the daily allowance',
    () async {
      final checkin = await f.scheduled();
      final service = RegretPromptService(
        checkinRepository: _FailAfterPromptRepository(f.database),
        transactionRepository: f.transactions,
        runInTransaction: f.database.transaction,
      );
      await expectLater(
        service.getPrompt(profileId: f.profile.id, asOf: f.now),
        throwsStateError,
      );
      expect(
        (await f.checkins.getCheckinById(checkinId: checkin.id))!.promptedAt,
        isNull,
      );
      expect((await f.select()).status, RegretPromptStatus.available);
    },
  );

  test('missing purchase is an error and does not consume delivery', () async {
    final checkin = await f.scheduled();
    final service = RegretPromptService(
      checkinRepository: f.checkins,
      transactionRepository: _MissingTransactionRepository(f.database),
      runInTransaction: f.database.transaction,
    );
    await expectLater(
      service.getPrompt(profileId: f.profile.id, asOf: f.now),
      throwsStateError,
    );
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.promptedAt,
      isNull,
    );
  });

  test(
    'answers reject missing, unprompted and already answered check-ins',
    () async {
      Future<void> answer(String id) => f.service.answerPrompt(
        profileId: f.profile.id,
        checkinId: id,
        response: RegretResponse.worthIt,
        asOf: f.now,
      );
      await expectLater(answer('missing'), throwsStateError);
      final checkin = await f.scheduled();
      await expectLater(answer(checkin.id), throwsStateError);
      await f.select();
      await expectLater(
        f.service.answerPrompt(
          profileId: f.profile.id,
          checkinId: checkin.id,
          response: RegretResponse.unsure,
          asOf: f.now.subtract(const Duration(seconds: 1)),
        ),
        throwsArgumentError,
      );
      await answer(checkin.id);
      await expectLater(answer(checkin.id), throwsStateError);
      expect(
        (await f.checkins.getCheckinById(checkinId: checkin.id))!.response,
        RegretResponse.worthIt,
      );
    },
  );

  test(
    'concurrent repository answers cannot overwrite the first response',
    () async {
      final checkin = await f.scheduled();
      await f.select();
      final outcomes = await Future.wait(
        RegretResponse.values.map((response) async {
          try {
            await f.checkins.answerCheckin(
              checkinId: checkin.id,
              response: response,
              answeredAt: f.now,
            );
            return true;
          } on StateError {
            return false;
          }
        }),
      );
      expect(outcomes.where((saved) => saved), hasLength(1));
    },
  );

  test('delivery and cap survive closing and reopening SQLite', () async {
    final directory = await Directory.systemTemp.createTemp(
      'afterlens-regret-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/test.sqlite');
    final persistent = RegretTestFixture(AppDatabase(NativeDatabase(file)));
    await persistent.initialize();
    await persistent.scheduled();
    await persistent.scheduled();
    final original = (await persistent.select()).prompt!;
    final profileId = persistent.profile.id;
    await persistent.database.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final service = RegretPromptService(
      checkinRepository: DriftRegretCheckinRepository(reopened),
      transactionRepository: DriftTransactionRepository(reopened),
      runInTransaction: reopened.transaction,
    );
    expect(
      (await service.getPrompt(
        profileId: profileId,
        asOf: f.now,
      )).prompt!.checkin.id,
      original.checkin.id,
    );
    await service.answerPrompt(
      profileId: profileId,
      checkinId: original.checkin.id,
      response: RegretResponse.worthIt,
      asOf: f.now,
    );
    expect(
      (await service.getPrompt(profileId: profileId, asOf: f.now)).status,
      RegretPromptStatus.dailyLimitReached,
    );
  });

  for (final mood in MoodTag.values) {
    for (final cents in [1500, 1501, 10000]) {
      test('$mood at $cents cents follows scheduling eligibility', () async {
        await f.expense(mood: mood, amountCents: cents);
        final eligible =
            (mood == MoodTag.want || mood == MoodTag.impulse) && cents > 1500;
        expect(
          (await f.select()).status,
          eligible
              ? RegretPromptStatus.available
              : RegretPromptStatus.noDueCheckins,
        );
      });
    }
  }
}

class _FailAfterPromptRepository extends DriftRegretCheckinRepository {
  _FailAfterPromptRepository(super.database);
  @override
  Future<void> markPrompted({
    required String checkinId,
    required DateTime promptedAt,
  }) async {
    await super.markPrompted(checkinId: checkinId, promptedAt: promptedAt);
    throw StateError('Simulated write failure');
  }
}

class _MissingTransactionRepository extends DriftTransactionRepository {
  _MissingTransactionRepository(super.database);
  @override
  Future<AppTransaction?> getTransactionById({
    required String transactionId,
  }) async => null;
}
