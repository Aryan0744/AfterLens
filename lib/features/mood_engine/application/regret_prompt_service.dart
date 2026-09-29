import '../../transactions/domain/transaction_repository.dart';
import '../domain/app_regret_checkin.dart';
import '../domain/regret_checkin_repository.dart';
import '../domain/regret_response.dart';
import 'regret_prompt_result.dart';

typedef RegretTransactionRunner = Future<T> Function<T>(
  Future<T> Function() operation,
);

class RegretPromptService {
  const RegretPromptService({
    required this.checkinRepository,
    required this.transactionRepository,
    required this.runInTransaction,
  });

  final RegretCheckinRepository checkinRepository;
  final TransactionRepository transactionRepository;

  /// Both repositories must use the database that runs this transaction.
  final RegretTransactionRunner runInTransaction;

  /// Delivers at most one new reflection per profile per local calendar day.
  /// An unanswered delivery remains available that day without re-prompting.
  /// Older deliveries are not automatically resurfaced in V1.
  Future<RegretPromptResult> getPrompt({
    required String profileId,
    required DateTime asOf,
  }) => runInTransaction(() async {
    final delivered = await checkinRepository.getCheckinsPromptedOnDate(
      profileId: profileId,
      date: asOf,
    );

    if (delivered.isNotEmpty) {
      final today = delivered.first;
      if (today.isDueAt(asOf) && !today.promptedAt!.isAfter(asOf)) {
        return RegretPromptResult.available(await _prompt(profileId, today));
      }
      return const RegretPromptResult.dailyLimitReached();
    }

    final due = await checkinRepository.getDueCheckins(
      profileId: profileId,
      asOf: asOf,
    );
    final candidates = due.where((checkin) => !checkin.isPrompted);
    if (candidates.isEmpty) {
      return const RegretPromptResult.noDueCheckins();
    }

    final checkin = candidates.first;
    // Validate ownership and the purchase before recording delivery.
    final prompt = await _prompt(profileId, checkin);
    await checkinRepository.markPrompted(
      checkinId: checkin.id,
      promptedAt: asOf,
    );
    final stored = await checkinRepository.getCheckinById(
      checkinId: checkin.id,
    );
    if (stored == null) {
      throw StateError('The selected regret check-in no longer exists.');
    }
    return RegretPromptResult.available(
      RegretPrompt(checkin: stored, transaction: prompt.transaction),
    );
  });

  Future<void> answerPrompt({
    required String profileId,
    required String checkinId,
    required RegretResponse response,
    required DateTime asOf,
  }) => runInTransaction(() async {
    final checkin = await checkinRepository.getCheckinById(
      checkinId: checkinId,
    );
    if (checkin == null) {
      throw StateError('The regret check-in no longer exists.');
    }
    await _prompt(profileId, checkin);
    await checkinRepository.answerCheckin(
      checkinId: checkinId,
      response: response,
      answeredAt: asOf,
    );
  });

  Future<RegretPrompt> _prompt(
    String profileId,
    AppRegretCheckin checkin,
  ) async {
    final transaction = await transactionRepository.getTransactionById(
      transactionId: checkin.transactionId,
    );
    if (transaction == null || transaction.profileId != profileId) {
      throw StateError(
        'The reflection purchase is missing or belongs to another profile.',
      );
    }
    return RegretPrompt(checkin: checkin, transaction: transaction);
  }
}
