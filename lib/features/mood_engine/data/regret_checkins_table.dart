import 'package:drift/drift.dart';
import '../../transactions/data/transactions_table.dart';

class RegretCheckins extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  DateTimeColumn get promptedAt => dateTime()();
  DateTimeColumn get answeredAt => dateTime().nullable()();
  BoolColumn get wasWorthIt => boolean().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}