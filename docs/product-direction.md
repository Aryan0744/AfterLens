At this point, AfterLens has moved past “proof that the idea can work.” You now have enough infrastructure that the project needs to become much more deliberate.

The vision should be:

> **AfterLens helps people understand which spending decisions they later value, regret, or question — then uses that behavioral history to help them make better future decisions.**

That means the product should not compete primarily as an expense tracker. Expense tracking is only the data-capture layer. The actual product is the **behavioral feedback loop**.

The core loop is:

```text
Purchase
→ capture context
→ wait
→ reflect
→ preserve the historical outcome
→ detect patterns
→ turn patterns into guidance
→ improve future decisions
```

Everything we build from here should strengthen that loop.

---

# Where the project stands now

The foundation is already much stronger than where we started.

You now effectively have:

```text
Profiles
Categories
Transactions
Expense entry
Transaction editing
Transaction deletion

Mood classification
Need
Want
Impulse
Social
Subscription
Emergency

Eligibility rules
Want / Impulse
> $15
2-day reflection delay

Reflection queue
Multiple due reflections
One shown at a time
Unanswered reflections persist

Reflection answers
Worth it
Regret
Unsure

Immutable behavioral snapshots
Historical reflection integrity

Behavioral Insights foundation

Soft deletion
Completed behavioral history survives ledger deletion

SQLite / Drift
Repository layer
Service layer
Riverpod presentation layer
Automated tests
Migration history
```

That is enough foundation.

The mistake now would be jumping into AI coaching, bank connections, complicated budgets, prediction models, dashboards, gamification, or cloud sync just because those features sound impressive.

The next phase should be about making the **existing behavioral system trustworthy and genuinely useful**.

---

# The development plan from here

1. **Finish V1 data integrity completely.**

The immediate next work should be fixing the remaining edge cases around categories and historical transactions.

One known issue is archived categories.

Example:

```text
Transaction:
$60
Shopping
Impulse

Later:
Shopping category is archived
```

That historical transaction still needs to display:

```text
Shopping
```

It should not suddenly show:

```text
Unavailable
Unknown
No category
```

New purchases should only use active categories.

Old purchases should retain their historical category.

If an old transaction is edited, its archived category should remain visible, while any replacement category must be active.

This sounds minor, but it matters because AfterLens depends on historical consistency.

After this, systematically review other integrity cases:

```text
Archived categories
Deleted transactions
Edited transactions
Answered reflections
Pending reflections
Profile isolation
Legacy migrations
Income records
Missing/null historical fields
```

The goal is:

> Once behavioral history exists, normal ledger management must never silently corrupt it.

That should become a hard design principle.

---

2. **Make behavioral Insights genuinely useful.**

Right now the analytics foundation exists.

The next job is deciding what information actually deserves to be shown.

Do not build a dashboard containing every statistic we can calculate.

The user should open Insights and immediately understand something about themselves.

A good V1 Insights structure would be something like:

```text
Your reflection overview

Reviewed purchases: 24
Worth it: 14
Regretted: 7
Unsure: 3
```

Then behavioral patterns:

```text
Impulse
8 reviewed
5 regretted
2 worth it
1 unsure

Want
10 reviewed
2 regretted
7 worth it
1 unsure
```

Then category patterns:

```text
Shopping
Highest regret pattern

Dining
Mostly worth it

Entertainment
Not enough data yet
```

Then reflected spending:

```text
$320 reviewed

$105 regretted
$180 worth it
$35 unsure
```

But the app must distinguish **data** from **conclusions**.

If someone has:

```text
2 Impulse purchases
2 regretted
```

we should not dramatically claim:

> You regret 100% of your impulse spending.

Technically true, but statistically useless.

We need minimum sample rules.

You already started this with minimum pattern counts. Keep building on that.

Something like:

```text
0–2 decisive reflections
→ Not enough data

3–5
→ Early pattern

6+
→ Pattern
```

I would still avoid presenting these as scientific confidence scores. Keep the language simple.

---

3. **Treat “Unsure” as useful data.**

Right now Unsure is excluded from decisive regret-rate calculations.

That is mathematically reasonable.

But Unsure itself can become behaviorally interesting.

