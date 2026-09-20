import 'package:drift/drift.dart';

enum MoodTag { need, want, impulse, social, subscription, emergency }

class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get description => text().withLength(min: 1, max: 200)();
  IntColumn get moodTag => intEnum<MoodTag>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}