import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/repository_providers.dart';
import '../../bootstrap/presentation/reflection_guide.dart';
import '../../categories/presentation/category_management_screen.dart';
import '../../profile/domain/app_profile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
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
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) {
                      return CategoryManagementScreen(profile: widget.profile);
                    },
                  ),
                );
              },
            ),

            const Divider(height: 32),

            Text('Your data', style: Theme.of(context).textTheme.titleLarge),

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
                  onTap: _isExporting
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

            ReflectionGuide(currencyCode: widget.profile.currencyCode),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext shareContext) async {
    if (_isExporting) {
      return;
    }

    // Capture the share-sheet position before the async work begins.
    // This avoids using BuildContext across an async gap.
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