Imagine:

```text
Subscriptions

Worth it: 2
Regret: 1
Unsure: 7
```

The interesting finding is not the regret percentage.

The interesting finding is:

> You are often unsure whether your subscriptions are providing value.

Eventually Insights should surface that.

So your analytics model should track separately:

```text
worth-it rate
regret rate
unsure rate
```

Do not force every result into regret vs worth-it.

---

4. **Improve the reflection experience.**

The reflection is the most important interaction in the app.

Expense entry gets the data.

Reflection creates the product value.

It should feel extremely quick.

The user should see:

```text
Headphones
$80
Impulse
Shopping

Was this purchase worth it?

Worth it
I regret it
Unsure
```

One tap.

Done.

Do not turn it into a questionnaire.

But once the basic habit is proven, we should consider adding an **optional reason**.

Example:

```text
I regret it.

Why?

Didn't use it
Too expensive
Didn't need it
Bought emotionally
Social pressure
Found a better option
Other
Skip
```

The important word is **optional**.

If every reflection turns into six questions, people will stop reflecting.

But optional reasons would eventually produce much deeper analytics.

Instead of:

```text
Impulse → Regret
```

AfterLens could understand:

```text
Impulse
→ Regret
→ Didn't need it
```

That becomes far more actionable.

I would not add this until the base V1 experience is stable.

---

5. **Create a behavioral history screen.**

Currently we have transactions and aggregated Insights.

Eventually users should also be able to see their completed reflections.

Something like:

```text
Reflection History

Sep 28
Headphones
$80
Impulse
Regret

Sep 25
Dinner
$42
Social
Worth it

Sep 21
Shoes
$110
Want
Worth it
```

This gives users transparency.

If Insights says:

> Shopping has been a high-regret category.

The user should be able to inspect what created that conclusion.

This is very important for trust.

Never make the analytics feel like a black box.

---

6. **Improve the Home screen around behavior rather than accounting.**

Home should eventually answer three questions:

```text
What happened recently?

Do I have anything to reflect on?

Is AfterLens learning anything useful yet?
```

Not:

```text
Charts
Charts
Charts
Charts
```

A good Home architecture could become:

```text
AfterLens

Reflection ready
1 purchase waiting

Recent transactions

Latest insight
"You've reviewed 8 impulse purchases.
5 were later regretted."

View Insights
```

The product should constantly remind the user why they are tracking spending.

---

7. **Introduce better category management.**

Categories will eventually need:

```text
Create category
Rename category
Archive category
Restore category
System categories
Custom categories
```

But the rules must be strict.

Never hard-delete a category that historical data depends on.

Instead:

```text
Active
Archived
```

Archived means:

```text
cannot use for new transaction
historical records remain intact
```

This aligns with the architecture we just created for soft-deleted transactions.

---

8. **Review the current mood model before expanding it.**

The six moods currently are:

```text
Need
Want
Impulse
Social
Subscription
Emergency
```

Do not keep adding tags casually.

Every extra tag creates:

```text
more UI complexity
more ambiguous classification
less data per category
harder analytics
```

The existing six are enough for V1.

But later we should evaluate whether some of them are actually the same conceptual type.

For example:

```text
Need
Want
Impulse
```

describe decision intent.

While:

```text
Social
Subscription
Emergency
```

describe circumstances or purchase type.

That means the current taxonomy is not conceptually perfect.

It works for V1, but eventually we may want two dimensions:

```text
Decision intent:
Need
Want
Impulse

Context:
Social
Subscription
Emergency
None
```

Do not change this now.

But write it down as a known model limitation.

---

9. **Move from fixed reflection rules toward adaptive rules later.**

Current logic:

```text
Want / Impulse
Amount > $15
Wait 2 days
```

Good for V1.

Bad as a permanent behavioral model.

Eventually AfterLens should learn:

```text
Which purchases are worth reflecting on?
When should this user be asked?
Which categories matter?
What spending threshold matters?
```

For example, one user might need reflection on:

```text
Impulse purchases > $20
```

Another:

```text
Shopping > $75
```

Another:

```text
Subscriptions regardless of amount
```

Eventually the app could personalize reflection eligibility.

