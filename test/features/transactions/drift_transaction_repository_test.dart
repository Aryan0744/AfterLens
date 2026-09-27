import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
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

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(),
    );

    profileRepository = DriftProfileRepository(database);
    categoryRepository = DriftCategoryRepository(database);
    transactionRepository = DriftTransactionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftTransactionRepository', () {
    test('creates an expense with category and mood', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      final date = DateTime(2026, 9, 25);

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 1999,
        moodTag: MoodTag.impulse,
        transactionDate: date,
        description: '  Coffee  ',
      );

      expect(transaction.id, isNotEmpty);
      expect(transaction.profileId, profile.id);
      expect(transaction.categoryId, category.id);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.amountCents, 1999);
      expect(transaction.moodTag, MoodTag.impulse);
      expect(transaction.description, 'Coffee');
      expect(transaction.transactionDate, date);
      expect(transaction.isExpense, true);
      expect(transaction.isIncome, false);

      final stored = await transactionRepository.getTransactionById(
        transactionId: transaction.id,
      );

      expect(stored, isNotNull);
      expect(stored!.amountCents, 1999);
      expect(stored.moodTag, MoodTag.impulse);
    });

    test('creates income without category or mood', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 250000,
        transactionDate: DateTime(2026, 9, 25),
        description: 'Salary',
      );

      expect(transaction.type, TransactionType.income);
      expect(transaction.amountCents, 250000);
      expect(transaction.categoryId, isNull);
      expect(transaction.moodTag, isNull);
      expect(transaction.description, 'Salary');
      expect(transaction.isIncome, true);
      expect(transaction.isExpense, false);
    });

    test('rejects zero amount', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      expect(
            () => transactionRepository.createExpense(
          profileId: profile.id,
          categoryId: category.id,
          amountCents: 0,
          moodTag: MoodTag.need,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative amount', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => transactionRepository.createIncome(
          profileId: profile.id,
          amountCents: -100,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects transaction for missing profile', () async {
      expect(
            () => transactionRepository.createIncome(
          profileId: 'missing-profile',
          amountCents: 10000,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects expense with missing category', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => transactionRepository.createExpense(
          profileId: profile.id,
          categoryId: 'missing-category',
          amountCents: 1500,
          moodTag: MoodTag.want,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects category belonging to another profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      // The database supports multiple profiles even though the V1
      // ProfileRepository only creates one local profile.
      await database.into(database.profiles).insert(
        ProfilesCompanion.insert(
          id: 'other-profile',
          currencyCode: 'USD',
        ),
      );

      final otherCategory = await categoryRepository.createCustomCategory(
        profileId: 'other-profile',
        name: 'Travel',
      );

      expect(
            () => transactionRepository.createExpense(
          profileId: profile.id,
          categoryId: otherCategory.id,
          amountCents: 5000,
          moodTag: MoodTag.want,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects archived category for new expense', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: category.id,
      );

      expect(
            () => transactionRepository.createExpense(
          profileId: profile.id,
          categoryId: category.id,
          amountCents: 3000,
          moodTag: MoodTag.impulse,
          transactionDate: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('converts blank description to null', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 50000,
        transactionDate: DateTime.now(),
        description: '   ',
      );

      expect(transaction.description, isNull);
    });

    test('rejects description longer than 200 characters', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => transactionRepository.createIncome(
          profileId: profile.id,
          amountCents: 10000,
          transactionDate: DateTime.now(),
          description: 'A' * 201,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns transactions newest first', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 10000,
        transactionDate: DateTime(2026, 9, 20),
        description: 'Older',
      );

      await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 20000,
        transactionDate: DateTime(2026, 9, 25),
        description: 'Newer',
      );

      final transactions = await transactionRepository.getTransactions(
        profileId: profile.id,
      );

      expect(transactions, hasLength(2));
      expect(transactions[0].description, 'Newer');
      expect(transactions[1].description, 'Older');
    });

    test('deletes transaction belonging to profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 75000,
        transactionDate: DateTime.now(),
      );

      await transactionRepository.deleteTransaction(
        profileId: profile.id,
        transactionId: transaction.id,
      );

      final stored = await transactionRepository.getTransactionById(
        transactionId: transaction.id,
      );

      expect(stored, isNull);
    });

    test('cannot delete transaction through wrong profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final transaction = await transactionRepository.createIncome(
        profileId: profile.id,
        amountCents: 75000,
        transactionDate: DateTime.now(),
      );

      expect(
            () => transactionRepository.deleteTransaction(
          profileId: 'wrong-profile',
          transactionId: transaction.id,
        ),
        throwsA(isA<StateError>()),
      );

      final stored = await transactionRepository.getTransactionById(
        transactionId: transaction.id,
      );

      expect(stored, isNotNull);
    });
  });
}