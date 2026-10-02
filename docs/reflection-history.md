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

V7 adds `transactions.deleted_at`. Ordinary deletion hides the transaction from
the ledger and cancels an unanswered check-in. Completed snapshots remain and
continue to contribute to history and Insights. Their transaction join exists
only to enforce profile ownership, including soft-deleted ledger rows.

## History screen and categories

Reflection History is available through Home and Insights. Answers are ordered
newest first, with transaction ID as a deterministic tie-breaker. It shows both
answer and purchase dates, description, amount/currency, mood, saved category name
and outcome. Null legacy descriptions fall back to Purchase; missing category or
mood is explicitly described as not recorded. It does not guess missing values.

Each mood/category Insights card opens the matching history, using the saved mood
or stable category ID, including the uncategorized group. Rename does not split a
category group; the group heading uses its earliest available saved name in the
repository's chronological order. Individual history entries show their own saved
names. There is no re-answer or ledger-edit action on saved history.

The ledger displays current category names even when archived. An edit can keep
its current archived category; replacements and newly created expenses must use
active categories from the same profile. Renaming or archiving categories never
rewrites a reflection snapshot. Category management uses archive/restore, not
hard deletion, and preserves system keys.

Complete profile erasure is a separate, still-open beta gate. Soft deletion must
not be described as permanent data erasure.

Relevant regression coverage:

- `test/features/mood_engine/reflection_snapshot_test.dart`
- `test/features/transactions/expense_edit_screen_test.dart`
- `test/drift/app_database/snapshot_migration_test.dart`
- `test/drift/app_database/migration_test.dart`
- `test/drift/app_database/soft_delete_migration_test.dart`
- `test/features/categories/historical_category_test.dart`
- `test/features/categories/category_management_test.dart`
- `test/features/insights/reflection_history_screen_test.dart`

The generated schemas now include V7. Structural checks cover all 21 upgrade
pairs from V1–V7. Data migration tests separately verify legacy conversion,
snapshot backfill and V7 preservation of saved answers, pending rows, income and
archived categories. See [delivery log](v1-delivery-plan.md) for results.

Regenerate schema artifacts with `dart run drift_dev make-migrations --no-test`
and `dart run build_runner build`, following the
[Drift migration workflow](https://drift.simonbinder.eu/migrations/).
