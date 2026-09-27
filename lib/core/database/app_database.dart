import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/categories/data/categories_table.dart';
import '../../features/mood_engine/data/regret_checkins_table.dart';
import '../../features/profile/data/profiles_table.dart';
import '../../features/transactions/data/transactions_table.dart';
import '../../features/transactions/domain/transaction_types.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Categories, Transactions, RegretCheckins])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
        await m.addColumn(schema.categories, schema.categories.updatedAt);

        // Rebuild Transactions and preserve existing data.
        await m.alterTable(
          TableMigration(
            schema.transactions,
            columnTransformer: {
              // Example:
              // 19.99 -> 1999 cents
              schema.transactions.amountCents: const CustomExpression<int>(
                'CAST(ROUND("amount" * 100.0) AS INTEGER)',
              ),

              // All V3 transactions represented expenses.
              schema.transactions.transactionType: const Constant('expense'),

              // Convert the old integer MoodTag enum into
              // stable persisted text values.
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

              // V3 did not have a separate transaction date.
              // created_at is the closest truthful historical value.
              schema.transactions.transactionDate: const CustomExpression<int>(
                '"created_at"',
              ),
            },

            // These fields did not exist in V3.
            // They are nullable, so legacy rows receive NULL.
            newColumns: [
              schema.transactions.profileId,
              schema.transactions.categoryId,
            ],
          ),
        );
      },

      // ------------------------------------------------------------
      // V4 -> V5
      //
      // RegretCheckins redesign:
      //
      // + due_at
      // prompted_at becomes nullable
      // was_worth_it BOOLEAN -> response TEXT
      // + created_at
      //
      // Also updates the transaction foreign key behavior.
      // ------------------------------------------------------------
      from4To5: (m, schema) async {
        await m.alterTable(
          TableMigration(
            schema.regretCheckins,
            columnTransformer: {
              // In V4 a regret check-in only existed once the user
              // had been prompted.
              //
              // Therefore the historical prompted_at timestamp is
              // the best available value for due_at.
              schema.regretCheckins.dueAt: const CustomExpression<int>(
                '"prompted_at"',
              ),

              // Convert the old nullable boolean response:
              //
              // 1    -> worthIt
              // 0    -> regret
              // NULL -> NULL
              schema.regretCheckins.response: const CustomExpression<String>('''
CASE "was_worth_it"
  WHEN 1 THEN 'worthIt'
  WHEN 0 THEN 'regret'
  ELSE NULL
END
'''),

              // V4 did not store created_at.
              // prompted_at is the closest historical timestamp.
              schema.regretCheckins.createdAt: const CustomExpression<int>(
                '"prompted_at"',
              ),
            },
          ),
        );
      },
    );

    return MigrationStrategy(
      // ------------------------------------------------------------
      // Fresh database
      // ------------------------------------------------------------
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      // ------------------------------------------------------------
      // Existing database upgrade
      // ------------------------------------------------------------
      onUpgrade: (Migrator m, int from, int to) async {
        // TableMigration may rebuild tables.
        // Foreign-key enforcement is temporarily disabled while the
        // migration runs and validated afterwards.
        await customStatement('PRAGMA foreign_keys = OFF');

        try {
          await upgrade(m, from, to);

          // Make sure the migration did not leave any broken
          // foreign-key relationships.
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

      // ------------------------------------------------------------
      // Every database open
      // ------------------------------------------------------------
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
