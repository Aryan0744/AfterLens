
# AfterLens

Spend with better hindsight.

AfterLens is a privacy-first personal finance and spending reflection application
built with Flutter, Riverpod, and Drift. The product direction combines spending
forecasts with mood and regret check-ins. The current app contains the database
foundation and a branded preview screen; financial workflows are still to come.

## Development

```sh
flutter pub get
flutter run
```

Use `flutter analyze` and `flutter test` for checks. The preview follows the system
light/dark setting and uses the approved SVG logo. Interface typography and the
full product design system will be defined separately.

## Branding

See [brand usage and regeneration](branding/USAGE.md) for asset selection, native
icon/splash generation, accessibility rules, and the release visual checklist.
The complete source package and overview PDF are archived in `branding/source/`;
only runtime logo SVGs are included in Flutter's asset bundle.
