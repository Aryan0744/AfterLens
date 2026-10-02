import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/insights/domain/behavioral_reflection.dart';
import 'package:afterlens/features/insights/presentation/behavioral_insights_provider.dart';
import 'package:afterlens/features/insights/presentation/reflection_history_screen.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
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

  for (final filter in ['mood', 'category', 'uncategorized']) {
    testWidgets(
      'history filters $filter using saved fields and handles missing context',
      (tester) async {
        final reflections = [
          BehavioralReflection(
            transactionId: 'impulse',
            amountCents: 8000,
            moodTag: MoodTag.impulse,
            response: RegretResponse.regret,
            categoryId: 'old-category',
            categoryName: 'Old category name',
            description: 'Original purchase',
            transactionDate: f.now,
            answeredAt: f.now,
          ),
          BehavioralReflection(
            transactionId: 'legacy',
            amountCents: 5000,
            moodTag: null,
            response: RegretResponse.unsure,
            transactionDate: f.now,
            answeredAt: f.now,
          ),
          BehavioralReflection(
            transactionId: 'want',
            amountCents: 2500,
            moodTag: MoodTag.want,
            response: RegretResponse.worthIt,
            categoryId: 'other',
            categoryName: 'Other',
            description: 'Different purchase',
            transactionDate: f.now,
            answeredAt: f.now,
          ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              completedReflectionsProvider(f.profile.id)
                  .overrideWith((ref) => Stream.value(reflections)),
            ],
            child: MaterialApp(
              home: ReflectionHistoryScreen(
                profile: f.profile,
                mood: filter == 'mood' ? MoodTag.impulse : null,
                categoryId: filter == 'category' ? 'old-category' : null,
                filterByCategory: filter != 'mood',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Different purchase'), findsNothing);
        if (filter == 'uncategorized') {
          expect(find.text('Purchase'), findsOneWidget);
          expect(
            find.text('Category not recorded • Mood not recorded'),
            findsOneWidget,
          );
          expect(find.text('Original purchase'), findsNothing);
        } else {
          expect(find.text('Original purchase'), findsOneWidget);
          expect(find.text('Old category name • Impulse'), findsOneWidget);
          expect(find.text('Purchase'), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }

  Future<void> pumpHistory(WidgetTester tester, {MoodTag? mood}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(f.database)],
        child: MaterialApp(
          home: ReflectionHistoryScreen(profile: f.profile, mood: mood),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'history stays truthful after ledger edits and removal, newest answer first',
    (tester) async {
      final first = await f.expense(amountCents: 8000);
      var prompt = (await f.select()).prompt!;
      await f.service.answerPrompt(
        profileId: f.profile.id,
        checkinId: prompt.checkin.id,
        response: RegretResponse.regret,
        asOf: f.now,
      );
      final second = await f.expense(description: 'Shoes', mood: MoodTag.want);
      prompt = (await f.select()).prompt!;
      await f.service.answerPrompt(
        profileId: f.profile.id,
        checkinId: prompt.checkin.id,
        response: RegretResponse.unsure,
        asOf: f.now.add(const Duration(minutes: 1)),
      );
      await f.transactions.updateExpense(
        profileId: f.profile.id,
        transactionId: first.id,
        categoryId: f.categoryId,
        amountCents: 9900,
        moodTag: MoodTag.need,
        transactionDate: f.now,
        description: 'Changed ledger',
      );
      await f.transactions.deleteTransaction(
        profileId: f.profile.id,
        transactionId: first.id,
      );
      await f.expense(description: 'Unanswered purchase');

      await pumpHistory(tester);
      expect(find.text('CAD 80.00'), findsOneWidget);
      expect(find.text('Headphones'), findsOneWidget);
      expect(find.text('Shopping • Impulse'), findsOneWidget);
      expect(find.text('Regret'), findsOneWidget);
      expect(find.text('Unsure'), findsOneWidget);
      expect(find.text('Changed ledger'), findsNothing);
      expect(find.text('Unanswered purchase'), findsNothing);
      expect(
        tester
            .getTopLeft(find.byKey(ValueKey('reflection_history_${second.id}')))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(ValueKey('reflection_history_${first.id}')),
              )
              .dy,
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('empty and recoverable failure states', (tester) async {
    await pumpHistory(tester);
    expect(
      find.textContaining('No completed reflections yet.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          completedReflectionsProvider(f.profile.id).overrideWith((ref) {
            attempts++;
            return attempts == 1
                ? Stream.error(StateError('offline'))
                : Stream.value([]);
          }),
        ],
        child: MaterialApp(home: ReflectionHistoryScreen(profile: f.profile)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load reflection history.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No completed reflections yet.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
