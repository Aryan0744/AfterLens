import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/afterlens_logo.dart';
import 'app_bootstrap_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currencyController = TextEditingController();

  @override
  void dispose() {
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currencyCode = _currencyController.text.trim().toUpperCase();

    await ref
        .read(appBootstrapControllerProvider.notifier)
        .completeOnboarding(currencyCode: currencyCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AfterLensLogo(width: 220)),
                    const SizedBox(height: 48),
                    Text(
                      'Set up your account',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose the currency AfterLens should use '
                      'for your spending and budget data.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _currencyController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 3,
                      decoration: const InputDecoration(
                        labelText: 'Currency code',
                        hintText: 'CAD',
                        helperText: 'Enter a 3-letter code such as CAD or USD.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final currency = value?.trim().toUpperCase() ?? '';

                        if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
                          return 'Enter a valid 3-letter currency code.';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _continue();
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _continue,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
