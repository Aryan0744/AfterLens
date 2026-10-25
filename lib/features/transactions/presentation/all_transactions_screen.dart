import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_display.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_types.dart';
import 'transaction_details_screen.dart';
import 'transaction_providers.dart';

class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider(profile.id));

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: SafeArea(
        child: transactionsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load transactions.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(transactionsProvider(profile.id));
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48),
                      SizedBox(height: 16),
                      Text('No transactions yet'),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(transactionsProvider(profile.id));

                await ref.read(transactionsProvider(profile.id).future);
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  return _TransactionTile(
                    transaction: transaction,
                    currencyCode: profile.currencyCode,
                    onTap: () async {
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
                    },
                  );
                },
              ),
            );
          },
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
        '${formatMoneyCents(transaction.amountCents, currencyCode: currencyCode)}';

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('all_transaction_${transaction.id}'),
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

    return transaction.isExpense ? 'Expense' : 'Income';
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
