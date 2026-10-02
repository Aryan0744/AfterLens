import 'reflection_summary.dart';
import 'category_insight.dart';
import 'mood_insight.dart';

class BehavioralInsights with ReflectionSummary {
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

  @override
  final int answeredCount;

  @override
  final int worthItCount;
  @override
  final int regretCount;
  @override
  final int unsureCount;

  final int totalReflectedSpendCents;
  final int worthItSpendCents;
  final int regrettedSpendCents;
  final int unsureSpendCents;

  final List<MoodInsight> moodInsights;
  final List<CategoryInsight> categoryInsights;

  bool get hasReflections => answeredCount > 0;
}
