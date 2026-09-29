import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/mood_engine/application/regret_scheduling_service.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
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

  late RegretSchedulingService schedulingService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);
    categoryRepository = DriftCategoryRepository(database);
    transactionRepository = DriftTransactionRepository(database);
    regretRepository = DriftRegretCheckinRepository(database);

    schedulingService = RegretSchedulingService(
      eligibilityPolicy: RegretEligibilityPolicy(),
      checkinRepository: regretRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('RegretSchedulingService', () {
    test('schedules eligible impulse expense', () async {
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
        amountCents: 3000,
        moodTag: MoodTag.impulse,
        transactionDate: transactionDate,
      );

      final result = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(result.status, RegretSchedulingStatus.scheduled);

      expect(result.checkin, isNotNull);

      expect(result.checkin!.transactionId, transaction.id);

      expect(result.checkin!.dueAt, DateTime(2026, 9, 22, 12));

      expect(result.ineligibilityReason, isNull);
    });

    test('schedules eligible want expense', () async {
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

      final result = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(result.status, RegretSchedulingStatus.scheduled);

      expect(result.checkin, isNotNull);
    });

    test('does not schedule expense exactly at threshold', () async {
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
        amountCents: 1500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final result = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(result.status, RegretSchedulingStatus.ineligible);

      expect(
        result.ineligibilityReason,
        RegretIneligibilityReason.amountNotAboveThreshold,
      );

      expect(result.checkin, isNull);

      final stored = await regretRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(stored, isNull);
    });

    test('does not schedule income', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 500000,
        transactionDate: DateTime(2026, 9, 20),
      );

      final result = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(result.status, RegretSchedulingStatus.ineligible);

      expect(result.ineligibilityReason, RegretIneligibilityReason.notExpense);

      expect(result.checkin, isNull);
    });

    test('does not schedule non-eligible mood', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Groceries',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 10000,
        moodTag: MoodTag.need,
        transactionDate: DateTime(2026, 9, 20),
      );

      final result = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(result.status, RegretSchedulingStatus.ineligible);

      expect(
        result.ineligibilityReason,
        RegretIneligibilityReason.moodNotEligible,
      );
    });

    test('calling service twice does not create duplicate check-in', () async {
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
        amountCents: 4500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      final first = await schedulingService.scheduleForTransaction(transaction);

      final second = await schedulingService.scheduleForTransaction(
        transaction,
      );

      expect(first.status, RegretSchedulingStatus.scheduled);

      expect(second.status, RegretSchedulingStatus.alreadyScheduled);

      expect(second.checkin!.id, first.checkin!.id);

      final stored = await regretRepository.getCheckinForTransaction(
        transactionId: transaction.id,
      );

      expect(stored, isNotNull);
      expect(stored!.id, first.checkin!.id);
    });
  });
}
