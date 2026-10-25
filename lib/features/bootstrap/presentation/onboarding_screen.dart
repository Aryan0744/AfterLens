import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/afterlens_logo.dart';
import '../../../core/formatting/currency_support.dart';
import 'app_bootstrap_controller.dart';
import 'reflection_guide.dart';

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

    final currencyCode = normalizeSupportedCurrencyCode(
      _currencyController.text,
    );

    if (currencyCode == null) {
      return;
    }

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

                    const SizedBox(height: 40),

                    Text(
                      'Spend with better hindsight',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Record purchases, reflect on them later, '
                      'and learn which spending decisions feel worth it.',
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
                        helperText: 'Enter a supported currency such as CAD, USD, or INR.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!isSupportedCurrencyCode(value)) {
                          return 'Enter a supported currency code.';
                        }

                        return null;
                      },
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 28),

                    ReflectionGuide(
                      currencyCode: _guideCurrencyCode,
                      showMoods: true,
                    ),

                    const SizedBox(height: 32),

                    FilledButton(
                      key: const Key('onboarding_continue'),
                      onPressed: _continue,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Continue'),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _guideCurrencyCode {
    return normalizeSupportedCurrencyCode(_currencyController.text) ?? 'CAD';
  }
}
