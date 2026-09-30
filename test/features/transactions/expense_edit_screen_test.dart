import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:afterlens/features/transactions/presentation/expense_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mood_engine/regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
  });
  tearDown(() => f.database.close());

  for (final answered in [false, true]) {
    testWidgets(
      'edit form ${answered ? 'explains a completed reflection and stays editable' : 'omits the notice for an unanswered reflection'}',
      (tester) async {
        final purchase = await f.expense(amountCents: 8000);
        final prompt = (await f.select()).prompt!;
        if (answered) {
          await f.service.answerPrompt(
            profileId: f.profile.id,
            checkinId: prompt.checkin.id,
            response: RegretResponse.regret,
            asOf: f.now,
          );
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(f.database)],
            child: MaterialApp(
              home: ExpenseEditScreen(
                profile: f.profile,
                transaction: purchase,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'This purchase already has a completed reflection. Editing the transaction will not change your past reflection.',
          ),
          answered ? findsOneWidget : findsNothing,
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('edit_expense_amount')),
              )
              .enabled,
          isTrue,
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('edit_expense_description')),
              )
              .enabled,
          isTrue,
        );
        expect(
          tester
              .widget<DropdownButtonFormField<String>>(
                find.byKey(const Key('edit_expense_category')),
              )
              .onChanged,
          isNotNull,
        );
        expect(
          tester
              .widget<ListTile>(find.byKey(const Key('edit_expense_date')))
              .onTap,
          isNotNull,
        );

        await tester.enterText(
          find.byKey(const Key('edit_expense_amount')),
          '90.00',
        );
        final need = find.byKey(const ValueKey('edit_expense_mood_need'));
        await tester.ensureVisible(need);
        await tester.tap(need);
        final save = find.byKey(const Key('edit_expense_save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        final ledger = (await f.transactions.getTransactionById(
          transactionId: purchase.id,
        ))!;
        expect(ledger.amountCents, 9000);
        expect(ledger.moodTag, MoodTag.need);
        final checkin = await f.checkins.getCheckinForTransaction(
          transactionId: purchase.id,
        );
        if (answered) {
          expect(checkin!.snapshot!.amountCents, 8000);
          expect(checkin.snapshot!.moodTag, MoodTag.impulse);
        } else {
          expect(checkin, isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }
}
