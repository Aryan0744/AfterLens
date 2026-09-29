import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/home/presentation/home_screen.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late DriftTransactionRepository transactionRepository;

  late AppProfile profile;
  late String groceriesCategoryId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);

    categoryRepository = DriftCategoryRepository(database);

    transactionRepository = DriftTransactionRepository(database);

    profile = await profileRepository.createLocalProfile(currencyCode: 'CAD');

    final groceries = await categoryRepository.createCustomCategory(
      profileId: profile.id,
      name: 'Groceries',
    );

    groceriesCategoryId = groceries.id;
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: HomeScreen(profile: profile, categoryCount: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> disposeTestApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pump(const Duration(milliseconds: 1));
  }

  group('HomeScreen recent transactions', () {
    testWidgets('shows empty state when there are no transactions', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Recent transactions'), findsOneWidget);

      expect(find.text('No transactions yet'), findsOneWidget);

      expect(
        find.text('Your recent expenses and income will appear here.'),
        findsOneWidget,
      );

      await disposeTestApp(tester);
    });

    testWidgets('shows an existing transaction', (tester) async {
      await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: groceriesCategoryId,
        amountCents: 1250,
        moodTag: MoodTag.need,
        transactionDate: DateTime(2026, 9, 29),
        description: 'Coffee',
      );

      await pumpHome(tester);

      expect(find.text('Coffee'), findsOneWidget);

      expect(find.text('-CAD 12.50'), findsOneWidget);

      expect(find.textContaining('Need'), findsOneWidget);

      expect(find.text('No transactions yet'), findsNothing);

      await disposeTestApp(tester);
    });

    testWidgets('updates automatically when a new transaction is created', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('No transactions yet'), findsOneWidget);

      expect(find.text('Headphones'), findsNothing);

      await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: groceriesCategoryId,
        amountCents: 2350,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 29),
        description: 'Headphones',
      );

      await tester.pumpAndSettle();

      expect(find.text('Headphones'), findsOneWidget);

      expect(find.text('-CAD 23.50'), findsOneWidget);

      expect(find.textContaining('Want'), findsOneWidget);

      expect(find.text('No transactions yet'), findsNothing);

      await disposeTestApp(tester);
    });
  });
}
