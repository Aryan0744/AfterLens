import '../../transactions/domain/transaction_types.dart';
import 'regret_response.dart';

/// Purchase details frozen when the reflection is answered.
/// Nullable values preserve missing legacy data and optional descriptions.
class RegretSnapshot {
  const RegretSnapshot({
    required this.amountCents,
    required this.transactionDate,
    this.categoryId,
    this.categoryName,
    this.moodTag,
    this.description,
  });

  final int amountCents;
  final String? categoryId;
  final String? categoryName;
  final MoodTag? moodTag;
  final String? description;
  final DateTime transactionDate;
}

class AppRegretCheckin {
  const AppRegretCheckin({
    required this.id,
    required this.transactionId,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.promptedAt,
    this.answeredAt,
    this.response,
    this.snapshot,
  }) : assert(
         (answeredAt == null && response == null && snapshot == null) ||
             (answeredAt != null && response != null && snapshot != null),
       );

  final String id;
  final String transactionId;

  final DateTime dueAt;
  final DateTime? promptedAt;
  final DateTime? answeredAt;

  final RegretResponse? response;
  final RegretSnapshot? snapshot;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPrompted => promptedAt != null;

  bool get isAnswered => answeredAt != null && response != null;

  bool get isPending => !isAnswered;

  bool isDueAt(DateTime time) => isPending && !dueAt.isAfter(time);
}
