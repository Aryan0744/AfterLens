import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/bootstrap/presentation/app_bootstrap_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await prepareAppStorage();

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
      home: const AppBootstrapGate(),
    );
  }
}
