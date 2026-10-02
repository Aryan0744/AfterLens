# Reflection check-in V1

Want/Impulse expenses strictly above 1,500 cents receive a check-in at purchase
date plus two days. Amounts use the profile currency; the threshold is not currency
converted. Need, Social, Subscription, Emergency and income do not schedule one.

## Delivery and answers

Home shows the oldest due, unanswered reflection for the current profile and the
number of due purchases. Due time orders the queue; check-in ID breaks ties.
Unanswered reflections persist across back navigation, refreshes and restarts.
Answering advances immediately to the next due purchase, including on the same
day. There is no daily cap.

The controller refreshes after transaction changes, on resume, pull-to-refresh,
after returning from a reflection, and every minute while Home is active. A load
failure exposes retry while expense entry remains usable.

The reflection displays description, amount, mood, category (including archives)
and purchase date. One tap saves Worth it, I regret it, or Unsure. Buttons/back
navigation are disabled while saving; failure keeps the screen open for retry.
Reasons are deferred until user testing justifies an optional extra step.

Selection and answer writes run in database transactions. Ownership, due/prompt
state and one-answer-only guards are enforced by the service/repository. An answer
atomically stores its response, answer time and immutable purchase snapshot.
See [history semantics](reflection-history.md).

## Persistence and edits

Current schema: **V7**. V5 introduced the queue/response model, V6 immutable
snapshots and unique check-ins, V7 soft-deleted ledger rows.

Eligible edits before an answer reschedule the same check-in and clear its prompt.
Ineligible edits remove it; a later eligible edit can schedule another. Completed
answers and snapshots survive edits and soft deletion. Deleting a pending purchase
through the management service cancels the pending reflection.

## Validation

```sh
flutter analyze
flutter test
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/regret_checkin_flow_test.dart \
  -d <simulator-id>
```

The device test uses temporary SQLite storage. It onboards, enters two past-dated
CAD 25.00 Impulse purchases, backs out of a reflection, answers Worth it, restarts,
checks the remaining prompt and saved history, then answers Unsure. The normal
app database is not modified. The driver saves screenshots under `build/qa/`.

Current results and remaining beta gates are recorded in the
[delivery log](v1-delivery-plan.md) and [beta checklist](v1-beta-readiness.md).
