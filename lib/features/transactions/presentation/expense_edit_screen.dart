import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../categories/domain/app_category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_types.dart';
import 'transaction_providers.dart';

class ExpenseEditScreen extends ConsumerStatefulWidget {
  const ExpenseEditScreen({
    required this.profile,
    required this.transaction,
    super.key,
  });

  final AppProfile profile;
  final AppTransaction transaction;

  @override
  ConsumerState<ExpenseEditScreen> createState() => _ExpenseEditScreenState();
}

class _ExpenseEditScreenState extends ConsumerState<ExpenseEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  String? _selectedCategoryId;
  MoodTag? _selectedMood;
  late DateTime _selectedDate;

  bool _showMoodError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: _formatInputAmount(widget.transaction.amountCents),
    );

    _descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );

    _selectedCategoryId = widget.transaction.categoryId;
    _selectedMood = widget.transaction.moodTag;
    _selectedDate = widget.transaction.transactionDate;
  }

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

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: SafeArea(
        child: categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load categories: $error')),
          data: (categories) {
            return _buildForm(context, categories);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<AppCategory> categories) {
    final checkinState = ref.watch(
      transactionCheckinProvider(widget.transaction.id),
    );
    final categoryExists = categories.any(
      (category) => category.id == _selectedCategoryId,
    );

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update expense',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 24),

            if (checkinState.value?.isAnswered == true) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This purchase already has a completed reflection. '
                    'Editing the transaction will not change your past reflection.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (checkinState.hasError) ...[
              const Text('Could not load reflection status.'),
              const SizedBox(height: 24),
            ],

            TextFormField(
              key: const Key('edit_expense_amount'),
              controller: _amountController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.profile.currencyCode} ',
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

            DropdownButtonFormField<String>(
              key: const Key('edit_expense_category'),
              initialValue: categoryExists ? _selectedCategoryId : null,
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
              onChanged: _isSaving
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

            Text(
              'How did this purchase feel?',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MoodTag.values.map((mood) {
                return ChoiceChip(
                  key: ValueKey('edit_expense_mood_${mood.name}'),
                  label: Text(_moodLabel(mood)),
                  selected: _selectedMood == mood,
                  onSelected: _isSaving
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

            TextFormField(
              key: const Key('edit_expense_description'),
              controller: _descriptionController,
              enabled: !_isSaving,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              key: const Key('edit_expense_date'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_formatDate(_selectedDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _isSaving ? null : _selectDate,
            ),

            const SizedBox(height: 32),

            FilledButton(
              key: const Key('edit_expense_save'),
              onPressed: _isSaving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (_selectedMood == null) {
      setState(() {
        _showMoodError = true;
      });
    }

    if (!formValid || _selectedMood == null || _selectedCategoryId == null) {
      return;
    }

    final amountCents = _parseAmountCents(_amountController.text);

    if (amountCents == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ref
          .read(transactionManagementServiceProvider)
          .updateExpense(
            profileId: widget.profile.id,
            transactionId: widget.transaction.id,
            categoryId: _selectedCategoryId!,
            amountCents: amountCents,
            moodTag: _selectedMood!,
            transactionDate: _selectedDate,
            description: _descriptionController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result.transaction);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update expense: $error')),
      );
    }
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

    final decimal = match.group(2);

    final cents = decimal == null
        ? 0
        : decimal.length == 1
        ? int.parse(decimal) * 10
        : int.parse(decimal);

    return (dollars * 100) + cents;
  }

  String _formatInputAmount(int cents) {
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
