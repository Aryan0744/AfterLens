import 'reflection_summary.dart';

class CategoryInsight with ReflectionSummary {
  const CategoryInsight({
    required this.categoryName,
    required this.answeredCount,
    required this.worthItCount,
    required this.regretCount,
    required this.unsureCount,
    required this.totalReflectedSpendCents,
    required this.worthItSpendCents,
    required this.regrettedSpendCents,
    required this.unsureSpendCents,
    this.categoryId,
  });

  final String? categoryId;
  final String categoryName;

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
