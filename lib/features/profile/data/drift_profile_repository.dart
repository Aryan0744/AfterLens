import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/app_profile.dart';
import '../domain/profile_repository.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<AppProfile?> getLocalProfile() async {
    final row = await (_database.select(
      _database.profiles,
    )..limit(1)).getSingleOrNull();

    return row == null ? null : _mapProfile(row);
  }

  @override
  Stream<AppProfile?> watchLocalProfile() {
    final query = _database.select(_database.profiles)..limit(1);

    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _mapProfile(row),
    );
  }

  @override
  Future<AppProfile> createLocalProfile({required String currencyCode}) async {
    final normalizedCurrency = _normalizeCurrency(currencyCode);

    final existing = await getLocalProfile();

    if (existing != null) {
      throw StateError('A local profile already exists.');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    await _database
        .into(_database.profiles)
        .insert(
          ProfilesCompanion.insert(
            id: id,
            currencyCode: normalizedCurrency,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppProfile(
      id: id,
      currencyCode: normalizedCurrency,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updateCurrency({
    required String profileId,
    required String currencyCode,
  }) async {
    final normalizedCurrency = _normalizeCurrency(currencyCode);

    final affectedRows =
        await (_database.update(
          _database.profiles,
        )..where((profile) => profile.id.equals(profileId))).write(
          ProfilesCompanion(
            currencyCode: Value(normalizedCurrency),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (affectedRows != 1) {
      throw StateError('Profile $profileId was not found.');
    }
  }

  @override
  Future<void> linkAuthUser({
    required String profileId,
    required String authUserId,
  }) async {
    final trimmedAuthUserId = authUserId.trim();

    if (trimmedAuthUserId.isEmpty) {
      throw ArgumentError.value(
        authUserId,
        'authUserId',
        'Auth user ID cannot be empty.',
      );
    }

    final affectedRows =
        await (_database.update(
          _database.profiles,
        )..where((profile) => profile.id.equals(profileId))).write(
          ProfilesCompanion(
            authUserId: Value(trimmedAuthUserId),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (affectedRows != 1) {
      throw StateError('Profile $profileId was not found.');
    }
  }

  String _normalizeCurrency(String currencyCode) {
    final value = currencyCode.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'Currency code must contain exactly three letters.',
      );
    }

    return value;
  }

  AppProfile _mapProfile(Profile row) {
    return AppProfile(
      id: row.id,
      authUserId: row.authUserId,
      currencyCode: row.currencyCode,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
