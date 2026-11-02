"""Generate nada!'s web favicon from the bundled display serif.

The mark is the same `n!` as the app launcher: bone ink on a black square. The
glyph is drawn larger than in the launcher so it survives a 16 px browser tab,
and the SVG keeps it crisp at any density.

    python web/tool/make_favicon.py

Requires Pillow and fontTools (`pip install pillow fonttools`).
"""

from io import BytesIO
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "fonts" / "InstrumentSerif-Italic.ttf"
SVG_OUT = ROOT / "favicon.svg"
ICO_OUT = ROOT / "favicon.ico"
TOUCH_OUT = ROOT / "images" / "apple-touch-icon.png"

BONE = (242, 239, 230, 255)
VOID = (0, 0, 0, 255)
GLYPH = "n!"
RATIO = 0.86
TOUCH_RATIO = 0.70
LIFT = 0.01
SS = 16


def raster(size: int, ratio: float) -> Image.Image:
    canvas = Image.new("RGBA", (size * SS, size * SS), VOID)
    face = ImageFont.truetype(str(FONT), size=int(size * SS * ratio))
    draw = ImageDraw.Draw(canvas)
    box = draw.textbbox((0, 0), GLYPH, font=face)
    x = (size * SS - (box[2] - box[0])) / 2 - box[0]
    y = (size * SS - (box[3] - box[1])) / 2 - box[1] - size * SS * LIFT
    draw.text((x, y), GLYPH, font=face, fill=BONE)
    return canvas.resize((size, size), Image.LANCZOS)


def build_svg() -> str:
    size = 64
    unit = size * RATIO
    font = TTFont(str(FONT))
    upm = font["head"].unitsPerEm
    scale = unit / upm
    cmap = font.getBestCmap()
    glyphs = font.getGlyphSet()

    items = []
    pen_x = 0
    for char in GLYPH:
        name = cmap[ord(char)]
        bounds = BoundsPen(glyphs)
        glyphs[name].draw(bounds)
        x_min, y_min, x_max, y_max = bounds.bounds
        pen = SVGPathPen(glyphs, ntos=lambda value: f"{value:.2f}")
        glyphs[name].draw(pen)
        items.append(
            {
                "path": pen.getCommands(),
                "pen_x": pen_x,
                "x0": (pen_x + x_min) * scale,
                "x1": (pen_x + x_max) * scale,
                "y0": -y_max * scale,
                "y1": -y_min * scale,
            }
        )
        pen_x += font["hmtx"][name][0]

    left = min(item["x0"] for item in items)
    right = max(item["x1"] for item in items)
    top = min(item["y0"] for item in items)
    bottom = max(item["y1"] for item in items)
    dx = size / 2 - (left + right) / 2
    baseline = size / 2 - size * LIFT - (top + bottom) / 2

    paths = "\n".join(
        f'    <path d="{item["path"]}" transform="translate({dx + item["pen_x"] * scale:.2f} '
        f'{baseline:.2f}) scale({scale:.4f} {-scale:.4f})"/>'
        for item in items
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" '
        'width="64" height="64" role="img" aria-label="nada!">\n'
        '  <rect width="64" height="64" fill="#000"/>\n'
        '  <g fill="#f2efe6">\n'
        f"{paths}\n"
        "  </g>\n"
        "</svg>\n"
    )


def build_ico() -> bytes:
    frames = []
    for size in (16, 32, 48):
        buffer = BytesIO()
        raster(size, RATIO).save(buffer, format="PNG", optimize=True)
        frames.append((size, buffer.getvalue()))

    header = bytearray()
    header += (0).to_bytes(2, "little")  # reserved
    header += (1).to_bytes(2, "little")  # type: icon
    header += len(frames).to_bytes(2, "little")
    offset = 6 + 16 * len(frames)
    entries = bytearray()
    for size, data in frames:
        entries += bytes([size, size, 0, 0])
        entries += (1).to_bytes(2, "little")
        entries += (32).to_bytes(2, "little")
        entries += len(data).to_bytes(4, "little")
        entries += offset.to_bytes(4, "little")
        offset += len(data)
    return bytes(header + entries + b"".join(data for _, data in frames))


def main() -> None:
    SVG_OUT.write_text(build_svg(), encoding="utf-8", newline="\n")
    ICO_OUT.write_bytes(build_ico())
    raster(180, TOUCH_RATIO).save(TOUCH_OUT, format="PNG", optimize=True)
    print(f"favicon.svg, favicon.ico and {TOUCH_OUT.name} generated")


if __name__ == "__main__":
    main()
