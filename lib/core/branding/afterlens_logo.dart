import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'brand_assets.dart';

enum AfterLensLogoType { primary, secondary, wordmark, mark }

enum AfterLensLogoSurface { automatic, light, dark }

/// Uses the artwork for the surrounding surface without tinting or stretching.
class AfterLensLogo extends StatelessWidget {
  const AfterLensLogo({
    super.key,
    this.type = AfterLensLogoType.primary,
    this.surface = AfterLensLogoSurface.automatic,
    this.width,
    this.height,
  });

  final AfterLensLogoType type;
  final AfterLensLogoSurface surface;
  final double? width;
  final double? height;

  String _asset(BuildContext context) {
    final darkBackground = switch (surface) {
      AfterLensLogoSurface.light => false,
      AfterLensLogoSurface.dark => true,
      AfterLensLogoSurface.automatic =>
        Theme.of(context).brightness == Brightness.dark,
    };

    return switch (type) {
      AfterLensLogoType.primary =>
        darkBackground ? BrandAssets.primaryDark : BrandAssets.primaryLight,
      AfterLensLogoType.secondary =>
        darkBackground ? BrandAssets.secondaryDark : BrandAssets.secondaryLight,
      AfterLensLogoType.wordmark =>
        darkBackground ? BrandAssets.wordmarkDark : BrandAssets.wordmarkLight,
      AfterLensLogoType.mark =>
        darkBackground ? BrandAssets.markDark : BrandAssets.markLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset(context),
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'AfterLens logo',
    );
  }
}
