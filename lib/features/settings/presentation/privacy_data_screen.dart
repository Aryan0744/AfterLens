import 'package:flutter/material.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'How AfterLens handles your data',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'AfterLens is currently designed around local storage '
              'and user-controlled data management.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            _InfoCard(
              icon: Icons.phone_iphone_outlined,
              title: 'Stored locally',
              body:
                  'Your profile, categories, transactions and reflection '
                  'history are stored in AfterLens\'s local database on '
                  'this device.',
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.cloud_off_outlined,
              title: 'No cloud sync',
              body:
                  'The current version of AfterLens does not provide '
                  'cloud synchronization. Your AfterLens database is not '
                  'currently synced to an AfterLens account or server.',
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.analytics_outlined,
              title: 'No analytics tracking',
              body:
                  'The current version does not include product analytics '
                  'or advertising tracking for your AfterLens activity.',
            ),

            const SizedBox(height: 32),

            Text('Exporting your data', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'You can create a JSON export containing your profile, '
              'categories, transactions and reflection history. '
              'After you save or share that file, the copy is outside '
              'AfterLens and you are responsible for where it is stored.',
            ),

            const SizedBox(height: 32),

            Text('Deleting your data', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Delete all data permanently removes the local AfterLens '
              'profile, categories, transactions, deleted transactions, '
              'pending reflections and completed reflection history.',
            ),
            const SizedBox(height: 8),
            const Text(
              'This does not remove copies that you previously exported '
              'or saved somewhere else.',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AfterLens does not currently claim encrypted local '
                      'storage, cloud backup protection or end-to-end '
                      'encryption.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(body),
          ),
        ),
      ),
    );
  }
}
