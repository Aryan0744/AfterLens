import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../mood_engine/application/regret_scheduling_service.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_types.dart';

final transactionEntryControllerProvider =
    AsyncNotifierProvider<TransactionEntryController, TransactionEntryResult?>(
      TransactionEntryController.new,
    );

class TransactionEntryResult {
  const TransactionEntryResult({
    required this.transaction,
    this.regretScheduling,
  });

  final AppTransaction transaction;

  /// Null for income transactions.
  ///
  /// Expenses contain the result of the regret eligibility/scheduling flow.
  final RegretSchedulingResult? regretScheduling;

  bool get regretCheckinScheduled =>
      regretScheduling?.status == RegretSchedulingStatus.scheduled;
}

class TransactionEntryController
    extends AsyncNotifier<TransactionEntryResult?> {
  @override
  FutureOr<TransactionEntryResult?> build() {
    return null;
  }

  Future<TransactionEntryResult> createExpense({
    required String profileId,
    required String categoryId,
    required int amountCents,
    required MoodTag moodTag,
    required DateTime transactionDate,
    String? description,
  }) {
    return _run(() async {
      final database = ref.read(appDatabaseProvider);

      final transactionRepository = ref.read(transactionRepositoryProvider);

      final schedulingService = ref.read(regretSchedulingServiceProvider);

      // ------------------------------------------------------------
      // Keep expense creation + regret scheduling atomic.
      //
      // If scheduling unexpectedly fails, the transaction creation
      // also rolls back instead of leaving a partially completed
      // user action.
      // ------------------------------------------------------------
      return database.transaction(() async {
        final transaction = await transactionRepository.createExpense(
          profileId: profileId,
          categoryId: categoryId,
          amountCents: amountCents,
          moodTag: moodTag,
          transactionDate: transactionDate,
          description: description,
        );

        final regretScheduling = await schedulingService.scheduleForTransaction(
          transaction,
        );

        return TransactionEntryResult(
          transaction: transaction,
          regretScheduling: regretScheduling,
        );
      });
    });
  }

  Future<TransactionEntryResult> createIncome({
    required String profileId,
    required int amountCents,
    required DateTime transactionDate,
    String? description,
  }) {
    return _run(() async {
      final database = ref.read(appDatabaseProvider);

      final transactionRepository = ref.read(transactionRepositoryProvider);

      return database.transaction(() async {
        final transaction = await transactionRepository.createIncome(
          profileId: profileId,
          amountCents: amountCents,
          transactionDate: transactionDate,
          description: description,
        );

        return TransactionEntryResult(transaction: transaction);
      });
    });
  }

  void reset() {
    state = const AsyncData(null);
  }

  Future<TransactionEntryResult> _run(
    Future<TransactionEntryResult> Function() operation,
  ) async {
    state = const AsyncLoading();

    try {
      final result = await operation();

      state = AsyncData(result);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
