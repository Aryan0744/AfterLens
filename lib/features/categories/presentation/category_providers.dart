import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/app_category.dart';

final categoriesProvider = StreamProvider.family<List<AppCategory>, String>((
  ref,
  profileId,
) {
  return ref
      .watch(categoryRepositoryProvider)
      .watchCategories(profileId: profileId);
});

final activeCategoriesProvider =
    StreamProvider.family<List<AppCategory>, String>((ref, profileId) {
      final repository = ref.watch(categoryRepositoryProvider);

      return repository.watchActiveCategories(profileId: profileId);
    });
