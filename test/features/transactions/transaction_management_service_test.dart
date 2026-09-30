import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
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

    test('prompted check-in is preserved after expense edit', () async {
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

      expect(result.regretStatus, RegretReconciliationStatus.preserved);

      final preserved = await checkinRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(preserved, isNotNull);

      expect(preserved!.id, checkin.id);

      expect(preserved.promptedAt, DateTime(2026, 9, 22, 10));
    });

    test('delete transaction cascades regret check-in', () async {
      final transaction = await createExpense(
        amountCents: 2500,
        mood: MoodTag.impulse,
      );

      final checkin = await checkinRepository.scheduleCheckin(
        transactionId: transaction.id,
        dueAt: DateTime(2026, 9, 22),
      );

      await service.deleteTransaction(
        profileId: profile.id,
        transactionId: transaction.id,
      );

      final deletedTransaction = await transactionRepository.getTransactionById(
        transactionId: transaction.id,
      );

      final deletedCheckin = await checkinRepository.getCheckinById(
        checkinId: checkin.id,
      );

      expect(deletedTransaction, isNull);

      expect(deletedCheckin, isNull);
    });

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
