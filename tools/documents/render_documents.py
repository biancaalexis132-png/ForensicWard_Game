#!/usr/bin/env python3
"""Render paper document images for clues from the project's own data.

Reads a document list (tools/documents/*_documents.json) and data/clues.json,
and draws each listed clue as a sheet of paper: the hospital letterhead, a
form layout, a subtle seeded paper texture, and the clue's authored wording
printed verbatim (title, source, provenance, verification, description).

Nothing is invented. The only extra words are the generic form labels named
in the document list (for example "Date" or a table header), always left
blank. The manifest records exactly which strings came from which field.

Styles:
  form         a modern hospital form (serif letterhead, ruled boxes, stamp)
  typewritten  an older carbon-copy sheet (monospace, warmer, faded)
  printout     a terminal printout (monospace on light green-bar paper)

Only numpy and Pillow are needed. Fonts: DejaVu (Bitstream Vera licence,
free to use) found in the usual Linux and Homebrew locations, or a folder
given with --font-dir. With the same fonts, the same inputs and seed give
byte-identical PNGs:

    python3 tools/documents/render_documents.py tools/documents/ch01_documents.json

Every image is fictional and awaits the owner's review (PENDING_OWNER_REVIEW
in the manifest this script writes).
"""
import argparse
import hashlib
import json
import textwrap
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_DIRS = [
    "/usr/share/fonts/truetype/dejavu",
    "/usr/share/fonts/dejavu",
    "/opt/homebrew/share/fonts",
    "/usr/local/share/fonts",
    str(Path.home() / "Library/Fonts"),
]
FONT_FILES = {
    "serif": "DejaVuSerif.ttf",
    "serif_bold": "DejaVuSerif-Bold.ttf",
    "sans": "DejaVuSans.ttf",
    "sans_bold": "DejaVuSans-Bold.ttf",
    "mono": "DejaVuSansMono.ttf",
    "mono_bold": "DejaVuSansMono-Bold.ttf",
}
INK = (34, 38, 46)
FADED_INK = (70, 66, 60)
RULE = (120, 120, 118)
STAMP = (150, 52, 44)


def find_font(name, extra_dir):
    for folder in ([extra_dir] if extra_dir else []) + FONT_DIRS:
        path = Path(folder) / FONT_FILES[name]
        if path.exists():
            return path
    raise SystemExit("Font %s not found; install DejaVu fonts or pass --font-dir" % FONT_FILES[name])


class Fonts:
    def __init__(self, font_dir):
        self.paths = {name: find_font(name, font_dir) for name in FONT_FILES}

    def get(self, name, size):
        return ImageFont.truetype(str(self.paths[name]), size)


def humanize(value):
    return str(value).replace("_", " ")


