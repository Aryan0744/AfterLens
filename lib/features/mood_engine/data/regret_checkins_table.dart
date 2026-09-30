import 'package:drift/drift.dart';

import '../../transactions/data/transactions_table.dart';
import '../../transactions/domain/transaction_types.dart';
import '../domain/regret_response.dart';

class RegretCheckins extends Table {
  TextColumn get id => text()();

  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get dueAt => dateTime()();

  DateTimeColumn get promptedAt => dateTime().nullable()();

  DateTimeColumn get answeredAt => dateTime().nullable()();

  TextColumn get response => textEnum<RegretResponse>().nullable()();

  // Historical values, captured with the answer. These deliberately are not
  // foreign keys: category changes must not rewrite behavioral history.
  IntColumn get snapshotAmountCents => integer().nullable()();
  TextColumn get snapshotCategoryId => text().nullable()();
  TextColumn get snapshotCategoryName => text().nullable()();
  TextColumn get snapshotMoodTag => textEnum<MoodTag>().nullable()();
  TextColumn get snapshotDescription => text().nullable()();
  DateTimeColumn get snapshotTransactionDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {transactionId},
  ];

  @override
  List<String> get customConstraints => [
    // Description is optional; category and mood can be absent in legacy data.
    // Amount and date distinguish a finalized snapshot from a pending check-in.
    '''CHECK (
      (response IS NULL AND answered_at IS NULL
        AND snapshot_amount_cents IS NULL AND snapshot_category_id IS NULL
        AND snapshot_category_name IS NULL AND snapshot_mood_tag IS NULL
        AND snapshot_description IS NULL AND snapshot_transaction_date IS NULL)
      OR
      (response IS NOT NULL AND answered_at IS NOT NULL
        AND prompted_at IS NOT NULL AND snapshot_amount_cents IS NOT NULL
        AND snapshot_transaction_date IS NOT NULL)
    )''',
  ];
}
