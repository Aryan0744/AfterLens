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

  final RegretTransactionRunner runInTransaction;

  /// Returns the oldest due unanswered reflection.
  ///
  /// An unanswered reflection remains available until answered.
  /// Once answered, the next due reflection can become available
  /// immediately, including on the same calendar day.
  Future<RegretPromptResult> getPrompt({
    required String profileId,
    required DateTime asOf,
  }) => runInTransaction(() async {
    final due = await checkinRepository.getDueCheckins(
      profileId: profileId,
      asOf: asOf,
    );

    if (due.isEmpty) {
      return const RegretPromptResult.noDueCheckins();
    }

    final checkin = due.first;

    final prompt = await _prompt(profileId, checkin);

    // An already-prompted unanswered reflection stays available.
    if (checkin.isPrompted) {
      return RegretPromptResult.available(prompt, dueCount: due.length);
    }

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
      dueCount: due.length,
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

    if (!checkin.isPrompted || checkin.isAnswered) {
      throw StateError(
        'Only a prompted, unanswered reflection can be answered.',
      );
    }

    await _prompt(profileId, checkin);

    await checkinRepository.answerCheckin(
      profileId: profileId,
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
        'The reflection purchase is missing or '
        'belongs to another profile.',
      );
    }

    return RegretPrompt(checkin: checkin, transaction: transaction);
  }
}