def paper(size, rng, base, grain, fibres):
    """Off-white sheet: blurred seeded noise, faint fibres, soft edge shading."""
    width, height = size
    noise = rng.normal(0.0, 1.0, (height, width)).astype(np.float32)
    fine = Image.fromarray(np.clip(noise * 40 + 128, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    coarse = Image.fromarray(np.clip(rng.normal(0, 1, (height // 16, width // 16)) * 40 + 128, 0, 255)
                             .astype(np.uint8)).resize(size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    texture = (np.asarray(fine, np.float32) - 128) / 40 * grain + (np.asarray(coarse, np.float32) - 128) / 40 * grain * 1.6
    yy, xx = np.mgrid[0:height, 0:width].astype(np.float32)
    edge = np.minimum(np.minimum(xx, width - 1 - xx), np.minimum(yy, height - 1 - yy))
    shade = np.clip(1.0 - np.exp(-edge / 60.0), 0, 1) * 0.06 + 0.94
    rgb = np.empty((height, width, 3), np.float32)
    for channel in range(3):
        rgb[..., channel] = (base[channel] + texture) * shade
    image = Image.fromarray(np.clip(rgb + 0.5, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(image)
    for _ in range(fibres):
        x, y = rng.integers(0, width), rng.integers(0, height)
        length, angle = rng.uniform(6, 22), rng.uniform(0, np.pi)
        tone = int(rng.integers(178, 212))
        draw.line([(x, y), (x + length * np.cos(angle), y + length * np.sin(angle))], fill=(tone, tone - 4, tone - 12), width=1)
    return image


def wrap(draw, text, font, max_width):
    """Word-wrap text to max_width pixels."""
    lines = []
    for paragraph in str(text).split("\n"):
        words, line = paragraph.split(), ""
        for word in words:
            candidate = (line + " " + word).strip()
            if draw.textlength(candidate, font=font) <= max_width or not line:
                line = candidate
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines


def letterhead(draw, fonts, spec, width, y, mono=False):
    name = spec["letterhead"]
    font = fonts.get("mono_bold" if mono else "serif_bold", 38)
    text = name.upper()
    draw.text(((width - draw.textlength(text, font=font)) / 2, y), text, font=font, fill=INK)
    y += 54
    draw.line([(70, y), (width - 70, y)], fill=INK, width=3)
    draw.line([(70, y + 6), (width - 70, y + 6)], fill=INK, width=1)
    return y + 24


def field_box(draw, fonts, x, y, w, h, label, value, label_font="sans", value_font="serif"):
    draw.rectangle([x, y, x + w, y + h], outline=RULE, width=1)
    draw.text((x + 10, y + 6), label.upper(), font=fonts.get(label_font, 14), fill=RULE)
    if value:
        draw.text((x + 10, y + 26), value, font=fonts.get(value_font, 22), fill=INK)


def stamp(image, fonts, text, centre, angle):
    font = fonts.get("sans_bold", 24)
    probe = ImageDraw.Draw(image)
    tw = int(probe.textlength(text, font=font)) + 40
    layer = Image.new("RGBA", (tw, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle([2, 2, tw - 3, 61], radius=8, outline=STAMP + (170,), width=4)
    draw.text((20, 16), text, font=font, fill=STAMP + (170,))
    layer = layer.rotate(angle, expand=True, resample=Image.BICUBIC)
    image.paste(layer, (int(centre[0] - layer.width / 2), int(centre[1] - layer.height / 2)), layer)


def verification(clue):
    return "Independently verified" if clue["verified"] else "Not independently verified"


def render_form(spec, doc, clue, fonts, rng):
    width, height = spec["size"]
    image = paper((width, height), rng, (238, 234, 224), 2.2, 70)
    draw = ImageDraw.Draw(image)
    y = letterhead(draw, fonts, spec, width, 70)
    title = clue["title"].upper()
    font = fonts.get("sans_bold", 34)
    draw.text(((width - draw.textlength(title, font=font)) / 2, y + 6), title, font=font, fill=INK)
    y += 70
    left, inner = 70, width - 140
    half = inner // 2
    field_box(draw, fonts, left, y, half, 64, "Source", humanize(clue["source"]))
    field_box(draw, fonts, left + half, y, inner - half, 64, "Provenance", humanize(clue["provenance"]))
    y += 64
    blanks = doc.get("blank_fields", [])
    if blanks:
        each = inner // len(blanks)
        for i, label in enumerate(blanks):
            w = each if i < len(blanks) - 1 else inner - each * (len(blanks) - 1)
            field_box(draw, fonts, left + each * i, y, w, 64, label, "")
        y += 64
    field_box(draw, fonts, left, y, inner, 64, "Verification", verification(clue))
    y += 92
    draw.text((left, y), "SUMMARY", font=fonts.get("sans_bold", 18), fill=RULE)
    y += 30
    body_font = fonts.get("serif", 28)
    box_top = y
    y += 18
    for line in wrap(draw, clue["description"], body_font, inner - 40):
        draw.text((left + 20, y), line, font=body_font, fill=INK)
        y += 42
    box_bottom = max(y + 18, box_top + 420)
    draw.rectangle([left, box_top, left + inner, box_bottom], outline=RULE, width=1)
    for ruled in range(int(y + 24), int(box_bottom) - 10, 42):
        draw.line([(left + 20, ruled), (left + inner - 20, ruled)], fill=(205, 200, 190), width=1)
    if "signed" in clue["provenance"]:
        stamp(image, fonts, humanize(clue["provenance"]).upper(), (width - 290, box_bottom + 110), 6)
    footer(draw, fonts, width, height, "sans")
    return image


def table(draw, fonts, columns, rows, left, top, inner, row_h, font_name, ink):
    widths = [inner * w for w in column_weights(columns)]
    header_font = fonts.get(font_name, 18)
    draw.rectangle([left, top, left + inner, top + row_h * (rows + 1)], outline=ink, width=2)
    x = left
    for i, column in enumerate(columns):
        draw.text((x + 10, top + (row_h - 20) / 2), column.upper(), font=header_font, fill=ink)
        x += widths[i]
        if i < len(columns) - 1:
            draw.line([(x, top), (x, top + row_h * (rows + 1))], fill=ink, width=1)
    for r in range(1, rows + 1):
        draw.line([(left, top + row_h * r), (left + inner, top + row_h * r)], fill=ink, width=2 if r == 1 else 1)
    return top + row_h * (rows + 1)


def column_weights(columns):
    weights = [0.6 if len(c) <= 4 else 1.0 for c in columns]
    total = sum(weights)
    return [w / total for w in weights]


def render_typewritten(spec, doc, clue, fonts, rng):
    width, height = spec["size"]
    image = paper((width, height), rng, (228, 216, 188), 3.4, 120)
    draw = ImageDraw.Draw(image)
    y = letterhead(draw, fonts, spec, width, 70, mono=True)
    font = fonts.get("mono_bold", 32)
    title = clue["title"].upper()
    draw.text(((width - draw.textlength(title, font=font)) / 2, y + 4), title, font=font, fill=FADED_INK)
    y += 66
    small = fonts.get("mono", 21)
    left, inner = 70, width - 140
    for label, value in (("Source", humanize(clue["source"])), ("Provenance", humanize(clue["provenance"])),
                         ("Verification", verification(clue))):
        draw.text((left, y), "%-14s%s" % (label.upper() + ":", value), font=small, fill=FADED_INK)
        y += 32
    y += 20
    y = table(draw, fonts, doc["table_columns"], doc["table_rows"], left, y, inner, 46, "mono_bold", FADED_INK)
    y += 34
    draw.text((left, y), "NOTE:", font=fonts.get("mono_bold", 22), fill=FADED_INK)
    y += 36
    body = fonts.get("mono", 25)
    for line in wrap(draw, clue["description"], body, inner):
        draw.text((left, y), line, font=body, fill=FADED_INK)
        y += 38
    footer(draw, fonts, width, height, "mono")
    # Typewriter ink sits softly on the page: a light blur.
    image = image.filter(ImageFilter.GaussianBlur(0.45))
    return image


def render_printout(spec, doc, clue, fonts, rng):
    width, height = spec["size"]
    image = paper((width, height), rng, (236, 240, 232), 1.8, 40)
    draw = ImageDraw.Draw(image)
    for top in range(0, height, 96):  # Green-bar continuous paper.
        draw.rectangle([46, top, width - 46, top + 47], fill=(214, 230, 212))
    for top in range(30, height, 48):  # Tractor-feed holes.
        for x in (18, width - 18):
            draw.ellipse([x - 7, top - 7, x + 7, top + 7], fill=(205, 205, 200), outline=(170, 170, 165))
    y = letterhead(draw, fonts, spec, width, 70, mono=True)
    font = fonts.get("mono_bold", 32)
    title = clue["title"].upper()
    draw.text(((width - draw.textlength(title, font=font)) / 2, y + 4), title, font=font, fill=INK)
    y += 66
    small = fonts.get("mono", 21)
    left, inner = 80, width - 160
    for label, value in (("Source", humanize(clue["source"])), ("Provenance", humanize(clue["provenance"])),
                         ("Verification", verification(clue))):
        draw.text((left, y), "%-14s%s" % (label.upper() + ":", value), font=small, fill=INK)
        y += 32
    y += 20
    y = table(draw, fonts, doc["table_columns"], doc["table_rows"], left, y, inner, 46, "mono_bold", INK)
    y += 34
    body = fonts.get("mono", 25)
    lines = wrap(draw, "* " + clue["description"], body, inner)
    for line in lines:
        draw.text((left, y), line, font=body, fill=INK)
        y += 38
    footer(draw, fonts, width, height, "mono")
    return image


def footer(draw, fonts, width, height, family):
    font = fonts.get(family, 16)
    text = "Page 1 of 1"
    draw.text(((width - draw.textlength(text, font=font)) / 2, height - 60), text, font=font, fill=RULE)


RENDERERS = {"form": render_form, "typewritten": render_typewritten, "printout": render_printout}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("spec", type=Path)
    parser.add_argument("--font-dir", default="")
    args = parser.parse_args()
    spec = json.loads(args.spec.read_text())
    clues = {c["id"]: c for c in json.loads((ROOT / "data/clues.json").read_text())["clues"]}
    fonts = Fonts(args.font_dir)
    out_dir = ROOT / spec["output_dir"]
    out_dir.mkdir(parents=True, exist_ok=True)
    entries = {}
    for index, doc in enumerate(spec["documents"]):
        clue = clues[doc["clue_id"]]
        rng = np.random.default_rng(spec["seed"] + index)
        image = RENDERERS[doc["style"]](spec, doc, clue, fonts, rng)
        path = out_dir / (doc["clue_id"] + ".png")
        image.save(path, optimize=True)
        data = path.read_bytes()
        rel = path.relative_to(ROOT).as_posix()
        generic = list(doc.get("blank_fields", [])) + list(doc.get("table_columns", [])) + ["Summary", "Note", "Page 1 of 1"]
        entries[doc["clue_id"]] = {
            "file": rel,
            "res_path": "res://" + rel,
            "clue_id": doc["clue_id"],
            "chapter": spec["chapter"],
            "style": doc["style"],
            "size_px": list(image.size),
            "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "fictional": True,
            "text_sources": {
                "letterhead": "fixed hospital name (Ashcroft State Forensic Hospital)",
                "title": "data/clues.json %s.title (verbatim, upper-cased)" % doc["clue_id"],
                "source": "data/clues.json %s.source" % doc["clue_id"],
                "provenance": "data/clues.json %s.provenance" % doc["clue_id"],
                "verification": "data/clues.json %s.verified, worded as in ClueText" % doc["clue_id"],
                "body": "data/clues.json %s.description (verbatim)" % doc["clue_id"],
            },
            "generic_form_labels": generic,
            "generic_form_labels_note": "Layout labels only, left blank; they state no clinical or story fact.",
            "provenance": {
                "source": "Original procedural render; no third-party image",
                "tool": "tools/documents/render_documents.py (Pillow %s, numpy %s)" % (Image.__version__, np.__version__),
                "spec": args.spec.resolve().relative_to(ROOT).as_posix(),
                "seed": spec["seed"] + index,
                "fonts": "DejaVu Serif/Sans/Sans Mono (Bitstream Vera derivative licence, free use)",
                "licence": "Project-original",
            },
            "review_status": "PENDING_OWNER_REVIEW",
        }
        print("wrote %s (%d bytes)" % (rel, len(data)))
    manifest = {
        "schema_version": "0.1",
        "_note": "Fictional paper-document images shown by the document viewer (InfoPanel) for clues. Generated by tools/documents/render_documents.py; regenerate rather than edit. All wording comes from data/clues.json except the generic form labels listed per entry.",
        "documents": entries,
    }
    manifest_path = ROOT / spec["manifest"]
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print("wrote %s" % manifest_path.relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
