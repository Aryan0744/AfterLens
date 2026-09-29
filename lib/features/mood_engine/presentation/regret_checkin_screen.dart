import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../profile/domain/app_profile.dart';
import '../application/regret_prompt_result.dart';
import '../domain/regret_response.dart';
import 'regret_prompt_controller.dart';
import 'regret_purchase_details.dart';

class RegretCheckinScreen extends ConsumerStatefulWidget {
  const RegretCheckinScreen({
    required this.profile,
    required this.prompt,
    super.key,
  });

  final AppProfile profile;
  final RegretPrompt prompt;

  @override
  ConsumerState<RegretCheckinScreen> createState() =>
      _RegretCheckinScreenState();
}

class _RegretCheckinScreenState extends ConsumerState<RegretCheckinScreen> {
  bool _isSaving = false;
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Reflection')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Was this purchase worth it?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RegretPurchaseDetails(
                    transaction: widget.prompt.transaction,
                    currencyCode: widget.profile.currencyCode,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              for (final response in RegretResponse.values) ...[
                OutlinedButton(
                  key: ValueKey('regret_response_${response.name}'),
                  onPressed: _isSaving ? null : () => _answer(response),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(switch (response) {
                      RegretResponse.worthIt => 'Worth it',
                      RegretResponse.regret => 'I regret it',
                      RegretResponse.unsure => 'Unsure',
                    }),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_isSaving)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Saving reflection',
                    ),
                  ),
                ),
              if (_saveFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Could not save your reflection. Please try again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _answer(RegretResponse response) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    try {
      await ref
          .read(regretPromptServiceProvider)
          .answerPrompt(
            profileId: widget.profile.id,
            checkinId: widget.prompt.checkin.id,
            response: response,
            asOf: ref.read(regretClockProvider)(),
          );
      if (!mounted) return;
      ref.invalidate(regretPromptControllerProvider(widget.profile.id));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }
}
