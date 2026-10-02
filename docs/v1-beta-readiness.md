# V1 controlled beta readiness

Updated: 2026-10-01. This is a preparation checklist, not release approval.
Implementation and automated results: [delivery work log](v1-delivery-plan.md).

## Release gates

| Gate | Evidence required | Current status |
| --- | --- | --- |
| Domain integrity | Passing repository, service, widget and migration suites | See delivery log |
| Device flow | Temporary SQLite DB: onboard, record, reflect twice, restart, inspect history | Updated integration test; result in delivery log |
| Manual usability | Small screens, large text, light/dark, keyboard, error recovery | Open |
| Data ownership | JSON/CSV export includes ledger and saved reflections with clear deletion semantics | Open: not implemented |
| Complete erasure | Explicit erase action removes profile, categories, transactions, pending and completed reflections, snapshots and derived caches; verify after restart | Open: not implemented |
| Local storage/security | Review file protection, database access, OS backup behavior, logs and crash output with real build settings | Open: dedicated review required |
| Privacy explanation | Reviewed policy matches actual local storage, backups, erasure and export behavior | Open |
| Participant readiness | Consent, support contact, feedback protocol and build distribution chosen | Open |

The app currently has no authentication service, backend API, AI processing, bank
import, or cloud sync. Cloud authentication, transport security, secrets, API
authorization, row-level access controls, recovery and deletion propagation are
gates for a future cloud milestone. Do not claim these are implemented simply
because the local app works. No new telemetry or financial-data logging was added
in this phase.

An ordinary ledger delete preserves completed reflections. Complete erasure must
be a separate, explicit operation. Export should distinguish original saved
reflection details from later ledger corrections, use integer minor units plus
currency, include timestamps and schema version, and handle CSV escaping. Do not
reconstruct missing historical values or assign ownerless legacy data to an
arbitrary profile. Backup retention/deletion behavior needs a documented decision.

## Manual QA script

Use disposable data. Record device/OS, app version, result and screenshot for each
failure. The automated integration test uses its own temporary database.

1. Onboard with CAD. Read the reflection explanation and find it again in Settings.
2. Create a CAD 80.00 Impulse Shopping expense dated three days ago. Check purchase
   description, amount, mood, category and date in the reflection.
3. Add another eligible expense. Home should show two waiting, one at a time.
   Back out without answering; the oldest remains. Answer Worth it; the next appears
   immediately. Answer Unsure; the queue clears. Restart and inspect both answers.
4. Open Reflection History from Home and Insights. Check most recent answer first,
   both dates, currency and outcomes. Navigate from a mood/category pattern and
   verify only that group's evidence is displayed.
5. Edit an answered expense's amount, date, category and mood. Delete that expense.
   Check history and Insights still show the saved values and answer.
6. Archive Shopping. Its old transactions must still display Shopping. Edit one
   while keeping Shopping; it saves. A new expense cannot select Shopping. Replace
   the old category with an active category; the archived one cannot be reassigned.
7. Rename a category after answering a reflection. The ledger uses its current
   name; the saved answer retains its historical name. Archive/restore a system
   category, restart, and check bootstrap keeps its ID and management choices.
8. Try blank and duplicate category names. Try restoring an archive whose name is
   already active, then rename it and restore successfully. Archive all categories;
   Add Expense must provide a route to create or restore one.
9. Inspect empty Insights and History. With two Regret answers, no regret percentage
   appears. Three decisive answers show Early pattern; six show Pattern. With only
   Unsure answers, no decisive rate appears, and uncertainty can surface at three
   answers without being called regret.
10. Check CAD 15.00 versus 15.01, Want versus Need, and future-dated eligibility.
    Pending eligible edits reschedule; ineligible edits cancel; pending deletion
    removes the prompt. Income never creates a behavioral reflection.
11. Repeat key flows with large text, the smallest supported screen, long category
    names/descriptions and light/dark modes. Confirm keyboard and accessibility
    labels, especially amount, menus, answer buttons and dates.

## Learning from 5 → 10 → 20 participants

Start with five only after the release gates pass. Observe at least two weeks of
use before considering expansion. At each step, resolve integrity failures and
repeat the core loop. Do not expand merely because participants compliment the UI.
Recruitment, consent and distribution remain owner decisions; no invitations have
been sent.

Use consented interviews and a simple participant worksheet initially. Avoid
collecting descriptions, amounts or individual answers unless the participant
chooses to discuss them. Counts can be shared voluntarily. No remote analytics
SDK is required to test the core product hypothesis.

| Measure | Definition / question | Interpretation limit |
| --- | --- | --- |
| Purchase capture | Days with recorded purchases; ask about purchases omitted | Manual entry omits unknown spending; recorded count is not coverage |
| Reflection return | Did the participant return after the first eligible purchase became due? | No eligible purchases means no opportunity; report separately |
| Completion | Answered eligible scheduled reflections / eligible reflections that became due during the observation window | Keep deleted/cancelled opportunities separately in the study notes; current DB removes pending cancellations |
| Weekly retention | Participants who recorded or reflected in each subsequent study week | Small cohort: report counts, not impressive percentages |
| Time to first pattern | Days from first record to three decisive answers in one mood/category (track Unsure separately) | Threshold indicates sample size, not statistical reliability |
| Insight usefulness | Can they name one thing history/Insights taught them? | Quote with consent; do not count generic praise as learning |
| Behavior change | Did an insight change a later decision? Ask for a concrete example | Self-report, not a demonstrated causal effect |
| Regretted spending trend | Compare reflected regret amounts only with capture and response coverage context | Lower totals may mean less recording or reflecting, not improvement |

Ask: What confused you? What did you forget to enter? Did reflections feel
annoying? Did Insights surprise you? What decision changed? What did you ignore?
What did you expect but not find? Record actual return behavior alongside answers.

## Optional reasons gate

Keep one-tap Worth it / Regret / Unsure unchanged for now. Consider an optional,
skippable reason only if observed users want to explain an answer and the added
step does not reduce reflection completion. Prototype it before adding a schema.
Never make a reason required to save an answer.

## Stop rule

After the V1 release gates are satisfied, stop adding feature breadth and test the
loop. Repeated failure to return for reflections is a product problem to investigate,
not a reason to add AI, scoring, dashboards or gamification.
