import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/behavioral_insights.dart';
import '../domain/behavioral_reflection.dart';

final completedReflectionsProvider =
    StreamProvider.family<List<BehavioralReflection>, String>((ref, profileId) {
      return ref
          .watch(behavioralInsightsRepositoryProvider)
          .watchCompletedReflections(profileId: profileId);
    });

final behavioralInsightsProvider =
    StreamProvider.family<BehavioralInsights, String>((ref, profileId) {
      final repository = ref.watch(behavioralInsightsRepositoryProvider);

      final service = ref.watch(behavioralInsightsServiceProvider);

      return repository
          .watchCompletedReflections(profileId: profileId)
          .map(service.analyze);
    });
