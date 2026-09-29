import 'package:flutter/material.dart';

import '../../../core/branding/afterlens_logo.dart';
import '../../profile/domain/app_profile.dart';
import '../../transactions/domain/app_transaction.dart';
import '../../transactions/presentation/expense_entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.profile,
    required this.categoryCount,
    super.key,
  });

  final AppProfile profile;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AfterLensLogo(width: 130)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your spending starts here.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 12),

              Text('Currency: ${profile.currencyCode}'),

              const SizedBox(height: 6),

              Text('Active categories: $categoryCount'),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openExpenseEntry(context),
                  icon: const Icon(Icons.add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Add Expense'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Recent transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              Text(
                'Your saved transactions will appear here next.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExpenseEntry(BuildContext context) async {
    final transaction = await Navigator.of(context).push<AppTransaction>(
      MaterialPageRoute(
        builder: (context) => ExpenseEntryScreen(profile: profile),
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
          '${(transaction.amountCents / 100).toStringAsFixed(2)}',
        ),
      ),
    );
  }
}
