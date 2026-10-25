import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/formatting/money_input.dart';
import '../../categories/domain/app_category.dart';
import '../../categories/presentation/category_management_screen.dart';
import '../../categories/presentation/category_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/transaction_types.dart';
import 'transaction_entry_controller.dart';
import '../../../core/validation/transaction_description.dart';

class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  MoodTag? _selectedMood;

  DateTime _selectedDate = DateTime.now();

  bool _showMoodError = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(
      activeCategoriesProvider(widget.profile.id),
    );

    final transactionState = ref.watch(transactionEntryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: categoriesState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48),
                    SizedBox(height: 16),
                    Text('Could not load categories.'),
                  ],
                ),
              ),
            );
          },
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create or restore a category to record an expense.',
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (context) => CategoryManagementScreen(
                                profile: widget.profile,
                              ),
                            ),
                          );
                        },
                        child: const Text('Manage categories'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildForm(context, categories, transactionState.isLoading);
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<AppCategory> categories,
    bool isSaving,
  ) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How much did you spend?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'Record the purchase while it is still fresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // Amount
            // ----------------------------------------------------------
            TextFormField(
              key: const Key('expense_amount'),
              controller: _amountController,
              enabled: !isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.profile.currencyCode} ',
                hintText: '0.00',
                border: const OutlineInputBorder(),
              ),
              validator: validateMoneyInput,
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // Category
            // ----------------------------------------------------------
            DropdownButtonFormField<String>(
              key: const Key('expense_category'),
              initialValue:
                  categories.any(
                    (category) => category.id == _selectedCategoryId,
                  )
                  ? _selectedCategoryId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
              validator: (value) {
                if (value == null ||
                    !categories.any((category) => category.id == value)) {
                  return 'Select a category.';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------------
            // Mood
            // ----------------------------------------------------------
            Text(
              'How did this purchase feel?',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              'Choose the option that best describes why you made it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MoodTag.values.map((mood) {
                return ChoiceChip(
                  key: ValueKey('expense_mood_${mood.name}'),
                  label: Text(_moodLabel(mood)),
                  tooltip: mood.explanation,
                  selected: _selectedMood == mood,
                  onSelected: isSaving
                      ? null
                      : (selected) {
                          setState(() {
                            _selectedMood = selected ? mood : null;

                            if (_selectedMood != null) {
                              _showMoodError = false;
                            }
                          });
                        },
                );
              }).toList(),
            ),

            if (_selectedMood != null) ...[
              const SizedBox(height: 8),
              Text(_selectedMood!.explanation),
            ],

            if (_showMoodError && _selectedMood == null) ...[
              const SizedBox(height: 8),
              Text(
                'Select a mood before saving.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ----------------------------------------------------------
            // Description
            // ----------------------------------------------------------
            TextFormField(
              key: const Key('expense_description'),
              controller: _descriptionController,
              enabled: !isSaving,
              maxLength: maxTransactionDescriptionLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              validator: validateTransactionDescription,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What did you buy?',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------------
            // Transaction date
            // ----------------------------------------------------------
            ListTile(
              key: const Key('expense_date'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_formatDate(_selectedDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: isSaving ? null : _selectDate,
            ),

            const SizedBox(height: 32),

            // ----------------------------------------------------------
            // Save
            // ----------------------------------------------------------
            FilledButton(
              key: const Key('expense_save'),
              onPressed: isSaving ? null : _saveExpense,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Expense'),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Want and Impulse purchases above '
              '${widget.profile.currencyCode} 15.00 may receive '
              'a reflection check-in two days later.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _saveExpense() async {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (_selectedMood == null) {
      setState(() {
        _showMoodError = true;
      });
    }

    if (!formValid || _selectedMood == null) {
      return;
    }

    final amountCents = parseMoneyInputToCents(_amountController.text);

    if (amountCents == null) {
      return;
    }

    final categoryId = _selectedCategoryId;

    if (categoryId == null) {
      return;
    }

    try {
      final result = await ref
          .read(transactionEntryControllerProvider.notifier)
          .createExpense(
            profileId: widget.profile.id,
            categoryId: categoryId,
            amountCents: amountCents,
            moodTag: _selectedMood!,
            transactionDate: _selectedDate,
            description: _descriptionController.text,
          );

      if (!mounted) {
        return;
      }

      ref.read(transactionEntryControllerProvider.notifier).reset();

      Navigator.of(context).pop(result.transaction);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save expense. Please try again.'),
        ),
      );
    }
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
