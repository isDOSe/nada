"""Generate nada!'s monochrome icons from the bundled serifs."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT_DISPLAY = ROOT / "assets" / "fonts" / "InstrumentSerif-Italic.ttf"
FONT_TEXT = ROOT / "assets" / "fonts" / "CrimsonText-SemiBold.ttf"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

BONE = (242, 239, 230, 255)
VOID = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)


def draw_glyph(canvas: Image.Image, font_path: Path, glyph: str, target_ratio: float) -> None:
    """Centre a glyph optically, using its ink bounding box rather than metrics."""
    draw = ImageDraw.Draw(canvas)
    size = canvas.height
    font = ImageFont.truetype(str(font_path), size=int(size * target_ratio))
    bbox = draw.textbbox((0, 0), glyph, font=font)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    x = (canvas.width - width) / 2 - bbox[0]
    y = (canvas.height - height) / 2 - bbox[1]
    # Optical lift: serif periods sit low, the glyph should feel centred.
    y -= size * 0.01
    draw.text((x, y), glyph, font=font, fill=BONE)


def make_legacy(size: int, out: Path) -> None:
    image = Image.new("RGBA", (size, size), VOID)
    draw_glyph(image, FONT_DISPLAY, "n!", 0.62)
    image.save(out)


def make_foreground(size: int, out: Path) -> None:
    image = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_glyph(image, FONT_DISPLAY, "n!", 0.44)
    image.save(out)


def make_notification(size: int, out: Path) -> None:
    image = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_glyph(image, FONT_TEXT, "n", 0.86)
    image.save(out)


def main() -> None:
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in densities.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        make_legacy(size, folder / "ic_launcher.png")
        make_foreground(size * 9 // 4, folder / "ic_launcher_foreground.png")

    notif = {
        "mdpi": 36,
        "hdpi": 54,
        "xhdpi": 72,
        "xxhdpi": 96,
        "xxxhdpi": 144,
    }
    for density, size in notif.items():
        folder = RES / f"drawable-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        make_notification(size, folder / "ic_nada.png")

    fallback = RES / "drawable"
    fallback.mkdir(parents=True, exist_ok=True)
    make_notification(96, fallback / "ic_nada.png")

    print("icons generated")


if __name__ == "__main__":
    main()
