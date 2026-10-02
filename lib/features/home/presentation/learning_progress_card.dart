import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../insights/presentation/behavioral_insights_provider.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/transaction_types.dart';

class LearningProgressCard extends ConsumerWidget {
  const LearningProgressCard({required this.profile, super.key});
  final AppProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(behavioralInsightsProvider(profile.id))
        .when(
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => TextButton(
            onPressed: () =>
                ref.invalidate(behavioralInsightsProvider(profile.id)),
            child: const Text('Retry learning progress'),
          ),
          data: (insights) {
            final candidates =
                insights.moodInsights
                    .where(
                      (group) =>
                          group.hasMinimumPatternSample() ||
                          group.hasUnsurePattern,
                    )
                    .toList()
                  ..sort((a, b) {
                    final countOrder = b.answeredCount.compareTo(
                      a.answeredCount,
                    );
                    return countOrder != 0
                        ? countOrder
                        : a.mood.index.compareTo(b.mood.index);
                  });
            final message = candidates.isEmpty
                ? insights.hasReflections
                      ? 'You have reviewed ${insights.answeredCount} purchases. Keep reflecting to discover patterns within a mood or category.'
                      : 'Your first reflection starts your history. Return after a purchase is ready to decide: Worth it, Regret, or Unsure.'
                : '${candidates.first.mood.label}: ${candidates.first.patternDescription} '
                      '${candidates.first.regretCount} regretted, ${candidates.first.worthItCount} worth it, '
                      '${candidates.first.unsureCount} unsure across ${candidates.first.answeredCount} reviewed purchases.';
            return Card(
              key: const Key('home_learning_progress'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidates.isEmpty
                          ? 'What AfterLens is learning'
                          : 'From your reflections',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(message),
                    TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) =>
                              InsightsScreen(profile: profile),
                        ),
                      ),
                      child: const Text('Explore Insights'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
