import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/repository_providers.dart';
import '../../bootstrap/presentation/app_bootstrap_controller.dart';
import '../../bootstrap/presentation/reflection_guide.dart';
import '../../categories/presentation/category_management_screen.dart';
import '../../profile/domain/app_profile.dart';
import 'privacy_data_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              title: const Text('Currency'),
              subtitle: Text(widget.profile.currencyCode),
            ),

            ListTile(
              key: const Key('settings_categories'),
              title: const Text('Categories'),
              subtitle: const Text('Create, rename, archive and restore'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isDeleting
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) {
                            return CategoryManagementScreen(
                              profile: widget.profile,
                            );
                          },
                        ),
                      );
                    },
            ),

            const Divider(height: 32),

            Text('Your data', style: theme.textTheme.titleLarge),

            const SizedBox(height: 8),

            ListTile(
              key: const Key('settings_privacy_data'),
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Privacy & data'),
              subtitle: const Text(
                'How AfterLens stores, exports and deletes your data',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isExporting || _isDeleting
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) {
                            return const PrivacyDataScreen();
                          },
                        ),
                      );
                    },
            ),

            const SizedBox(height: 8),

            Builder(
              builder: (exportContext) {
                return ListTile(
                  key: const Key('settings_export_data'),
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export your data'),
                  subtitle: const Text(
                    'Create a JSON copy of your transactions, '
                    'categories and reflection history.',
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting || _isDeleting
                      ? null
                      : () {
                          _exportData(exportContext);
                        },
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'The export contains personal financial and '
                'behavioral information. Once you save or share '
                'the file, it is outside AfterLens.',
              ),
            ),

            const Divider(height: 32),

            Text(
              'Danger zone',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              key: const Key('settings_delete_all_data'),
              leading: Icon(
                Icons.delete_forever_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete all data',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text(
                'Permanently remove all AfterLens data '
                'stored on this device.',
              ),
              trailing: _isDeleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chevron_right, color: theme.colorScheme.error),
              onTap: _isExporting || _isDeleting
                  ? null
                  : _confirmAndDeleteAllData,
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'This includes your profile, categories, '
                'transactions, deleted transactions, pending '
                'reflections and completed reflection history.',
              ),
            ),

            const Divider(height: 32),

            ReflectionGuide(currencyCode: widget.profile.currencyCode),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteAllData() async {
    var confirmationText = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            final canDelete = confirmationText.trim().toUpperCase() == 'DELETE';

            return AlertDialog(
              title: const Text('Delete all AfterLens data?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your profile, '
                    'categories, transactions and complete '
                    'reflection history from this device.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This cannot be undone. Export your data '
                    'first if you want to keep a copy.',
                  ),
                  const SizedBox(height: 20),
                  const Text('Type DELETE to continue.'),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('delete_all_data_confirmation_field'),
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'DELETE',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        confirmationText = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('confirm_delete_all_data'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: canDelete
                      ? () {
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  child: const Text('Delete all data'),
                ),
              ],
            );
          },
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
          .read(appBootstrapControllerProvider.notifier)
          .eraseAllLocalData();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete your data. '
              'Your data has not been intentionally retained '
              'by this action. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _exportData(BuildContext shareContext) async {
    if (_isExporting || _isDeleting) {
      return;
    }

    final box = shareContext.findRenderObject() as RenderBox?;

    final sharePositionOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ref.read(dataExportServiceProvider);

      final json = await exportService.exportProfileData(
        profileId: widget.profile.id,
      );

      if (!mounted) {
        return;
      }

      final fileName =
          'afterlens-export-${_fileTimestamp(DateTime.now())}.json';

      await SharePlus.instance.share(
        ShareParams(
          title: 'AfterLens Data Export',
          subject: 'AfterLens Data Export',
          text:
              'Your AfterLens data export. '
              'Keep this file somewhere private and secure.',
          files: [
            XFile.fromData(utf8.encode(json), mimeType: 'application/json'),
          ],
          fileNameOverrides: [fileName],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not export your data. '
              'Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _fileTimestamp(DateTime date) {
    final local = date.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.year}'
        '${twoDigits(local.month)}'
        '${twoDigits(local.day)}-'
        '${twoDigits(local.hour)}'
        '${twoDigits(local.minute)}'
        '${twoDigits(local.second)}';
  }
}
