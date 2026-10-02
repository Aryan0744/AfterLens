# AfterLens V1 — Production Reflection (Acceptance Run)

Run date: 2026-10-01
Branch: `feature/transaction-management-v1` at `a69786a` plus the uncommitted working tree
Toolchain: Flutter 3.47.4 (stable); iOS Simulator iPhone 16e, iOS 26.3

This document records the result of the 120-item V1 acceptance checklist for the core loop:
**record → wait → reflect → inspect history → learn**.

> **Important:** Passing this checklist means the V1 app logic is behaving correctly. It does
> **not** mean the product is ready for public beta. Export, complete erasure, a storage and
> security review, privacy wording, and manual device and accessibility QA are separate gates
> (see [v1-beta-readiness.md](v1-beta-readiness.md)).

---

## 1. Summary

| Result | Count | Items |
|---|---:|---|
| ✅ Pass | 100 | Everything not listed below. #1, #104 and #119 pass but carry a small note. |
| ❌ Fail | 3 | #3, #93, #94 |
| ⚠️ Needs improvement | 9 | #2, #4, #79, #84, #90, #92, #95, #99, #102 |
| 🔍 Manual check still required | 7 | #96, #97, #98, #100, #101, #116, #120 |
| ➖ Not applicable | 1 | #91 (there is no income UI in V1) |
| **Total** | **120** | |

Each item is counted once, under its main result. Items #116 and #120 (the "real-device feel"
checks) need a person using the app. Automation can only show that the screens and logic line up.

**Bottom line.** The behavioral core is solid. Eligibility, the queue, snapshots, edit and delete
semantics, Unsure handling, sample-size labels, migrations and persistence all pass, and each
area is backed by automated tests. All three must-pass end-to-end scenarios (A, B, C) pass.
The failures are at the edges: input validation on amounts, onboarding content, and a Home
ledger that shows only 5 transactions.

### Top issues to fix before beta

| Priority | Issue | Items |
|---|---|---|
| **P1** | An amount of 20 or more digits (e.g. `99999999999999999999`) throws an uncaught `FormatException` inside the form validator. **Save silently does nothing and no error appears.** The same parser is in both the Add and Edit screens. | #93, #94 |
| **P1** | Amount parsing strips commas, so `1,5` (a European-style 1.50) is **saved silently as 15.00**. There is also no upper limit: `92233720368547758` saved as about 9.2 × 10¹⁶ cents, which is close to the int64 limit and can overflow when Insights adds amounts together. | #93, #94 |
| **P1** | **Home is the only ledger, and it shows only the 5 most recent transactions.** Anything older cannot be opened, edited or deleted. | #84 |
| **P2** | Onboarding hides the six mood explanations (`ReflectionGuide(showMoods: false)`), and the guide sits *below* the Continue button, so users can skip it without seeing it. | #2, #3 |
| **P2** | A 200-emoji description passes the field's 200-*character* limit but fails the repository's 200-*UTF-16-unit* check. The user then sees a raw `Invalid argument(s)...` snackbar. | #92 |
| **P3** | Accessibility and layout polish: the edit icon on Transaction details has no tooltip or label. The "Recent transactions" header and the details rows use unconstrained `Text` inside a `Row`, which risks overflow with large text or long category names. | #97–#99, #102 |
| **P3** | Wording and consistency: "above *your currency* 15.00" on onboarding, a hard-coded `$15` on Add Expense, no thousands separators, and raw `error.toString()` in error messages. | #4, #95, #104 |

---

## 2. How this was tested

| Code | Method | What it means |
|---|---|---|
| **A** | Automated test suite | `flutter test --reporter expanded`: **228 tests, all passed**. These cover repositories, services, widgets and migrations. |
| **D** | On-device integration test | `flutter test integration_test` on the iPhone 16e simulator: **passed**. It runs the full flow (past-dated expense, reflection queue, answers, a real SQLite close and reopen, then History) against a temporary database, so the simulator's real app data was not touched. |
| **C** | Code review | I read the relevant code path and traced the behavior. |
| **P** | Targeted probe | I wrote throw-away widget tests for edge cases the suite doesn't cover (bad amounts, emoji descriptions, a 320 pt screen, 2× text, renaming a category between answers). I deleted the probe file after the run, so the repo is unchanged. |
| **M** | Manual | A person needs to do this on a device. These items are marked 🔍 below. |

