import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../application/app_bootstrap_service.dart';

final appBootstrapControllerProvider =
    AsyncNotifierProvider<AppBootstrapController, AppBootstrapResult>(
      AppBootstrapController.new,
    );

class AppBootstrapController extends AsyncNotifier<AppBootstrapResult> {
  @override
  Future<AppBootstrapResult> build() async {
    final service = ref.read(appBootstrapServiceProvider);

    return service.initialize();
  }

  Future<AppBootstrapResult> completeOnboarding({
    required String currencyCode,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(appBootstrapServiceProvider);

      final result = await service.completeOnboarding(
        currencyCode: currencyCode,
      );

      state = AsyncData(result);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final service = ref.read(appBootstrapServiceProvider);

      return service.initialize();
    });
  }

  Future<void> eraseAllLocalData() async {
    final previousState = state;
    var eraseCompleted = false;

    state = const AsyncLoading();

    try {
      final erasureService = ref.read(dataErasureServiceProvider);

      await erasureService.eraseAllLocalData();

      eraseCompleted = true;

      final bootstrapService = ref.read(appBootstrapServiceProvider);

      final result = await bootstrapService.initialize();

      state = AsyncData(result);
    } catch (error, stackTrace) {
      if (eraseCompleted) {
        state = AsyncError(error, stackTrace);
      } else {
        state = previousState;
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
