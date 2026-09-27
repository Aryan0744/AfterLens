import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/core/providers/repository_providers.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:afterlens/features/transactions/presentation/transaction_entry_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('TransactionEntryController', () {
    test(
      'eligible impulse expense is saved and automatically schedules check-in',
      () async {
        final profileRepository = container.read(profileRepositoryProvider);

        final categoryRepository = container.read(categoryRepositoryProvider);

        final regretRepository = container.read(
          regretCheckinRepositoryProvider,
        );

        final controller = container.read(
          transactionEntryControllerProvider.notifier,
        );

        final profile = await profileRepository.createLocalProfile(
          currencyCode: 'CAD',
        );

        final category = await categoryRepository.createCustomCategory(
          profileId: profile.id,
          name: 'Shopping',
        );

        final transactionDate = DateTime(2026, 9, 20, 12);

        final result = await controller.createExpense(
          profileId: profile.id,
          categoryId: category.id,
          amountCents: 3000,
          moodTag: MoodTag.impulse,
          transactionDate: transactionDate,
          description: '  Headphones  ',
        );

        // ----------------------------------------------------------
        // Transaction
        // ----------------------------------------------------------

        expect(result.transaction.amountCents, 3000);

        expect(result.transaction.moodTag, MoodTag.impulse);

        expect(result.transaction.description, 'Headphones');

        // ----------------------------------------------------------
        // Regret scheduling
        // ----------------------------------------------------------

        expect(result.regretCheckinScheduled, true);

        expect(result.regretScheduling, isNotNull);

        final checkin = await regretRepository.getCheckinForTransaction(
          transactionId: result.transaction.id,
        );

        expect(checkin, isNotNull);

        expect(checkin!.dueAt, DateTime(2026, 9, 22, 12));
      },
    );

    test('ineligible expense is saved without creating check-in', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final categoryRepository = container.read(categoryRepositoryProvider);

      final regretRepository = container.read(regretCheckinRepositoryProvider);

      final controller = container.read(
        transactionEntryControllerProvider.notifier,
      );

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Groceries',
      );

      // Need expenses are not eligible for regret reflection.
      final result = await controller.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 10000,
        moodTag: MoodTag.need,
        transactionDate: DateTime(2026, 9, 20),
      );

      expect(result.transaction.amountCents, 10000);

      expect(result.regretCheckinScheduled, false);

      final checkin = await regretRepository.getCheckinForTransaction(
        transactionId: result.transaction.id,
      );

      expect(checkin, isNull);
    });

    test('expense at exactly \$15 is saved without check-in', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final categoryRepository = container.read(categoryRepositoryProvider);

      final regretRepository = container.read(regretCheckinRepositoryProvider);

      final controller = container.read(
        transactionEntryControllerProvider.notifier,
      );

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final result = await controller.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 1500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 20),
      );

      expect(result.transaction.amountCents, 1500);

      expect(result.regretCheckinScheduled, false);

      final checkin = await regretRepository.getCheckinForTransaction(
        transactionId: result.transaction.id,
      );

      expect(checkin, isNull);
    });

    test('income is saved without entering regret flow', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final regretRepository = container.read(regretCheckinRepositoryProvider);

      final controller = container.read(
        transactionEntryControllerProvider.notifier,
      );

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final result = await controller.createIncome(
        profileId: profile.id,
        amountCents: 250000,
        transactionDate: DateTime(2026, 9, 25),
        description: 'Salary',
      );

      expect(result.transaction.type, TransactionType.income);

      expect(result.transaction.amountCents, 250000);

      expect(result.transaction.categoryId, isNull);

      expect(result.transaction.moodTag, isNull);

      expect(result.regretScheduling, isNull);

      final checkin = await regretRepository.getCheckinForTransaction(
        transactionId: result.transaction.id,
      );

      expect(checkin, isNull);
    });

    test('controller exposes success through AsyncNotifier state', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final controller = container.read(
        transactionEntryControllerProvider.notifier,
      );

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final result = await controller.createIncome(
        profileId: profile.id,
        amountCents: 50000,
        transactionDate: DateTime(2026, 9, 25),
      );

      final state = container.read(transactionEntryControllerProvider);

      expect(state.hasValue, true);

      expect(state.value?.transaction.id, result.transaction.id);
    });

    test('reset clears previous transaction result', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final controller = container.read(
        transactionEntryControllerProvider.notifier,
      );

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      await controller.createIncome(
        profileId: profile.id,
        amountCents: 50000,
        transactionDate: DateTime(2026, 9, 25),
      );

      controller.reset();

      final state = container.read(transactionEntryControllerProvider);

      expect(state.value, isNull);
    });
  });
}
