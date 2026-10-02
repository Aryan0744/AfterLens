
# AfterLens

Spend with better hindsight.

AfterLens helps you understand which purchases you later value, regret, or
question. Record a purchase, return for a reflection, then explore your saved
history and behavioral Insights.

The local Flutter app uses Riverpod and Drift/SQLite. It includes expense entry
and editing, soft deletion, category management, six spending moods, one-tap
reflections, snapshot-backed history, Insights with sample-size rules, onboarding
and basic settings. Want/Impulse purchases strictly above 15.00 in the profile's
currency are ready to reflect on two days after their purchase date.

Development status, decisions and validation are tracked in the
[V1 delivery plan](docs/v1-delivery-plan.md). See the
[product direction](docs/product-direction.md) for the supplied vision and the
[beta readiness checklist](docs/v1-beta-readiness.md) for release gates.

## Development

```sh
flutter pub get
flutter run
```

Use `flutter analyze` and `flutter test` for checks. The app follows the system
light/dark setting and uses the approved SVG logo. It currently has no cloud sync,
bank integration, AI coaching or budgeting engine.

## Branding

See [brand usage and regeneration](branding/USAGE.md) for asset selection, native
icon/splash generation, accessibility rules, and the release visual checklist.
The complete source package and overview PDF are archived in `branding/source/`;
only runtime logo SVGs are included in Flutter's asset bundle.
