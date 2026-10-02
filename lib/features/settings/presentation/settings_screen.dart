import 'package:flutter/material.dart';

import '../../bootstrap/presentation/reflection_guide.dart';
import '../../categories/presentation/category_management_screen.dart';
import '../../profile/domain/app_profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.profile, super.key});
  final AppProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            title: const Text('Currency'),
            subtitle: Text(profile.currencyCode),
          ),
          ListTile(
            key: const Key('settings_categories'),
            title: const Text('Categories'),
            subtitle: const Text('Create, rename, archive and restore'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) =>
                    CategoryManagementScreen(profile: profile),
              ),
            ),
          ),
          const Divider(height: 32),
          ReflectionGuide(currencyCode: profile.currencyCode),
        ],
      ),
    ),
  );
}
