import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/afterlens_logo.dart';
import '../../mood_engine/application/regret_prompt_result.dart';
import '../../mood_engine/presentation/regret_checkin_screen.dart';
import '../../mood_engine/presentation/regret_prompt_card.dart';
import '../../mood_engine/presentation/regret_prompt_controller.dart';
import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/app_transaction.dart';
import '../../transactions/domain/transaction_types.dart';
import '../../transactions/presentation/expense_entry_screen.dart';
import '../../transactions/presentation/transaction_providers.dart';

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
      appBar: AppBar(title: const AfterLensLogo(width: 130)),
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
                'Your spending starts here.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 10),

              Text(
                'Track what you spend and understand '
                'the decisions behind it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              _ProfileSummaryCard(
                currencyCode: profile.currencyCode,
                categoryCount: categoryCount,
              ),

              const SizedBox(height: 24),

              promptState.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (result) {
                  final prompt = result.prompt;
                  if (prompt == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RegretPromptCard(
                      prompt: prompt,
                      currencyCode: profile.currencyCode,
                      onReflect: () => _openReflection(context, ref, prompt),
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

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent transactions',
                    style: Theme.of(context).textTheme.titleLarge,
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
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReflection(
    BuildContext context,
    WidgetRef ref,
    RegretPrompt prompt,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            RegretCheckinScreen(profile: profile, prompt: prompt),
      ),
    );
    if (!context.mounted) return;
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
          '${_formatMoney(transaction.amountCents)}',
        ),
      ),
    );
  }

  static String _formatMoney(int amountCents) {
    final dollars = amountCents ~/ 100;
    final cents = amountCents % 100;

    return '$dollars.${cents.toString().padLeft(2, '0')}';
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.currencyCode,
    required this.categoryCount,
  });

  final String currencyCode;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(label: 'Currency', value: currencyCode),
            ),
            Expanded(
              child: _SummaryItem(
                label: 'Categories',
                value: categoryCount.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
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
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
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
  });

  final AppTransaction transaction;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    final amountText =
        '${isExpense ? '-' : '+'}'
        '$currencyCode '
        '${_formatMoney(transaction.amountCents)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward),
        ),
        title: Text(_transactionTitle(transaction)),
        subtitle: Text(_transactionSubtitle(transaction)),
        trailing: Text(
          amountText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isExpense
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
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

  String _formatMoney(int amountCents) {
    final dollars = amountCents ~/ 100;
    final cents = amountCents % 100;

    return '$dollars.${cents.toString().padLeft(2, '0')}';
  }
}
