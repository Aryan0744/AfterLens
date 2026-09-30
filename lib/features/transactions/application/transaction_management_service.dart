import '../../mood_engine/domain/regret_checkin_repository.dart';
import '../../mood_engine/domain/regret_eligibility_policy.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_types.dart';

enum RegretReconciliationStatus {
  unchanged,
  scheduled,
  rescheduled,
  removed,
  preserved,
}

class TransactionUpdateResult {
  const TransactionUpdateResult({
    required this.transaction,
    required this.regretStatus,
  });

  final AppTransaction transaction;
  final RegretReconciliationStatus regretStatus;
}

class TransactionManagementService {
  TransactionManagementService({
    required this.transactionRepository,
    required this.checkinRepository,
    required this.eligibilityPolicy,
    required this.runInTransaction,
  });

  final TransactionRepository transactionRepository;
  final RegretCheckinRepository checkinRepository;
  final RegretEligibilityPolicy eligibilityPolicy;

  final Future<T> Function<T>(Future<T> Function() action) runInTransaction;

  Future<TransactionUpdateResult> updateExpense({
    required String profileId,
    required String transactionId,
    required String categoryId,
    required int amountCents,
    required MoodTag moodTag,
    required DateTime transactionDate,
    String? description,
  }) {
    return runInTransaction(() async {
      final existingTransaction = await transactionRepository
          .getTransactionById(transactionId: transactionId);

      if (existingTransaction == null) {
        throw StateError('Transaction $transactionId does not exist.');
      }

      if (existingTransaction.profileId != profileId) {
        throw StateError(
          'Transaction $transactionId does not belong '
          'to profile $profileId.',
        );
      }

      if (!existingTransaction.isExpense) {
        throw StateError('Transaction $transactionId is not an expense.');
      }

      final existingCheckin = await checkinRepository.getCheckinForTransaction(
        transactionId: transactionId,
      );

      final updatedTransaction = await transactionRepository.updateExpense(
        profileId: profileId,
        transactionId: transactionId,
        categoryId: categoryId,
        amountCents: amountCents,
        moodTag: moodTag,
        transactionDate: transactionDate,
        description: description,
      );

      if (existingCheckin != null && existingCheckin.isAnswered) {
        return TransactionUpdateResult(
          transaction: updatedTransaction,
          regretStatus: RegretReconciliationStatus.preserved,
        );
      }

      final decision = eligibilityPolicy.evaluate(updatedTransaction);

      if (existingCheckin == null) {
        if (!decision.isEligible) {
          return TransactionUpdateResult(
            transaction: updatedTransaction,
            regretStatus: RegretReconciliationStatus.unchanged,
          );
        }

        final dueAt = decision.dueAt;

        if (dueAt == null) {
          throw StateError(
            'Eligible regret decision did not provide '
            'a due date.',
          );
        }

        await checkinRepository.scheduleCheckin(
          transactionId: transactionId,
          dueAt: dueAt,
        );

        return TransactionUpdateResult(
          transaction: updatedTransaction,
          regretStatus: RegretReconciliationStatus.scheduled,
        );
      }

      if (!decision.isEligible) {
        await checkinRepository.deleteUnansweredCheckin(
          checkinId: existingCheckin.id,
        );

        return TransactionUpdateResult(
          transaction: updatedTransaction,
          regretStatus: RegretReconciliationStatus.removed,
        );
      }

      final dueAt = decision.dueAt;

      if (dueAt == null) {
        throw StateError(
          'Eligible regret decision did not provide '
          'a due date.',
        );
      }

      await checkinRepository.rescheduleUnansweredCheckin(
        checkinId: existingCheckin.id,
        dueAt: dueAt,
      );

      return TransactionUpdateResult(
        transaction: updatedTransaction,
        regretStatus: RegretReconciliationStatus.rescheduled,
      );
    });
  }

  Future<void> deleteTransaction({
    required String profileId,
    required String transactionId,
  }) {
    return runInTransaction(() async {
      final transaction = await transactionRepository.getTransactionById(
        transactionId: transactionId,
      );

      if (transaction == null) {
        throw StateError('Transaction $transactionId does not exist.');
      }

      if (transaction.profileId != profileId) {
        throw StateError(
          'Transaction $transactionId does not belong '
          'to profile $profileId.',
        );
      }

      final checkin = await checkinRepository.getCheckinForTransaction(
        transactionId: transactionId,
      );

      // Pending reflections disappear with the deleted purchase. Completed
      // snapshots remain untouched and continue to contribute to Insights.
      if (checkin != null && !checkin.isAnswered) {
        await checkinRepository.deleteUnansweredCheckin(checkinId: checkin.id);
      }

      await transactionRepository.deleteTransaction(
        profileId: profileId,
        transactionId: transactionId,
      );
    });
  }
}
