import 'app_category.dart';

abstract class CategoryRepository {
  /// Includes archived categories for historical display and management.
  Stream<List<AppCategory>> watchCategories({required String profileId});

  Future<List<AppCategory>> getActiveCategories({required String profileId});

  Stream<List<AppCategory>> watchActiveCategories({required String profileId});

  Future<AppCategory?> getCategoryById({required String categoryId});

  Future<AppCategory> createCustomCategory({
    required String profileId,
    required String name,
  });

  Future<AppCategory> ensureSystemCategory({
    required String profileId,
    required String systemKey,
    required String name,
  });

  Future<void> archiveCategory({
    required String profileId,
    required String categoryId,
  });

  Future<void> renameCategory({
    required String profileId,
    required String categoryId,
    required String name,
  });

  Future<void> restoreCategory({
    required String profileId,
    required String categoryId,
  });
}
