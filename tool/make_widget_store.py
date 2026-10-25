"""Compose the Play Store screenshot for the 2x2 home-screen widget."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs" / "screenshots"
OUT = ROOT / "store" / "screenshots" / "phone-05-widget.png"

FONT_DISPLAY = ROOT / "assets" / "fonts" / "InstrumentSerif-Regular.ttf"
FONT_TEXT = ROOT / "assets" / "fonts" / "CrimsonText-Regular.ttf"
FONT_TEXT_ITALIC = ROOT / "assets" / "fonts" / "CrimsonText-Italic.ttf"

BLACK = (0, 0, 0, 255)
BONE = (242, 239, 230, 255)
ASH = (166, 160, 150, 255)
EDGE = (74, 69, 61, 255)
HAIRLINE = (38, 35, 31, 255)

def rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1), radius=radius, fill=255
    )
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def widget_card(theme: str) -> Image.Image:
    # Clean preview art. The live widget screenshots (docs 10/11) keep the
    # launcher wallpaper around the corners, which looks like a blue halo in a
    # store asset; these previews are the intended widget design.
    source = ROOT / "store" / "brand" / f"widget-{theme}.png"
    card = Image.open(source).convert("RGB")
    card = rounded(card, 36)
    return card.resize((380, 380), Image.Resampling.LANCZOS)


def main() -> None:
    canvas = Image.new("RGBA", (1080, 1920), BLACK)
    draw = ImageDraw.Draw(canvas)

    label = ImageFont.truetype(str(FONT_TEXT), 28)
    title = ImageFont.truetype(str(FONT_DISPLAY), 82)
    subtitle = ImageFont.truetype(str(FONT_TEXT_ITALIC), 34)
    theme_font = ImageFont.truetype(str(FONT_TEXT), 28)
    url_font = ImageFont.truetype(str(FONT_TEXT), 20)

    draw.text((540, 118), "widget 2×2", font=label, fill=ASH, anchor="mm")
    draw.text((540, 215), "tu nada,", font=title, fill=BONE, anchor="mm")
    draw.text(
        (540, 292),
        "también en la pantalla de inicio",
        font=subtitle,
        fill=ASH,
        anchor="mm",
    )

    dark = widget_card("dark")
    light = widget_card("light")
    gap = 40
    total_width = dark.width + light.width + gap
    left = (1080 - total_width) // 2
    top = 420

    for index, (card, name) in enumerate(((dark, "negro"), (light, "blanco"))):
        x = left + index * (card.width + gap)
        canvas.alpha_composite(card, (x, top))
        draw.rounded_rectangle(
            (x, top, x + card.width - 1, top + card.height - 1),
            radius=42,
            outline=EDGE,
            width=2,
        )
        draw.text(
            (x + card.width // 2, top + card.height + 42),
            name,
            font=theme_font,
            fill=ASH,
            anchor="mm",
        )

    line_y = 950
    draw.line((270, line_y, 810, line_y), fill=HAIRLINE, width=2)
    draw.text(
        (540, 1035),
        "negro o blanco. tú eliges.",
        font=subtitle,
        fill=BONE,
        anchor="mm",
    )
    draw.text(
        (540, 1110),
        "se actualiza cuando terminas de no hacer nada.",
        font=label,
        fill=ASH,
        anchor="mm",
    )
    draw.text(
        (540, 1530),
        "nada.isdose.com",
        font=url_font,
        fill=(123, 118, 108, 255),
        anchor="mm",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT)
    print(OUT, OUT.stat().st_size)


if __name__ == "__main__":
    main()
