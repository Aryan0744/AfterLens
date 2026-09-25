// dart format width=80
// ignore_for_file: unused_local_variable, unused_import

import 'package:afterlens/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // ---------------------------------------------------------------------------
  // STRUCTURAL MIGRATION TESTS
  // ---------------------------------------------------------------------------
  //
  // Drift automatically checks every supported migration path:
  //
  // V1 -> V2
  // V1 -> V3
  // V1 -> V4
  // V1 -> V5
  //
  // V2 -> V3
  // V2 -> V4
  // V2 -> V5
  //
  // V3 -> V4
  // V3 -> V5
  //
  // V4 -> V5
  //
  // These tests verify that the final database schema is correct.
  // ---------------------------------------------------------------------------

  group('simple database migrations', () {
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

  // ---------------------------------------------------------------------------
  // V3 -> V4 DATA INTEGRITY
  // ---------------------------------------------------------------------------
  //
  // V3 Transactions:
  //
  // amount REAL
  // mood_tag INTEGER
  //
  // V4 Transactions:
  //
  // amount_cents INTEGER
  // mood_tag TEXT
  // transaction_type TEXT
  // transaction_date INTEGER
  //
  // This test proves that the financial meaning of historical transactions
  // survives the migration.
  // ---------------------------------------------------------------------------

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
        // ---------------------------------------------------------------
        // Old V3 transaction
        //
        // amount = 19.99
        // moodTag = 2 -> impulse
        // ---------------------------------------------------------------

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

        // ---------------------------------------------------------------
        // Existing regret check-in referencing the transaction.
        //
        // This makes sure rebuilding Transactions doesn't destroy the
        // relationship.
        // ---------------------------------------------------------------

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
        // ---------------------------------------------------------------
        // Validate migrated Transaction
        // ---------------------------------------------------------------

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

        // V3 had no profile information.
        expect(transaction.readNullable<String>('profile_id'), isNull);

        // V3 had no category information.
        expect(transaction.readNullable<String>('category_id'), isNull);

        // All historical V3 transactions represented expenses.
        expect(transaction.read<String>('transaction_type'), 'expense');

        // 19.99 -> 1999 cents.
        expect(transaction.read<int>('amount_cents'), 1999);

        expect(transaction.readNullable<String>('description'), 'Coffee');

        // Old enum index:
        //
        // 2 -> impulse
        expect(transaction.readNullable<String>('mood_tag'), 'impulse');

        // V3 didn't have transaction_date.
        // created_at becomes the historical fallback.
        expect(transaction.read<int>('transaction_date'), createdAt);

        expect(transaction.read<int>('created_at'), createdAt);

        expect(transaction.read<int>('updated_at'), updatedAt);

        // ---------------------------------------------------------------
        // Validate existing RegretCheckin
        // ---------------------------------------------------------------

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

        // ---------------------------------------------------------------
        // Verify foreign-key integrity
        // ---------------------------------------------------------------

        final foreignKeyErrors = await newDb
            .customSelect('PRAGMA foreign_key_check')
            .get();

        expect(foreignKeyErrors, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // V4 -> V5 DATA INTEGRITY
  // ---------------------------------------------------------------------------
  //
  // V4 RegretCheckins:
  //
  // prompted_at REQUIRED
  // answered_at nullable
  // was_worth_it nullable BOOLEAN
  //
  // V5 RegretCheckins:
  //
  // due_at REQUIRED
  // prompted_at nullable
  // answered_at nullable
  // response nullable TEXT
  // created_at REQUIRED
  //
  // Mapping:
  //
  // was_worth_it = 1    -> worthIt
  // was_worth_it = 0    -> regret
  // was_worth_it = NULL -> NULL
  //
  // prompted_at -> due_at
  // prompted_at -> prompted_at
  // prompted_at -> created_at
  // ---------------------------------------------------------------------------

  test('migration from v4 to v5 preserves regret check-in data', () async {
    const worthItTransactionId = 'transaction-worth-it';
    const regretTransactionId = 'transaction-regret';
    const unansweredTransactionId = 'transaction-unanswered';

    const worthItCheckinId = 'checkin-worth-it';
    const regretCheckinId = 'checkin-regret';
    const unansweredCheckinId = 'checkin-unanswered';

    const transactionDate = 1760000000;

    const worthItPromptedAt = 1760001000;
    const regretPromptedAt = 1760002000;
    const unansweredPromptedAt = 1760003000;

    const worthItAnsweredAt = 1760001100;
    const regretAnsweredAt = 1760002100;

    const updatedAt = 1760004000;

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.new,

      createItems: (batch, oldDb) {
        // ---------------------------------------------------------------
        // Create three V4 transactions.
        //
        // RegretCheckins requires transaction_id to reference an existing
        // transaction.
        // ---------------------------------------------------------------

        batch.customStatement(
          '''
          INSERT INTO transactions (
            id,
            amount_cents,
            transaction_date
          )
          VALUES (?, ?, ?)
          ''',
          [worthItTransactionId, 1999, transactionDate],
        );

        batch.customStatement(
          '''
          INSERT INTO transactions (
            id,
            amount_cents,
            transaction_date
          )
          VALUES (?, ?, ?)
          ''',
          [regretTransactionId, 2500, transactionDate],
        );

        batch.customStatement(
          '''
          INSERT INTO transactions (
            id,
            amount_cents,
            transaction_date
          )
          VALUES (?, ?, ?)
          ''',
          [unansweredTransactionId, 5000, transactionDate],
        );

        // ---------------------------------------------------------------
        // Case 1:
        //
        // was_worth_it = 1
        // Expected V5 response = worthIt
        // ---------------------------------------------------------------

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
            worthItCheckinId,
            worthItTransactionId,
            worthItPromptedAt,
            worthItAnsweredAt,
            1,
            updatedAt,
          ],
        );

        // ---------------------------------------------------------------
        // Case 2:
        //
        // was_worth_it = 0
        // Expected V5 response = regret
        // ---------------------------------------------------------------

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
            regretTransactionId,
            regretPromptedAt,
            regretAnsweredAt,
            0,
            updatedAt,
          ],
        );

        // ---------------------------------------------------------------
        // Case 3:
        //
        // was_worth_it = NULL
        // answered_at = NULL
        //
        // Expected V5 response = NULL
        // ---------------------------------------------------------------

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
            unansweredCheckinId,
            unansweredTransactionId,
            unansweredPromptedAt,
            null,
            null,
            updatedAt,
          ],
        );
      },

      validateItems: (newDb) async {
        final rows = await newDb.customSelect('''
              SELECT
                id,
                transaction_id,
                due_at,
                prompted_at,
                answered_at,
                response,
                created_at,
                updated_at
              FROM regret_checkins
              ORDER BY id
              ''').get();

        expect(rows, hasLength(3));

        // ---------------------------------------------------------------
        // Case 1:
        // true -> worthIt
        // ---------------------------------------------------------------

        final worthIt = rows.firstWhere(
          (row) => row.read<String>('id') == worthItCheckinId,
        );

        expect(worthIt.read<String>('transaction_id'), worthItTransactionId);

        expect(worthIt.read<int>('due_at'), worthItPromptedAt);

        expect(worthIt.readNullable<int>('prompted_at'), worthItPromptedAt);

        expect(worthIt.readNullable<int>('answered_at'), worthItAnsweredAt);

        expect(worthIt.readNullable<String>('response'), 'worthIt');

        expect(worthIt.read<int>('created_at'), worthItPromptedAt);

        expect(worthIt.read<int>('updated_at'), updatedAt);

        // ---------------------------------------------------------------
        // Case 2:
        // false -> regret
        // ---------------------------------------------------------------

        final regret = rows.firstWhere(
          (row) => row.read<String>('id') == regretCheckinId,
        );

        expect(regret.read<String>('transaction_id'), regretTransactionId);

        expect(regret.read<int>('due_at'), regretPromptedAt);

        expect(regret.readNullable<int>('prompted_at'), regretPromptedAt);

        expect(regret.readNullable<int>('answered_at'), regretAnsweredAt);

        expect(regret.readNullable<String>('response'), 'regret');

        expect(regret.read<int>('created_at'), regretPromptedAt);

        expect(regret.read<int>('updated_at'), updatedAt);

        // ---------------------------------------------------------------
        // Case 3:
        // unanswered remains unanswered
        // ---------------------------------------------------------------

        final unanswered = rows.firstWhere(
          (row) => row.read<String>('id') == unansweredCheckinId,
        );

        expect(
          unanswered.read<String>('transaction_id'),
          unansweredTransactionId,
        );

        expect(unanswered.read<int>('due_at'), unansweredPromptedAt);

        expect(
          unanswered.readNullable<int>('prompted_at'),
          unansweredPromptedAt,
        );

        expect(unanswered.readNullable<int>('answered_at'), isNull);

        expect(unanswered.readNullable<String>('response'), isNull);

        expect(unanswered.read<int>('created_at'), unansweredPromptedAt);

        expect(unanswered.read<int>('updated_at'), updatedAt);

        // ---------------------------------------------------------------
        // Verify all transaction relationships survived the table rebuild.
        // ---------------------------------------------------------------

        final foreignKeyErrors = await newDb
            .customSelect('PRAGMA foreign_key_check')
            .get();

        expect(foreignKeyErrors, isEmpty);
      },
    );
  });
}
