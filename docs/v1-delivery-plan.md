# AfterLens V1 delivery plan and work log

Started: 2026-10-01. Source: the [supplied product direction](product-direction.md).

## Product purpose

AfterLens helps people understand which purchases they later value, regret, or
question, then uses their reflection history to inform future decisions.
The V1 loop is record a purchase → wait → reflect → inspect history → learn.

## Assessment of the plan

The direction fits the existing Flutter/Riverpod/Drift architecture. The repository
already has local profiles, eleven default categories, six moods, scheduling,
one-at-a-time due reflections, immutable answer snapshots, soft deletion, and
snapshot-backed analytics. The main gaps are historical category handling,
visibility of completed reflections, responsible presentation of small samples,
category management UI, and explanation of the behavioral loop.

Findings at the start of implementation (addressed below):

- Details and edit screens read active categories only. The repository also
  rejects an unchanged archived category during an expense edit.
- Insights shows regret percentages even below its minimum sample threshold.
- Completed reflection data is available but has no history screen.
- The current database is V7, but generated migration fixtures end at V6.
- README and reflection docs describe older product behavior. The deletion
  confirmation incorrectly claims completed reflections are permanently deleted.

The plan also has two important interpretation limits. Current eligibility samples
only Want/Impulse purchases above the threshold; examples comparing Social or
Subscription moods cannot emerge from the ordinary V1 flow yet. A Subscriptions
category can still collect Want/Impulse reflections. These examples describe a
future broader sample, not claims V1 should make. Manual capture and optional
reflection also mean reviewed purchases are not representative of all spending.

The 3/6 thresholds are useful restraint, not statistical validation. The UI now
states that explicitly and shows counts. No highest-regret ranking, prediction,
score or recommendation is inferred from these thresholds.

## Non-negotiable rules

- Normal ledger edits/deletion must preserve completed reflection snapshots.
- New and replacement categories must be active and belong to the same profile.
  The existing archived category may remain on an edited historical transaction.
- History and analytics use saved reflection values, never mutable ledger fields.
- Worth it and Regret form the decisive denominator; Unsure has its own denominator
  of all reviewed purchases. Counts and denominators remain visible.
- 0–2 decisive answers: not enough data; 3–5: early pattern; 6+: pattern.
  These are product presentation thresholds, not scientific confidence measures.
- Keep Want/Impulse, strictly above 1,500 cents, with a two-day delay for V1.
- Keep the existing six moods. They mix intent (Need/Want/Impulse) with context
  (Social/Subscription/Emergency); splitting these is a future model decision.
- Ordinary soft deletion is distinct from eventual complete profile erasure.

## Task tracker

| Order | Task | Acceptance criteria | Status |
| --- | --- | --- | --- |
| 1 | Historical category integrity | Archived names display; unchanged archived category saves; archived replacements/new usage rejected; ownership enforced | Complete; 40 targeted tests passed |
| 2 | Reflection History | Newest completed answers first; purchase context and answer date from snapshots; accessible from Home/Insights; empty/error states | Complete |
| 3 | Insights and sample rules | Counts first; reflected spending; 0–2 / 3–5 / 6+ tiers; no dramatic small-sample rates; history drill-through | Complete |
| 4 | Unsure patterns | Separate outcome rates; sufficient-sample uncertainty wording; never treat Unsure as Regret | Complete |
| 5 | Behavioral Home | Reflection remains prominent; recent activity; learning progress/evidence; routes to history and Insights | Complete |
| 6 | Category management | Create, rename, archive, restore; system/custom labels; duplicate-name and ownership rules; no hard deletion | Complete |
| 7 | Integrity and migrations | Regression coverage for edits/deletes/answers/pending/income/profile/null fields; current migration fixtures | Complete; unit/widget/migration and device checks passed |
| 8 | Onboarding and explanation | Explain record/wait/reflect, moods, exact eligibility, local storage and historical preservation; revisit in settings | Complete |
| 9 | Optional reasons | Add only if observed user testing supports the extra interaction | Deferred: evidence gate |
| 10 | Prepare controlled beta | Readiness checklist, manual QA, security/privacy/export/erasure gates, metrics and 5→10→20 feedback protocol | Preparation complete; release gates remain open |

## Boundaries and dependencies

No AI coach, bank connection, budgeting engine, regret score, predictive model,
cloud sync, social feature, gamification, or advanced notifications in this phase.
Personalized thresholds, trends, follow-ups, optional reasons, interventions,
budgeting and AI interpretation depend on evidence from real use. Import and sync
follow a stable domain model and a separate privacy/security milestone.

Preparing beta is not releasing beta. Device QA, export and complete erasure,
privacy/security decisions, and actual participant feedback must be recorded
before inviting real users. No participant outreach or deployment is part of
this implementation.

## Mapping the wider vision to milestones

| Original plan items | Decision and prerequisite |
| --- | --- |
| 1–3: integrity, Insights, Unsure | Implemented in this V1 pass |
| 4–7: reflection UX, history, Home, categories | Implemented; optional reasons retain their testing gate |
| 8: mood model | Six moods kept; mixed intent/context limitation documented |
| 9: adaptive rules | After sufficient personal history and observed scheduling friction; preserve interpretable eligibility |
| 10: regret score | Explicitly deferred; no unexplained scalar score |
| 11–13: personal models, coaching, interventions | First validate evidence-based patterns and capture/response coverage; explanations must trace to history |
| 14: behavior-aware budgeting | Future income/essential-expense/goals model plus reliable personal outcomes; no generic budget engine now |
| 15: import | Future capture milestone; automate financial fields while keeping user-supplied intent/context |
| 16: sync/authentication | After local model stability and a data ownership/security design; retain snapshot and deletion semantics |
| 17–18: security, export, complete deletion | Explicit pre-beta release gates in the readiness document; not implemented by this pass |
| 19–20: measurement and controlled beta | Protocol and definitions documented; actual recruitment and learning remain future work |

