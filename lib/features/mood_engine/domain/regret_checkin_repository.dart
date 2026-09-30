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

  Future<List<AppRegretCheckin>> getCheckinsPromptedOnDate({
    required String profileId,
    required DateTime date,
  });

  Future<AppRegretCheckin> scheduleCheckin({
    required String transactionId,
    required DateTime dueAt,
  });

  Future<void> rescheduleUnpromptedCheckin({
    required String checkinId,
    required DateTime dueAt,
  });

  Future<void> deleteUnpromptedCheckin({required String checkinId});

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
