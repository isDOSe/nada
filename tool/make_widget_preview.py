"""Generate the widget preview image used by older launchers and store art."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT_DISPLAY = ROOT / "assets" / "fonts" / "InstrumentSerif-Regular.ttf"
FONT_TEXT = ROOT / "assets" / "fonts" / "CrimsonText-Regular.ttf"
FONT_TEXT_SEMI = ROOT / "assets" / "fonts" / "CrimsonText-SemiBold.ttf"

DARK = (0, 0, 0, 255)
LIGHT = (242, 239, 230, 255)
BONE = (242, 239, 230, 255)
ASH = (166, 160, 150, 255)
INK = (10, 10, 10, 255)
LIGHT_ASH = (74, 69, 61, 255)
HAIRLINE = (38, 35, 31, 255)
LIGHT_EDGE = (216, 211, 200, 255)


def make(theme: str, out: Path) -> None:
    light = theme == "light"
    bg = LIGHT if light else DARK
    primary = INK if light else BONE
    secondary = LIGHT_ASH if light else ASH
    edge = LIGHT_EDGE if light else HAIRLINE

    size = 512
    image = Image.new("RGBA", (size, size), bg)
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 1, size - 2, size - 2), outline=edge, width=2)

    padding = 44
    wordmark = ImageFont.truetype(str(FONT_TEXT_SEMI), 44)
    phrase = ImageFont.truetype(str(FONT_TEXT), 36)
    time_font = ImageFont.truetype(str(FONT_DISPLAY), 122)
    sessions = ImageFont.truetype(str(FONT_TEXT), 34)

    draw.text((padding, 46), "nada!", font=wordmark, fill=primary)
    draw.multiline_text(
        (padding, 182),
        "Has hecho nada\ndurante",
        font=phrase,
        fill=secondary,
        spacing=6,
    )
    draw.text((padding, 278), "3 h 12 min", font=time_font, fill=primary)
    draw.text((padding, 430), "9 sesiones", font=sessions, fill=secondary)

    out.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(out)


def main() -> None:
    make("dark", ROOT / "android/app/src/main/res/drawable-nodpi/widget_preview.png")
    make("dark", ROOT / "store/brand/widget-dark.png")
    make("light", ROOT / "store/brand/widget-light.png")
    print("widget previews generated")


if __name__ == "__main__":
    main()