But personalized rules require enough historical data.

So V1 should gather the data first.

---

10. **Do not build the regret score yet.**

We have discussed a regret score before.

The danger is creating fake intelligence.

Something like:

```text
Regret Score: 72
```

looks sophisticated.

But unless we can clearly explain why it is 72 rather than 61 or 84, the number is mostly decoration.

First collect:

```text
responses
amounts
moods
categories
timing
optional reasons
```

Then study what meaningful patterns emerge.

Only after that should a score exist.

And even then, it should probably be interpretable.

---

11. **Build a personal spending model, not generic advice.**

This is the long-term differentiator.

Bad future AfterLens:

> Try to reduce unnecessary spending.

That is generic financial advice.

Nobody needs months of data for that.

Better AfterLens:

> You rarely regret social spending under $40, but 6 of your last 8 impulse Shopping purchases above $50 were regretted.

That is personal.

Even better:

> Your regretted impulse spending has fallen from $180/month to $70/month over the last three months.

Now the app is showing behavioral improvement.

That is the direction.

---

12. **Add coaching only after meaningful personal patterns exist.**

AI coaching belongs much later.

The AI should never invent financial wisdom from nothing.

Instead, it should interpret real personal data.

For example:

```text
Your data:
12 impulse Shopping purchases
8 regretted
average regretted purchase = $64
most occur during weekends
```

Then AI might say:

> Your reflections suggest larger weekend Shopping purchases are one of your more consistent regret patterns. A 24-hour waiting rule for purchases over $50 could be worth trying.

Now the AI has evidence.

That is far stronger than:

> Spend less money.

So the architecture should eventually become:

```text
Raw transactions
↓
Reflections
↓
Structured behavioral analytics
↓
Detected patterns
↓
AI explanation/coaching
```

Never:

```text
Transactions
↓
LLM
↓
random advice
```

---

13. **Eventually create interventions.**

Insights alone are passive.

The real product eventually needs to help before the next questionable purchase.

Imagine AfterLens learns:

```text
Impulse
Shopping
>$60

→ historically high regret
```

Later, when the user enters a similar purchase:

> Purchases like this have often been regretted in your past reflections.

That is where AfterLens transitions from:

```text
behavior tracking
```

to:

```text
behavior change
```

But this requires sufficient historical confidence.

Do not trigger warnings based on two purchases.

---

14. **Budgeting should eventually become behavior-aware.**

You wanted AI-assisted budgeting.

That can still make sense.

But it should not become a generic:

```text
Income: $3000
Rent: $1200
Food: $400
Entertainment: $200
```

There are already many apps that do that.

AfterLens budgeting should eventually use:

```text
income
essential expenses
user goals
historical spending
regretted spending
worth-it spending
behavioral patterns
```

Example:

Instead of saying:

> Reduce Entertainment by $100.

AfterLens might discover:

```text
Entertainment:
$250/month
85% Worth It

Shopping:
$300/month
55% Regret
```

Then cutting Entertainment may actually make the user's life worse while doing nothing about the problematic behavior.

A behavior-aware budget could recommend focusing on Shopping first.

That would fit AfterLens much better.

---

15. **Bank/statement integration comes later, but eventually it matters.**

Manual entry is currently correct for development.

Long term, it creates a major weakness:

```text
user spends
→ forgets to record
→ AfterLens never sees transaction
```

That creates selection bias.

Eventually transaction import will probably be necessary.

The ideal future flow:

```text
Bank transaction detected

Amazon
$82.47

AfterLens asks:
How would you classify this?

Need
Want
Impulse
...
```

Then reflection happens later.

This keeps the behavioral input manual while automating the boring financial input.

That is much stronger than asking the user to type every transaction forever.

---

16. **Cloud sync and authentication should come after the local product is stable.**

Supabase can eventually provide:

```text
authentication
encrypted cloud storage strategy
device synchronization
account recovery
```

But syncing bad schema creates permanent problems.

The current local-first development approach is good.

Finish the domain model first.

Then sync it.

Not the other way around.

---

17. **Security needs its own milestone before public beta.**

Because this app handles personal financial behavior, this cannot be treated casually.

Before real users:

