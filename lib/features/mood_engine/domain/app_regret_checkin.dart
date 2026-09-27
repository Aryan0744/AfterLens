import 'regret_response.dart';

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
  });

  final String id;
  final String transactionId;

  final DateTime dueAt;
  final DateTime? promptedAt;
  final DateTime? answeredAt;

  final RegretResponse? response;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPrompted => promptedAt != null;

  bool get isAnswered =>
      answeredAt != null && response != null;

  bool get isPending => !isAnswered;

  bool isDueAt(DateTime time) =>
      isPending && !dueAt.isAfter(time);
}