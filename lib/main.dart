import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/branding/afterlens_logo.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AfterLensApp()));
}

class AfterLensApp extends StatelessWidget {
  const AfterLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfterLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const BrandPreviewScreen(),
    );
  }
}

class BrandPreviewScreen extends StatelessWidget {
  const BrandPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: AfterLensLogo(width: 240),
          ),
        ),
      ),
    );
  }
}
