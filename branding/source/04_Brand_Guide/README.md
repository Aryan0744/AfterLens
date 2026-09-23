# AfterLens - Final Brand Asset System

This is the final production package. The core logo has been rebuilt as native vector geometry rather than an automated raster trace. All wordmarks in the master SVG files are converted to paths, so the files do not depend on an installed font.

## Official color palette
- Deep Navy: #0B1F33
- Cyan: #00C2E6
- Coral: #FF7B6E
- Off White: #F4F7FA

## Which logo to use
- Light backgrounds: `afterlens-primary-light.svg`
- Dark backgrounds: `afterlens-primary-dark.svg`
- Tight horizontal spaces: wordmark-only variant
- Square/compact spaces: mark-only variant
- One-color printing: navy or white monochrome variant
- App stores: files in `02_App_Icons/`
- Browser tabs: `favicon.svg` or `favicon.ico`

## Production decisions
The earlier concept used decorative 3D shading. The final master simplifies that treatment into clean brand colors. This is intentional: it makes the identity reproducible, scalable, print-safe, and consistent at small sizes. The geometry and color logic remain aligned to the approved AfterLens direction.

The mobile app icon exports are full-bleed opaque square artwork. They do not contain pre-rounded corners or an external drop shadow; iOS and Android apply their own masks.

The favicon uses a responsive micro-mark rather than the full orbital logo because the arc becomes visually noisy at 16-32 px.

## Clear space
Keep clear space around the primary logo equal to at least the diameter of the coral focus dot in the mark.

## Minimum size
- Primary horizontal logo: 140 px wide minimum for UI usage.
- Mark only: 24 px minimum.
- Below 24 px: use the responsive favicon micro-mark.

## File formats
- SVG: source-of-truth vector masters
- PDF: print/vector handoff
- EPS: legacy print/vendor handoff
- PNG: digital use

Do not stretch, recolor individual elements outside the approved palette, add shadows to the core logo, or use the light-background variant on dark surfaces.

## Accessibility and UI color usage

Deep Navy and Off White are the primary text and surface pairing. Cyan and Coral
are accents; neither has enough contrast for normal text on Off White.

Recommended combinations:

- Deep Navy text on Off White
- Off White text on Deep Navy
- Deep Navy text/icons on Cyan
- Deep Navy text/icons on Coral

Use Cyan and Coral for accents, filled buttons, highlights, and decorative
elements. For meaningful icons, chart marks, selected states, borders, and focus
indicators, also verify non-text contrast against adjacent colors. On light
surfaces, use a sufficiently contrasting outline or another accessible treatment.

Do not rely on color alone to communicate financial states, warnings, errors,
spending categories, or regret status. Include text, labels, icons, or patterns.
Coral does not automatically mean error, and Cyan does not automatically mean
success; financial/status colors will be defined separately.

Verify new combinations against WCAG contrast requirements: 4.5:1 for normal
text, 3:1 for large text, and 3:1 for meaningful non-text UI graphics. Brand logo
artwork is not the model for body-text color usage.

## Native integration exports

The original package is retained here. Runtime SVGs live in `assets/brand/`,
outside this archive. The generated iOS icon source is RGB with no alpha channel;
all mobile launcher artwork remains square, full bleed, and unrounded. Splash
exports resize/pad the approved mark for native density and Android 12 masking
without changing its geometry. See `branding/USAGE.md` for regeneration.
