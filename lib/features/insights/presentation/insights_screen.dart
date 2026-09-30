import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/behavioral_insights.dart';
import '../domain/category_insight.dart';
import '../domain/mood_insight.dart';
import 'behavioral_insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsState = ref.watch(behavioralInsightsProvider(profile.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: SafeArea(
        child: insightsState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _InsightsError(
              error: error,
              onRetry: () {
                ref.invalidate(behavioralInsightsProvider(profile.id));
              },
            );
          },
          data: (insights) {
            if (!insights.hasReflections) {
              return const _EmptyInsights();
            }

            return _InsightsContent(
              insights: insights,
              currencyCode: profile.currencyCode,
            );
          },
        ),
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.insights, required this.currencyCode});

  final BehavioralInsights insights;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('insights_content'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your spending behavior',
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(height: 8),

        Text(
          'Based on ${insights.answeredCount} '
          '${insights.answeredCount == 1 ? 'reflection' : 'reflections'}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 24),

        if (!insights.hasMinimumPatternSample()) ...[
          const _EarlyDataCard(),
          const SizedBox(height: 20),
        ],

        _OverallReflectionCard(insights: insights),

        const SizedBox(height: 24),

        Text(
          'Reflected spending',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        _SpendingSummary(insights: insights, currencyCode: currencyCode),

        const SizedBox(height: 32),

        Text('By mood', style: Theme.of(context).textTheme.titleLarge),

        const SizedBox(height: 6),

        Text(
          'How your completed reflections differ '
          'across spending moods.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 14),

        ...insights.moodInsights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MoodInsightCard(
              insight: insight,
              currencyCode: currencyCode,
            ),
          );
        }),

        const SizedBox(height: 22),

        Text('By category', style: Theme.of(context).textTheme.titleLarge),

        const SizedBox(height: 6),

        Text(
          'Categories are ordered by reflected spending, '
          'not by regret percentage.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 14),

        ...insights.categoryInsights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryInsightCard(
              insight: insight,
              currencyCode: currencyCode,
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _EarlyDataCard extends StatelessWidget {
  const _EarlyDataCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Early data',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'More decisive reflections are needed '
                    'before AfterLens can treat these numbers '
                    'as a meaningful behavioral pattern.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallReflectionCard extends StatelessWidget {
  const _OverallReflectionCard({required this.insights});

  final BehavioralInsights insights;

  @override
  Widget build(BuildContext context) {
    final regretRate = insights.regretRate;

    return Card(
      key: const Key('insights_overall_summary'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decisive regret rate',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 10),

            Text(
              regretRate == null ? '—' : _formatPercentage(regretRate),
              style: Theme.of(context).textTheme.displaySmall,
            ),

            const SizedBox(height: 8),

            if (insights.decisiveCount == 0)
              const Text(
                'You have not completed a decisive '
                'Worth it or Regret reflection yet.',
              )
            else
              Text(
                '${insights.regretCount} regretted • '
                '${insights.worthItCount} worth it • '
                '${insights.unsureCount} unsure',
              ),

            const SizedBox(height: 8),

            Text(
              'Calculated from ${insights.decisiveCount} '
              'decisive '
              '${insights.decisiveCount == 1 ? 'reflection' : 'reflections'}. '
              'Unsure responses are not counted in the rate.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingSummary extends StatelessWidget {
  const _SpendingSummary({required this.insights, required this.currencyCode});

  final BehavioralInsights insights;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MoneyCard(
          label: 'Worth it',
          amountCents: insights.worthItSpendCents,
          currencyCode: currencyCode,
          icon: Icons.check_circle_outline,
        ),

        const SizedBox(height: 10),

        _MoneyCard(
          label: 'Regretted',
          amountCents: insights.regrettedSpendCents,
          currencyCode: currencyCode,
          icon: Icons.refresh_outlined,
        ),

        const SizedBox(height: 10),

        _MoneyCard(
          label: 'Unsure',
          amountCents: insights.unsureSpendCents,
          currencyCode: currencyCode,
          icon: Icons.help_outline,
        ),

        const SizedBox(height: 10),

        _MoneyCard(
          label: 'Total reflected',
          amountCents: insights.totalReflectedSpendCents,
          currencyCode: currencyCode,
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.label,
    required this.amountCents,
    required this.currencyCode,
    required this.icon,
  });

  final String label;
  final int amountCents;
  final String currencyCode;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(label),
        trailing: Text(
          '$currencyCode '
          '${_formatMoney(amountCents)}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MoodInsightCard extends StatelessWidget {
  const _MoodInsightCard({required this.insight, required this.currencyCode});

  final MoodInsight insight;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return _BreakdownCard(
      key: ValueKey('mood_insight_${insight.mood.name}'),
      title: _moodLabel(insight.mood),
      answeredCount: insight.answeredCount,
      decisiveCount: insight.decisiveCount,
      regretCount: insight.regretCount,
      worthItCount: insight.worthItCount,
      unsureCount: insight.unsureCount,
      regretRate: insight.regretRate,
      reflectedSpendCents: insight.totalReflectedSpendCents,
      regrettedSpendCents: insight.regrettedSpendCents,
      currencyCode: currencyCode,
      hasMinimumSample: insight.hasMinimumPatternSample(),
    );
  }
}

class _CategoryInsightCard extends StatelessWidget {
  const _CategoryInsightCard({
    required this.insight,
    required this.currencyCode,
  });

  final CategoryInsight insight;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return _BreakdownCard(
      key: ValueKey(
        'category_insight_'
        '${insight.categoryId ?? 'uncategorized'}',
      ),
      title: insight.categoryName,
      answeredCount: insight.answeredCount,
      decisiveCount: insight.decisiveCount,
      regretCount: insight.regretCount,
      worthItCount: insight.worthItCount,
      unsureCount: insight.unsureCount,
      regretRate: insight.regretRate,
      reflectedSpendCents: insight.totalReflectedSpendCents,
      regrettedSpendCents: insight.regrettedSpendCents,
      currencyCode: currencyCode,
      hasMinimumSample: insight.hasMinimumPatternSample(),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.answeredCount,
    required this.decisiveCount,
    required this.regretCount,
    required this.worthItCount,
    required this.unsureCount,
    required this.regretRate,
    required this.reflectedSpendCents,
    required this.regrettedSpendCents,
    required this.currencyCode,
    required this.hasMinimumSample,
    super.key,
  });

  final String title;

  final int answeredCount;
  final int decisiveCount;

  final int regretCount;
  final int worthItCount;
  final int unsureCount;

  final double? regretRate;

  final int reflectedSpendCents;
  final int regrettedSpendCents;

  final String currencyCode;

  final bool hasMinimumSample;

  @override
  Widget build(BuildContext context) {
    final rate = regretRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  rate == null
                      ? 'No decisive data'
                      : '${_formatPercentage(rate)} regret',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              '$regretCount regret • '
              '$worthItCount worth it • '
              '$unsureCount unsure',
            ),

            const SizedBox(height: 6),

            Text(
              '$decisiveCount decisive out of '
              '$answeredCount answered',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),

            Text(
              'Reflected spend: '
              '$currencyCode '
              '${_formatMoney(reflectedSpendCents)}',
            ),

            const SizedBox(height: 4),

            Text(
              'Regretted spend: '
              '$currencyCode '
              '${_formatMoney(regrettedSpendCents)}',
            ),

            if (!hasMinimumSample) ...[
              const SizedBox(height: 10),
              Text(
                'Limited sample — more decisive '
                'reflections are needed before treating '
                'this as a pattern.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('insights_empty_state'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 18),

            Text(
              'Your insights will grow '
              'as you reflect',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'After you answer reflection check-ins, '
              'AfterLens will begin showing patterns in '
              'your spending decisions.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),

            const SizedBox(height: 14),

            Text(
              'Could not load insights.',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _formatPercentage(double rate) {
  final percentage = rate * 100;

  final rounded = percentage.roundToDouble();

  if ((percentage - rounded).abs() < 0.000001) {
    return '${percentage.toStringAsFixed(0)}%';
  }

  return '${percentage.toStringAsFixed(1)}%';
}

String _formatMoney(int amountCents) {
  final dollars = amountCents ~/ 100;
  final cents = amountCents % 100;

  return '$dollars.'
      '${cents.toString().padLeft(2, '0')}';
}

String _moodLabel(MoodTag mood) {
  return switch (mood) {
    MoodTag.need => 'Need',
    MoodTag.want => 'Want',
    MoodTag.impulse => 'Impulse',
    MoodTag.social => 'Social',
    MoodTag.subscription => 'Subscription',
    MoodTag.emergency => 'Emergency',
  };
}
