import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/app_regret_checkin.dart';
import '../domain/regret_checkin_repository.dart';
import '../domain/regret_response.dart';

class DriftRegretCheckinRepository implements RegretCheckinRepository {
  DriftRegretCheckinRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<AppRegretCheckin?> getCheckinById({required String checkinId}) async {
    final row = await (_database.select(
      _database.regretCheckins,
    )..where((checkin) => checkin.id.equals(checkinId))).getSingleOrNull();

    return row == null ? null : _mapCheckin(row);
  }

  @override
  Future<AppRegretCheckin?> getCheckinForTransaction({
    required String transactionId,
  }) async {
    final row =
        await (_database.select(_database.regretCheckins)
              ..where((checkin) => checkin.transactionId.equals(transactionId)))
            .getSingleOrNull();

    return row == null ? null : _mapCheckin(row);
  }

  @override
  Future<List<AppRegretCheckin>> getDueCheckins({
    required String profileId,
    required DateTime asOf,
  }) async {
    final query =
        _database.select(_database.regretCheckins).join([
            innerJoin(
              _database.transactions,
              _database.transactions.id.equalsExp(
                _database.regretCheckins.transactionId,
              ),
            ),
          ])
          ..where(
            _database.transactions.profileId.equals(profileId) &
                _database.regretCheckins.dueAt.isSmallerOrEqualValue(asOf) &
                _database.regretCheckins.answeredAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(_database.regretCheckins.dueAt),
            OrderingTerm.asc(_database.regretCheckins.id),
          ]);

    final rows = await query.get();

    return rows
        .map((row) => _mapCheckin(row.readTable(_database.regretCheckins)))
        .toList();
  }

  @override
  Future<List<AppRegretCheckin>> getCheckinsPromptedOnDate({
    required String profileId,
    required DateTime date,
  }) async {
    final localDate = date.toLocal();
    final start = DateTime(localDate.year, localDate.month, localDate.day);
    // Calendar arithmetic also handles days shortened/lengthened by DST.
    final end = DateTime(localDate.year, localDate.month, localDate.day + 1);
    final query =
        _database.select(_database.regretCheckins).join([
            innerJoin(
              _database.transactions,
              _database.transactions.id.equalsExp(
                _database.regretCheckins.transactionId,
              ),
            ),
          ])
          ..where(
            _database.transactions.profileId.equals(profileId) &
                _database.regretCheckins.promptedAt.isBiggerOrEqualValue(
                  start,
                ) &
                _database.regretCheckins.promptedAt.isSmallerThanValue(end),
          )
          ..orderBy([
            OrderingTerm.asc(_database.regretCheckins.promptedAt),
            OrderingTerm.asc(_database.regretCheckins.id),
          ]);

    return (await query.get())
        .map((row) => _mapCheckin(row.readTable(_database.regretCheckins)))
        .toList();
  }

  @override
  Future<AppRegretCheckin> scheduleCheckin({
    required String transactionId,
    required DateTime dueAt,
  }) async {
    final transaction =
        await (_database.select(_database.transactions)
              ..where((transaction) => transaction.id.equals(transactionId)))
            .getSingleOrNull();

    if (transaction == null) {
      throw StateError('Transaction $transactionId does not exist.');
    }

    if (transaction.profileId == null) {
      throw StateError(
        'Legacy transaction $transactionId has no profile ownership.',
      );
    }

    if (transaction.transactionType != TransactionType.expense) {
      throw StateError('Regret check-ins can only be scheduled for expenses.');
    }

    if (!dueAt.isAfter(transaction.transactionDate)) {
      throw ArgumentError.value(
        dueAt,
        'dueAt',
        'Check-in due time must be after the transaction date.',
      );
    }

    final existing = await getCheckinForTransaction(
      transactionId: transactionId,
    );

    if (existing != null) {
      throw StateError(
        'Transaction $transactionId already has a regret check-in.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.regretCheckins)
        .insert(
          RegretCheckinsCompanion.insert(
            id: id,
            transactionId: transactionId,
            dueAt: dueAt,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppRegretCheckin(
      id: id,
      transactionId: transactionId,
      dueAt: dueAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> markPrompted({
    required String checkinId,
    required DateTime promptedAt,
  }) async {
    final checkin = await getCheckinById(checkinId: checkinId);

    if (checkin == null) {
      throw StateError('Regret check-in $checkinId does not exist.');
    }

    if (checkin.answeredAt != null || checkin.response != null) {
      throw StateError('An answered regret check-in cannot be prompted again.');
    }

    if (checkin.promptedAt != null) {
      throw StateError('Regret check-in $checkinId has already been prompted.');
    }

    if (promptedAt.isBefore(checkin.dueAt)) {
      throw ArgumentError.value(
        promptedAt,
        'promptedAt',
        'A regret check-in cannot be prompted before it is due.',
      );
    }

    final affectedRows =
        await (_database.update(_database.regretCheckins)..where(
              (row) =>
                  row.id.equals(checkinId) &
                  row.promptedAt.isNull() &
                  row.answeredAt.isNull() &
                  row.response.isNull(),
            ))
            .write(
              RegretCheckinsCompanion(
                promptedAt: Value(promptedAt),
                updatedAt: Value(DateTime.now()),
              ),
            );

    if (affectedRows != 1) {
      throw StateError('Regret check-in $checkinId could not be updated.');
    }
  }

  @override
  Future<void> answerCheckin({
    required String checkinId,
    required RegretResponse response,
    required DateTime answeredAt,
  }) async {
    final checkin = await getCheckinById(checkinId: checkinId);

    if (checkin == null) {
      throw StateError('Regret check-in $checkinId does not exist.');
    }

    if (checkin.answeredAt != null || checkin.response != null) {
      throw StateError('Regret check-in $checkinId has already been answered.');
    }

    final promptedAt = checkin.promptedAt;

    if (promptedAt == null) {
      throw StateError(
        'A regret check-in must be prompted before it can be answered.',
      );
    }

    if (answeredAt.isBefore(promptedAt)) {
      throw ArgumentError.value(
        answeredAt,
        'answeredAt',
        'Answer time cannot be before prompt time.',
      );
    }

    final affectedRows =
        await (_database.update(_database.regretCheckins)..where(
              (row) =>
                  row.id.equals(checkinId) &
                  row.answeredAt.isNull() &
                  row.response.isNull() &
                  row.promptedAt.isNotNull(),
            ))
            .write(
              RegretCheckinsCompanion(
                response: Value(response),
                answeredAt: Value(answeredAt),
                updatedAt: Value(DateTime.now()),
              ),
            );

    if (affectedRows != 1) {
      throw StateError('Regret check-in $checkinId could not be updated.');
    }
  }

  AppRegretCheckin _mapCheckin(RegretCheckin row) {
    return AppRegretCheckin(
      id: row.id,
      transactionId: row.transactionId,
      dueAt: row.dueAt,
      promptedAt: row.promptedAt,
      answeredAt: row.answeredAt,
      response: row.response,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
