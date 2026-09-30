import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/insights/presentation/insights_screen.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart';
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

  late String shoppingCategoryId;
  late String diningCategoryId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);

    categoryRepository = DriftCategoryRepository(database);

    transactionRepository = DriftTransactionRepository(database);

    profile = await profileRepository.createLocalProfile(currencyCode: 'CAD');

    final shopping = await categoryRepository.createCustomCategory(
      profileId: profile.id,
      name: 'Shopping',
    );

    final dining = await categoryRepository.createCustomCategory(
      profileId: profile.id,
      name: 'Dining',
    );

    shoppingCategoryId = shopping.id;
    diningCategoryId = dining.id;
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpInsights(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: InsightsScreen(profile: profile)),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> disposeTestApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> addCompletedReflection({
    required String checkinId,
    required String categoryId,
    required int amountCents,
    required MoodTag mood,
    required RegretResponse response,
    String? description,
  }) async {
    final transaction = await transactionRepository.createExpense(
      profileId: profile.id,
      categoryId: categoryId,
      amountCents: amountCents,
      moodTag: mood,
      transactionDate: DateTime(2026, 9, 20),
      description: description,
    );

    await database
        .into(database.regretCheckins)
        .insert(
          RegretCheckinsCompanion.insert(
            id: checkinId,
            transactionId: transaction.id,
            dueAt: DateTime(2026, 9, 22),
            promptedAt: Value(DateTime(2026, 9, 22, 9)),
            answeredAt: Value(DateTime(2026, 9, 22, 10)),
            response: Value(response),
          ),
        );
  }

  group('InsightsScreen', () {
    testWidgets('shows empty state when there are no completed reflections', (
      tester,
    ) async {
      await pumpInsights(tester);

      expect(find.byKey(const Key('insights_empty_state')), findsOneWidget);

      expect(
        find.text('Your insights will grow as you reflect'),
        findsOneWidget,
      );

      await disposeTestApp(tester);
    });

    testWidgets('shows correct overall summary and spending totals', (
      tester,
    ) async {
      await addCompletedReflection(
        checkinId: 'checkin-1',
        categoryId: shoppingCategoryId,
        amountCents: 2500,
        mood: MoodTag.impulse,
        response: RegretResponse.regret,
      );

      await addCompletedReflection(
        checkinId: 'checkin-2',
        categoryId: diningCategoryId,
        amountCents: 1500,
        mood: MoodTag.want,
        response: RegretResponse.worthIt,
      );

      await addCompletedReflection(
        checkinId: 'checkin-3',
        categoryId: diningCategoryId,
        amountCents: 1000,
        mood: MoodTag.want,
        response: RegretResponse.unsure,
      );

      await pumpInsights(tester);

      expect(find.text('Based on 3 reflections.'), findsOneWidget);

      expect(find.text('50%'), findsOneWidget);

      expect(find.text('1 regretted • 1 worth it • 1 unsure'), findsOneWidget);

      expect(find.text('CAD 15.00'), findsOneWidget);

      expect(find.text('CAD 25.00'), findsOneWidget);

      expect(find.text('CAD 10.00'), findsOneWidget);

      expect(find.text('CAD 50.00'), findsOneWidget);

      await disposeTestApp(tester);
    });

    testWidgets('shows correct mood breakdown', (tester) async {
      await addCompletedReflection(
        checkinId: 'checkin-1',
        categoryId: shoppingCategoryId,
        amountCents: 10000,
        mood: MoodTag.impulse,
        response: RegretResponse.regret,
      );

      await addCompletedReflection(
        checkinId: 'checkin-2',
        categoryId: shoppingCategoryId,
        amountCents: 5000,
        mood: MoodTag.impulse,
        response: RegretResponse.regret,
      );

      await addCompletedReflection(
        checkinId: 'checkin-3',
        categoryId: shoppingCategoryId,
        amountCents: 7500,
        mood: MoodTag.impulse,
        response: RegretResponse.worthIt,
      );

      await pumpInsights(tester);

      final moodCard = find.byKey(const ValueKey('mood_insight_impulse'));

      await tester.scrollUntilVisible(moodCard, 250);

      await tester.pumpAndSettle();

      expect(moodCard, findsOneWidget);

      expect(
        find.descendant(of: moodCard, matching: find.text('66.7% regret')),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: moodCard,
          matching: find.text('2 regret • 1 worth it • 0 unsure'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: moodCard,
          matching: find.text('3 decisive out of 3 answered'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: moodCard,
          matching: find.text('Reflected spend: CAD 225.00'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: moodCard,
          matching: find.text('Regretted spend: CAD 150.00'),
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester);
    });

    testWidgets('shows correct category breakdown', (tester) async {
      await addCompletedReflection(
        checkinId: 'checkin-1',
        categoryId: shoppingCategoryId,
        amountCents: 10000,
        mood: MoodTag.impulse,
        response: RegretResponse.regret,
      );

      await addCompletedReflection(
        checkinId: 'checkin-2',
        categoryId: shoppingCategoryId,
        amountCents: 5000,
        mood: MoodTag.want,
        response: RegretResponse.worthIt,
      );

      await pumpInsights(tester);

      final categoryCard = find.byKey(
        ValueKey('category_insight_$shoppingCategoryId'),
      );

      await tester.scrollUntilVisible(categoryCard, 250);

      await tester.pumpAndSettle();

      expect(categoryCard, findsOneWidget);

      expect(
        find.descendant(of: categoryCard, matching: find.text('Shopping')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: categoryCard, matching: find.text('50% regret')),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: categoryCard,
          matching: find.text('1 regret • 1 worth it • 0 unsure'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: categoryCard,
          matching: find.text('Reflected spend: CAD 150.00'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: categoryCard,
          matching: find.text('Regretted spend: CAD 100.00'),
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester);
    });

    testWidgets('updates automatically when a reflection is completed', (
      tester,
    ) async {
      await pumpInsights(tester);

      expect(find.byKey(const Key('insights_empty_state')), findsOneWidget);

      await addCompletedReflection(
        checkinId: 'checkin-1',
        categoryId: shoppingCategoryId,
        amountCents: 2500,
        mood: MoodTag.impulse,
        response: RegretResponse.regret,
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('insights_empty_state')), findsNothing);

      expect(find.byKey(const Key('insights_content')), findsOneWidget);

      expect(find.text('Based on 1 reflection.'), findsOneWidget);

      expect(find.text('100%'), findsOneWidget);

      expect(find.text('CAD 25.00'), findsNWidgets(2));

      await disposeTestApp(tester);
    });
  });
}
