"""Generate native branding while preserving unrelated Xcode asset settings."""

import re
import subprocess

from prepare_brand_assets import ROOT, main as prepare_assets


def main():
    prepare_assets()
    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    # flutter_launcher_icons 0.14.4 matches every ASSETCATALOG setting when
    # selecting AppIcon. Preserve settings such as Swift asset symbol generation.
    pattern = re.compile(r"ASSETCATALOG_(?!COMPILER_APPICON_NAME\b)[A-Z_]+ = [^;]+;")
    original_settings = pattern.findall(project.read_text())
    try:
        subprocess.run(["dart", "run", "flutter_launcher_icons"], cwd=ROOT, check=True)
    finally:
        generated = project.read_text()
        if len(pattern.findall(generated)) != len(original_settings):
            raise RuntimeError("Xcode asset settings changed shape; inspect project.pbxproj")
        settings = iter(original_settings)
        project.write_text(pattern.sub(lambda _: next(settings), generated))
    subprocess.run(
        ["dart", "run", "flutter_native_splash:create"], cwd=ROOT, check=True
    )


if __name__ == "__main__":
    main()
