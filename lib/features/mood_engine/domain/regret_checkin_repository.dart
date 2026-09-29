import 'app_regret_checkin.dart';
import 'regret_response.dart';

abstract class RegretCheckinRepository {
  Future<AppRegretCheckin?> getCheckinById({required String checkinId});

  Future<AppRegretCheckin?> getCheckinForTransaction({
    required String transactionId,
  });

  Future<List<AppRegretCheckin>> getDueCheckins({
    required String profileId,
    required DateTime asOf,
  });

  /// All deliveries on the local calendar date, including answered check-ins.
  Future<List<AppRegretCheckin>> getCheckinsPromptedOnDate({
    required String profileId,
    required DateTime date,
  });

  Future<AppRegretCheckin> scheduleCheckin({
    required String transactionId,
    required DateTime dueAt,
  });

  Future<void> markPrompted({
    required String checkinId,
    required DateTime promptedAt,
  });

  Future<void> answerCheckin({
    required String checkinId,
    required RegretResponse response,
    required DateTime answeredAt,
  });
}
