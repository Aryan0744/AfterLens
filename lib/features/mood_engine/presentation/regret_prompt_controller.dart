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
    // Expense creation and scheduling commit together; the transaction stream
    // then refreshes Home, including for already-due, past-dated purchases.
    ref.watch(transactionsProvider(profileId));
    final service = ref.watch(regretPromptServiceProvider);
    final clock = ref.watch(regretClockProvider);

    // Refresh due dates and the local-day boundary while Home stays open.
    final timer = Timer(const Duration(minutes: 1), () {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        ref.invalidateSelf();
      }
    });
    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    ref.onDispose(lifecycle.dispose);

    return service.getPrompt(profileId: profileId, asOf: clock());
  }
}
