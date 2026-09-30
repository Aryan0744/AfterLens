import 'package:afterlens/features/insights/application/behavioral_insights_service.dart';
import 'package:afterlens/features/insights/domain/behavioral_reflection.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BehavioralInsightsService();

  BehavioralReflection reflection({
    required String id,
    required int amountCents,
    required MoodTag mood,
    required RegretResponse response,
    String? categoryId,
    String? categoryName,
  }) {
    return BehavioralReflection(
      transactionId: id,
      amountCents: amountCents,
      moodTag: mood,
      response: response,
      categoryId: categoryId,
      categoryName: categoryName,
      transactionDate: DateTime(2026, 9, 1),
      answeredAt: DateTime(2026, 9, 3),
    );
  }

  group('BehavioralInsightsService', () {
    test('empty data produces empty insights', () {
      final insights = service.analyze(const []);

      expect(insights.answeredCount, 0);

      expect(insights.decisiveCount, 0);

      expect(insights.regretRate, isNull);

      expect(insights.totalReflectedSpendCents, 0);

      expect(insights.worthItSpendCents, 0);

      expect(insights.regrettedSpendCents, 0);

      expect(insights.unsureSpendCents, 0);

      expect(insights.moodInsights, isEmpty);

      expect(insights.categoryInsights, isEmpty);

      expect(insights.hasReflections, isFalse);
    });

    test('regret rate excludes unsure responses', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 1000,
          mood: MoodTag.want,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '2',
          amountCents: 2000,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
        ),
        reflection(
          id: '3',
          amountCents: 3000,
          mood: MoodTag.want,
          response: RegretResponse.unsure,
        ),
      ]);

      expect(insights.answeredCount, 3);

      expect(insights.regretCount, 1);

      expect(insights.worthItCount, 1);

      expect(insights.unsureCount, 1);

      expect(insights.decisiveCount, 2);

      expect(insights.regretRate, closeTo(0.5, 0.000001));
    });

    test('regret rate is null when every response is unsure', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 2500,
          mood: MoodTag.impulse,
          response: RegretResponse.unsure,
        ),
        reflection(
          id: '2',
          amountCents: 3500,
          mood: MoodTag.want,
          response: RegretResponse.unsure,
        ),
      ]);

      expect(insights.decisiveCount, 0);

      expect(insights.regretRate, isNull);
    });

    test('calculates response counts and spend totals', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 10000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '2',
          amountCents: 5000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '3',
          amountCents: 7500,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '4',
          amountCents: 4000,
          mood: MoodTag.social,
          response: RegretResponse.worthIt,
          categoryId: 'dining',
          categoryName: 'Dining',
        ),
        reflection(
          id: '5',
          amountCents: 3000,
          mood: MoodTag.want,
          response: RegretResponse.unsure,
          categoryId: 'dining',
          categoryName: 'Dining',
        ),
        reflection(
          id: '6',
          amountCents: 6000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
          categoryId: 'gaming',
          categoryName: 'Gaming',
        ),
      ]);

      expect(insights.answeredCount, 6);

      expect(insights.regretCount, 3);

      expect(insights.worthItCount, 2);

      expect(insights.unsureCount, 1);

      expect(insights.decisiveCount, 5);

      expect(insights.regretRate, closeTo(0.6, 0.000001));

      expect(insights.regrettedSpendCents, 21000);

      expect(insights.worthItSpendCents, 11500);

      expect(insights.unsureSpendCents, 3000);

      expect(insights.totalReflectedSpendCents, 35500);
    });

    test('groups reflections by mood', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 10000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '2',
          amountCents: 5000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '3',
          amountCents: 7500,
          mood: MoodTag.impulse,
          response: RegretResponse.worthIt,
        ),
        reflection(
          id: '4',
          amountCents: 3000,
          mood: MoodTag.want,
          response: RegretResponse.unsure,
        ),
      ]);

      expect(insights.moodInsights, hasLength(2));

      final want = insights.moodInsights.firstWhere(
        (insight) => insight.mood == MoodTag.want,
      );

      expect(want.answeredCount, 1);

      expect(want.unsureCount, 1);

      expect(want.decisiveCount, 0);

      expect(want.regretRate, isNull);

      final impulse = insights.moodInsights.firstWhere(
        (insight) => insight.mood == MoodTag.impulse,
      );

      expect(impulse.answeredCount, 3);

      expect(impulse.regretCount, 2);

      expect(impulse.worthItCount, 1);

      expect(impulse.decisiveCount, 3);

      expect(impulse.regretRate, closeTo(2 / 3, 0.000001));

      expect(impulse.regrettedSpendCents, 15000);

      expect(impulse.worthItSpendCents, 7500);
    });

    test('keeps mood insights in domain mood order', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 1000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '2',
          amountCents: 1000,
          mood: MoodTag.need,
          response: RegretResponse.worthIt,
        ),
        reflection(
          id: '3',
          amountCents: 1000,
          mood: MoodTag.social,
          response: RegretResponse.unsure,
        ),
      ]);

      expect(insights.moodInsights.map((insight) => insight.mood).toList(), [
        MoodTag.need,
        MoodTag.impulse,
        MoodTag.social,
      ]);
    });

    test('groups reflections by category', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 10000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '2',
          amountCents: 5000,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '3',
          amountCents: 3000,
          mood: MoodTag.social,
          response: RegretResponse.unsure,
          categoryId: 'dining',
          categoryName: 'Dining',
        ),
      ]);

      expect(insights.categoryInsights, hasLength(2));

      final shopping = insights.categoryInsights.firstWhere(
        (insight) => insight.categoryId == 'shopping',
      );

      expect(shopping.categoryName, 'Shopping');

      expect(shopping.answeredCount, 2);

      expect(shopping.regretCount, 1);

      expect(shopping.worthItCount, 1);

      expect(shopping.totalReflectedSpendCents, 15000);

      expect(shopping.regretRate, closeTo(0.5, 0.000001));
    });

    test('sorts categories by reflected spend descending', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 3000,
          mood: MoodTag.want,
          response: RegretResponse.regret,
          categoryId: 'dining',
          categoryName: 'Dining',
        ),
        reflection(
          id: '2',
          amountCents: 10000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
        reflection(
          id: '3',
          amountCents: 5000,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
          categoryId: 'shopping',
          categoryName: 'Shopping',
        ),
      ]);

      expect(
        insights.categoryInsights
            .map((insight) => insight.categoryName)
            .toList(),
        ['Shopping', 'Dining'],
      );
    });

    test('uses Uncategorized for missing category context', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 2500,
          mood: MoodTag.want,
          response: RegretResponse.regret,
        ),
      ]);

      expect(insights.categoryInsights, hasLength(1));

      expect(insights.categoryInsights.single.categoryId, isNull);

      expect(insights.categoryInsights.single.categoryName, 'Uncategorized');
    });

    test('minimum pattern sample uses decisive responses only', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 1000,
          mood: MoodTag.impulse,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '2',
          amountCents: 1000,
          mood: MoodTag.impulse,
          response: RegretResponse.worthIt,
        ),
        reflection(
          id: '3',
          amountCents: 1000,
          mood: MoodTag.impulse,
          response: RegretResponse.unsure,
        ),
      ]);

      expect(insights.decisiveCount, 2);

      expect(
        insights.hasMinimumPatternSample(
          minimumSampleSize: BehavioralInsightsService.minimumPatternSampleSize,
        ),
        isFalse,
      );

      final impulse = insights.moodInsights.single;

      expect(impulse.decisiveCount, 2);

      expect(
        impulse.hasMinimumPatternSample(
          minimumSampleSize: BehavioralInsightsService.minimumPatternSampleSize,
        ),
        isFalse,
      );
    });

    test('three decisive responses satisfy minimum pattern sample', () {
      final insights = service.analyze([
        reflection(
          id: '1',
          amountCents: 1000,
          mood: MoodTag.want,
          response: RegretResponse.regret,
        ),
        reflection(
          id: '2',
          amountCents: 1000,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
        ),
        reflection(
          id: '3',
          amountCents: 1000,
          mood: MoodTag.want,
          response: RegretResponse.worthIt,
        ),
      ]);

      expect(
        insights.hasMinimumPatternSample(
          minimumSampleSize: BehavioralInsightsService.minimumPatternSampleSize,
        ),
        isTrue,
      );
    });

    test('rejects invalid non-positive monetary data', () {
      expect(
        () => service.analyze([
          reflection(
            id: '1',
            amountCents: 0,
            mood: MoodTag.want,
            response: RegretResponse.regret,
          ),
        ]),
        throwsArgumentError,
      );
    });
  });
}
