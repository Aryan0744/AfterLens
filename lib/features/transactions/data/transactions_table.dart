import 'package:drift/drift.dart';

import '../../categories/data/categories_table.dart';
import '../../profile/data/profiles_table.dart';
import '../domain/transaction_types.dart';

class Transactions extends Table {
  /// Unique identifier for the transaction.
  ///
  /// IDs will be generated as UUID strings by the application layer.
  TextColumn get id => text()();

  /// Profile that owns this transaction.
  ///
  /// Temporarily nullable so existing V3 transactions can be migrated
  /// safely. New V1 application logic will require a profile.
  TextColumn get profileId => text().nullable().references(
    Profiles,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Spending category associated with this transaction.
  ///
  /// Temporarily nullable for legacy V3 rows.
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Whether this record represents money coming in or going out.
  ///
  /// Stored as text ("expense" / "income") instead of an enum index.
  TextColumn get transactionType => textEnum<TransactionType>().withDefault(
    Constant(TransactionType.expense.name),
  )();

  /// Monetary amount stored in minor currency units.
  ///
  /// Examples:
  /// CAD 19.99 -> 1999
  /// CAD 125.00 -> 12500
  IntColumn get amountCents => integer()();

  /// Optional user-facing transaction description.
  TextColumn get description =>
      text().withLength(min: 1, max: 200).nullable()();

  /// Behavioural spending tag.
  ///
  /// Stored using the enum name rather than enum index.
  TextColumn get moodTag => textEnum<MoodTag>().nullable()();

  /// When the financial event actually occurred.
  DateTimeColumn get transactionDate => dateTime()();

  /// When this record was created inside AfterLens.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this record was last modified.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
