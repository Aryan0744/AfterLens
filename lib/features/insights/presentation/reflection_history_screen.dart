import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_display.dart';
import '../../mood_engine/domain/regret_response.dart';
import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/behavioral_reflection.dart';
import 'behavioral_insights_provider.dart';

/// Displays only saved reflection values, including for removed ledger entries.
class ReflectionHistoryScreen extends ConsumerWidget {
  const ReflectionHistoryScreen({
    required this.profile,
    this.mood,
    this.categoryId,
    this.filterByCategory = false,
    this.filterLabel,
    super.key,
  });

  final AppProfile profile;
  final MoodTag? mood;
  final String? categoryId;
  final bool filterByCategory;
  final String? filterLabel;

  bool get _isFiltered => mood != null || filterByCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(completedReflectionsProvider(profile.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Reflection History')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load reflection history.'),
                TextButton(
                  onPressed: () {
                    ref.invalidate(completedReflectionsProvider(profile.id));
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (reflections) {
            final items =
                reflections
                    .where(
                      (item) =>
                          (mood == null || item.moodTag == mood) &&
                          (!filterByCategory || item.categoryId == categoryId),
                    )
                    .toList()
                  ..sort((a, b) {
                    final dateOrder = b.answeredAt.compareTo(a.answeredAt);

                    return dateOrder != 0
                        ? dateOrder
                        : a.transactionId.compareTo(b.transactionId);
                  });

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _isFiltered
                        ? 'No completed reflections '
                              'for ${filterLabel ?? 'this group'}.'
                        : 'No completed reflections yet.\n'
                              'Answer a reflection to see it here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              key: const Key('reflection_history_list'),
              padding: const EdgeInsets.all(24),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isFiltered && filterLabel != null) ...[
                          Text(
                            filterLabel!,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          '${items.length} '
                          '${items.length == 1 ? 'reviewed purchase' : 'reviewed purchases'}'
                          '${_isFiltered ? ' in this group' : ''}. '
                          'Details are saved when you reflect. '
                          'Editing or removing a transaction '
                          'does not change these answers.',
                        ),
                      ],
                    ),
                  );
                }

                return _ReflectionCard(
                  reflection: items[index - 1],
                  currencyCode: profile.currencyCode,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.reflection, required this.currencyCode});

  final BehavioralReflection reflection;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final r = reflection;

    final dates = MaterialLocalizations.of(context);

    final description = r.description?.trim();

    final category = r.categoryName?.trim();

    return Card(
      key: ValueKey(
        'reflection_history_'
        '${r.transactionId}',
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflected '
              '${dates.formatShortDate(r.answeredAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 8),

            Text(
              description == null || description.isEmpty
                  ? 'Purchase'
                  : description,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              '$currencyCode '
              '${formatMoneyCents(r.amountCents, currencyCode: currencyCode)}',
            ),

            Text(
              '${category == null || category.isEmpty ? 'Category not recorded' : category} '
              '• ${r.moodTag?.label ?? 'Mood not recorded'}',
            ),

            Text(
              'Purchased '
              '${dates.formatShortDate(r.transactionDate.toLocal())}',
            ),

            const SizedBox(height: 8),

            Text(switch (r.response) {
              RegretResponse.worthIt => 'Worth it',
              RegretResponse.regret => 'Regret',
              RegretResponse.unsure => 'Unsure',
            }, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
