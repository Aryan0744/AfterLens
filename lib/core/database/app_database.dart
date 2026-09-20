import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/transactions/data/transactions_table.dart';
import '../../features/mood_engine/data/regret_checkins_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Transactions, RegretCheckins])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'afterlens.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}