Static gates: `flutter analyze` reported **No issues found**. `git diff --check` was **clean**,
and a separate trailing-whitespace scan of the untracked files was also clean, because
`git diff --check` does not look at untracked files.

A note on the layout probes: Flutter's test font draws every glyph as a full square, so text
comes out *wider* than on a real device. A probe that passes is therefore strong evidence. A
probe that overflows needs to be confirmed on a device (see #97).

---

## 3. Must-pass end-to-end scenarios

| Scenario | Result | Evidence |
|---|---|---|
| **A: Clean journey.** $80 Shopping / Impulse "Headphones" → reflect 3 days later → Regret → History → Insights | ✅ Pass | D (`past-dated expenses, reflection queue and persistent history`); A (`oldest due item is selected and persisted with purchase context`, `${response.name} is saved and Home advances…`, Insights breakdown tests) |
| **B: Historical integrity.** $80 Shopping/Impulse → Regret → edit to $120 Groceries/Need | ✅ Pass | `answerCheckin` copies amount, category id and name, mood, description and date into `snapshot_*` columns in the same transaction as the answer. History and Insights read **only** the snapshot ([drift_behavioral_insights_repository.dart](../lib/features/insights/data/drift_behavioral_insights_repository.dart)). A: `history stays truthful after ledger edits and removal, newest answer first`, `ledger corrections and category renames never rewrite insights` |
| **C1: Delete a completed purchase** → gone from the ledger, kept in History and Insights | ✅ Pass | The delete is a soft delete (`deleted_at`). The answered check-in is left alone, and the Insights query deliberately includes soft-deleted transactions. A: `deleting a transaction preserves its completed snapshot and Insights` |
| **C2: Delete a pending purchase** → gone from the ledger, pending reflection removed, nothing added to History | ✅ Pass | `deleteTransaction` removes the unanswered check-in before soft-deleting. A: `deleting a transaction removes its prompted/unprompted unanswered check-in` |

---

## 4. Full checklist results

Legend: ✅ Pass · ❌ Fail · ⚠️ Needs improvement · 🔍 Manual check required · ➖ N/A
Evidence codes: A / D / C / P / M (see §2).

### Onboarding, Settings and explanation (1–6)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 1 | Fresh install → onboarding | ✅ 🔍 | A, C | With no profile, bootstrap returns `needsOnboarding` (`requires onboarding when no profile exists`). I did not delete the app on a device. Confirm by hand. |
| 2 | Onboarding explains record → wait → reflect → learn | ⚠️ | C | The text covers the whole loop, but the heading reads "Record → return → reflect" and never says *learn*. The guide is placed **below** the Continue button, so a user can finish onboarding without scrolling to it. |
| 3 | Six moods explained in onboarding | ❌ | C | `OnboardingScreen` uses `ReflectionGuide(showMoods: false)`, so **no moods are explained during onboarding**. The explanations do exist in Settings, as chip tooltips, and as a line under the selected mood on Add/Edit Expense. |
| 4 | Eligibility explained (Want/Impulse, > 15, two days) | ⚠️ | C | The content is correct. During onboarding, though, `currencyCode: 'your currency'` makes it read "above **your currency 15.00**". |
| 5 | Explanation reachable from Settings | ✅ | A, C | Settings shows the full `ReflectionGuide`, moods included. A: `Home opens history and settings category management`. |
| 6 | Honest local-storage wording | ✅ | C | "Stores your purchases and reflections locally. It has no cloud sync, bank connection, or AI processing. Device backups may include app data…" No overclaiming. |

### Recording and eligibility (7–17)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 7 | $10 Need today → no reflection | ✅ | A | `need expense does not schedule regret check-in`, `expense below $15 is not eligible` |
| 8 | $80 Impulse 3 days ago → due | ✅ | A, D | `valid impulse expense is saved and schedules regret check-in` |
| 9 | $30 Want → due | ✅ | A | `schedules eligible want expense` |
| 10 | $30 Need → none | ✅ | A | `need expense is not eligible` |
| 11 | $30 Social → none | ✅ | A | `social expense is not eligible` |
| 12 | $30 Subscription → none | ✅ | A | `subscription expense is not eligible` |
| 13 | $30 Emergency → none | ✅ | A | `emergency expense is not eligible` |
| 14 | Exactly $15.00 → none | ✅ | A | The rule is `amountCents <= 1500` → ineligible. `exactly $15 is not eligible` |
| 15 | $15.01 → due | ✅ | A, C | Strictly greater than 1500. Also covered by the `$mood at $cents cents` matrix. |
| 16 | Future date → not due | ✅ | C | The date picker caps at `lastDate: DateTime.now()`, so a future date can't be picked in the UI. At the domain level the due date would still be in the future (`future check-ins are not delivered`). |
| 17 | Today → due two days later | ✅ | A | `future purchase stays hidden until it becomes due while Home is open`. Small caveat: the default date includes the current time of day, while picked dates are midnight, so "two days" counts from a slightly different point depending on how the date was set. |

### Reflection prompt and queue (18–28)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 18 | Prompt shows the correct description, amount, category, mood and date | ✅ | A, D | `oldest due item is selected and persisted with purchase context` |
| 19 | Worth it saves `worthIt` | ✅ | A | `${response.name} is saved and Home advances…` (run for every response) |
| 20 | I regret it saves `regret` | ✅ | A | Same test |
| 21 | Unsure saves `unsure`, not Regret | ✅ | A | Same test, plus `regret rate excludes unsure responses` |
| 22 | Back without answering → still available | ✅ | A | `backing out and rebuilding Home preserves the unanswered prompt` |
| 23 | Restart → still pending | ✅ | A, D | `active reflection and queue survive closing and reopening SQLite` |
| 24 | Two due → count shown, one at a time | ✅ | A, C | The card shows "2 purchases waiting. Reflect on one at a time." |
| 25 | Oldest first | ✅ | A | Ordered by `dueAt ASC, id ASC` |
| 26 | Next appears right away | ✅ | A | `answering unlocks the next due reflection immediately` |
| 27 | No one-per-day limit | ✅ | A | `all due reflections can be answered on the same day` |
| 28 | Queue empties | ✅ | A, C | Home falls back to "No reflections waiting…" |

### Editing before and after an answer (29–39)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 29 | Edit the date to today → rescheduled | ✅ | A | Rescheduling also clears `promptedAt`. `eligible edit resets delivery and rejects a stale answer` |
| 30 | Impulse → Need → pending removed | ✅ | A | `ineligible edit removes a prompted, unanswered check-in` |
| 31 | Need → Impulse → scheduled again | ✅ | A | `eligible edit schedules check-in when none exists` |
| 32 | Want ↔ Impulse → no duplicates | ✅ | A, C | Same row is rescheduled. A DB `UNIQUE(transaction_id)` constraint backs this up. |
| 33 | $30 → $10 → cancelled | ✅ | A | `pending eligibility can cycle until the first answer becomes permanent` |
| 34 | $10 → $30 → eligible again | ✅ | A | Same test |
| 35 | An answer stores a snapshot | ✅ | A | `database rejects duplicate check-ins and incomplete snapshot states`. A DB `CHECK` makes the snapshot required whenever there is an answer. |
| 36 | Edit to $120 Groceries/Need after answering | ✅ | A | Scenario B |
| 37 | Edit the description after answering | ✅ | A, C | `snapshot_description` is frozen |
| 38 | Edit the date after answering | ✅ | A, C | `snapshot_transaction_date` is frozen |
| 39 | Impulse → Need → Impulse after answering → no second reflection | ✅ | A, C | An answered check-in is `preserved` and is never deleted or rescheduled |

### Deletion (40–44)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 40 | Delete an ordinary transaction | ✅ | A | `deletes transaction belonging to profile` |
| 41 | Delete with a pending reflection | ✅ | A | Scenario C2 |
| 42 | Delete with a completed reflection | ✅ | A | Scenario C1 |
| 43 | Insights unchanged after the delete | ✅ | A | `deleting a transaction preserves its completed snapshot and Insights` |
| 44 | Restart → still hidden | ✅ | A, C | `deleted_at` is persisted, and every ledger query filters `deletedAt IS NULL` (`v6 to v7 …` migration test) |

### Reflection History (45–52)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 45 | History from Home | ✅ | A | History icon in the Home app bar |
| 46 | History from Insights | ✅ | A | Icon in the Insights app bar |
| 47 | Newest answer first | ✅ | A | `…newest answer first` |
| 48 | Uses snapshot values | ✅ | A, C | `ReflectionHistoryScreen` only ever reads `BehavioralReflection` (snapshot) |
| 49 | Unchanged after an edit | ✅ | A | Scenario B |
| 50 | Kept after a delete | ✅ | A | Scenario C1 |
| 51 | Empty state | ✅ | A | "No completed reflections yet. Answer a reflection to see it here." |
| 52 | Load failure can be recovered | ✅ | A | `empty and recoverable failure states` (Try again) |

### Categories (53–68)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 53 | Archive Shopping → the old transaction still shows Shopping | ✅ | A | Details resolves the name from all categories, archived included |
| 54 | Edit and keep the archived category | ✅ | A | `allowArchived: existing.categoryId == categoryId`. `archived category can stay on an edit but cannot be newly assigned` |
| 55 | Archived category hidden on new expense | ✅ | A | `activeCategoriesProvider`. `rejects archived category for new expense` |
| 56 | Move to an active category | ✅ | A | |
| 57 | Archived category can't be assigned to another transaction | ✅ | A | `details and edit preserve an archived category, excluding other archives` |
| 58 | Rename Shopping → Personal | ✅ | A | Ledger shows Personal; the snapshot keeps Shopping. `rename protects ownership, active uniqueness and saved reflection names` |
| 59 | Create a category | ✅ | A | `create, rename, archive and restore from the management screen` |
| 60 | Blank or whitespace name | ✅ | A | Rejected by the dialog validator and by the repository |
| 61 | Duplicate active name | ✅ | A | Case-insensitive, including under concurrency (`concurrent create calls cannot introduce duplicate active names`) |
| 62 | Rename | ✅ | A | |
| 63 | Rename to an existing active name | ✅ | A | |
| 64 | Archive | ✅ | A | `archives a category instead of deleting it` |
| 65 | Restore | ✅ | A | `restores an archived category` |
| 66 | Restore when the name conflicts | ✅ | A | `cannot restore category when active duplicate exists` |
| 67 | System category survives a restart | ✅ | A | Lookup by `systemKey` and never re-created. `system category keeps its key and archive through bootstrap`, `running bootstrap repeatedly does not duplicate categories` |
| 68 | All categories archived → Add Expense | ✅ | C | "Create or restore a category to record an expense." with a **Manage categories** button |

### Insights (69–80)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 69 | Empty state | ✅ | A | "Your insights will grow as you reflect" |
| 70 | 1 answer | ✅ | A, C | Counts are shown with "Not enough data: 1 of 3 decisive reflections." and no percentage |
| 71 | 2 decisive answers → Not enough data | ✅ | A | `sample tiers apply to every group at 0, 2, 3, 5 and 6 decisive answers` |
| 72 | 3 → Early pattern | ✅ | A | Same test |
| 73 | 5 → Early pattern | ✅ | A | Same test |
| 74 | 6 → Pattern | ✅ | A | Same test |
| 75 | 3 Worth it + 2 Regret + 5 Unsure → denominator of 5 | ✅ | A, C | Shows 40% regret / 60% worth it "of 5 decisive answers" |
| 76 | Unsure uses its own denominator | ✅ | A, C | 50% unsure "of all 10 reviewed". This doesn't count as an Unsure *pattern* because 5 is not more than half of 10. `uncertainty has its own denominator…` |
| 77 | All Unsure | ✅ | A | No regret %. Shows "Early pattern: often unsure about value (3 of 3 reviewed)". `regret rate is null when every response is unsure` |
| 78 | Drill-through filters | ✅ | A | `history filters $filter using saved fields and handles missing context` |
| 79 | Category insight after a rename | ⚠️ | P | Each evidence item keeps its own saved name. **However,** groups are keyed by category *id* and titled with the **oldest** saved name. In the probe, one answer was saved before renaming Shopping → Personal and one after; both landed in a single group titled "Shopping" (`groups=[Shopping:2]`). That reads oddly. Consider titling the group with the latest saved name, or showing "Shopping (now Personal)". |
| 80 | A soft-deleted purchase still counts | ✅ | A | Scenario C1 |

### Home (81–86)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 81 | Nothing due | ✅ | C | "No reflections waiting. Want and Impulse purchases above CAD 15.00 are ready two days after the purchase date." |
| 82 | One due → prominent | ✅ | A | The "Reflection ready" card sits above Add Expense |
| 83 | Several due → count | ✅ | C | "N purchases waiting" |
| 84 | Recent activity updates | ⚠️ | A, C | It updates live through a Drift stream (`updates automatically when a new transaction is created`). **But Home shows only `transactions.take(5)`, and there is no full ledger screen.** The sixth-oldest transaction and anything older can't be viewed, edited or deleted. |
| 85 | Learning card uses the same rules as Insights | ✅ | C | Uses the same `ReflectionSummary` thresholds (decisive ≥ 3 or an Unsure majority). Note that it only shows mood groups. |
| 86 | Reflection query fails → Home still usable | ✅ | A | `load failure leaves Home and expense entry usable` |

### Navigation (87–90)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 87 | Home → details → edit → back | ✅ | A, C | Details updates its local copy and Home updates through the stream. Minor: deleting from details returns to Home with no confirmation snackbar. |
| 88 | Home → Reflection → back | ✅ | A | #22 |
| 89 | Home → History → back | ✅ | A | |
| 90 | Home → Insights → History → back | ⚠️ | A, C | Works, but a filtered History keeps the title "Reflection History" and only says "…in this group" without naming the mood or category being shown. |

### Inputs and display (91–95)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 91 | Income | ➖ | A | There is no income UI in V1. At the domain level, income is never eligible (`income is never eligible`, `rejects scheduling a check-in for income`). |
| 92 | Long description | ⚠️ | A, P | 200 ASCII characters save and lay out fine on a 320 pt screen. **200 emoji pass the field's limit but the repository rejects them** (it counts UTF-16 units), and the user sees a raw `Could not save expense: Invalid argument(s)…`. |
| 93 | Invalid amount | ❌ | P | `0`, `-5`, `1.234` and `.5` are rejected cleanly. **`99999999999999999999` throws an uncaught `FormatException` in the validator, so Save silently does nothing.** **`1,5` is saved as 15.00.** |
| 94 | Very large amount | ❌ | P | 9,999,999.99 saves and lays out fine. There is no upper bound: `92233720368547758` is accepted at about 9.2 × 10¹⁶ cents, near int64 overflow, and longer inputs crash as in #93. Amounts have no thousands separators. |
| 95 | Currency consistency | ⚠️ | C | Home, Reflection, History, Insights and Details all use `CAD 0.00`. Add Expense hard-codes "over **\$15**", and money is formatted by hand in about 6 places with no grouping. |

### Device, layout and accessibility (96–102)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 96 | Keyboard | 🔍 | C | All forms are `SingleChildScrollView` with the default `resizeToAvoidBottomInset`, so Save should scroll into reach. Confirm on a device. |
| 97 | Small screen | 🔍 ⚠️ | P | At 320 × 568 the Reflection, Insights, History, Add Expense and Details screens had **no overflow**, even with the wide test font. Home overflowed in the **"Recent transactions" header `Row`** (`Text` with no `Flexible`/`Expanded`). The test font exaggerates width, but the structure is fragile. Wrap it in `Flexible` and confirm on an iPhone SE. |
| 98 | Large text (2×) | 🔍 | P | Reflection, Insights, History and Add Expense had no overflow at 2× text and 320 pt. The Home header row from #97 is the likely risk. Check with Dynamic Type at its largest setting. |
| 99 | Long category names (50 chars) | ⚠️ 🔍 | C, P | The dropdowns use `isExpanded: true`, and History and Insights wrap. The Transaction details `_DetailRow` puts the value `Text` in a `Row` with no `Flexible`. Wrap it so 50-character names can't overflow. |
| 100 | Dark mode | 🔍 | A | Automated contrast tests pass (`theme text and filled controls meet normal-text contrast`, logo light/dark). A screen-by-screen visual check, including dialogs and chips, is still needed. |
| 101 | Light mode | 🔍 | A | Same as #100. |
| 102 | Accessibility labels | ⚠️ | C | Reflection answers, mood chips (tooltip = explanation), Home icon buttons and category menus all have labels, and the saving spinner and error text are announced. **The Transaction details app-bar edit `IconButton` has no `tooltip`**, so VoiceOver reads only "button". Run VoiceOver once over the full loop. |

### Robustness and integrity (103–111)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 103 | Double-tap an answer | ✅ | A | `rapid taps submit once and disable all answers while saving` and `concurrent repository answers cannot overwrite the first response` |
| 104 | Save failure | ✅ ⚠️ | A | The Reflection screen stays put, shows an inline error and allows a retry (`save failure stays on the screen and allows retry`). Add and Edit also stay on screen, but the snackbars show raw exception text. |
| 105 | Heavy use → kill → reopen | ✅ | A, D | SQLite reopen tests |
| 106 | No duplicate check-ins | ✅ | A | Idempotent scheduling plus the DB unique constraint (`prevents duplicate check-ins for one transaction`) |
| 107 | A completed answer can't change | ✅ | A | `cannot answer the same check-in twice`, `repository operations cannot alter an answered reflection`. There is no UI to change an answer. |
| 108 | A deleted transaction isn't editable | ✅ | C | Ledger queries filter deleted rows, `updateExpense` throws on a deleted id, and Details closes after a delete. History cards aren't tappable, so there's no stale path back to a deleted item. |
| 109 | Can't answer the reflection of a deleted transaction | ✅ | A, C | `answerCheckin` rejects a deleted purchase, and the pending check-in is removed on delete |
| 110 | Pull-to-refresh | ✅ | A | `refresh returns the same unanswered reflection` |
| 111 | Background → foreground | ✅ | A | `AppLifecycleListener(onResume)` plus a 1-minute refresh timer. `resuming the app refreshes a reflection that became due` |

### Engineering gates (112–115)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 112 | V1–V7 migrations | ✅ | A | Every from→to pair is generated in `migration_test.dart`, with data tests for v3→v4, v4→v5, v5→v6, v3→v6 and v6→v7. All pass. |
| 113 | `flutter analyze` | ✅ | — | No issues found |
| 114 | `flutter test` | ✅ | — | 228 / 228 passed. The integration test also passed on the simulator. |
| 115 | `git diff --check` | ✅ | — | Clean, and the untracked files have no trailing whitespace either |

### Product judgement (116–120)

| # | Check | Result | Evidence | Notes |
|---:|---|:---:|:---:|---|
| 116 | 15–30 minutes of real use | 🔍 | M | Not done; it needs a person. Likely friction points from code review: the ledger stops at 5 items (#84), onboarding is skippable (#2), and nothing on Home says *when* the next reflection will be ready. |
| 117 | No AI coach, budgets, regret score or bank sync | ✅ | C | None exist. The only mentions are the honest "has no…" statements. |
| 118 | No "why?" step | ✅ | C | One tap: Worth it / I regret it / Unsure |
| 119 | Ledger vs History can be understood | ✅ ⚠️ | C | History says "Details are saved when you reflect. Editing or removing a transaction does not change these answers." The edit form warns when a completed reflection exists. Transaction details itself doesn't show that a saved reflection exists, which would help users connect the two. |
| 120 | Whole loop feels coherent | 🔍 | D, M | The simulator integration test runs the full loop end to end. The subjective "feels coherent" judgement needs a person. |

---

## 5. Recommended fix list (in order)

1. **Amount parsing (#93/#94).** Use one shared parser for Add and Edit. Reject anything above a
   sane maximum (for example ≤ 9 integer digits) *before* calling `int.parse`, or use
   `int.tryParse`. Don't silently drop commas: either reject `1,5` or treat a comma as the decimal
   separator by locale. Add tests for `99999999999999999999`, `1,5` and the maximum.
2. **Full ledger (#84).** Add a "See all transactions" screen so older items can be edited and
   deleted.
3. **Onboarding (#2/#3/#4).** Show the moods (`showMoods: true`, or a short summary), move the
   guide above Continue (or make it a second step), use "learn" in the heading, and drop the
   "your currency 15.00" wording.
4. **Description length (#92).** Measure length the same way in the UI and the repository (count
   characters on both sides), and show a friendly message.
5. **Layout and a11y (#97–#99, #102).** Wrap the Home header and `_DetailRow` text in `Flexible`,
   and add `tooltip: 'Edit expense'` to the details edit icon.
6. **Polish (#79, #90, #95, #104, #119).** Title category groups with the latest saved name, name
   the group on filtered History, use a single shared money formatter with grouping, replace raw
   error text with friendly messages, and show "Reflection saved: Regret" on Transaction details.

Then repeat the 🔍 items on a real iPhone (smallest supported size, largest Dynamic Type,
VoiceOver, light and dark), and move on to the beta gates: export, complete erasure, the
storage and security review, and the privacy policy.
