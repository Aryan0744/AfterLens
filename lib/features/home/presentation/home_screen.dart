import 'package:flutter/material.dart';

import '../../../core/branding/afterlens_logo.dart';
import '../../profile/domain/app_profile.dart';

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
                'AfterLens is ready.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('Currency: ${profile.currencyCode}'),
              const SizedBox(height: 8),
              Text('Active categories: $categoryCount'),
              const SizedBox(height: 32),
              const Text('Next: build the transaction entry experience.'),
            ],
          ),
        ),
      ),
    );
  }
}
