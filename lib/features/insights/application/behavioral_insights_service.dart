import '../../mood_engine/domain/regret_response.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/behavioral_insights.dart';
import '../domain/behavioral_reflection.dart';
import '../domain/category_insight.dart';
import '../domain/mood_insight.dart';

class BehavioralInsightsService {
  const BehavioralInsightsService();

  static const int minimumPatternSampleSize = 3;

  BehavioralInsights analyze(List<BehavioralReflection> reflections) {
    var worthItCount = 0;
    var regretCount = 0;
    var unsureCount = 0;

    var totalReflectedSpendCents = 0;
    var worthItSpendCents = 0;
    var regrettedSpendCents = 0;
    var unsureSpendCents = 0;

    for (final reflection in reflections) {
      if (reflection.amountCents <= 0) {
        throw ArgumentError.value(
          reflection.amountCents,
          'amountCents',
          'Behavioral reflection amounts must be greater than zero.',
        );
      }

      totalReflectedSpendCents += reflection.amountCents;

      switch (reflection.response) {
        case RegretResponse.worthIt:
          worthItCount++;
          worthItSpendCents += reflection.amountCents;

        case RegretResponse.regret:
          regretCount++;
          regrettedSpendCents += reflection.amountCents;

        case RegretResponse.unsure:
          unsureCount++;
          unsureSpendCents += reflection.amountCents;
      }
    }

    return BehavioralInsights(
      answeredCount: reflections.length,
      worthItCount: worthItCount,
      regretCount: regretCount,
      unsureCount: unsureCount,
      totalReflectedSpendCents: totalReflectedSpendCents,
      worthItSpendCents: worthItSpendCents,
      regrettedSpendCents: regrettedSpendCents,
      unsureSpendCents: unsureSpendCents,
      moodInsights: _buildMoodInsights(reflections),
      categoryInsights: _buildCategoryInsights(reflections),
    );
  }

  List<MoodInsight> _buildMoodInsights(List<BehavioralReflection> reflections) {
    final result = <MoodInsight>[];

    for (final mood in MoodTag.values) {
      final moodReflections = reflections
          .where((reflection) => reflection.moodTag == mood)
          .toList();

      if (moodReflections.isEmpty) {
        continue;
      }

      var worthItCount = 0;
      var regretCount = 0;
      var unsureCount = 0;

      var totalReflectedSpendCents = 0;
      var worthItSpendCents = 0;
      var regrettedSpendCents = 0;
      var unsureSpendCents = 0;

      for (final reflection in moodReflections) {
        totalReflectedSpendCents += reflection.amountCents;

        switch (reflection.response) {
          case RegretResponse.worthIt:
            worthItCount++;
            worthItSpendCents += reflection.amountCents;

          case RegretResponse.regret:
            regretCount++;
            regrettedSpendCents += reflection.amountCents;

          case RegretResponse.unsure:
            unsureCount++;
            unsureSpendCents += reflection.amountCents;
        }
      }

      result.add(
        MoodInsight(
          mood: mood,
          answeredCount: moodReflections.length,
          worthItCount: worthItCount,
          regretCount: regretCount,
          unsureCount: unsureCount,
          totalReflectedSpendCents: totalReflectedSpendCents,
          worthItSpendCents: worthItSpendCents,
          regrettedSpendCents: regrettedSpendCents,
          unsureSpendCents: unsureSpendCents,
        ),
      );
    }

    return List.unmodifiable(result);
  }

  List<CategoryInsight> _buildCategoryInsights(
    List<BehavioralReflection> reflections,
  ) {
    final groups = <String, List<BehavioralReflection>>{};

    for (final reflection in reflections) {
      final key = reflection.categoryId ?? '__uncategorized__';

      groups.putIfAbsent(key, () => <BehavioralReflection>[]);

      groups[key]!.add(reflection);
    }

    final result = <CategoryInsight>[];

    for (final entry in groups.entries) {
      final categoryReflections = entry.value;

      var worthItCount = 0;
      var regretCount = 0;
      var unsureCount = 0;

      var totalReflectedSpendCents = 0;
      var worthItSpendCents = 0;
      var regrettedSpendCents = 0;
      var unsureSpendCents = 0;

      for (final reflection in categoryReflections) {
        totalReflectedSpendCents += reflection.amountCents;

        switch (reflection.response) {
          case RegretResponse.worthIt:
            worthItCount++;
            worthItSpendCents += reflection.amountCents;

          case RegretResponse.regret:
            regretCount++;
            regrettedSpendCents += reflection.amountCents;

          case RegretResponse.unsure:
            unsureCount++;
            unsureSpendCents += reflection.amountCents;
        }
      }

      final first = categoryReflections.first;

      final categoryName = first.categoryName?.trim().isNotEmpty == true
          ? first.categoryName!.trim()
          : 'Uncategorized';

      result.add(
        CategoryInsight(
          categoryId: first.categoryId,
          categoryName: categoryName,
          answeredCount: categoryReflections.length,
          worthItCount: worthItCount,
          regretCount: regretCount,
          unsureCount: unsureCount,
          totalReflectedSpendCents: totalReflectedSpendCents,
          worthItSpendCents: worthItSpendCents,
          regrettedSpendCents: regrettedSpendCents,
          unsureSpendCents: unsureSpendCents,
        ),
      );
    }

    result.sort((a, b) {
      final spendComparison = b.totalReflectedSpendCents.compareTo(
        a.totalReflectedSpendCents,
      );

      if (spendComparison != 0) {
        return spendComparison;
      }

      return a.categoryName.toLowerCase().compareTo(
        b.categoryName.toLowerCase(),
      );
    });

    return List.unmodifiable(result);
  }
}
