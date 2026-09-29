import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late DriftTransactionRepository transactionRepository;
  late DriftRegretCheckinRepository regretRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);
    categoryRepository = DriftCategoryRepository(database);
    transactionRepository = DriftTransactionRepository(database);
    regretRepository = DriftRegretCheckinRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftRegretCheckinRepository', () {
    test('schedules a check-in for an expense', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final transactionDate = DateTime(2026, 9, 20, 12);

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 1999,
        moodTag: MoodTag.impulse,
        transactionDate: transactionDate,
        description: 'Coffee',
      );

      final dueAt = DateTime(2026, 9, 22, 12);

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: dueAt,
      );

      expect(checkin.id, isNotEmpty);
      expect(checkin.transactionId, transaction.id);
      expect(checkin.dueAt, dueAt);
      expect(checkin.promptedAt, isNull);
      expect(checkin.answeredAt, isNull);
      expect(checkin.response, isNull);
      expect(checkin.isPrompted, false);
      expect(checkin.isAnswered, false);
      expect(checkin.isPending, true);

      final stored = await regretRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(stored, isNotNull);
      expect(stored!.id, checkin.id);
    });

    test('rejects scheduling a check-in for income', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 250000,
        transactionDate: DateTime(2026, 9, 20),
        description: 'Salary',
      );

      expect(
        () => regretRepository.scheduleCheckin(
          transactionId: transaction.id,
          dueAt: DateTime(2026, 9, 22),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects scheduling for missing transaction', () async {
      expect(
        () => regretRepository.scheduleCheckin(
          transactionId: 'missing-transaction',
          dueAt: DateTime(2026, 9, 22),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('requires due time to be after transaction date', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transactionDate = DateTime(2026, 9, 20, 12);

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 5000,
        moodTag: MoodTag.want,
        transactionDate: transactionDate,
      );

      expect(
        () => regretRepository.scheduleCheckin(
          transactionId: transaction.id,
          dueAt: transactionDate,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('prevents duplicate check-ins for one transaction', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Entertainment',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 4000,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      expect(
        () => regretRepository.scheduleCheckin(
          transactionId: transaction.id,
          dueAt: DateTime(2026, 9, 23),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('marks a due check-in as prompted', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 2500,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22, 12),
      );

      final promptedAt = DateTime(2026, 9, 22, 13);

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: promptedAt,
      );

      final updated = await regretRepository.getCheckinById(
        checkinId: checkin.id,
      );

      expect(updated, isNotNull);
      expect(updated!.promptedAt, promptedAt);
      expect(updated.isPrompted, true);
    });

    test('cannot prompt a check-in before it is due', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 3000,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22, 12),
      );

      expect(
        () => regretRepository.markPrompted(
          checkinId: checkin.id,
          promptedAt: DateTime(2026, 9, 22, 11),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cannot prompt the same check-in twice', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Travel',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 10000,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: DateTime(2026, 9, 22, 10),
      );

      expect(
        () => regretRepository.markPrompted(
          checkinId: checkin.id,
          promptedAt: DateTime(2026, 9, 22, 11),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('answers a prompted check-in', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 4500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      final promptedAt = DateTime(2026, 9, 22, 10);
      final answeredAt = DateTime(2026, 9, 22, 10, 5);

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: promptedAt,
      );

      await regretRepository.answerCheckin(
        checkinId: checkin.id,
        response: RegretResponse.regret,
        answeredAt: answeredAt,
      );

      final updated = await regretRepository.getCheckinById(
        checkinId: checkin.id,
      );

      expect(updated, isNotNull);
      expect(updated!.response, RegretResponse.regret);
      expect(updated.answeredAt, answeredAt);
      expect(updated.isAnswered, true);
      expect(updated.isPending, false);
    });

    test('cannot answer before the check-in has been prompted', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 3000,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      expect(
        () => regretRepository.answerCheckin(
          checkinId: checkin.id,
          response: RegretResponse.unsure,
          answeredAt: DateTime(2026, 9, 22, 12),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cannot answer before prompt time', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 6000,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: DateTime(2026, 9, 22, 12),
      );

      expect(
        () => regretRepository.answerCheckin(
          checkinId: checkin.id,
          response: RegretResponse.regret,
          answeredAt: DateTime(2026, 9, 22, 11),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cannot answer the same check-in twice', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Entertainment',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 7000,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: DateTime(2026, 9, 22, 10),
      );

      await regretRepository.answerCheckin(
        checkinId: checkin.id,
        response: RegretResponse.worthIt,
        answeredAt: DateTime(2026, 9, 22, 10, 5),
      );

      expect(
        () => regretRepository.answerCheckin(
          checkinId: checkin.id,
          response: RegretResponse.regret,
          answeredAt: DateTime(2026, 9, 22, 10, 10),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('returns only due unanswered check-ins for profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final dueTransaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 1000,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final futureTransaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 2000,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final dueCheckin = await regretRepository.scheduleCheckin(
        transactionId: dueTransaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await regretRepository.scheduleCheckin(
        transactionId: futureTransaction.id,
        dueAt: DateTime(2026, 9, 30),
      );

      final results = await regretRepository.getDueCheckins(
        profileId: profile.id,
        asOf: DateTime(2026, 9, 25),
      );

      expect(results, hasLength(1));
      expect(results.single.id, dueCheckin.id);
    });

    test('answered check-ins are excluded from due check-ins', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 2200,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await regretRepository.markPrompted(
        checkinId: checkin.id,
        promptedAt: DateTime(2026, 9, 22, 9),
      );

      await regretRepository.answerCheckin(
        checkinId: checkin.id,
        response: RegretResponse.worthIt,
        answeredAt: DateTime(2026, 9, 22, 9, 5),
      );

      final results = await regretRepository.getDueCheckins(
        profileId: profile.id,
        asOf: DateTime(2026, 9, 25),
      );

      expect(results, isEmpty);
    });

    test('deleting transaction cascades its regret check-in', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 3500,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 20),
      );

      final checkin = await regretRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await transactionRepository.deleteTransaction(
        profileId: profile.id,
        transactionId: transaction.id,
      );

      final stored = await regretRepository.getCheckinById(
        checkinId: checkin.id,
      );

      expect(stored, isNull);
    });
  });
}
