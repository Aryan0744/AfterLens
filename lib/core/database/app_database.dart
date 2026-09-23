import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/categories/data/categories_table.dart';
import '../../features/mood_engine/data/regret_checkins_table.dart';
import '../../features/profile/data/profiles_table.dart';
import '../../features/transactions/data/transactions_table.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Categories, Transactions, RegretCheckins])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    final upgrade = stepByStep(
      // ------------------------------------------------------------
      // V1 -> V2
      // Add Profiles
      // ------------------------------------------------------------
      from1To2: (m, schema) async {
        await m.createTable(schema.profiles);
      },

      // ------------------------------------------------------------
      // V2 -> V3
      // Add Categories
      // ------------------------------------------------------------
      from2To3: (m, schema) async {
        await m.createTable(schema.categories);
      },

      // ------------------------------------------------------------
      // V3 -> V4
      //
      // Categories:
      // + updated_at
      //
      // Transactions:
      // amount REAL -> amount_cents INTEGER
      // mood_tag INTEGER -> TEXT
      // + profile_id
      // + category_id
      // + transaction_type
      // + transaction_date
      // ------------------------------------------------------------
      from3To4: (m, schema) async {
        // Categories in V3 did not contain updated_at.
        // Because the new column has a database default,
        // existing rows can receive a valid timestamp automatically.
        await m.addColumn(schema.categories, schema.categories.updatedAt);

        await m.alterTable(
          TableMigration(
            schema.transactions,

            columnTransformer: {
              // $19.99 -> 1999
              schema.transactions.amountCents: const CustomExpression<int>(
                'CAST(ROUND("amount" * 100.0) AS INTEGER)',
              ),

              // Every transaction in V3 represented an expense.
              schema.transactions.transactionType: const Constant('expense'),

              // Convert the old integer enum into stable text values.
              schema.transactions.moodTag: const CustomExpression<String>('''
CASE "mood_tag"
  WHEN 0 THEN 'need'
  WHEN 1 THEN 'want'
  WHEN 2 THEN 'impulse'
  WHEN 3 THEN 'social'
  WHEN 4 THEN 'subscription'
  WHEN 5 THEN 'emergency'
  ELSE NULL
END
'''),

              // Before V4 there was no separate transaction date.
              // created_at is the best truthful historical value.
              schema.transactions.transactionDate: const CustomExpression<int>(
                '"created_at"',
              ),
            },

            // These genuinely new nullable columns don't need data
            // transformations for historical rows.
            newColumns: [
              schema.transactions.profileId,
              schema.transactions.categoryId,
            ],
          ),
        );
      },
    );

    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      onUpgrade: (Migrator m, int from, int to) async {
        // We wrap Drift's generated step-by-step upgrade so that
        // table reconstruction can occur safely around foreign keys.
        await customStatement('PRAGMA foreign_keys = OFF');

        try {
          await upgrade(m, from, to);

          final foreignKeyErrors = await customSelect(
            'PRAGMA foreign_key_check',
          ).get();

          if (foreignKeyErrors.isNotEmpty) {
            throw StateError(
              'Database migration produced foreign-key errors: '
              '$foreignKeyErrors',
            );
          }
        } finally {
          await customStatement('PRAGMA foreign_keys = ON');
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
