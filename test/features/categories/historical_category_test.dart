import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:afterlens/features/transactions/presentation/expense_edit_screen.dart';
import 'package:afterlens/features/transactions/presentation/transaction_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mood_engine/regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  late DriftCategoryRepository categories;
  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
    categories = DriftCategoryRepository(f.database);
  });
  tearDown(() => f.database.close());

  test(
    'archived category can stay on an edit but cannot be newly assigned',
    () async {
      final purchase = await f.expense();
      await categories.archiveCategory(
        profileId: f.profile.id,
        categoryId: f.categoryId,
      );
      final updated = await f.transactions.updateExpense(
        profileId: f.profile.id,
        transactionId: purchase.id,
        categoryId: f.categoryId,
        amountCents: 6000,
        moodTag: MoodTag.want,
        transactionDate: purchase.transactionDate,
      );
      expect(updated.categoryId, f.categoryId);
      expect(updated.amountCents, 6000);
      await expectLater(f.expense(), throwsStateError);

      final active = await categories.createCustomCategory(
        profileId: f.profile.id,
        name: 'Dining',
      );
      await f.transactions.updateExpense(
        profileId: f.profile.id,
        transactionId: purchase.id,
        categoryId: active.id,
        amountCents: 6000,
        moodTag: MoodTag.want,
        transactionDate: purchase.transactionDate,
      );
      await expectLater(
        f.transactions.updateExpense(
          profileId: f.profile.id,
          transactionId: purchase.id,
          categoryId: f.categoryId,
          amountCents: 6000,
          moodTag: MoodTag.want,
          transactionDate: purchase.transactionDate,
        ),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'details and edit preserve an archived category, excluding other archives',
    (tester) async {
      final purchase = await f.expense();
      final other = await categories.createCustomCategory(
        profileId: f.profile.id,
        name: 'Travel',
      );
      for (final id in [f.categoryId, other.id]) {
        await categories.archiveCategory(
          profileId: f.profile.id,
          categoryId: id,
        );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(f.database)],
          child: MaterialApp(
            home: TransactionDetailsScreen(
              profile: f.profile,
              transaction: purchase,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shopping'), findsOneWidget);
      await tester.tap(find.byKey(const Key('transaction_edit')));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseEditScreen), findsOneWidget);
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('edit_expense_category')),
      );
      expect(field.initialValue, f.categoryId);
      expect(find.text('Shopping (archived)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit_expense_category')));
      await tester.pumpAndSettle();
      expect(find.text('Travel (archived)'), findsNothing);
      await tester.tap(find.text('Shopping (archived)').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit_expense_amount')),
        '60.00',
      );
      final save = find.byKey(const Key('edit_expense_save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseEditScreen), findsNothing);
      expect(
        (await f.transactions.getTransactionById(transactionId: purchase.id))!
            .amountCents,
        6000,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
