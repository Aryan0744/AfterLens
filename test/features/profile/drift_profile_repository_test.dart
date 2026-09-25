import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository repository;

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(),
    );

    repository = DriftProfileRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftProfileRepository', () {
    test('creates a local profile and normalizes currency code', () async {
      final profile = await repository.createLocalProfile(
        currencyCode: 'cad',
      );

      expect(profile.id, isNotEmpty);
      expect(profile.currencyCode, 'CAD');
      expect(profile.authUserId, isNull);

      final storedProfile = await repository.getLocalProfile();

      expect(storedProfile, isNotNull);
      expect(storedProfile!.id, profile.id);
      expect(storedProfile.currencyCode, 'CAD');
    });

    test('does not allow more than one local profile', () async {
      await repository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => repository.createLocalProfile(
          currencyCode: 'USD',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects invalid currency codes', () async {
      expect(
            () => repository.createLocalProfile(
          currencyCode: 'CA',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
            () => repository.createLocalProfile(
          currencyCode: 'Canadian Dollar',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
            () => repository.createLocalProfile(
          currencyCode: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updates profile currency and normalizes it', () async {
      final profile = await repository.createLocalProfile(
        currencyCode: 'CAD',
      );

      await repository.updateCurrency(
        profileId: profile.id,
        currencyCode: 'usd',
      );

      final updated = await repository.getLocalProfile();

      expect(updated, isNotNull);
      expect(updated!.currencyCode, 'USD');
    });

    test('links an auth user to the local profile', () async {
      final profile = await repository.createLocalProfile(
        currencyCode: 'CAD',
      );

      await repository.linkAuthUser(
        profileId: profile.id,
        authUserId: 'auth-user-123',
      );

      final updated = await repository.getLocalProfile();

      expect(updated, isNotNull);
      expect(updated!.authUserId, 'auth-user-123');
    });

    test('rejects an empty auth user id', () async {
      final profile = await repository.createLocalProfile(
        currencyCode: 'CAD',
      );

      expect(
            () => repository.linkAuthUser(
          profileId: profile.id,
          authUserId: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating a profile that does not exist', () async {
      expect(
            () => repository.updateCurrency(
          profileId: 'missing-profile',
          currencyCode: 'USD',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}