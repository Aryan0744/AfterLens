import 'app_profile.dart';

abstract class ProfileRepository {
  Future<AppProfile?> getLocalProfile();

  Stream<AppProfile?> watchLocalProfile();

  Future<AppProfile> createLocalProfile({required String currencyCode});

  Future<void> updateCurrency({
    required String profileId,
    required String currencyCode,
  });

  Future<void> linkAuthUser({
    required String profileId,
    required String authUserId,
  });
}
