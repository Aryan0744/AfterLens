import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_types.dart';

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<AppTransaction?> getTransactionById({
    required String transactionId,
  }) async {
    final row =
        await (_database.select(_database.transactions)
              ..where((transaction) => transaction.id.equals(transactionId)))
            .getSingleOrNull();

    return row == null ? null : _mapTransaction(row);
  }

  @override
  Future<List<AppTransaction>> getTransactions({
    required String profileId,
  }) async {
    final rows =
        await (_database.select(_database.transactions)
              ..where((transaction) => transaction.profileId.equals(profileId))
              ..orderBy([
                (transaction) => OrderingTerm.desc(transaction.transactionDate),
                (transaction) => OrderingTerm.desc(transaction.createdAt),
              ]))
            .get();

    return rows.map(_mapTransaction).toList();
  }

  @override
  Stream<List<AppTransaction>> watchTransactions({required String profileId}) {
    final query = _database.select(_database.transactions)
      ..where((transaction) => transaction.profileId.equals(profileId))
      ..orderBy([
        (transaction) => OrderingTerm.desc(transaction.transactionDate),
        (transaction) => OrderingTerm.desc(transaction.createdAt),
      ]);

    return query.watch().map((rows) => rows.map(_mapTransaction).toList());
  }

  @override
  Future<AppTransaction> createExpense({
    required String profileId,
    required String categoryId,
    required int amountCents,
    required MoodTag moodTag,
    required DateTime transactionDate,
    String? description,
  }) async {
    _validateAmount(amountCents);

    final normalizedDescription = _normalizeDescription(description);

    await _ensureProfileExists(profileId);

    await _ensureUsableCategory(profileId: profileId, categoryId: categoryId);

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            profileId: Value(profileId),
            categoryId: Value(categoryId),
            transactionType: const Value(TransactionType.expense),
            amountCents: amountCents,
            description: Value(normalizedDescription),
            moodTag: Value(moodTag),
            transactionDate: transactionDate,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppTransaction(
      id: id,
      profileId: profileId,
      categoryId: categoryId,
      type: TransactionType.expense,
      amountCents: amountCents,
      description: normalizedDescription,
      moodTag: moodTag,
      transactionDate: transactionDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<AppTransaction> createIncome({
    required String profileId,
    required int amountCents,
    required DateTime transactionDate,
    String? description,
  }) async {
    _validateAmount(amountCents);

    final normalizedDescription = _normalizeDescription(description);

    await _ensureProfileExists(profileId);

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            profileId: Value(profileId),
            transactionType: const Value(TransactionType.income),
            amountCents: amountCents,
            description: Value(normalizedDescription),
            transactionDate: transactionDate,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return AppTransaction(
      id: id,
      profileId: profileId,
      type: TransactionType.income,
      amountCents: amountCents,
      description: normalizedDescription,
      transactionDate: transactionDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteTransaction({
    required String profileId,
    required String transactionId,
  }) async {
    final affectedRows =
        await (_database.delete(_database.transactions)..where(
              (transaction) =>
                  transaction.id.equals(transactionId) &
                  transaction.profileId.equals(profileId),
            ))
            .go();

    if (affectedRows != 1) {
      throw StateError(
        'Transaction $transactionId was not found for '
        'profile $profileId.',
      );
    }
  }

  Future<void> _ensureProfileExists(String profileId) async {
    final profile = await (_database.select(
      _database.profiles,
    )..where((profile) => profile.id.equals(profileId))).getSingleOrNull();

    if (profile == null) {
      throw StateError('Profile $profileId does not exist.');
    }
  }

  Future<void> _ensureUsableCategory({
    required String profileId,
    required String categoryId,
  }) async {
    final category = await (_database.select(
      _database.categories,
    )..where((category) => category.id.equals(categoryId))).getSingleOrNull();

    if (category == null) {
      throw StateError('Category $categoryId does not exist.');
    }

    if (category.profileId != profileId) {
      throw StateError(
        'Category $categoryId does not belong to '
        'profile $profileId.',
      );
    }

    if (category.isArchived) {
      throw StateError(
        'Archived category $categoryId cannot be used '
        'for a new transaction.',
      );
    }
  }

  void _validateAmount(int amountCents) {
    if (amountCents <= 0) {
      throw ArgumentError.value(
        amountCents,
        'amountCents',
        'Amount must be greater than zero.',
      );
    }
  }

  String? _normalizeDescription(String? description) {
    if (description == null) {
      return null;
    }

    final value = description.trim();

    if (value.isEmpty) {
      return null;
    }

    if (value.length > 200) {
      throw ArgumentError.value(
        description,
        'description',
        'Description cannot exceed 200 characters.',
      );
    }

    return value;
  }

  AppTransaction _mapTransaction(Transaction row) {
    final profileId = row.profileId;

    if (profileId == null) {
      throw StateError(
        'Legacy transaction ${row.id} has no profile ownership.',
      );
    }

    return AppTransaction(
      id: row.id,
      profileId: profileId,
      categoryId: row.categoryId,
      type: row.transactionType,
      amountCents: row.amountCents,
      description: row.description,
      moodTag: row.moodTag,
      transactionDate: row.transactionDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
