# AfterLens Brand Usage

## Source of truth

Approved vector masters: `branding/source/00_Master_Vector/SVG/`.
The full supplied package, including print files and the overview PDF, is archived
under `branding/source/`. The original `QA_REPORT.txt` describes that package;
it is not a record of device testing for this integration.

Flutter bundles only `assets/brand/logos/` and `assets/brand/marks/`.
`assets/brand/native/` contains build inputs; neither it nor `branding/` belongs
in the Flutter asset bundle. Web icons are served directly from `web/`.

## Core colors

| Color | Value | Main use |
| --- | --- | --- |
| Deep Navy | `#0B1F33` | Text on light surfaces, dark surfaces |
| Cyan | `#00C2E6` | Brand accents and filled controls |
| Coral | `#FF7B6E` | Brand accents |
| Off White | `#F4F7FA` | Light surfaces and text on dark surfaces |

Use Navy text on Cyan/Coral fills. Avoid Cyan/Coral body text on light surfaces.
Text and outlined buttons explicitly use the surface foreground for contrast.
Check meaningful graphics and focus indicators for non-text contrast too; brand
accent colors are not automatically accessible on every background. Never use
color alone to communicate financial or error states. See the
[accessibility guidance](source/04_Brand_Guide/README.md#accessibility-and-ui-color-usage).

## Logo selection

Use `AfterLensLogo` and `BrandAssets` instead of repeating SVG paths.

```dart
const AfterLensLogo(width: 240); // Follows system light/dark mode.
const AfterLensLogo(
  type: AfterLensLogoType.mark,
  surface: AfterLensLogoSurface.dark, // Explicit dark panel in either theme.
  width: 48,
);
```

- Primary horizontal logo: onboarding, authentication, and wide compositions;
  minimum 140px wide.
- Secondary logo: stacked compositions.
- Wordmark: tight horizontal spaces.
- Mark: square/compact areas, minimum 24px.
- Responsive favicon micro-mark: browser tabs and sizes below 24px.
- App icon: mobile launcher. Let the operating system apply its mask.

Keep clear space at least equal to the coral dot diameter around the primary
logo. Do not stretch, rotate, recolor, add shadows/glow, recreate the logo, or use
the wrong surface variant. Do not round or add transparent padding to full-bleed
launcher artwork. Padding on adaptive foreground/splash layers is platform safe
area, not a change to the launcher master. Keep default Material typography for
the app; the outlined logo lettering is not the UI font.

## Regenerate native branding

Run from the project root (the preparation script requires Python 3 with Pillow):

```sh
flutter pub get
python3 tool/generate_native_branding.py
```

The preparation script copies canonical native sources, flattens the iOS icon
onto Navy and saves RGB, and exports splash artwork. The general splash image
is 768px at 4x density (192 logical pixels). Android 12 uses a 960px transparent
canvas with a 640px mark layer, keeping the mark inside the 640px safe circle.
Adaptive Android foreground and monochrome layers use a 20% inset.
The source vectors and full-bleed launcher master are unchanged.

The wrapper runs `tool/prepare_brand_assets.py`, `dart run flutter_launcher_icons`,
and `dart run flutter_native_splash:create`. It also preserves unrelated Xcode
asset-catalog settings: launcher generator 0.14.4 otherwise overwrites the Swift
asset-symbol generation flag while selecting the app icon. Use the wrapper for
repeatable regeneration.

Generator references: [launcher icons](https://pub.dev/packages/flutter_launcher_icons)
and [native splash](https://pub.dev/packages/flutter_native_splash).
Keep both generator YAML files and their generated Android/iOS resources in Git.
The splash follows native startup timing; there is no artificial delay.

Web uses the supplied favicon, Apple touch icon, and separate normal/maskable PWA
icons. Do not enable web generation in the native tools, which would overwrite
the dedicated favicon system. Keep Flutter's base href and bootstrap script.

## Verification

```sh
flutter analyze
flutter test
flutter build web
```

The branding tests decode all runtime SVGs, ensure archive/native files are not
bundled, check system theme changes and explicit surface variants, verify logo
semantics, and check contrast for supported text/control pairs.

Before release, cold-start on Android and iOS and inspect the launcher, recents,
app list, Android icon masks/themed icons, and splash transition. Test web title,
favicon, installed PWA icons, and both color schemes. A simulator/emulator
runtime must be installed to complete native visual checks. Do not mistake
generated files or a passing build for visual verification on a device.

## Integration validation — September 22, 2026

- `flutter analyze`: no issues.
- `flutter test`: all 7 tests passed.
- Production web build and Android debug APK: passed.
- Chrome: light/dark previews visually checked, correct title/favicon/theme
  metadata, all PWA icons served, no browser runtime errors.
- Pixel 8 / Android 15: app installed and launched; circular launcher icon and
  AfterLens display name checked. Native splash uses the mark on Navy.
- Native asset checks: all iOS icons are RGB at the catalog dimensions; Android
  resource XML and web icon sizes validate; Android 12 artwork fits its safe
  circle. Regeneration preserves unrelated Xcode asset settings.
- iOS build/device verification is pending: this Xcode installation lacks the
  required iOS 26.2 platform and has no simulator runtime/devices. Install the
  platform in Xcode Settings → Components, then build and inspect a cold start.
- Other Android launcher masks and Android themed-icon appearance still need
  device coverage; the adaptive foreground and monochrome resources are present.
