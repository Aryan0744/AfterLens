import 'package:drift/drift.dart';

import '../../transactions/data/transactions_table.dart';
import '../domain/regret_response.dart';

class RegretCheckins extends Table {
  TextColumn get id => text()();

  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get dueAt => dateTime()();

  DateTimeColumn get promptedAt => dateTime().nullable()();

  DateTimeColumn get answeredAt => dateTime().nullable()();

  TextColumn get response => textEnum<RegretResponse>().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
