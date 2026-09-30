import '../../mood_engine/domain/regret_response.dart';
import '../../transactions/domain/transaction_types.dart';

class BehavioralReflection {
  const BehavioralReflection({
    required this.transactionId,
    required this.amountCents,
    required this.moodTag,
    required this.response,
    required this.transactionDate,
    required this.answeredAt,
    this.categoryId,
    this.categoryName,
  });

  final String transactionId;

  final int amountCents;

  final MoodTag moodTag;
  final RegretResponse response;

  final String? categoryId;
  final String? categoryName;

  final DateTime transactionDate;
  final DateTime answeredAt;
}
