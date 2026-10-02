import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../categories/presentation/category_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_types.dart';
import 'expense_edit_screen.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  const TransactionDetailsScreen({
    required this.profile,
    required this.transaction,
    super.key,
  });

  final AppProfile profile;
  final AppTransaction transaction;

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  late AppTransaction _transaction;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider(widget.profile.id));

    final categoryName = categoriesState.maybeWhen(
      data: (categories) {
        for (final category in categories) {
          if (category.id == _transaction.categoryId) {
            return category.name;
          }
        }

        return 'Category not recorded';
      },
      error: (error, stackTrace) => 'Could not load category',
      orElse: () => 'Loading...',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          if (_transaction.isExpense)
            IconButton(
              key: const Key('transaction_edit'),
              onPressed: _isDeleting ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${widget.profile.currencyCode} '
              '${_formatMoney(_transaction.amountCents)}',
              style: Theme.of(context).textTheme.displaySmall,
            ),

            const SizedBox(height: 8),

            Text(
              _transaction.description ??
                  (_transaction.isExpense ? 'Expense' : 'Income'),
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 28),

            _DetailRow(
              label: 'Type',
              value: _transaction.isExpense ? 'Expense' : 'Income',
            ),

            if (_transaction.isExpense)
              _DetailRow(label: 'Category', value: categoryName),

            if (_transaction.moodTag != null)
              _DetailRow(
                label: 'Mood',
                value: _moodLabel(_transaction.moodTag!),
              ),

            _DetailRow(
              label: 'Date',
              value: _formatDate(_transaction.transactionDate),
            ),

            const SizedBox(height: 32),

            if (_transaction.isExpense)
              OutlinedButton.icon(
                key: const Key('transaction_edit_button'),
                onPressed: _isDeleting ? null : _edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Edit Expense'),
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              key: const Key('transaction_delete'),
              onPressed: _isDeleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<AppTransaction>(
      MaterialPageRoute(
        builder: (context) {
          return ExpenseEditScreen(
            profile: widget.profile,
            transaction: _transaction,
          );
        },
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _transaction = updated;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Expense updated.')));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'This removes the transaction from your ledger and cancels any '
            'pending reflection. Completed reflections stay in your history '
            'and Insights.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_transaction_delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(transactionManagementServiceProvider)
          .deleteTransaction(
            profileId: widget.profile.id,
            transactionId: _transaction.id,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $error')),
      );
    }
  }

  String _formatMoney(int cents) {
    final dollars = cents ~/ 100;
    final remainder = cents % 100;

    return '$dollars.'
        '${remainder.toString().padLeft(2, '0')}';
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
