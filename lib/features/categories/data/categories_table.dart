import 'package:drift/drift.dart';

import '../../profile/data/profiles_table.dart';

class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get profileId => text().references(
    Profiles,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text().withLength(
    min:1,
    max: 50,
  )();

  TextColumn get systemKey => text().nullable()();

  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
