import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(),
    );

    profileRepository = DriftProfileRepository(database);
    categoryRepository = DriftCategoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftCategoryRepository', () {
    test('creates a custom category and trims its name', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: '  Dining  ',
      );

      expect(category.id, isNotEmpty);
      expect(category.profileId, profile.id);
      expect(category.name, 'Dining');
      expect(category.systemKey, isNull);
      expect(category.isSystem, false);
      expect(category.isArchived, false);

      final stored = await categoryRepository.getCategoryById(
        categoryId: category.id,
      );

      expect(stored, isNotNull);
      expect(stored!.name, 'Dining');
    });

    test('rejects empty category names', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => categoryRepository.createCustomCategory(
          profileId: profile.id,
          name: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects category names longer than 50 characters', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => categoryRepository.createCustomCategory(
          profileId: profile.id,
          name: 'A' * 51,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'rejects duplicate active category names case-insensitively',
          () async {
        final profile = await profileRepository.createLocalProfile(
          currencyCode: 'CAD',
        );

        await categoryRepository.createCustomCategory(
          profileId: profile.id,
          name: 'Dining',
        );

        expect(
              () => categoryRepository.createCustomCategory(
            profileId: profile.id,
            name: 'dining',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('cannot create a category for a missing profile', () async {
      expect(
            () => categoryRepository.createCustomCategory(
          profileId: 'missing-profile',
          name: 'Dining',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('returns only active categories', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final dining = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Groceries',
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: dining.id,
      );

      final categories = await categoryRepository.getActiveCategories(
        profileId: profile.id,
      );

      expect(categories, hasLength(1));
      expect(categories.single.name, 'Groceries');
    });

    test('archives a category instead of deleting it', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Entertainment',
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: category.id,
      );

      final stored = await categoryRepository.getCategoryById(
        categoryId: category.id,
      );

      expect(stored, isNotNull);
      expect(stored!.isArchived, true);

      final active = await categoryRepository.getActiveCategories(
        profileId: profile.id,
      );

      expect(active, isEmpty);
    });

    test('restores an archived category', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Travel',
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: category.id,
      );

      await categoryRepository.restoreCategory(
        profileId: profile.id,
        categoryId: category.id,
      );

      final restored = await categoryRepository.getCategoryById(
        categoryId: category.id,
      );

      expect(restored, isNotNull);
      expect(restored!.isArchived, false);
    });

    test('cannot restore category when active duplicate exists', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final oldCategory = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Dining',
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: oldCategory.id,
      );

      await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'dining',
      );

      expect(
            () => categoryRepository.restoreCategory(
          profileId: profile.id,
          categoryId: oldCategory.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cannot archive a category through the wrong profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      expect(
            () => categoryRepository.archiveCategory(
          profileId: 'wrong-profile-id',
          categoryId: category.id,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}