# Reflection history

One purchase has at most one check-in. Schema V6 enforces this with a unique
constraint on `regret_checkins.transaction_id`.

Before an answer, editing an expense reconciles its check-in with the eligibility
policy. Eligible purchases retain the check-in ID, receive a recalculated due
date, and clear `promptedAt`. Ineligible purchases lose their pending check-in,
even if it was already prompted. A later eligible edit can schedule a new one.

`RegretPromptService.answerPrompt` verifies the prompt and ownership inside a
database transaction. `DriftRegretCheckinRepository.answerCheckin` also uses a
transaction so direct repository callers get the same atomic behavior. It reads
the purchase and category, verifies ownership, then saves the response, answer
time, and all six snapshot fields in one guarded update. Repeated answers,
rescheduling, and removal through the check-in repository reject answered rows.

After an answer, ledger corrections preserve the entire check-in. Insights reads
amount, category ID/name, mood, description, and purchase date from the snapshot.
Its transaction join is only for profile ownership. Category renames and archival
do not change the captured name. The edit screen explains this behavior while
keeping every expense field editable.

The V5 to V6 migration backfills completed snapshots from the ledger data available
at migration time. It cannot recover earlier edits. Optional descriptions and
missing legacy categories/moods stay null; unknown moods are not assigned to a
mood group. Pending snapshots stay null. A database check constraint rejects
partial answer/snapshot states. The migration runs atomically, so inconsistent
legacy rows (such as duplicate check-ins) fail without silently deleting records.

Transaction deletion still cascades to its reflection. Preserving history after
deletion remains a separate milestone.

Relevant regression coverage:

- `test/features/mood_engine/reflection_snapshot_test.dart`
- `test/features/transactions/expense_edit_screen_test.dart`
- `test/drift/app_database/snapshot_migration_test.dart`
- `test/drift/app_database/migration_test.dart`

Regenerate schema artifacts with `dart run drift_dev make-migrations --no-test`
and `dart run build_runner build`, following the
[Drift migration workflow](https://drift.simonbinder.eu/migrations/).
