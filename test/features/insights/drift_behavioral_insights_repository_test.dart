import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/insights/data/drift_behavioral_insights_repository.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  late DriftProfileRepository profileRepository;
  late DriftCategoryRepository categoryRepository;
  late DriftTransactionRepository transactionRepository;
  late DriftBehavioralInsightsRepository insightsRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);

    categoryRepository = DriftCategoryRepository(database);

    transactionRepository = DriftTransactionRepository(database);

    insightsRepository = DriftBehavioralInsightsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertAnsweredCheckin({
    required String id,
    required String transactionId,
    required RegretResponse response,
    DateTime? dueAt,
    DateTime? promptedAt,
    DateTime? answeredAt,
  }) async {
    final resolvedDueAt = dueAt ?? DateTime(2026, 9, 3, 9);

    final resolvedPromptedAt = promptedAt ?? DateTime(2026, 9, 3, 10);

    final resolvedAnsweredAt = answeredAt ?? DateTime(2026, 9, 3, 10, 5);

    await database
        .into(database.regretCheckins)
        .insert(
          RegretCheckinsCompanion.insert(
            id: id,
            transactionId: transactionId,
            dueAt: resolvedDueAt,
            promptedAt: Value(resolvedPromptedAt),
            answeredAt: Value(resolvedAnsweredAt),
            response: Value(response),
          ),
        );
  }

  Future<void> insertUnansweredCheckin({
    required String id,
    required String transactionId,
  }) async {
    await database
        .into(database.regretCheckins)
        .insert(
          RegretCheckinsCompanion.insert(
            id: id,
            transactionId: transactionId,
            dueAt: DateTime(2026, 9, 3, 9),
            promptedAt: Value(DateTime(2026, 9, 3, 10)),
          ),
        );
  }

  group('DriftBehavioralInsightsRepository', () {
    test('returns completed reflections for the requested profile', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 2500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 1),
        description: 'Headphones',
      );

      await insertAnsweredCheckin(
        id: 'checkin-1',
        transactionId: transaction.id,
        response: RegretResponse.regret,
      );

      final reflections = await insightsRepository.getCompletedReflections(
        profileId: profile.id,
      );

      expect(reflections, hasLength(1));

      final reflection = reflections.single;

      expect(reflection.transactionId, transaction.id);

      expect(reflection.amountCents, 2500);

      expect(reflection.moodTag, MoodTag.impulse);

      expect(reflection.response, RegretResponse.regret);

      expect(reflection.categoryId, category.id);

      expect(reflection.categoryName, 'Shopping');
    });

    test('excludes unanswered check-ins', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 2500,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 1),
      );

      await insertUnansweredCheckin(
        id: 'checkin-1',
        transactionId: transaction.id,
      );

      final reflections = await insightsRepository.getCompletedReflections(
        profileId: profile.id,
      );

      expect(reflections, isEmpty);
    });

    test('isolates reflections by profile', () async {
      final profileA = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      // ProfileRepository is intentionally one-local-profile oriented.
      // Insert a second profile directly for profile-isolation testing.
      await database
          .into(database.profiles)
          .insert(
            ProfilesCompanion.insert(id: 'profile-b', currencyCode: 'CAD'),
          );

      final categoryA = await categoryRepository.createCustomCategory(
        profileId: profileA.id,
        name: 'Shopping',
      );

      final categoryB = await categoryRepository.createCustomCategory(
        profileId: 'profile-b',
        name: 'Dining',
      );

      final transactionA = await transactionRepository.createExpense(
        profileId: profileA.id,
        categoryId: categoryA.id,
        amountCents: 2500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 1),
      );

      final transactionB = await transactionRepository.createExpense(
        profileId: 'profile-b',
        categoryId: categoryB.id,
        amountCents: 4000,
        moodTag: MoodTag.social,
        transactionDate: DateTime(2026, 9, 1),
      );

      await insertAnsweredCheckin(
        id: 'checkin-a',
        transactionId: transactionA.id,
        response: RegretResponse.regret,
      );

      await insertAnsweredCheckin(
        id: 'checkin-b',
        transactionId: transactionB.id,
        response: RegretResponse.worthIt,
      );

      final reflections = await insightsRepository.getCompletedReflections(
        profileId: profileA.id,
      );

      expect(reflections, hasLength(1));

      expect(reflections.single.transactionId, transactionA.id);
    });

    test('keeps archived categories in historical insights', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Entertainment',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 6500,
        moodTag: MoodTag.impulse,
        transactionDate: DateTime(2026, 9, 1),
      );

      await insertAnsweredCheckin(
        id: 'checkin-1',
        transactionId: transaction.id,
        response: RegretResponse.regret,
      );

      await categoryRepository.archiveCategory(
        profileId: profile.id,
        categoryId: category.id,
      );

      final reflections = await insightsRepository.getCompletedReflections(
        profileId: profile.id,
      );

      expect(reflections, hasLength(1));

      expect(reflections.single.categoryId, category.id);

      expect(reflections.single.categoryName, 'Entertainment');
    });

    test('watch stream updates when a reflection becomes completed', () async {
      final profile = await profileRepository.createLocalProfile(
        currencyCode: 'CAD',
      );

      final category = await categoryRepository.createCustomCategory(
        profileId: profile.id,
        name: 'Shopping',
      );

      final transaction = await transactionRepository.createExpense(
        profileId: profile.id,
        categoryId: category.id,
        amountCents: 3200,
        moodTag: MoodTag.want,
        transactionDate: DateTime(2026, 9, 1),
      );

      final stream = insightsRepository.watchCompletedReflections(
        profileId: profile.id,
      );

      final expectation = expectLater(
        stream.take(2),
        emitsInOrder([
          isEmpty,
          predicate<List<dynamic>>((items) {
            return items.length == 1;
          }),
        ]),
      );

      // Allow the initial watched-query result to be emitted.
      await Future<void>.delayed(Duration.zero);

      await insertAnsweredCheckin(
        id: 'checkin-1',
        transactionId: transaction.id,
        response: RegretResponse.worthIt,
      );

      await expectation;
    });
  });
}
