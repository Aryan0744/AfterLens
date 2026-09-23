import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/transactions/data/transactions_table.dart';
import '../../features/mood_engine/data/regret_checkins_table.dart';
import '../../features/profile/data/profiles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Transactions, RegretCheckins])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(profiles);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'afterlens.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}