## Remaining technical limits

- Currency belongs to the local profile and cannot be changed in Settings. Current
  amounts and thresholds assume two decimal places; multi-currency and currency
  precision support need a separate design before changing that contract.
- Legacy rows with no profile ownership are preserved but not exposed to an
  arbitrary profile. Any recovery/import assignment must be explicit.
- History uses a lazily built list; analytics still aggregate all completed local
  reflections. Revisit query performance with measured data volume, not a speculative
  new backend. Category groups retain stable IDs and saved names.
- Reflection reasons, trends, follow-up answers, notification automation and
  prediction are intentionally absent. There is still one immutable answer per
  purchase.
- Income persistence is supported by the repository; this pass does not introduce
  a new income-entry UI or budgeting workflow.

## Validation and work log

- Initial worktree was clean.
- Inspected product brief, repository contracts, snapshot analytics, category
  persistence, presentation, scheduling and migration structure.
- Baseline: all 207 existing tests passed. Flutter commands need access to their
  SDK cache outside the workspace; the test command was approved and ran.
- Task 1: added a profile-scoped stream including archived categories. Details use
  it; editing offers active categories plus the transaction's existing archive.
  Repository validation permits only that unchanged archive. Corrected the
  transaction deletion confirmation to describe soft deletion and saved history.
  Validation: 40 category-integrity and transaction tests passed, including an
  actual edit/save through the widget with every category archived.
- Tasks 2–4 implementation: history reads immutable snapshots, newest answers first;
  Home/Insights routes and mood/category drill-through expose the evidence.
  Insights leads with counts, suppresses decisive percentages below three
  decisive answers and distinguishes 3–5 from 6+. Worth-it/regret rates use decisive
  answers; Unsure uses all reviewed answers. A majority and at least three Unsure
  answers are required for the uncertainty observation; its stage uses total
  reviewed count. Added tests for tiers at 0/2/3/5/6, mixed denominators, all-Unsure,
  newest-first saved history after ledger edits/deletion, filters, missing legacy
  context, and recoverable failures.
- Task 5: removed the accounting-oriented currency/category-count summary from
  Home. Added due purchase counts, recoverable prompt errors, no-due explanation,
  and a learning card based on the same sample rules. Reflection purchase context
  now includes the category, including archives. Answers remain one tap.
- Task 6: Settings → Categories supports create/rename/archive/restore with
  system/custom labels. Create/rename/restore guard active duplicates, ownership
  is checked, and multi-step validation/writes run atomically. System category IDs,
  keys, renames and archival survive bootstrap. New-expense empty categories link
  directly to management. Regression tests cover concurrent duplicate creation,
  archive/restore/name conflicts, saved names and the actual management UI.
- Task 7: generated the missing V7 schema and fixture, and moved the existing V7
  upgrade into Drift's generated step sequence (no version bump or new fields).
  All 21 V1–V7 structural migration pairs are now checked. Added a V6→V7 data
  test for snapshots differing from current ledger values, archived categories,
  income and pending answers. Existing tests cover profile isolation, answer
  atomicity, null legacy values, reconciliation, soft deletion and reopen.
- Task 8: onboarding explains the local behavioral product; Settings repeats a
  detailed guide, eligibility, all six moods, preservation semantics and local
  storage. Entry/edit show the selected mood's explanation and tooltips. No extra
  reflection questions were added.
- Task 9: deferred under the brief's explicit testing condition. No evidence from
  users is available to justify an extra answer step.
- Task 10: [beta readiness](v1-beta-readiness.md) records QA, privacy/storage review,
  export/erasure gates, participant protocol, metric denominators and bias limits.
  README and older reflection docs now describe current V7 behavior.
- Intermediate validation: 40 task-1 tests and 85 combined feature/migration tests
  passed. Full suite passed 224 tests before the final filter/navigation additions.
  Static analysis passed after correcting style findings. Final results below.
- Device test maintenance: removed obsolete daily-cap expectations. The first run
  exposed equal due dates ordered by random IDs; the test now uses distinct purchase
  dates to deterministically exercise oldest-first behavior. This preserves the
  existing ID tie-breaker rather than changing scheduling policy to satisfy a test.

## Final validation — 2026-10-01

| Check | Result |
| --- | --- |
| `flutter analyze` | Passed: no issues |
| `flutter test --reporter expanded` | Passed: 228 tests (baseline 207) |
| iPhone 17 Pro / iOS 26.3 `flutter drive` | Passed: onboarding, two purchases, back navigation, answer, next due reflection, SQLite reopen, history, second answer |
| Changed Dart files formatted | Passed: 39 files checked |
| `git diff --check` | Passed |
| Simulator screenshots | Home and one-tap reflection inspected; saved in `build/qa/` |

The device test uses a temporary database and removes it after the test. The
simulator was returned to its original shutdown state. No production/user database
was migrated or edited by these checks. No commit, deployment or participant
outreach was performed.

Screenshots: `build/qa/regret-home-ready.png`, `build/qa/regret-reflection.png`,
`build/qa/regret-home-completed.png`. These are generated local QA artifacts, not
tracked application assets. Pre-existing SVG loader notices about source metadata
still appear during tests; they do not fail decoding or rendering checks.

Remaining work before a real-user beta is listed in [beta readiness](v1-beta-readiness.md):
export, complete erasure, privacy/security review, broader manual accessibility
and device QA, and the actual participant study. Optional reasons and V2 features
remain behind the evidence gates described above.
