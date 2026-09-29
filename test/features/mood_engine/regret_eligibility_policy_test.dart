import 'package:afterlens/features/mood_engine/domain/regret_eligibility_policy.dart';
import 'package:afterlens/features/transactions/domain/app_transaction.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final policy = RegretEligibilityPolicy();

  AppTransaction transaction({
    TransactionType type = TransactionType.expense,
    int amountCents = 2000,
    MoodTag? moodTag = MoodTag.impulse,
    DateTime? transactionDate,
  }) {
    final date = transactionDate ?? DateTime(2026, 9, 20, 12);

    return AppTransaction(
      id: 'transaction-test',
      profileId: 'profile-test',
      categoryId: type == TransactionType.expense ? 'category-test' : null,
      type: type,
      amountCents: amountCents,
      moodTag: moodTag,
      transactionDate: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('RegretEligibilityPolicy', () {
    test('impulse expense over \$15 is eligible', () {
      final purchase = transaction(amountCents: 1501, moodTag: MoodTag.impulse);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, true);
      expect(result.reason, isNull);
    });

    test('want expense over \$15 is eligible', () {
      final purchase = transaction(amountCents: 2500, moodTag: MoodTag.want);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, true);
    });

    test('exactly \$15 is not eligible', () {
      final purchase = transaction(amountCents: 1500, moodTag: MoodTag.impulse);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.amountNotAboveThreshold);

      expect(result.dueAt, isNull);
    });

    test('expense below \$15 is not eligible', () {
      final purchase = transaction(amountCents: 1499, moodTag: MoodTag.want);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.amountNotAboveThreshold);
    });

    test('income is never eligible', () {
      final income = transaction(
        type: TransactionType.income,
        amountCents: 500000,
        moodTag: null,
      );

      final result = policy.evaluate(income);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.notExpense);
    });

    test('expense without mood is not eligible', () {
      final purchase = transaction(amountCents: 5000, moodTag: null);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.missingMood);
    });

    test('need expense is not eligible', () {
      final purchase = transaction(amountCents: 5000, moodTag: MoodTag.need);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.moodNotEligible);
    });

    test('social expense is not eligible', () {
      final purchase = transaction(amountCents: 5000, moodTag: MoodTag.social);

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.moodNotEligible);
    });

    test('subscription expense is not eligible', () {
      final purchase = transaction(
        amountCents: 5000,
        moodTag: MoodTag.subscription,
      );

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.moodNotEligible);
    });

    test('emergency expense is not eligible', () {
      final purchase = transaction(
        amountCents: 5000,
        moodTag: MoodTag.emergency,
      );

      final result = policy.evaluate(purchase);

      expect(result.isEligible, false);

      expect(result.reason, RegretIneligibilityReason.moodNotEligible);
    });

    test('eligible transaction is scheduled two days later', () {
      final date = DateTime(2026, 9, 20, 14, 30);

      final purchase = transaction(
        amountCents: 3000,
        moodTag: MoodTag.impulse,
        transactionDate: date,
      );

      final result = policy.evaluate(purchase);

      expect(result.isEligible, true);

      expect(result.dueAt, DateTime(2026, 9, 22, 14, 30));
    });

    test('supports configurable threshold and delay', () {
      final customPolicy = RegretEligibilityPolicy(
        minimumAmountCents: 5000,
        delay: Duration(days: 3),
      );

      final date = DateTime(2026, 9, 20);

      final purchase = transaction(
        amountCents: 5001,
        moodTag: MoodTag.want,
        transactionDate: date,
      );

      final result = customPolicy.evaluate(purchase);

      expect(result.isEligible, true);

      expect(result.dueAt, DateTime(2026, 9, 23));
    });
  });
}
