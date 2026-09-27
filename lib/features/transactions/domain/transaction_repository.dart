import 'app_transaction.dart';
import 'transaction_types.dart';

abstract class TransactionRepository {
  Future<AppTransaction?> getTransactionById({required String transactionId});

  Future<List<AppTransaction>> getTransactions({required String profileId});

  Stream<List<AppTransaction>> watchTransactions({required String profileId});

  Future<AppTransaction> createExpense({
    required String profileId,
    required String categoryId,
    required int amountCents,
    required MoodTag moodTag,
    required DateTime transactionDate,
    String? description,
  });

  Future<AppTransaction> createIncome({
    required String profileId,
    required int amountCents,
    required DateTime transactionDate,
    String? description,
  });

  Future<void> deleteTransaction({
    required String profileId,
    required String transactionId,
  });
}
