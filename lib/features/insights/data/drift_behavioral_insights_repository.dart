import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../transactions/domain/transaction_types.dart';
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
    final categories = _database.categories;

    final query = _database.select(checkins).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(checkins.transactionId),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
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

    final category = row.readTableOrNull(_database.categories);

    if (transaction.profileId != profileId) {
      throw StateError(
        'Transaction ${transaction.id} does not belong '
        'to profile $profileId.',
      );
    }

    if (transaction.transactionType != TransactionType.expense) {
      throw StateError(
        'Completed regret check-in ${checkin.id} '
        'references non-expense transaction '
        '${transaction.id}.',
      );
    }

    final moodTag = transaction.moodTag;

    if (moodTag == null) {
      throw StateError(
        'Completed regret check-in ${checkin.id} '
        'references transaction ${transaction.id} '
        'without a mood tag.',
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

    if (category != null && category.profileId != profileId) {
      throw StateError(
        'Category ${category.id} does not belong '
        'to profile $profileId.',
      );
    }

    return BehavioralReflection(
      transactionId: transaction.id,
      amountCents: transaction.amountCents,
      moodTag: moodTag,
      response: response,
      categoryId: category?.id,
      categoryName: category?.name,
      transactionDate: transaction.transactionDate,
      answeredAt: answeredAt,
    );
  }
}