```text
secure authentication
secure API access
row-level access controls
safe backups
data deletion
privacy policy
data export
minimal logging of financial data
secure secret management
transport encryption
database strategy
```

We also need to decide clearly:

```text
what stays local
what goes to cloud
what AI can see
what AI cannot see
```

The user should be able to understand that without reading fifty pages of legal language.

---

18. **Build data export and true account deletion.**

Soft deletion is correct for normal ledger behavior.

But if the user says:

> Delete my account and data.

Then:

```text
transactions
reflections
snapshots
profile
analytics
cloud records
```

must actually be deletable.

Soft-delete is a product behavior.

It cannot become an excuse for permanent data retention.

Also eventually allow export:

```text
CSV
JSON
```

because users should own their financial history.

---

19. **Start measuring product success properly.**

Do not judge success by:

```text
number of screens
number of features
lines of code
beautiful UI
```

For AfterLens, the meaningful measures are closer to:

```text
Do people record purchases?

Do they come back for reflections?

What percentage of scheduled reflections get answered?

How many weeks do they keep using the app?

How long before meaningful patterns emerge?

Do users say the Insights taught them something?

Does regretted spending decrease?

Do spending decisions change?
```

That is what validates the product.

---

20. **Then move into a controlled beta.**

Once V1 is stable:

```text
5 users
then 10
then maybe 20
```

Not 1,000.

You need observational feedback.

Ask them:

```text
What confused you?

Did you remember to enter purchases?

Did reflections feel annoying?

Did Insights tell you anything surprising?

Did you change any spending decision because of AfterLens?

Which features did you ignore?

What did you expect that wasn't there?
```

Their behavior matters more than their compliments.

If people say:

> This is cool.

but stop using it after four days, the product is failing.

---

# What I would define as the V1 boundary

V1 should probably include:

```text
Reliable transaction management

Categories

Mood classification

Reflection scheduling

Reflection history

Worth it / Regret / Unsure

Behavioral snapshots

Behavioral Insights

Historical data integrity

Soft deletion

Clean onboarding

Useful Home screen

Basic settings

Local persistence

Strong tests
```

Maybe optional reflection reasons if we decide the UX needs them.

V1 does **not** need:

```text
AI coach
Bank connection
Full budgeting engine
Regret score
Predictive models
Cloud sync
Social features
Gamification
Advanced notification engine
Investment tracking
Credit score features
```

Those are expansion layers.

---

# The V2 vision

Once V1 proves the behavior loop works:

```text
Personalized reflection thresholds

Optional regret reasons

Trend analysis

Behavior improvement tracking

Follow-up reflections

Behavior-aware budgeting

Personalized spending interventions

AI interpretation

Automatic transaction import

Cloud sync
```

That moves AfterLens from:

> “Track and reflect.”

to:

> “Understand and improve.”

---

# The long-term version of AfterLens

The long-term system could eventually know:

```text
What you usually regret

What you rarely regret

Which categories create the most regret

What spending amounts are risky for you

Which moods lead to poor decisions

Whether your behavior is improving

Which interventions actually work

What kind of budget fits your real priorities
```

Then before a purchase, the app could potentially say:

> Similar purchases have often been regretted.

After a purchase:

> Reflect on this later.

After weeks:

> A pattern is emerging.

After months:

> Your behavior is improving.

That is a coherent product journey.

---

# What we should actually build next

The immediate order I would follow is:

```text
1. Archived-category / historical-category integrity
2. Reflection History
3. Improve Insights presentation and sample-size rules
4. Surface Unsure patterns
5. Review Home around the behavioral loop
6. Complete category management
7. Review edge cases + migration tests
8. Improve onboarding/explanation of moods and reflection
9. Add optional reflection reasons if testing supports it
10. Prepare V1 beta
```

Then stop.

Get people using it.

Do not keep building indefinitely.

The biggest risk now is no longer whether you can technically build AfterLens. You clearly can.

The biggest risk is spending months building an elaborate system before proving that people will repeatedly complete the fundamental behavior:

```text
record purchase
→ return later
→ reflect honestly
→ care about what the app learns
```

That loop determines whether AfterLens is a real product or just a technically impressive finance project.