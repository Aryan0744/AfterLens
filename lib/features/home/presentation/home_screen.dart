import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/afterlens_logo.dart';
import '../../../core/formatting/money_display.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../insights/presentation/reflection_history_screen.dart';
import '../../mood_engine/application/regret_prompt_result.dart';
import '../../mood_engine/presentation/regret_checkin_screen.dart';
import '../../mood_engine/presentation/regret_prompt_card.dart';
import '../../mood_engine/presentation/regret_prompt_controller.dart';
import '../../profile/domain/app_profile.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transactions/domain/app_transaction.dart';
import '../../transactions/domain/transaction_types.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/expense_entry_screen.dart';
import '../../transactions/presentation/transaction_details_screen.dart';
import '../../transactions/presentation/transaction_providers.dart';
import 'learning_progress_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.profile,
    required this.categoryCount,
    super.key,
  });

  final AppProfile profile;
  final int categoryCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider(profile.id));

    final promptState = ref.watch(regretPromptControllerProvider(profile.id));

    return Scaffold(
      appBar: AppBar(
        title: const AfterLensLogo(width: 130),
        actions: [
          IconButton(
            key: const Key('home_settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) {
                    return SettingsScreen(profile: profile);
                  },
                ),
              );
            },
          ),
          IconButton(
            key: const Key('home_view_history'),
            tooltip: 'Reflection History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) {
                    return ReflectionHistoryScreen(profile: profile);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider(profile.id));

            ref.invalidate(regretPromptControllerProvider(profile.id));

            await ref.read(transactionsProvider(profile.id).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Spend with better hindsight.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 10),

              Text(
                'Record a purchase. Reflect later. '
                'Learn what feels worth it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              promptState.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) {
                  return ListTile(
                    title: const Text('Could not load reflections.'),
                    trailing: TextButton(
                      onPressed: () {
                        ref.invalidate(
                          regretPromptControllerProvider(profile.id),
                        );
                      },
                      child: const Text('Try again'),
                    ),
                  );
                },
                data: (result) {
                  final prompt = result.prompt;

                  if (prompt == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No reflections waiting. '
                        'Want and Impulse purchases above '
                        '${profile.currencyCode} 15.00 '
                        'are ready two days after the '
                        'purchase date.',
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RegretPromptCard(
                      prompt: prompt,
                      dueCount: result.dueCount,
                      currencyCode: profile.currencyCode,
                      onReflect: () {
                        _openReflection(context, ref, prompt);
                      },
                    ),
                  );
                },
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('home_add_expense'),
                  onPressed: () {
                    _openExpenseEntry(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Add Expense'),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('home_view_insights'),
                  onPressed: () {
                    _openInsights(context);
                  },
                  icon: const Icon(Icons.insights_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('View Insights'),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    key: const Key('home_see_all_transactions'),
                    onPressed: () {
                      _openAllTransactions(context, ref);
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              transactionsState.when(
                loading: () {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                error: (error, stackTrace) {
                  return _TransactionsError(
                    error: error,
                    onRetry: () {
                      ref.invalidate(transactionsProvider(profile.id));
                    },
                  );
                },
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const _EmptyTransactions();
                  }

                  final recentTransactions = transactions.take(5).toList();

                  return Column(
                    children: recentTransactions
                        .map(
                          (transaction) => _TransactionTile(
                            transaction: transaction,
                            currencyCode: profile.currencyCode,
                            onTap: () {
                              _openTransactionDetails(
                                context,
                                ref,
                                transaction,
                              );
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              LearningProgressCard(profile: profile),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInsights(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return InsightsScreen(profile: profile);
        },
      ),
    );
  }

  Future<void> _openAllTransactions(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return AllTransactionsScreen(profile: profile);
        },
      ),
    );

    if (!context.mounted) {
      return;
    }

    ref.invalidate(regretPromptControllerProvider(profile.id));
  }

  Future<void> _openReflection(
    BuildContext context,
    WidgetRef ref,
    RegretPrompt prompt,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return RegretCheckinScreen(profile: profile, prompt: prompt);
        },
      ),
    );

    if (!context.mounted) {
      return;
    }

    ref.invalidate(regretPromptControllerProvider(profile.id));

    if (saved == true) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Reflection saved.')));
    }
  }

  Future<void> _openExpenseEntry(BuildContext context) async {
    final transaction = await Navigator.of(context).push<AppTransaction>(
      MaterialPageRoute(
        builder: (context) {
          return ExpenseEntryScreen(profile: profile);
        },
      ),
    );

    if (transaction == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Expense saved: '
          '${profile.currencyCode} '
          '${formatMoneyCents(
            transaction.amountCents,
            currencyCode: profile.currencyCode,
          )}',
        ),
      ),
    );
  }

  Future<void> _openTransactionDetails(
    BuildContext context,
    WidgetRef ref,
    AppTransaction transaction,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return TransactionDetailsScreen(
            profile: profile,
            transaction: transaction,
          );
        },
      ),
    );

    if (!context.mounted) {
      return;
    }

    ref.invalidate(regretPromptControllerProvider(profile.id));
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 12),

            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              'Your recent expenses and income '
              'will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsError extends StatelessWidget {
  const _TransactionsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 36),

            const SizedBox(height: 10),

            const Text('Could not load transactions.'),

            const SizedBox(height: 14),

            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.currencyCode,
    required this.onTap,
  });

  final AppTransaction transaction;
  final String currencyCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    final amountText =
        '${isExpense ? '-' : '+'}'
        '$currencyCode '
        '${formatMoneyCents(
          transaction.amountCents,
          currencyCode: currencyCode,
        )}';

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('transaction_${transaction.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack =
                  constraints.maxWidth < 360 || textScale >= 1.4;

              final details = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Icon(
                      isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _transactionTitle(transaction),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _transactionSubtitle(transaction),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,

                    const SizedBox(height: 12),

                    Text(
                      amountText,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isExpense
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: details),

                  const SizedBox(width: 16),

                  Flexible(
                    child: Text(
                      amountText,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isExpense
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _transactionTitle(AppTransaction transaction) {
    final description = transaction.description?.trim();

    if (description != null && description.isNotEmpty) {
      return description;
    }

    return transaction.type == TransactionType.expense ? 'Expense' : 'Income';
  }

  String _transactionSubtitle(AppTransaction transaction) {
    final parts = <String>[_formatDate(transaction.transactionDate)];

    final mood = transaction.moodTag;

    if (mood != null) {
      parts.add(_moodLabel(mood));
    }

    return parts.join(' • ');
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
