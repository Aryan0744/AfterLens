import 'package:afterlens/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;

void main() {
  test('v6 to v7 preserves archived categories, income, pending rows and saved snapshots', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final verifier = SchemaVerifier(GeneratedHelper());
    await verifier.testWithDataIntegrity(
      oldVersion: 6,
      newVersion: 7,
      createOld: v6.DatabaseAtV6.new,
      createNew: v7.DatabaseAtV7.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        batch.customStatement(
          "INSERT INTO profiles (id, currency_code) VALUES ('p', 'CAD')",
        );
        batch.customStatement(
          "INSERT INTO categories (id, profile_id, name, is_archived) VALUES ('c', 'p', 'Renamed', 1)",
        );
        for (final id in ['answered', 'pending', 'income']) {
          batch.customStatement(
            '''INSERT INTO transactions (id, profile_id, category_id,
            transaction_type, amount_cents, mood_tag, transaction_date)
            VALUES (?, 'p', ?, ?, 9900, ?, 1760000000)''',
            [
              id,
              id == 'income' ? null : 'c',
              id == 'income' ? 'income' : 'expense',
              id == 'income' ? null : 'want',
            ],
          );
        }
        batch.customStatement('''INSERT INTO regret_checkins (id, transaction_id, due_at, prompted_at,
          answered_at, response, snapshot_amount_cents, snapshot_category_id, snapshot_category_name,
          snapshot_mood_tag, snapshot_description, snapshot_transaction_date)
          VALUES ('answer', 'answered', 1760200000, 1760200000, 1760200100, 'unsure',
            8000, 'c', 'Original name', 'impulse', NULL, 1759900000)''');
        batch.customStatement(
          "INSERT INTO regret_checkins (id, transaction_id, due_at) VALUES ('waiting', 'pending', 1760200000)",
        );
      },
      validateItems: (db) async {
        final rows = await db.customSelect('SELECT * FROM transactions').get();
        expect(rows, hasLength(3));
        expect(rows.every((row) => row.data['deleted_at'] == null), isTrue);
        final income = rows.singleWhere((row) => row.data['id'] == 'income');
        expect(income.data['transaction_type'], 'income');
        expect(income.data['category_id'], isNull);
        expect(income.data['mood_tag'], isNull);
        expect(
          (await db.customSelect('SELECT * FROM categories').getSingle())
              .data['is_archived'],
          1,
        );
        final before = await db
            .customSelect("SELECT * FROM regret_checkins WHERE id = 'answer'")
            .getSingle();
        expect(before.data['snapshot_amount_cents'], 8000);
        expect(before.data['snapshot_category_name'], 'Original name');
        expect(before.data['snapshot_mood_tag'], 'impulse');
        expect(before.data['snapshot_description'], isNull);
        expect(before.data['snapshot_transaction_date'], 1759900000);
        expect(before.data['response'], 'unsure');
        final pending = await db
            .customSelect("SELECT * FROM regret_checkins WHERE id = 'waiting'")
            .getSingle();
        expect(pending.data['answered_at'], isNull);
        expect(pending.data['snapshot_amount_cents'], isNull);
        await db.customStatement(
          "UPDATE transactions SET deleted_at = 1760300000 WHERE id = 'answered'",
        );
        final after = await db
            .customSelect("SELECT * FROM regret_checkins WHERE id = 'answer'")
            .getSingle();
        expect(after.data, before.data);
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      },
    );
  });
}
