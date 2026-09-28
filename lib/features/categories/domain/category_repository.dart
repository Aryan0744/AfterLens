import 'app_category.dart';

abstract class CategoryRepository {
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

  Future<void> restoreCategory({
    required String profileId,
    required String categoryId,
  });
}
