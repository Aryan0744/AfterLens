import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/bootstrap/application/app_bootstrap_service.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/categories/domain/default_categories.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late AppBootstrapService bootstrapService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);
    categoryRepository = DriftCategoryRepository(database);

    bootstrapService = AppBootstrapService(
      profileRepository: profileRepository,
      categoryRepository: categoryRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('AppBootstrapService', () {
    test('requires onboarding when no profile exists', () async {
      final result = await bootstrapService.initialize();

      expect(result.status, AppBootstrapStatus.needsOnboarding);
      expect(result.needsOnboarding, true);
      expect(result.profile, isNull);
      expect(result.categories, isEmpty);
    });

    test('complete onboarding creates profile', () async {
      final result = await bootstrapService.completeOnboarding(
        currencyCode: 'cad',
      );

      expect(result.status, AppBootstrapStatus.ready);
      expect(result.isReady, true);

      expect(result.profile, isNotNull);
      expect(result.profile!.currencyCode, 'CAD');
    });

    test('onboarding creates all default categories', () async {
      final result = await bootstrapService.completeOnboarding(
        currencyCode: 'CAD',
      );

      expect(result.categories.length, defaultCategories.length);

      final systemKeys = result.categories
          .map((category) => category.systemKey)
          .toSet();

      for (final definition in defaultCategories) {
        expect(systemKeys, contains(definition.systemKey));
      }
    });

    test('initialize returns ready for existing profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final result = await bootstrapService.initialize();

      expect(result.status, AppBootstrapStatus.ready);

      expect(result.profile!.id, profile.id);

      expect(result.categories.length, defaultCategories.length);
    });

    test(
      'running bootstrap repeatedly does not duplicate categories',
      () async {
        await bootstrapService.completeOnboarding(currencyCode: 'CAD');

        final first = await bootstrapService.initialize();
        final second = await bootstrapService.initialize();

        expect(first.categories.length, defaultCategories.length);

        expect(second.categories.length, defaultCategories.length);

        final ids = second.categories.map((category) => category.id).toSet();

        expect(ids.length, defaultCategories.length);
      },
    );

    test('complete onboarding is safe when profile already exists', () async {
      final first = await bootstrapService.completeOnboarding(
        currencyCode: 'CAD',
      );

      final second = await bootstrapService.completeOnboarding(
        currencyCode: 'CAD',
      );

      expect(second.profile!.id, first.profile!.id);

      expect(second.categories.length, defaultCategories.length);
    });
  });
}
