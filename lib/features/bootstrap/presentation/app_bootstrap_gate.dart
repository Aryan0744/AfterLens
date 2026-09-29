import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_screen.dart';
import 'app_bootstrap_controller.dart';
import 'onboarding_screen.dart';

class AppBootstrapGate extends ConsumerWidget {
  const AppBootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(appBootstrapControllerProvider);

    return bootstrapState.when(
      loading: () => const _BootstrapLoadingScreen(),
      error: (error, stackTrace) => _BootstrapErrorScreen(
        error: error,
        onRetry: () {
          ref.read(appBootstrapControllerProvider.notifier).refresh();
        },
      ),
      data: (result) {
        if (result.needsOnboarding) {
          return const OnboardingScreen();
        }

        final profile = result.profile;

        if (profile == null) {
          return _BootstrapErrorScreen(
            error: StateError('Bootstrap returned ready without a profile.'),
            onRetry: () {
              ref.read(appBootstrapControllerProvider.notifier).refresh();
            },
          );
        }

        return HomeScreen(
          profile: profile,
          categoryCount: result.categories.length,
        );
      },
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'AfterLens could not start.',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
