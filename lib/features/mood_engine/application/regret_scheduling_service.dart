import '../domain/app_regret_checkin.dart';
import '../domain/regret_checkin_repository.dart';
import '../domain/regret_eligibility_policy.dart';
import '../../transactions/domain/app_transaction.dart';

enum RegretSchedulingStatus { ineligible, scheduled, alreadyScheduled }

class RegretSchedulingResult {
  const RegretSchedulingResult._({
    required this.status,
    this.checkin,
    this.ineligibilityReason,
  });

  const RegretSchedulingResult.ineligible({
    required RegretIneligibilityReason reason,
  }) : this._(
         status: RegretSchedulingStatus.ineligible,
         ineligibilityReason: reason,
       );

  const RegretSchedulingResult.scheduled({required AppRegretCheckin checkin})
    : this._(status: RegretSchedulingStatus.scheduled, checkin: checkin);

  const RegretSchedulingResult.alreadyScheduled({
    required AppRegretCheckin checkin,
  }) : this._(
         status: RegretSchedulingStatus.alreadyScheduled,
         checkin: checkin,
       );

  final RegretSchedulingStatus status;

  final AppRegretCheckin? checkin;

  final RegretIneligibilityReason? ineligibilityReason;
}

class RegretSchedulingService {
  RegretSchedulingService({
    required this.eligibilityPolicy,
    required this.checkinRepository,
  });

  final RegretEligibilityPolicy eligibilityPolicy;

  final RegretCheckinRepository checkinRepository;

  Future<RegretSchedulingResult> scheduleForTransaction(
    AppTransaction transaction,
  ) async {
    // ------------------------------------------------------------
    // 1. Determine whether this transaction qualifies for a
    //    regret/reflection check-in.
    // ------------------------------------------------------------
    final decision = eligibilityPolicy.evaluate(transaction);

    // ------------------------------------------------------------
    // 2. If the transaction is not eligible, return the reason.
    //
    // No database write happens in this case.
    // ------------------------------------------------------------
    if (!decision.isEligible) {
      final reason = decision.reason;

      if (reason == null) {
        throw StateError(
          'Ineligible regret decision did not provide a reason.',
        );
      }

      return RegretSchedulingResult.ineligible(reason: reason);
    }

    // ------------------------------------------------------------
    // 3. Eligible decisions must contain a due date.
    // ------------------------------------------------------------
    final dueAt = decision.dueAt;

    if (dueAt == null) {
      throw StateError('Eligible regret decision did not provide a due date.');
    }

    // ------------------------------------------------------------
    // 4. Make scheduling idempotent.
    //
    // If this service is accidentally called twice for the same
    // transaction, do not create another check-in.
    // ------------------------------------------------------------
    final existing = await checkinRepository.getCheckinForTransaction(
      transactionId: transaction.id,
    );

    if (existing != null) {
      return RegretSchedulingResult.alreadyScheduled(checkin: existing);
    }

    // ------------------------------------------------------------
    // 5. Create the scheduled check-in.
    // ------------------------------------------------------------
    final checkin = await checkinRepository.scheduleCheckin(
      transactionId: transaction.id,
      dueAt: dueAt,
    );

    return RegretSchedulingResult.scheduled(checkin: checkin);
  }
}
