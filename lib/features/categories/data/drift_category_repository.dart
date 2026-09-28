import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/app_category.dart';
import '../domain/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<List<AppCategory>> getActiveCategories({
    required String profileId,
  }) async {
    final rows =
        await (_database.select(_database.categories)
              ..where(
                (category) =>
                    category.profileId.equals(profileId) &
                    category.isArchived.equals(false),
              )
              ..orderBy([(category) => OrderingTerm.asc(category.name)]))
            .get();

    return rows.map(_mapCategory).toList();
  }

  @override
  Stream<List<AppCategory>> watchActiveCategories({required String profileId}) {
    final query = _database.select(_database.categories)
      ..where(
        (category) =>
            category.profileId.equals(profileId) &
            category.isArchived.equals(false),
      )
      ..orderBy([(category) => OrderingTerm.asc(category.name)]);

    return query.watch().map((rows) => rows.map(_mapCategory).toList());
  }

  @override
  Future<AppCategory?> getCategoryById({required String categoryId}) async {
    final row = await (_database.select(
      _database.categories,
    )..where((category) => category.id.equals(categoryId))).getSingleOrNull();

    return row == null ? null : _mapCategory(row);
  }

  @override
  Future<AppCategory> createCustomCategory({
    required String profileId,
    required String name,
  }) async {
    final normalizedName = _normalizeName(name);

    await _ensureProfileExists(profileId);

    final existingRows =
        await (_database.select(_database.categories)..where(
              (category) =>
                  category.profileId.equals(profileId) &
                  category.isArchived.equals(false),
            ))
            .get();

    final duplicateExists = existingRows.any(
      (category) =>
          category.name.trim().toLowerCase() == normalizedName.toLowerCase(),
    );

    if (duplicateExists) {
      throw StateError(
        'An active category named "$normalizedName" already exists.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            profileId: profileId,
            name: normalizedName,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppCategory(
      id: id,
      profileId: profileId,
      name: normalizedName,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<AppCategory> ensureSystemCategory({
    required String profileId,
    required String systemKey,
    required String name,
  }) async {
    await _ensureProfileExists(profileId);

    final normalizedName = _normalizeName(name);
    final normalizedSystemKey = systemKey.trim().toLowerCase();

    if (normalizedSystemKey.isEmpty) {
      throw ArgumentError.value(
        systemKey,
        'systemKey',
        'System key cannot be empty.',
      );
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(normalizedSystemKey)) {
      throw ArgumentError.value(
        systemKey,
        'systemKey',
        'System key may contain only lowercase letters, '
            'numbers, and underscores.',
      );
    }

    final existing =
        await (_database.select(_database.categories)..where(
              (category) =>
                  category.profileId.equals(profileId) &
                  category.systemKey.equals(normalizedSystemKey),
            ))
            .getSingleOrNull();

    // Bootstrap can safely run every time the app starts.
    // Reuse the existing system category rather than creating duplicates.
    if (existing != null) {
      return _mapCategory(existing);
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            profileId: profileId,
            name: normalizedName,
            systemKey: Value(normalizedSystemKey),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppCategory(
      id: id,
      profileId: profileId,
      name: normalizedName,
      systemKey: normalizedSystemKey,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> archiveCategory({
    required String profileId,
    required String categoryId,
  }) async {
    final affectedRows =
        await (_database.update(_database.categories)..where(
              (category) =>
                  category.id.equals(categoryId) &
                  category.profileId.equals(profileId),
            ))
            .write(
              CategoriesCompanion(
                isArchived: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );

    if (affectedRows != 1) {
      throw StateError(
        'Category $categoryId was not found for profile $profileId.',
      );
    }
  }

  @override
  Future<void> restoreCategory({
    required String profileId,
    required String categoryId,
  }) async {
    final category = await getCategoryById(categoryId: categoryId);

    if (category == null || category.profileId != profileId) {
      throw StateError(
        'Category $categoryId was not found for profile $profileId.',
      );
    }

    final activeCategories = await getActiveCategories(profileId: profileId);

    final duplicateExists = activeCategories.any(
      (active) =>
          active.id != categoryId &&
          active.name.toLowerCase() == category.name.toLowerCase(),
    );

    if (duplicateExists) {
      throw StateError(
        'Another active category named "${category.name}" already exists.',
      );
    }

    await (_database.update(_database.categories)..where(
          (row) => row.id.equals(categoryId) & row.profileId.equals(profileId),
        ))
        .write(
          CategoriesCompanion(
            isArchived: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _ensureProfileExists(String profileId) async {
    final profile = await (_database.select(
      _database.profiles,
    )..where((row) => row.id.equals(profileId))).getSingleOrNull();

    if (profile == null) {
      throw StateError('Profile $profileId does not exist.');
    }
  }

  String _normalizeName(String name) {
    final value = name.trim();

    if (value.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Category name cannot be empty.');
    }

    if (value.length > 50) {
      throw ArgumentError.value(
        name,
        'name',
        'Category name cannot exceed 50 characters.',
      );
    }

    return value;
  }

  AppCategory _mapCategory(Category row) {
    return AppCategory(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      systemKey: row.systemKey,
      isArchived: row.isArchived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
