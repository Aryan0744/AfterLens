import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../application/regret_prompt_result.dart';

final regretClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final regretPromptControllerProvider = AsyncNotifierProvider.autoDispose
    .family<RegretPromptController, RegretPromptResult, String>(
      RegretPromptController.new,
    );

class RegretPromptController extends AsyncNotifier<RegretPromptResult> {
  RegretPromptController(this.profileId);

  final String profileId;

  @override
  Future<RegretPromptResult> build() {
    // Transaction changes can create, remove, or reschedule
    // a reflection, so refresh when the transaction stream changes.
    ref.watch(transactionsProvider(profileId));

    final service = ref.watch(regretPromptServiceProvider);

    final clock = ref.watch(regretClockProvider);

    // Refresh while Home stays open so reflections can become
    // available when their due time is reached.
    final timer = Timer(const Duration(minutes: 1), () {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;

      if (lifecycleState == null ||
          lifecycleState == AppLifecycleState.resumed) {
        ref.invalidateSelf();
      }
    });

    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);

    ref.onDispose(timer.cancel);

    ref.onDispose(lifecycle.dispose);

    return service.getPrompt(profileId: profileId, asOf: clock());
  }
}
