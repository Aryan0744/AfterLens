import 'package:afterlens/features/insights/application/behavioral_insights_service.dart';
import 'package:afterlens/features/insights/domain/behavioral_reflection.dart';
import 'package:afterlens/features/insights/domain/reflection_summary.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BehavioralReflection reflection(RegretResponse response) =>
      BehavioralReflection(
        transactionId: 'purchase',
        amountCents: 2500,
        moodTag: MoodTag.impulse,
        response: response,
        transactionDate: DateTime(2026, 9, 20),
        answeredAt: DateTime(2026, 9, 23),
        categoryId: 'shopping',
        categoryName: 'Shopping',
      );
  const service = BehavioralInsightsService();

  test(
    'sample tiers apply to every group at 0, 2, 3, 5 and 6 decisive answers',
    () {
      for (final count in [0, 2, 3, 5, 6]) {
        final result = service.analyze([
          for (var i = 0; i < count; i++) reflection(RegretResponse.regret),
          reflection(RegretResponse.unsure),
        ]);
        final expected = count < 3
            ? PatternStage.insufficient
            : count < 6
            ? PatternStage.early
            : PatternStage.established;
        for (final summary in [
          result,
          ...result.moodInsights,
          ...result.categoryInsights,
        ]) {
          expect(summary.patternStage, expected);
          expect(summary.hasMinimumPatternSample(), count >= 3);
        }
      }
    },
  );

  test(
    'uncertainty has its own denominator and needs three unsure answers',
    () {
      final result = service.analyze([
        reflection(RegretResponse.worthIt),
        reflection(RegretResponse.worthIt),
        reflection(RegretResponse.regret),
        for (var i = 0; i < 7; i++) reflection(RegretResponse.unsure),
      ]);
      for (final summary in [
        result,
        ...result.moodInsights,
        ...result.categoryInsights,
      ]) {
        expect(summary.worthItRate, closeTo(2 / 3, 0.0001));
        expect(summary.regretRate, closeTo(1 / 3, 0.0001));
        expect(summary.unsureRate, 0.7);
        expect(
          summary.patternDescription,
          'Pattern: often unsure about value (7 of 10 reviewed).',
        );
      }
      expect(
        service.analyze([
          reflection(RegretResponse.unsure),
          reflection(RegretResponse.unsure),
        ]).hasUnsurePattern,
        isFalse,
      );
      final onlyUnsure = service.analyze(
        List.generate(3, (_) => reflection(RegretResponse.unsure)),
      );
      expect(onlyUnsure.regretRate, isNull);
      expect(onlyUnsure.worthItRate, isNull);
      expect(onlyUnsure.unsureRate, 1);
      expect(
        onlyUnsure.patternDescription,
        startsWith('Early pattern: often unsure'),
      );
      expect(service.analyze([]).unsureRate, isNull);
    },
  );
}
