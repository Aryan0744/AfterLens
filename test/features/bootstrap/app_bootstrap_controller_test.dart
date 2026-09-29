import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/core/providers/repository_providers.dart';
import 'package:afterlens/features/bootstrap/application/app_bootstrap_service.dart';
import 'package:afterlens/features/bootstrap/presentation/app_bootstrap_controller.dart';
import 'package:afterlens/features/categories/domain/default_categories.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('AppBootstrapController', () {
    test('starts in needsOnboarding when no profile exists', () async {
      final result = await container.read(
        appBootstrapControllerProvider.future,
      );

      expect(result.status, AppBootstrapStatus.needsOnboarding);

      expect(result.needsOnboarding, true);

      expect(result.profile, isNull);

      expect(result.categories, isEmpty);
    });

    test(
      'completeOnboarding creates profile and transitions to ready',
      () async {
        // Allow the initial controller build to finish.
        await container.read(appBootstrapControllerProvider.future);

        final controller = container.read(
          appBootstrapControllerProvider.notifier,
        );

        final result = await controller.completeOnboarding(currencyCode: 'cad');

        expect(result.status, AppBootstrapStatus.ready);

        expect(result.isReady, true);

        expect(result.profile, isNotNull);

        expect(result.profile!.currencyCode, 'CAD');

        expect(result.categories.length, defaultCategories.length);

        final state = container.read(appBootstrapControllerProvider);

        expect(state.hasValue, true);

        expect(state.value?.status, AppBootstrapStatus.ready);
      },
    );

    test('existing profile starts directly in ready state', () async {
      final profileRepository = container.read(profileRepositoryProvider);

      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final result = await container.read(
        appBootstrapControllerProvider.future,
      );

      expect(result.status, AppBootstrapStatus.ready);

      expect(result.profile, isNotNull);

      expect(result.profile!.id, profile.id);

      expect(result.categories.length, defaultCategories.length);
    });

    test('completeOnboarding seeds all default categories', () async {
      await container.read(appBootstrapControllerProvider.future);

      final controller = container.read(
        appBootstrapControllerProvider.notifier,
      );

      final result = await controller.completeOnboarding(currencyCode: 'CAD');

      final systemKeys = result.categories
          .map((category) => category.systemKey)
          .toSet();

      for (final definition in defaultCategories) {
        expect(systemKeys, contains(definition.systemKey));
      }
    });

    test(
      'refresh detects profile created after initial onboarding state',
      () async {
        final initial = await container.read(
          appBootstrapControllerProvider.future,
        );

        expect(initial.status, AppBootstrapStatus.needsOnboarding);

        final profileRepository = container.read(profileRepositoryProvider);

        await profileRepository.createLocalProfile(currencyCode: 'CAD');

        final controller = container.read(
          appBootstrapControllerProvider.notifier,
        );

        await controller.refresh();

        final state = container.read(appBootstrapControllerProvider);

        expect(state.hasValue, true);

        expect(state.value?.status, AppBootstrapStatus.ready);

        expect(state.value?.categories.length, defaultCategories.length);
      },
    );

    test('invalid onboarding currency exposes error state', () async {
      await container.read(appBootstrapControllerProvider.future);

      final controller = container.read(
        appBootstrapControllerProvider.notifier,
      );

      await expectLater(
        controller.completeOnboarding(currencyCode: 'INVALID'),
        throwsA(isA<ArgumentError>()),
      );

      final state = container.read(appBootstrapControllerProvider);

      expect(state.hasError, true);

      expect(state.error, isA<ArgumentError>());
    });
  });
}
