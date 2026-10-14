"""Builds the minus-sign fonts: Figtree's plus without its vertical bar, mapped to U+2212.

    pip install fonttools brotli
    python dev/fonts/build_minus.py priv/static/fonts
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import GlyphCoordinates


def build(source, target, style):
    font = TTFont(source, recalcTimestamp=False)
    options = subset.Options()
    options.layout_features = []
    options.name_IDs = []
    options.notdef_outline = False
    options.glyph_names = False
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[0x2B])
    subsetter.subset(font)

    glyph_name = font.getBestCmap()[0x2B]
    glyph = font["glyf"][glyph_name]
    ends = list(glyph.endPtsOfContours)
    coords = list(glyph.coordinates)
    bars = [coords[start : end + 1] for start, end in zip([0] + [e + 1 for e in ends[:-1]], ends)]
    keep = next(i for i, bar in enumerate(bars) if span(bar, 0) > span(bar, 1))
    start = 0 if keep == 0 else ends[keep - 1] + 1
    end = ends[keep]
    glyph.coordinates = GlyphCoordinates(coords[start : end + 1])
    glyph.flags = glyph.flags[start : end + 1]
    glyph.endPtsOfContours = [end - start]
    glyph.numberOfContours = 1
    glyph.recalcBounds(font["glyf"])

    phantom = len(coords)
    for variation in font["gvar"].variations[glyph_name]:
        deltas = variation.coordinates
        variation.coordinates = deltas[start : end + 1] + deltas[phantom : phantom + 4]

    for table in font["cmap"].tables:
        table.cmap = {0x2212: glyph_name}

    family = "Setzkasten Minus"
    name = font["name"]
    name.names = []
    name.setName(TTFont(source)["name"].getDebugName(0), 0, 3, 1, 0x409)
    name.setName(family, 1, 3, 1, 0x409)
    name.setName(style, 2, 3, 1, 0x409)
    name.setName(f"{family} {style}", 4, 3, 1, 0x409)
    name.setName(f"SetzkastenMinus-{style}", 6, 3, 1, 0x409)
    name.setName("Derived from Figtree (SIL OFL 1.1): its plus sign without the vertical bar.", 10, 3, 1, 0x409)
    name.setName("SIL Open Font License 1.1", 13, 3, 1, 0x409)
    name.setName("https://openfontlicense.org", 14, 3, 1, 0x409)
    for axis in font["fvar"].axes:
        axis.axisNameID = 256
    name.setName("Weight", 256, 3, 1, 0x409)
    for instance in font["fvar"].instances:
        instance.subfamilyNameID = 2
        instance.postscriptNameID = 0xFFFF
    if "STAT" in font:
        del font["STAT"]

    font.flavor = "woff2"
    font.save(target)


def span(points, axis):
    values = [point[axis] for point in points]
    return max(values) - min(values)


fonts = Path(sys.argv[1])
build(fonts / "Figtree-Variable.woff2", fonts / "SetzkastenMinus-Variable.woff2", "Regular")
build(fonts / "Figtree-Italic-Variable.woff2", fonts / "SetzkastenMinus-Italic-Variable.woff2", "Italic")
