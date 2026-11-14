"""Generate platform app icons from the supplied brand artwork."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(r"C:\Users\nader\Downloads\files")
BRAND = ROOT / "assets" / "branding"
ICON = SOURCE / "icon.png"
FOREGROUND = SOURCE / "icon_foreground.png"
MONO = SOURCE / "icon_mono.png"


def save_square(image: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(destination, "PNG")


def main() -> None:
    for path in (ICON, FOREGROUND, MONO):
        if not path.is_file():
            raise FileNotFoundError(f"Brand asset not found: {path}")

    BRAND.mkdir(parents=True, exist_ok=True)
    for source in (ICON, FOREGROUND, MONO):
        shutil.copy2(source, BRAND / source.name)
    shutil.copy2(SOURCE / "icon.svg", BRAND / "icon.svg")

    with Image.open(ICON) as opened:
        icon = opened.convert("RGBA")

    # Android legacy launcher densities.
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        save_square(icon, ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)

    # iOS asset catalog uses the standard Flutter filenames and point sizes.
    ios_catalog = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_json = json.loads((ios_catalog / "Contents.json").read_text(encoding="utf-8"))
    for item in ios_json["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        points = float(item["size"].split("x")[0])
        scale = int(item["scale"].removesuffix("x"))
        save_square(icon, ios_catalog / filename, round(points * scale))

    # macOS asset catalog.
    mac_catalog = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    mac_json = json.loads((mac_catalog / "Contents.json").read_text(encoding="utf-8"))
    for item in mac_json["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        points = int(item["size"].split("x")[0])
        scale = int(item["scale"].removesuffix("x"))
        save_square(icon, mac_catalog / filename, points * scale)

    # Flutter web PWA icons.
    for size in (192, 512):
        save_square(icon, ROOT / f"web/icons/Icon-{size}.png", size)
    for size in (192, 512):
        # Keep the source artwork intact; it already has a solid background and safe margins.
        save_square(icon, ROOT / f"web/icons/Icon-maskable-{size}.png", size)
    save_square(icon, ROOT / "web/favicon.png", 32)

    # Android adaptive launcher icon foreground and monochrome layers.
    with Image.open(FOREGROUND) as opened:
        foreground = opened.convert("RGBA")
    save_square(foreground, ROOT / "android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png", 432)
    with Image.open(MONO) as opened:
        monochrome = opened.convert("RGBA")
    save_square(monochrome, ROOT / "android/app/src/main/res/drawable-nodpi/ic_launcher_monochrome.png", 432)

    adaptive = ROOT / "android/app/src/main/res/mipmap-anydpi-v26"
    adaptive.mkdir(parents=True, exist_ok=True)
    (adaptive / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
""",
        encoding="utf-8",
    )
    colors = ROOT / "android/app/src/main/res/values/ic_launcher_background.xml"
    colors.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0F172A</color>
</resources>
""",
        encoding="utf-8",
    )
    print("Generated Android, iOS, macOS, and web icons from the supplied football tactics artwork.")


if __name__ == "__main__":
    main()
