import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_result.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_service.dart';
import 'package:afterlens/features/mood_engine/application/regret_scheduling_service.dart';
import 'package:afterlens/features/mood_engine/data/drift_regret_checkin_repository.dart';
import 'package:afterlens/features/mood_engine/domain/app_regret_checkin.dart';
import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:afterlens/features/transactions/data/drift_transaction_repository.dart';
import 'package:afterlens/features/transactions/domain/app_transaction.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/native.dart';

class RegretTestFixture {
  RegretTestFixture([AppDatabase? database])
    : database = database ?? AppDatabase(NativeDatabase.memory());

  final AppDatabase database;
  final now = DateTime(2026, 9, 29, 12);
  late final transactions = DriftTransactionRepository(database);
  late final checkins = DriftRegretCheckinRepository(database);
  late final service = RegretPromptService(
    checkinRepository: checkins,
    transactionRepository: transactions,
    runInTransaction: database.transaction,
  );
  late AppProfile profile;
  late String categoryId;

  Future<void> initialize() async {
    profile = await DriftProfileRepository(database)
        .createLocalProfile(currencyCode: 'CAD');
    categoryId = (await DriftCategoryRepository(
      database,
    ).createCustomCategory(profileId: profile.id, name: 'Shopping')).id;
  }

  Future<AppTransaction> expense({
    DateTime? date,
    int amountCents = 2500,
    MoodTag mood = MoodTag.impulse,
    String? description = 'Headphones',
  }) async {
    final transaction = await transactions.createExpense(
      profileId: profile.id,
      categoryId: categoryId,
      amountCents: amountCents,
      moodTag: mood,
      transactionDate: date ?? now.subtract(const Duration(days: 3)),
      description: description,
    );
    await RegretSchedulingService(
      eligibilityPolicy: RegretEligibilityPolicy(),
      checkinRepository: checkins,
    ).scheduleForTransaction(transaction);
    return transaction;
  }

  Future<AppRegretCheckin> scheduled({DateTime? dueAt}) async {
    final purchase = await expense(
      date: dueAt?.subtract(const Duration(days: 2)),
    );
    return (await checkins.getCheckinForTransaction(
      transactionId: purchase.id,
    ))!;
  }

  Future<RegretPromptResult> select({DateTime? at, String? profileId}) =>
      service.getPrompt(profileId: profileId ?? profile.id, asOf: at ?? now);
}
