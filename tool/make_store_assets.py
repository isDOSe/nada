"""Build the public brand kit and store assets from the official wordmark.

Inputs:
  store/ai/logo-recraft-a.png   official 2048x2048 wordmark on black
  store/ai/logo-recraft-a.svg   official vector wordmark
  docs/screenshots/*.png        final app screenshots (1080x2400)

Outputs:
  store/brand/                  wordmark, monogram, transparent versions
  store/feature-graphic-1024x500.png
  store/web/                    hero and Open Graph images
  store/screenshots/            1080x1920 phone screenshots for Google Play
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "store"
BRAND = STORE / "brand"
WEB = STORE / "web"
SHOTS = STORE / "screenshots"
DOCS = ROOT / "docs" / "screenshots"

FONT_DISPLAY = ROOT / "assets" / "fonts" / "InstrumentSerif-Italic.ttf"
FONT_TEXT = ROOT / "assets" / "fonts" / "CrimsonText-Regular.ttf"
FONT_TEXT_ITALIC = ROOT / "assets" / "fonts" / "CrimsonText-Italic.ttf"

BLACK = (0, 0, 0, 255)
BONE = (242, 239, 230, 255)
ASH = (166, 160, 150, 255)
FAINT = (123, 118, 108, 255)
HAIRLINE = (38, 35, 31, 255)


def load_wordmark() -> Image.Image:
    source = Image.open(STORE / "ai" / "logo-recraft-a.png").convert("RGB")
    return source


def trim(image: Image.Image, margin: int) -> Image.Image:
    gray = image.convert("L")
    mask = gray.point(lambda value: 255 if value > 6 else 0)
    box = mask.getbbox()
    if box is None:
        raise RuntimeError("The wordmark image is empty.")
    left, top, right, bottom = box
    left = max(0, left - margin)
    top = max(0, top - margin)
    right = min(image.width, right + margin)
    bottom = min(image.height, bottom + margin)
    return image.crop((left, top, right, bottom))


def transparent_wordmark(image: Image.Image, margin: int) -> Image.Image:
    cropped = trim(image, margin)
    alpha = cropped.convert("L")
    peak = alpha.getextrema()[1] or 1
    alpha = alpha.point(lambda value: min(255, round(value * 255 / peak)))
    out = Image.new("RGBA", cropped.size, (BONE[0], BONE[1], BONE[2], 0))
    out.putalpha(alpha)
    return out


def fit_width(image: Image.Image, width: int) -> Image.Image:
    height = round(image.height * width / image.width)
    return image.resize((width, height), Image.Resampling.LANCZOS)


def draw_centered(
    canvas: Image.Image,
    text: str,
    font: ImageFont.FreeTypeFont,
    y: int,
    fill: tuple[int, int, int, int],
) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.text((canvas.width // 2, y), text, font=font, fill=fill, anchor="mm")


def make_wordmark_assets(source: Image.Image) -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    source.save(BRAND / "nada-wordmark-2048.png")
    source.resize((1024, 1024), Image.Resampling.LANCZOS).save(
        BRAND / "nada-wordmark-1024.png"
    )

    tight = trim(source, 80)
    tight.save(BRAND / "nada-wordmark-black-tight.png")

    transparent = transparent_wordmark(source, 60)
    transparent.save(BRAND / "nada-wordmark-transparent.png")
    transparent.resize(
        (transparent.width // 2, transparent.height // 2),
        Image.Resampling.LANCZOS,
    ).save(BRAND / "nada-wordmark-transparent-1024.png")

    svg = (STORE / "ai" / "logo-recraft-a.svg").read_text(encoding="utf-8")
    (BRAND / "nada-wordmark.svg").write_text(svg, encoding="utf-8")


def make_monogram_icon() -> None:
    """The compact n! mark, matching the launcher icon."""
    size = 2048
    image = Image.new("RGBA", (size, size), BLACK)
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONT_DISPLAY), int(size * 0.62))
    glyph = "n!"
    left, top, right, bottom = draw.textbbox((0, 0), glyph, font=font)
    width = right - left
    height = bottom - top
    x = (size - width) / 2 - left
    y = (size - height) / 2 - top - size * 0.01
    draw.text((x, y), glyph, font=font, fill=BONE)

    for target in (1024, 512):
        # RGBA with an opaque alpha channel: Google Play's 32-bit PNG spec
        # without actual transparency.
        resized = image.resize((target, target), Image.Resampling.LANCZOS)
        resized.save(BRAND / f"icon-play-{target}.png")


def make_wordmark_icon(transparent: Image.Image) -> None:
    for target in (1024, 512):
        canvas = Image.new("RGBA", (target, target), BLACK)
        mark = fit_width(transparent, int(target * 0.84))
        x = (target - mark.width) // 2
        y = (target - mark.height) // 2
        canvas.alpha_composite(mark, (x, y))
        canvas.save(BRAND / f"icon-wordmark-{target}.png")


def make_feature_graphic(transparent: Image.Image) -> None:
    canvas = Image.new("RGBA", (1024, 500), BLACK)
    mark = fit_width(transparent, 520)
    canvas.alpha_composite(mark, ((1024 - mark.width) // 2, 92))

    tagline = ImageFont.truetype(str(FONT_TEXT_ITALIC), 26)
    url = ImageFont.truetype(str(FONT_TEXT), 15)
    draw_centered(canvas, "el contador de lo que no hiciste", tagline, 318, ASH)
    line = Image.new("RGBA", (420, 1), HAIRLINE)
    canvas.alpha_composite(line, (302, 350))
    draw_centered(canvas, "nada.isdose.com", url, 432, FAINT)

    canvas.convert("RGB").save(STORE / "feature-graphic-1024x500.png")


def make_web_assets(transparent: Image.Image) -> None:
    WEB.mkdir(parents=True, exist_ok=True)

    hero = Image.new("RGBA", (1920, 1080), BLACK)
    mark = fit_width(transparent, 900)
    hero.alpha_composite(mark, ((1920 - mark.width) // 2, 240))
    draw_centered(
        hero,
        "el contador de lo que no hiciste",
        ImageFont.truetype(str(FONT_TEXT_ITALIC), 40),
        700,
        ASH,
    )
    line = Image.new("RGBA", (620, 1), HAIRLINE)
    hero.alpha_composite(line, (650, 760))
    draw_centered(
        hero,
        "nada.isdose.com",
        ImageFont.truetype(str(FONT_TEXT), 22),
        860,
        FAINT,
    )
    hero.convert("RGB").save(WEB / "hero-1920x1080.png")

    og = Image.new("RGBA", (1200, 630), BLACK)
    og_mark = fit_width(transparent, 600)
    og.alpha_composite(og_mark, ((1200 - og_mark.width) // 2, 92))
    draw_centered(
        og,
        "el contador de lo que no hiciste",
        ImageFont.truetype(str(FONT_TEXT_ITALIC), 28),
        372,
        ASH,
    )
    line = Image.new("RGBA", (420, 1), HAIRLINE)
    og.alpha_composite(line, (390, 404))
    draw_centered(
        og,
        "nada.isdose.com",
        ImageFont.truetype(str(FONT_TEXT), 16),
        548,
        FAINT,
    )
    og.convert("RGB").save(WEB / "og-1200x630.png")


def make_store_screenshot(source: Path, out: Path) -> None:
    shot = Image.open(source).convert("RGB")
    shot = shot.resize((864, 1920), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (1080, 1920), BLACK)
    canvas.paste(shot, (108, 0))

    # A hairline frame makes the screenshot read as a phone screen on black.
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((108, 0, 971, 1919), outline=(38, 35, 31))
    canvas.save(out)


def make_store_screenshots() -> None:
    SHOTS.mkdir(parents=True, exist_ok=True)
    mapping = {
        "phone-01-home.png": DOCS / "01-home.png",
        "phone-02-session.png": DOCS / "02-running.png",
        "phone-03-history.png": DOCS / "05-history.png",
        "phone-04-settings.png": DOCS / "06-settings.png",
    }
    for name, source in mapping.items():
        make_store_screenshot(source, SHOTS / name)


def main() -> None:
    source = load_wordmark()
    transparent = transparent_wordmark(source, 60)
    make_wordmark_assets(source)
    make_monogram_icon()
    make_wordmark_icon(transparent)
    make_feature_graphic(transparent)
    make_web_assets(transparent)
    make_store_screenshots()
    print("brand and store assets generated")


if __name__ == "__main__":
    main()
