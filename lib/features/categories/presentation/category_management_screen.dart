import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../domain/app_category.dart';
import 'category_providers.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update category. '
              'Check the category name or status and try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _editName([AppCategory? category]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return _CategoryNameDialog(category: category);
      },
    );

    if (name == null || !mounted) {
      return;
    }

    await _run(() async {
      final repository = ref.read(categoryRepositoryProvider);

      if (category == null) {
        await repository.createCustomCategory(
          profileId: widget.profile.id,
          name: name,
        );

        return;
      }

      await repository.renameCategory(
        profileId: widget.profile.id,
        categoryId: category.id,
        name: name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesProvider(widget.profile.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load categories.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(categoriesProvider(widget.profile.id));
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Archive categories you no longer use. '
                  'Past purchases keep their category; completed '
                  'reflections keep the name saved when you answered.',
                ),

                const SizedBox(height: 16),

                FilledButton.icon(
                  key: const Key('category_create'),
                  onPressed: _busy ? null : () => _editName(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create category'),
                ),

                for (final archived in [false, true]) ...[
                  const SizedBox(height: 24),

                  Text(
                    archived ? 'Archived' : 'Active',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 8),

                  if (!categories.any((item) => item.isArchived == archived))
                    Text(
                      archived
                          ? 'No archived categories.'
                          : 'No active categories. '
                                'Create one or restore an archive '
                                'to add expenses.',
                    ),

                  for (final category in categories.where(
                    (item) => item.isArchived == archived,
                  ))
                    Card(
                      child: ListTile(
                        key: ValueKey('category_${category.id}'),
                        title: Text(category.name),
                        subtitle: Text(
                          category.isSystem
                              ? 'System category'
                              : 'Custom category',
                        ),
                        trailing: PopupMenuButton<String>(
                          key: ValueKey('category_actions_${category.id}'),
                          tooltip: 'Manage ${category.name}',
                          enabled: !_busy,
                          onSelected: (action) {
                            if (action == 'rename') {
                              _editName(category);

                              return;
                            }

                            _run(() {
                              final repository = ref.read(
                                categoryRepositoryProvider,
                              );

                              return category.isArchived
                                  ? repository.restoreCategory(
                                      profileId: widget.profile.id,
                                      categoryId: category.id,
                                    )
                                  : repository.archiveCategory(
                                      profileId: widget.profile.id,
                                      categoryId: category.id,
                                    );
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                category.isArchived ? 'Restore' : 'Archive',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({this.category});

  final AppCategory? category;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.category?.name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Create category' : 'Rename category',
      ),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('category_name'),
          controller: _name,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Category name'),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Enter a name.';
            }

            return null;
          },
          onFieldSubmitted: (_) {
            _submit();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('category_name_save'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
