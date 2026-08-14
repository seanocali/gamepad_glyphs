"""Convert the original private-use controller font glyphs to SVG assets."""

from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parents[1]
FONT_ASSETS = ROOT / "assets" / "fonts"
OUTPUT_ROOT = ROOT / "assets" / "input_prompt" / "Monochrome"
FIRST_PRIVATE_USE_CHARACTER = 0xE800
LAST_INPUT_INDEX = 51
CANVAS_SIZE = 100
PADDING = 5


def convert_font(font_name: str, output_name: str) -> None:
    font = TTFont(str(FONT_ASSETS / font_name))
    glyph_set = font.getGlyphSet()
    cmap = {}
    for table in font["cmap"].tables:
        cmap.update(table.cmap)

    units_per_em = font["head"].unitsPerEm
    output_dir = OUTPUT_ROOT / output_name
    output_dir.mkdir(parents=True, exist_ok=True)

    for index in range(LAST_INPUT_INDEX + 1):
        character = FIRST_PRIVATE_USE_CHARACTER + index
        glyph_name = cmap[character]

        bounds_pen = BoundsPen(glyph_set)
        glyph_set[glyph_name].draw(bounds_pen)
        if bounds_pen.bounds is None:
            raise ValueError(f"Glyph {glyph_name} has no outline")

        x_min, y_min, x_max, y_max = bounds_pen.bounds
        width = x_max - x_min
        height = y_max - y_min
        scale = min(
            (CANVAS_SIZE - 2 * PADDING) / width,
            (CANVAS_SIZE - 2 * PADDING) / height,
        )
        translate_x = PADDING - scale * x_min
        translate_y = PADDING + scale * y_max

        path_pen = SVGPathPen(glyph_set)
        glyph_set[glyph_name].draw(path_pen)
        path = path_pen.getCommands()

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS_SIZE} {CANVAS_SIZE}">
  <path fill="#000000" transform="translate({translate_x:.6f} {translate_y:.6f}) scale({scale:.6f} -{scale:.6f})" d="{path}"/>
</svg>
'''
        (output_dir / f"{index}.svg").write_text(svg, encoding="utf-8")


if __name__ == "__main__":
    convert_font("xboxone.ttf", "Xbox")
    convert_font("ps4.ttf", "PlayStation")
