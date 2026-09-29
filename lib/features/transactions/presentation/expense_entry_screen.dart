import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/domain/app_category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/transaction_types.dart';
import 'transaction_entry_controller.dart';

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text('Could not load categories.'),
                    const SizedBox(height: 8),
                    Text(error.toString(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
          data: (categories) {
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
              validator: (value) {
                final cents = _parseAmountCents(value);

                if (cents == null || cents <= 0) {
                  return 'Enter a valid amount greater than zero.';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // Category
            // ----------------------------------------------------------
            DropdownButtonFormField<String>(
              key: const Key('expense_category'),
              initialValue: _selectedCategoryId,
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
                if (value == null) {
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
              maxLength: 200,
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
              'Want and Impulse purchases over \$15 may receive '
              'a reflection check-in later.',
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

    final amountCents = _parseAmountCents(_amountController.text);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save expense: $error')));
    }
  }

  int? _parseAmountCents(String? input) {
    if (input == null) {
      return null;
    }

    final value = input.trim().replaceAll(',', '').replaceAll('\$', '');

    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(value);

    if (match == null) {
      return null;
    }

    final dollars = int.parse(match.group(1)!);

    final decimalPart = match.group(2);

    final cents = decimalPart == null
        ? 0
        : decimalPart.length == 1
        ? int.parse(decimalPart) * 10
        : int.parse(decimalPart);

    return (dollars * 100) + cents;
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
