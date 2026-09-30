import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bootstrap/application/app_bootstrap_service.dart';
import '../../features/categories/data/drift_category_repository.dart';
import '../../features/categories/domain/category_repository.dart';
import '../../features/insights/application/behavioral_insights_service.dart';
import '../../features/insights/data/drift_behavioral_insights_repository.dart';
import '../../features/insights/domain/behavioral_insights_repository.dart';
import '../../features/mood_engine/application/regret_prompt_service.dart';
import '../../features/mood_engine/application/regret_scheduling_service.dart';
import '../../features/mood_engine/data/drift_regret_checkin_repository.dart';
import '../../features/mood_engine/domain/regret_checkin_repository.dart';
import '../../features/mood_engine/domain/regret_eligibility_policy.dart';
import '../../features/profile/data/drift_profile_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/transactions/data/drift_transaction_repository.dart';
import '../../features/transactions/domain/transaction_repository.dart';
import '../database/database_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return DriftProfileRepository(database);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return DriftCategoryRepository(database);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return DriftTransactionRepository(database);
});

final regretCheckinRepositoryProvider = Provider<RegretCheckinRepository>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);

  return DriftRegretCheckinRepository(database);
});

final regretEligibilityPolicyProvider = Provider<RegretEligibilityPolicy>((
  ref,
) {
  return RegretEligibilityPolicy();
});

final regretSchedulingServiceProvider = Provider<RegretSchedulingService>((
  ref,
) {
  final eligibilityPolicy = ref.watch(regretEligibilityPolicyProvider);

  final checkinRepository = ref.watch(regretCheckinRepositoryProvider);

  return RegretSchedulingService(
    eligibilityPolicy: eligibilityPolicy,
    checkinRepository: checkinRepository,
  );
});

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);

  final categoryRepository = ref.watch(categoryRepositoryProvider);

  return AppBootstrapService(
    profileRepository: profileRepository,
    categoryRepository: categoryRepository,
  );
});

final regretPromptServiceProvider = Provider<RegretPromptService>((ref) {
  return RegretPromptService(
    checkinRepository: ref.watch(regretCheckinRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    runInTransaction: ref.watch(appDatabaseProvider).transaction,
  );
});

final behavioralInsightsRepositoryProvider =
    Provider<BehavioralInsightsRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);

      return DriftBehavioralInsightsRepository(database);
    });

final behavioralInsightsServiceProvider = Provider<BehavioralInsightsService>((
  ref,
) {
  return const BehavioralInsightsService();
});
