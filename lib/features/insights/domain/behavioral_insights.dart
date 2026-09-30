import 'category_insight.dart';
import 'mood_insight.dart';

class BehavioralInsights {
  const BehavioralInsights({
    required this.answeredCount,
    required this.worthItCount,
    required this.regretCount,
    required this.unsureCount,
    required this.totalReflectedSpendCents,
    required this.worthItSpendCents,
    required this.regrettedSpendCents,
    required this.unsureSpendCents,
    required this.moodInsights,
    required this.categoryInsights,
  });

  final int answeredCount;

  final int worthItCount;
  final int regretCount;
  final int unsureCount;

  final int totalReflectedSpendCents;
  final int worthItSpendCents;
  final int regrettedSpendCents;
  final int unsureSpendCents;

  final List<MoodInsight> moodInsights;
  final List<CategoryInsight> categoryInsights;

  int get decisiveCount => worthItCount + regretCount;

  double? get regretRate {
    if (decisiveCount == 0) {
      return null;
    }

    return regretCount / decisiveCount;
  }

  bool get hasReflections => answeredCount > 0;

  bool hasMinimumPatternSample({int minimumSampleSize = 3}) {
    return decisiveCount >= minimumSampleSize;
  }
}
