# Regret check-in V1

Eligible Want/Impulse expenses above 1,500 cents continue to receive a check-in
at the transaction date plus two days. Scheduling does not depend on the daily
prompt allowance.

## Delivery policy

- A profile receives at most one new automatic reflection per local calendar day.
- Selection checks persisted `promptedAt` values, including answered check-ins,
  then selects the oldest due, unanswered, never-prompted check-in. IDs break ties.
- The allowance check, purchase lookup and `markPrompted` write share a database
  transaction. Both repositories use that same database.
- Today's unanswered delivery remains visible across refreshes and restarts.
  Answering it does not unlock another delivery that day.
- `promptedAt` remains write-once. Ignored deliveries from earlier days remain
  unanswered in storage and are not automatically resurfaced in V1. A later day
  may deliver the next never-prompted purchase.
- Calendar bounds use local midnight and the next local midnight, including DST
  days; they are not a rolling 24-hour window.

The controller refreshes after purchase changes, on app resume, on pull-to-refresh,
after leaving the reflection screen, and once per minute while Home is active.
Loading and reflection errors do not block expense entry.

## Answers and storage

The reflection screen records exactly `worthIt`, `regret`, or `unsure`. It checks
purchase ownership before saving and updates `response`, `answeredAt`, and
`updatedAt`. Missing, unprompted or already-answered check-ins are rejected, as
are answers dated before their prompt. Conditional updates protect against
overlapping writes. Back navigation leaves the check-in unanswered; a save failure
keeps the screen open for retry. Buttons and back navigation are disabled during
the save.

Schema version remains **5**. No migration, scoring, notifications or cloud sync
is introduced.

## Validation

```sh
flutter analyze
flutter test
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/regret_checkin_flow_test.dart \
  -d <simulator-id>
```

The service and widget tests cover eligibility boundaries, profile isolation,
due ordering, daily limits, local midnight/DST boundaries, concurrent selection,
transaction rollback, database reopen, all three answers, save failures,
double taps, backing out, Home refresh, foreground due times and app resume.

The device test uses a temporary SQLite file, completes onboarding, enters two
CAD 25.00 Impulse expenses dated three days earlier, opens and backs out of the
first reflection, saves Worth it, and reopens the database to verify that the
second scheduled check-in is still unprompted. The normal app database is not
modified. Screenshots are saved under `build/qa/` by the integration driver.

For manual QA, perform the same flow through Add Expense with category Shopping
and description Headphones. Expect the reflection card after saving the first
past-dated purchase, and no card after answering it, even with another eligible
purchase waiting. Next-day behavior is tested with an injected clock.
