import '../../transactions/domain/app_transaction.dart';
import '../../transactions/domain/transaction_types.dart';

enum RegretIneligibilityReason {
  notExpense,
  missingMood,
  moodNotEligible,
  amountNotAboveThreshold,
}

class RegretEligibilityDecision {
  const RegretEligibilityDecision._({
    required this.isEligible,
    this.dueAt,
    this.reason,
  });

  const RegretEligibilityDecision.eligible({
    required DateTime dueAt,
  }) : this._(
    isEligible: true,
    dueAt: dueAt,
  );

  const RegretEligibilityDecision.ineligible({
    required RegretIneligibilityReason reason,
  }) : this._(
    isEligible: false,
    reason: reason,
  );

  final bool isEligible;
  final DateTime? dueAt;
  final RegretIneligibilityReason? reason;
}

class RegretEligibilityPolicy {
  RegretEligibilityPolicy({
    this.minimumAmountCents = 1500,
    this.delay = const Duration(days: 2),
    this.eligibleMoods = const {
      MoodTag.want,
      MoodTag.impulse,
    },
  })  : assert(minimumAmountCents >= 0),
        assert(delay.inMicroseconds > 0);

  /// The transaction must be strictly greater than this amount.
  ///
  /// Default:
  /// 1500 cents = $15.00
  final int minimumAmountCents;

  final Duration delay;

  final Set<MoodTag> eligibleMoods;

  RegretEligibilityDecision evaluate(
      AppTransaction transaction,
      ) {
    if (transaction.type != TransactionType.expense) {
      return const RegretEligibilityDecision.ineligible(
        reason: RegretIneligibilityReason.notExpense,
      );
    }

    final mood = transaction.moodTag;

    if (mood == null) {
      return const RegretEligibilityDecision.ineligible(
        reason: RegretIneligibilityReason.missingMood,
      );
    }

    if (!eligibleMoods.contains(mood)) {
      return const RegretEligibilityDecision.ineligible(
        reason: RegretIneligibilityReason.moodNotEligible,
      );
    }

    if (transaction.amountCents <= minimumAmountCents) {
      return const RegretEligibilityDecision.ineligible(
        reason: RegretIneligibilityReason.amountNotAboveThreshold,
      );
    }

    return RegretEligibilityDecision.eligible(
      dueAt: transaction.transactionDate.add(delay),
    );
  }
}