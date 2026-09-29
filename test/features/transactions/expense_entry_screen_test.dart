import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:afterlens/features/transactions/presentation/expense_entry_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late AppProfile profile;

  setUp(() async {
    database = AppDatabase(
      NativeDatabase.memory(),
    );

    profileRepository = DriftProfileRepository(
      database,
    );

    categoryRepository = DriftCategoryRepository(
      database,
    );

    profile = await profileRepository.createLocalProfile(
      currencyCode: 'CAD',
    );

    await categoryRepository.createCustomCategory(
      profileId: profile.id,
      name: 'Groceries',
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> openExpenseScreen(
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            database,
          ),
        ],
        child: MaterialApp(
          home: _ExpenseTestHost(
            profile: profile,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const Key('open_expense'),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(ExpenseEntryScreen),
      findsOneWidget,
    );
  }

  Future<void> selectGroceries(
      WidgetTester tester,
      ) async {
    await tester.tap(
      find.byKey(
        const Key('expense_category'),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Groceries').last,
    );

    await tester.pumpAndSettle();
  }

  Future<void> selectMood(
      WidgetTester tester,
      MoodTag mood,
      ) async {
    final moodChip = find.byKey(
      ValueKey(
        'expense_mood_${mood.name}',
      ),
    );

    expect(
      moodChip,
      findsOneWidget,
    );

    await tester.tap(
      moodChip,
    );

    await tester.pump();
  }

  Future<void> tapSave(
      WidgetTester tester,
      ) async {
    tester.testTextInput.hide();

    await tester.pump();

    final saveButton = find.byKey(
      const Key('expense_save'),
    );

    await tester.scrollUntilVisible(
      saveButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();

    expect(
      saveButton,
      findsOneWidget,
    );

    await tester.tap(
      saveButton,
    );
  }

  Future<void> disposeTestApp(
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const SizedBox.shrink(),
    );

    await tester.pump(
      const Duration(
        milliseconds: 1,
      ),
    );
  }

  group('ExpenseEntryScreen', () {
    testWidgets(
      'valid impulse expense is saved and schedules regret check-in',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '19.99',
        );

        await selectGroceries(
          tester,
        );

        await selectMood(
          tester,
          MoodTag.impulse,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_description'),
          ),
          'Headphones',
        );

        await tapSave(
          tester,
        );

        await tester.pumpAndSettle();

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          hasLength(1),
        );

        final transaction = transactions.single;

        expect(
          transaction.amountCents,
          1999,
        );

        expect(
          transaction.moodTag,
          MoodTag.impulse,
        );

        expect(
          transaction.description,
          'Headphones',
        );

        expect(
          transaction.profileId,
          profile.id,
        );

        final checkins =
        await database.select(database.regretCheckins).get();

        expect(
          checkins,
          hasLength(1),
        );

        expect(
          checkins.single.transactionId,
          transaction.id,
        );

        expect(
          find.byKey(
            const Key('open_expense'),
          ),
          findsOneWidget,
        );

        expect(
          find.byType(ExpenseEntryScreen),
          findsNothing,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'exactly 15 dollar impulse expense does not schedule check-in',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '15.00',
        );

        await selectGroceries(
          tester,
        );

        await selectMood(
          tester,
          MoodTag.impulse,
        );

        await tapSave(
          tester,
        );

        await tester.pumpAndSettle();

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          hasLength(1),
        );

        expect(
          transactions.single.amountCents,
          1500,
        );

        expect(
          transactions.single.moodTag,
          MoodTag.impulse,
        );

        final checkins =
        await database.select(database.regretCheckins).get();

        expect(
          checkins,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'amount above 15 dollars for want schedules check-in',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '15.01',
        );

        await selectGroceries(
          tester,
        );

        await selectMood(
          tester,
          MoodTag.want,
        );

        await tapSave(
          tester,
        );

        await tester.pumpAndSettle();

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          hasLength(1),
        );

        expect(
          transactions.single.amountCents,
          1501,
        );

        expect(
          transactions.single.moodTag,
          MoodTag.want,
        );

        final checkins =
        await database.select(database.regretCheckins).get();

        expect(
          checkins,
          hasLength(1),
        );

        expect(
          checkins.single.transactionId,
          transactions.single.id,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'need expense does not schedule regret check-in',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '100.00',
        );

        await selectGroceries(
          tester,
        );

        await selectMood(
          tester,
          MoodTag.need,
        );

        await tapSave(
          tester,
        );

        await tester.pumpAndSettle();

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          hasLength(1),
        );

        expect(
          transactions.single.amountCents,
          10000,
        );

        expect(
          transactions.single.moodTag,
          MoodTag.need,
        );

        final checkins =
        await database.select(database.regretCheckins).get();

        expect(
          checkins,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'amount with more than two decimal places is rejected',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '19.999',
        );

        await tapSave(
          tester,
        );

        await tester.pump();

        expect(
          find.text(
            'Enter a valid amount greater than zero.',
          ),
          findsOneWidget,
        );

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'zero amount is rejected',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '0',
        );

        await tapSave(
          tester,
        );

        await tester.pump();

        expect(
          find.text(
            'Enter a valid amount greater than zero.',
          ),
          findsOneWidget,
        );

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'missing category prevents save',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '25.00',
        );

        await selectMood(
          tester,
          MoodTag.want,
        );

        await tapSave(
          tester,
        );

        await tester.pump();

        expect(
          find.text(
            'Select a category.',
          ),
          findsOneWidget,
        );

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );

    testWidgets(
      'missing mood prevents save',
          (tester) async {
        await openExpenseScreen(
          tester,
        );

        await tester.enterText(
          find.byKey(
            const Key('expense_amount'),
          ),
          '25.00',
        );

        await selectGroceries(
          tester,
        );

        await tapSave(
          tester,
        );

        await tester.pump();

        expect(
          find.text(
            'Select a mood before saving.',
          ),
          findsOneWidget,
        );

        final transactions =
        await database.select(database.transactions).get();

        expect(
          transactions,
          isEmpty,
        );

        await disposeTestApp(
          tester,
        );
      },
    );
  });
}

class _ExpenseTestHost extends StatelessWidget {
  const _ExpenseTestHost({
    required this.profile,
  });

  final AppProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key(
            'open_expense',
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) {
                  return ExpenseEntryScreen(
                    profile: profile,
                  );
                },
              ),
            );
          },
          child: const Text(
            'Open expense',
          ),
        ),
      ),
    );
  }
}