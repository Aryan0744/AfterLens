import 'transaction_types.dart';

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.profileId,
    required this.type,
    required this.amountCents,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.description,
    this.moodTag,
  });

  final String id;
  final String profileId;
  final String? categoryId;

  final TransactionType type;

  final int amountCents;

  final String? description;
  final MoodTag? moodTag;

  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpense => type == TransactionType.expense;

  bool get isIncome => type == TransactionType.income;
}
