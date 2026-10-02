import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/behavioral_insights.dart';
import '../domain/reflection_summary.dart';
import 'behavioral_insights_provider.dart';
import 'reflection_history_screen.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({required this.profile, super.key});
  final AppProfile profile;

  void _openHistory(
    BuildContext context, {
    MoodTag? mood,
    String? categoryId,
    bool filterByCategory = false,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ReflectionHistoryScreen(
          profile: profile,
          mood: mood,
          categoryId: categoryId,
          filterByCategory: filterByCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(behavioralInsightsProvider(profile.id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            key: const Key('insights_view_history'),
            tooltip: 'Reflection History',
            icon: const Icon(Icons.history),
            onPressed: () => _openHistory(context),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load insights.'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(behavioralInsightsProvider(profile.id)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (insights) {
            if (!insights.hasReflections) {
              return const Center(
                key: Key('insights_empty_state'),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insights_outlined, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Your insights will grow as you reflect',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Record a purchase, return for a reflection, and discover what felt worth it over time.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              key: const Key('insights_content'),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Your reflection overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on ${insights.answeredCount} ${insights.answeredCount == 1 ? 'reflection' : 'reflections'}.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'These are the purchases you reviewed, not all your spending. Patterns describe your answers; they do not predict future purchases.',
                ),
                const SizedBox(height: 16),
                _Overview(insights: insights),
                const SizedBox(height: 24),
                Text(
                  'Reflected spending',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _MoneyRow(
                  label: 'Total reflected',
                  cents: insights.totalReflectedSpendCents,
                  currency: profile.currencyCode,
                ),
                _MoneyRow(
                  label: 'Worth it',
                  cents: insights.worthItSpendCents,
                  currency: profile.currencyCode,
                ),
                _MoneyRow(
                  label: 'Regretted',
                  cents: insights.regrettedSpendCents,
                  currency: profile.currencyCode,
                ),
                _MoneyRow(
                  label: 'Unsure',
                  cents: insights.unsureSpendCents,
                  currency: profile.currencyCode,
                ),
                const SizedBox(height: 24),
                Text('By mood', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  '0–2 decisive answers: not enough data. 3–5: early pattern. 6 or more: pattern. These labels describe sample size, not certainty.',
                ),
                const SizedBox(height: 12),
                for (final insight in insights.moodInsights)
                  _BreakdownCard(
                    key: ValueKey('mood_insight_${insight.mood.name}'),
                    title: insight.mood.label,
                    summary: insight,
                    spend: insight.totalReflectedSpendCents,
                    regrettedSpend: insight.regrettedSpendCents,
                    currency: profile.currencyCode,
                    onHistory: () => _openHistory(context, mood: insight.mood),
                  ),
                const SizedBox(height: 24),
                Text(
                  'By category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ordered by reflected spending. Saved category names may differ from current names.',
                ),
                const SizedBox(height: 12),
                for (final insight in insights.categoryInsights)
                  _BreakdownCard(
                    key: ValueKey(
                      'category_insight_${insight.categoryId ?? 'uncategorized'}',
                    ),
                    title: insight.categoryName,
                    summary: insight,
                    spend: insight.totalReflectedSpendCents,
                    regrettedSpend: insight.regrettedSpendCents,
                    currency: profile.currencyCode,
                    onHistory: () => _openHistory(
                      context,
                      categoryId: insight.categoryId,
                      filterByCategory: true,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.insights});
  final BehavioralInsights insights;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('insights_overall_summary'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviewed purchases: ${insights.answeredCount}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '${insights.regretCount} regretted • ${insights.worthItCount} worth it • ${insights.unsureCount} unsure',
          ),
          const SizedBox(height: 12),
          Text(insights.patternDescription),
          const SizedBox(height: 8),
          _OutcomeRates(summary: insights),
        ],
      ),
    ),
  );
}

class _OutcomeRates extends StatelessWidget {
  const _OutcomeRates({required this.summary});
  final ReflectionSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (summary.hasMinimumPatternSample()) ...[
        Text('${_percentage(summary.regretRate!)} regret'),
        Text('${_percentage(summary.worthItRate!)} worth it'),
        Text(
          'Of ${summary.decisiveCount} decisive answers (Worth it or Regret). Unsure is counted separately.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      if (summary.answeredCount >= 3)
        Text(
          '${_percentage(summary.unsureRate!)} unsure of all ${summary.answeredCount} reviewed purchases.',
        ),
    ],
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.cents,
    required this.currency,
  });
  final String label;
  final int cents;
  final String currency;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 24,
        runSpacing: 4,
        children: [
          Text(label),
          Text(
            '$currency ${_money(cents)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.summary,
    required this.spend,
    required this.regrettedSpend,
    required this.currency,
    required this.onHistory,
    super.key,
  });
  final String title;
  final ReflectionSummary summary;
  final int spend;
  final int regrettedSpend;
  final String currency;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${summary.answeredCount} reviewed'),
          Text(
            '${summary.regretCount} regret • ${summary.worthItCount} worth it • ${summary.unsureCount} unsure',
          ),
          Text(
            '${summary.decisiveCount} decisive out of ${summary.answeredCount} answered',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(summary.patternDescription),
          const SizedBox(height: 8),
          _OutcomeRates(summary: summary),
          const SizedBox(height: 12),
          Text('Reflected spend: $currency ${_money(spend)}'),
          Text('Regretted spend: $currency ${_money(regrettedSpend)}'),
          TextButton(
            onPressed: onHistory,
            child: const Text('View these reflections'),
          ),
        ],
      ),
    ),
  );
}

String _money(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
String _percentage(double rate) {
  final value = rate * 100;
  return '${value.toStringAsFixed((value - value.round()).abs() < 0.000001 ? 0 : 1)}%';
}
