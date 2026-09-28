import '../../categories/domain/app_category.dart';
import '../../categories/domain/category_repository.dart';
import '../../categories/domain/default_categories.dart';
import '../../profile/domain/app_profile.dart';
import '../../profile/domain/profile_repository.dart';

enum AppBootstrapStatus { needsOnboarding, ready }

class AppBootstrapResult {
  const AppBootstrapResult._({
    required this.status,
    this.profile,
    this.categories = const [],
  });

  const AppBootstrapResult.needsOnboarding()
    : this._(status: AppBootstrapStatus.needsOnboarding);

  const AppBootstrapResult.ready({
    required AppProfile profile,
    required List<AppCategory> categories,
  }) : this._(
         status: AppBootstrapStatus.ready,
         profile: profile,
         categories: categories,
       );

  final AppBootstrapStatus status;
  final AppProfile? profile;
  final List<AppCategory> categories;

  bool get needsOnboarding => status == AppBootstrapStatus.needsOnboarding;

  bool get isReady => status == AppBootstrapStatus.ready;
}

class AppBootstrapService {
  AppBootstrapService({
    required this.profileRepository,
    required this.categoryRepository,
  });

  final ProfileRepository profileRepository;
  final CategoryRepository categoryRepository;

  Future<AppBootstrapResult> initialize() async {
    final profile = await profileRepository.getLocalProfile();

    if (profile == null) {
      return const AppBootstrapResult.needsOnboarding();
    }

    await _ensureDefaultCategories(profileId: profile.id);

    final categories = await categoryRepository.getActiveCategories(
      profileId: profile.id,
    );

    return AppBootstrapResult.ready(profile: profile, categories: categories);
  }

  Future<AppBootstrapResult> completeOnboarding({
    required String currencyCode,
  }) async {
    final existingProfile = await profileRepository.getLocalProfile();

    final profile =
        existingProfile ??
        await profileRepository.createLocalProfile(currencyCode: currencyCode);

    await _ensureDefaultCategories(profileId: profile.id);

    final categories = await categoryRepository.getActiveCategories(
      profileId: profile.id,
    );

    return AppBootstrapResult.ready(profile: profile, categories: categories);
  }

  Future<void> _ensureDefaultCategories({required String profileId}) async {
    for (final category in defaultCategories) {
      await categoryRepository.ensureSystemCategory(
        profileId: profileId,
        systemKey: category.systemKey,
        name: category.name,
      );
    }
  }
}
