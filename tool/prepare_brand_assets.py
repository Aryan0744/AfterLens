"""Prepare native generator inputs from the approved package (requires Pillow)."""

from pathlib import Path
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "branding/source"
NATIVE = ROOT / "assets/brand/native"


def main():
    NATIVE.mkdir(parents=True, exist_ok=True)
    for relative in (
        "02_App_Icons/afterlens-app-icon-1024.png",
        "01_Raster_PNG/afterlens-mark-dark.png",
        "01_Raster_PNG/afterlens-mark-white.png",
    ):
        shutil.copy2(SOURCE / relative, NATIVE / Path(relative).name)

    with Image.open(NATIVE / "afterlens-app-icon-1024.png") as icon:
        # Flatten any alpha onto official navy; never round the source artwork.
        background = Image.new("RGBA", icon.size, "#0B1F33")
        background.alpha_composite(icon.convert("RGBA"))
        background.convert("RGB").save(
            NATIVE / "afterlens-app-icon-ios.png", optimize=True
        )

    with Image.open(NATIVE / "afterlens-mark-dark.png") as mark:
        # Native splash generators treat this as a 4x image: 192 logical pixels.
        mark.resize((768, 768), Image.Resampling.LANCZOS).save(
            NATIVE / "afterlens-splash.png", optimize=True
        )
        # Android 12 with an icon background: 960px canvas, 640px safe circle.
        # Retain the original mark's clear space inside a 640px square.
        splash = Image.new("RGBA", (960, 960))
        splash.alpha_composite(
            mark.resize((640, 640), Image.Resampling.LANCZOS), (160, 160)
        )
        splash.save(NATIVE / "afterlens-splash-android12.png", optimize=True)


if __name__ == "__main__":
    main()
