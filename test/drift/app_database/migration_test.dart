// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:afterlens/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v3 to v4 preserves transaction data', () async {
    const transactionId = 'transaction-v3-test';
    const regretCheckinId = 'regret-v3-test';

    const createdAt = 1760000000;
    const updatedAt = 1760000100;
    const promptedAt = 1760000200;
    const answeredAt = 1760000300;

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,

      createItems: (batch, oldDb) {
        batch.customStatement(
          '''
        INSERT INTO transactions (
          id,
          amount,
          description,
          mood_tag,
          created_at,
          updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
          [transactionId, 19.99, 'Coffee', 2, createdAt, updatedAt],
        );

        batch.customStatement(
          '''
        INSERT INTO regret_checkins (
          id,
          transaction_id,
          prompted_at,
          answered_at,
          was_worth_it,
          updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
          [
            regretCheckinId,
            transactionId,
            promptedAt,
            answeredAt,
            1,
            updatedAt,
          ],
        );
      },

      validateItems: (newDb) async {
        final transactionRows = await newDb
            .customSelect(
              '''
        SELECT
          id,
          profile_id,
          category_id,
          transaction_type,
          amount_cents,
          description,
          mood_tag,
          transaction_date,
          created_at,
          updated_at
        FROM transactions
        WHERE id = ?
        ''',
              variables: [Variable.withString(transactionId)],
            )
            .get();

        expect(transactionRows, hasLength(1));

        final transaction = transactionRows.single;

        expect(transaction.read<String>('id'), transactionId);

        expect(transaction.readNullable<String>('profile_id'), isNull);

        expect(transaction.readNullable<String>('category_id'), isNull);

        expect(transaction.read<String>('transaction_type'), 'expense');

        expect(transaction.read<int>('amount_cents'), 1999);

        expect(transaction.readNullable<String>('description'), 'Coffee');

        expect(transaction.readNullable<String>('mood_tag'), 'impulse');

        expect(transaction.read<int>('transaction_date'), createdAt);

        expect(transaction.read<int>('created_at'), createdAt);

        expect(transaction.read<int>('updated_at'), updatedAt);

        final regretRows = await newDb
            .customSelect(
              '''
        SELECT
          id,
          transaction_id,
          prompted_at,
          answered_at,
          was_worth_it,
          updated_at
        FROM regret_checkins
        WHERE id = ?
        ''',
              variables: [Variable.withString(regretCheckinId)],
            )
            .get();

        expect(regretRows, hasLength(1));

        final regret = regretRows.single;

        expect(regret.read<String>('transaction_id'), transactionId);

        expect(regret.read<int>('prompted_at'), promptedAt);

        expect(regret.readNullable<int>('answered_at'), answeredAt);

        expect(regret.readNullable<int>('was_worth_it'), 1);

        final foreignKeyErrors = await newDb
            .customSelect('PRAGMA foreign_key_check')
            .get();

        expect(foreignKeyErrors, isEmpty);
      },
    );
  });
}
