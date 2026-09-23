import 'package:afterlens/core/branding/afterlens_logo.dart';
import 'package:afterlens/core/branding/brand_assets.dart';
import 'package:afterlens/core/theme/app_theme.dart';
import 'package:afterlens/core/theme/brand_colors.dart';
import 'package:afterlens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

String renderedAsset(WidgetTester tester) {
  final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
  return (picture.bytesLoader as SvgAssetLoader).assetName;
}

double contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all approved SVGs are bundled and decode without external fonts',
    () async {
      final assets = [
        BrandAssets.primaryLight,
        BrandAssets.primaryDark,
        BrandAssets.primaryNavy,
        BrandAssets.primaryWhite,
        BrandAssets.secondaryLight,
        BrandAssets.secondaryDark,
        BrandAssets.wordmarkLight,
        BrandAssets.wordmarkDark,
        BrandAssets.markLight,
        BrandAssets.markDark,
        BrandAssets.markNavy,
        BrandAssets.markWhite,
      ];
      for (final asset in assets) {
        final source = await rootBundle.loadString(asset);
        expect(source, isNot(contains('<text')), reason: asset);
        final decoded = await vg.loadPicture(SvgAssetLoader(asset), null);
        expect(decoded.size.isEmpty, isFalse, reason: asset);
        decoded.picture.dispose();
      }

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(
        manifest.listAssets().where(
          (path) =>
              path.startsWith('branding/') ||
              path.startsWith('assets/brand/native/'),
        ),
        isEmpty,
      );
    },
  );

  testWidgets('preview follows system light/dark changes and is labelled', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const AfterLensApp());
    await tester.pumpAndSettle();
    expect(renderedAsset(tester), BrandAssets.primaryLight);
    expect(find.bySemanticsLabel('AfterLens logo'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(AfterLensLogo)))
          .scaffoldBackgroundColor,
      BrandColors.offWhite,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(renderedAsset(tester), BrandAssets.primaryDark);
    expect(
      Theme.of(tester.element(find.byType(AfterLensLogo)))
          .scaffoldBackgroundColor,
      BrandColors.deepNavy,
    );
    expect(tester.takeException(), isNull);
  });

  final variants = {
    AfterLensLogoType.primary: [
      BrandAssets.primaryLight,
      BrandAssets.primaryDark,
    ],
    AfterLensLogoType.secondary: [
      BrandAssets.secondaryLight,
      BrandAssets.secondaryDark,
    ],
    AfterLensLogoType.wordmark: [
      BrandAssets.wordmarkLight,
      BrandAssets.wordmarkDark,
    ],
    AfterLensLogoType.mark: [BrandAssets.markLight, BrandAssets.markDark],
  };
  for (final entry in variants.entries) {
    testWidgets('${entry.key.name} respects explicit contrasting surfaces', (
      tester,
    ) async {
      for (final darkSurface in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: darkSurface ? AppTheme.light : AppTheme.dark,
            home: Scaffold(
              body: ColoredBox(
                color: darkSurface
                    ? BrandColors.deepNavy
                    : BrandColors.offWhite,
                child: AfterLensLogo(
                  type: entry.key,
                  surface: darkSurface
                      ? AfterLensLogoSurface.dark
                      : AfterLensLogoSurface.light,
                  width: 240,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(renderedAsset(tester), entry.value[darkSurface ? 1 : 0]);
        expect(tester.takeException(), isNull);
      }
    });
  }

  test('theme text and filled controls meet normal-text contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      expect(
        contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onSecondary, scheme.secondary),
        greaterThanOrEqualTo(4.5),
      );
      for (final style in [
        theme.textButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
      ]) {
        expect(
          contrast(style.foregroundColor!.resolve({})!, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
}
