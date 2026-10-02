import 'reflection_summary.dart';
import '../../transactions/domain/transaction_types.dart';

class MoodInsight with ReflectionSummary {
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
}
