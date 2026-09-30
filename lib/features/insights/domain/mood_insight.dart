import '../../transactions/domain/transaction_types.dart';

class MoodInsight {
  const MoodInsight({
    required this.mood,
    required this.answeredCount,
    required this.worthItCount,
    required this.regretCount,
    required this.unsureCount,
    required this.totalReflectedSpendCents,
    required this.worthItSpendCents,
    required this.regrettedSpendCents,
    required this.unsureSpendCents,
  });

  final MoodTag mood;

  final int answeredCount;

  final int worthItCount;
  final int regretCount;
  final int unsureCount;

  final int totalReflectedSpendCents;
  final int worthItSpendCents;
  final int regrettedSpendCents;
  final int unsureSpendCents;

  int get decisiveCount => worthItCount + regretCount;

  double? get regretRate {
    if (decisiveCount == 0) {
      return null;
    }

    return regretCount / decisiveCount;
  }

  bool hasMinimumPatternSample({int minimumSampleSize = 3}) {
    return decisiveCount >= minimumSampleSize;
  }
}
