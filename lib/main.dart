import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: AfterLensApp()));
}

class AfterLensApp extends StatelessWidget {
  const AfterLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfterLens',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D10),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'AfterLens',
            style: TextStyle(color: Color(0xFFE4E7EB), fontSize: 24),
          ),
        ),
      ),
    );
  }
}