import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/behavioral_insights_repository.dart';
import '../domain/behavioral_reflection.dart';

class DriftBehavioralInsightsRepository
    implements BehavioralInsightsRepository {
  DriftBehavioralInsightsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<BehavioralReflection>> getCompletedReflections({
    required String profileId,
  }) async {
    final rows = await _buildCompletedReflectionQuery(profileId).get();

    return rows
        .map((row) => _mapReflection(row, profileId: profileId))
        .toList();
  }

  @override
  Stream<List<BehavioralReflection>> watchCompletedReflections({
    required String profileId,
  }) {
    return _buildCompletedReflectionQuery(profileId).watch().map((rows) {
      return rows
          .map((row) => _mapReflection(row, profileId: profileId))
          .toList();
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCompletedReflectionQuery(
    String profileId,
  ) {
    final checkins = _database.regretCheckins;
    final transactions = _database.transactions;

    final query = _database.select(checkins).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(checkins.transactionId),
      ),
    ]);

    query.where(
      transactions.profileId.equals(profileId) &
          checkins.answeredAt.isNotNull() &
          checkins.response.isNotNull(),
    );

    query.orderBy([
      OrderingTerm.asc(checkins.answeredAt),
      OrderingTerm.asc(checkins.id),
    ]);

    return query;
  }

  BehavioralReflection _mapReflection(
    TypedResult row, {
    required String profileId,
  }) {
    final checkin = row.readTable(_database.regretCheckins);

    final transaction = row.readTable(_database.transactions);

    if (transaction.profileId != profileId) {
      throw StateError(
        'Transaction ${transaction.id} does not belong '
        'to profile $profileId.',
      );
    }

    final amountCents = checkin.snapshotAmountCents;
    final transactionDate = checkin.snapshotTransactionDate;
    if (amountCents == null || transactionDate == null) {
      throw StateError(
        'Completed regret check-in ${checkin.id} has no snapshot.',
      );
    }

    final answeredAt = checkin.answeredAt;

    if (answeredAt == null) {
      throw StateError(
        'Completed regret check-in ${checkin.id} '
        'has no answeredAt value.',
      );
    }

    final response = checkin.response;

    if (response == null) {
      throw StateError(
        'Completed regret check-in ${checkin.id} '
        'has no response.',
      );
    }

    // The ledger join is only for profile ownership. All behavioral values
    // come from the immutable reflection, including historical category names.
    return BehavioralReflection(
      transactionId: checkin.transactionId,
      amountCents: amountCents,
      moodTag: checkin.snapshotMoodTag,
      response: response,
      categoryId: checkin.snapshotCategoryId,
      categoryName: checkin.snapshotCategoryName,
      description: checkin.snapshotDescription,
      transactionDate: transactionDate,
      answeredAt: answeredAt,
    );
  }
}
