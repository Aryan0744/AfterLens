import 'behavioral_reflection.dart';

abstract class BehavioralInsightsRepository {
  Future<List<BehavioralReflection>> getCompletedReflections({
    required String profileId,
  });

  Stream<List<BehavioralReflection>> watchCompletedReflections({
    required String profileId,
  });
}
