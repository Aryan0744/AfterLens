import 'package:afterlens/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v5 to v6 backfills all answers and leaves pending snapshots empty', () async {
    const purchaseDate = 1760000000;
    const dueAt = 1760200000;
    const promptedAt = 1760200100;
    const answeredAt = 1760200200;
    const responses = ['worthIt', 'regret', 'unsure', null, null];
    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.customStatement(
          "INSERT INTO profiles (id, currency_code) VALUES ('profile', 'CAD')",
        );
        batch.customStatement(
          "INSERT INTO categories (id, profile_id, name) VALUES ('category', 'profile', 'Shopping')",
        );
        for (var i = 0; i < responses.length; i++) {
          batch.customStatement(
            '''
            INSERT INTO transactions (id, profile_id, category_id, amount_cents,
              description, mood_tag, transaction_date)
            VALUES (?, 'profile', 'category', 8000, ?, 'impulse', ?)
          ''',
            ['purchase-$i', i == 1 ? null : 'Headphones', purchaseDate],
          );
          batch.customStatement(
            '''
            INSERT INTO regret_checkins (id, transaction_id, due_at, prompted_at,
              answered_at, response, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
            [
              'checkin-$i',
              'purchase-$i',
              dueAt,
              i == 4 ? null : promptedAt,
              responses[i] == null ? null : answeredAt,
              responses[i],
              purchaseDate,
              promptedAt,
            ],
          );
        }
      },
      validateItems: (db) async {
        final rows = await db
            .customSelect('SELECT * FROM regret_checkins ORDER BY id')
            .get();
        expect(rows, hasLength(responses.length));
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          expect(row.read<String>('id'), 'checkin-$i');
          expect(row.read<String>('transaction_id'), 'purchase-$i');
          expect(row.read<int>('due_at'), dueAt);
          expect(
            row.readNullable<int>('prompted_at'),
            i == 4 ? null : promptedAt,
          );
          expect(
            row.readNullable<int>('answered_at'),
            responses[i] == null ? null : answeredAt,
          );
          expect(row.readNullable<String>('response'), responses[i]);
          expect(row.read<int>('created_at'), purchaseDate);
          expect(row.read<int>('updated_at'), promptedAt);
          if (responses[i] != null) {
            expect(row.read<int>('snapshot_amount_cents'), 8000);
            expect(row.read<String>('snapshot_category_id'), 'category');
            expect(row.read<String>('snapshot_category_name'), 'Shopping');
            expect(row.read<String>('snapshot_mood_tag'), 'impulse');
            expect(
              row.readNullable<String>('snapshot_description'),
              i == 1 ? null : 'Headphones',
            );
            expect(row.read<int>('snapshot_transaction_date'), purchaseDate);
          } else {
            for (final field in [
              'amount_cents',
              'category_id',
              'category_name',
              'mood_tag',
              'description',
              'transaction_date',
            ]) {
              expect(row.data['snapshot_$field'], isNull);
            }
          }
        }

        await db.customStatement(
          "UPDATE transactions SET amount_cents = 9000, mood_tag = 'need'",
        );
        await db.customStatement("UPDATE categories SET name = 'Essentials'");
        final snapshots = await db
            .customSelect('SELECT * FROM regret_checkins ORDER BY id')
            .get();
        expect(snapshots.map((row) => row.data), rows.map((row) => row.data));
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );

        // The migrated table enforces the same invariants as a fresh database.
        await expectLater(
          db.customStatement(
            '''
          INSERT INTO regret_checkins (id, transaction_id, due_at)
          VALUES ('duplicate', 'purchase-0', ?)
        ''',
            [dueAt],
          ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement(
            '''
          UPDATE regret_checkins SET response = 'regret', answered_at = ?
          WHERE id = 'checkin-3'
        ''',
            [answeredAt],
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  test(
    'v3 to v6 preserves legacy answers without inventing missing values',
    () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 3,
        newVersion: 6,
        createOld: v3.DatabaseAtV3.new,
        createNew: v6.DatabaseAtV6.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.customStatement('''
          INSERT INTO transactions (id, amount, description, mood_tag, created_at, updated_at)
          VALUES ('legacy', 19.99, 'Coffee', 99, 1760000000, 1760000010)
        ''');
          batch.customStatement('''
          INSERT INTO regret_checkins (id, transaction_id, prompted_at, answered_at, was_worth_it, updated_at)
          VALUES ('checkin', 'legacy', 1760200000, 1760200100, 1, 1760200100)
        ''');
        },
        validateItems: (db) async {
          final row = await db
              .customSelect('SELECT * FROM regret_checkins')
              .getSingle();
          expect(row.read<String>('response'), 'worthIt');
          expect(row.read<int>('snapshot_amount_cents'), 1999);
          expect(row.read<int>('snapshot_transaction_date'), 1760000000);
          expect(row.read<String>('snapshot_description'), 'Coffee');
          for (final field in ['category_id', 'category_name', 'mood_tag']) {
            expect(row.data['snapshot_$field'], isNull);
          }
          expect(
            await db.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        },
      );
    },
  );
}
