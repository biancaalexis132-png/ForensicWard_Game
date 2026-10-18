#!/usr/bin/env python3
"""Paint graphic-novel cutscene plates from the project's own renders.

Reads a plate list (tools/cutscenes/*_plates.json), crops each source render
(Blender environment renders or in-game captures already in this repository),
and repaints it in the locked "cinematic painted graphic novel" look:

  1. Kuwahara smoothing (flat painted shapes, edges kept).
  2. Brush-direction texture and paper grain (seeded, deterministic).
  3. Ink line pass from luminance edges.
  4. Grade: desaturated slate/navy shadows, ivory highlights, warm hues kept
     as restrained amber. Character plates may blend back part of the graded,
     unpainted render ("preserve") so faces keep their modelled features.
  5. Soft vignette.

It also writes one shared RGBA "glaze" layer (brush streaks and light haze) that the
CutsceneDirector moves at a different parallax rate over each plate.

Only numpy and Pillow are needed. Same inputs and seed give byte-identical
PNGs, so the plates can be regenerated on the Mac:

    python3 tools/cutscenes/paint_panels.py tools/cutscenes/ch01_pilot_plates.json

Every plate is review-only until the owner approves it (see the manifest this
script writes next to the plates).
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]

# Locked palette (cinematic bible): slate/navy shadows, ivory highlights, amber accent.
SHADOW = np.array([0.075, 0.095, 0.140])
MIDTONE = np.array([0.36, 0.40, 0.45])
HIGHLIGHT = np.array([0.95, 0.925, 0.86])
AMBER = np.array([0.85, 0.60, 0.30])
INK = np.array([0.055, 0.065, 0.085])


def to_float(image):
    return np.asarray(image.convert("RGB"), dtype=np.float32) / 255.0


def to_image(array):
    return Image.fromarray(np.clip(array * 255.0 + 0.5, 0, 255).astype(np.uint8))


def box_mean(values, radius):
    """Mean over a (radius+1)^2 window anchored at each corner quadrant, via integral images."""
    padded = np.pad(values, ((radius, radius), (radius, radius)) + ((0, 0),) * (values.ndim - 2), mode="edge")
    integral = np.cumsum(np.cumsum(padded, axis=0), axis=1)
    integral = np.pad(integral, ((1, 0), (1, 0)) + ((0, 0),) * (values.ndim - 2))
    height, width = values.shape[:2]
    size = radius + 1
    quadrants = []
    for dy in (0, radius):
        for dx in (0, radius):
            y0, x0 = dy, dx
            total = (integral[y0 + size:y0 + size + height, x0 + size:x0 + size + width]
                     - integral[y0:y0 + height, x0 + size:x0 + size + width]
                     - integral[y0 + size:y0 + size + height, x0:x0 + width]
                     + integral[y0:y0 + height, x0:x0 + width])
            quadrants.append(total / float(size * size))
    return quadrants


def kuwahara(rgb, radius):
    """Classic four-quadrant Kuwahara filter: each pixel takes the mean of its calmest quadrant."""
    luma = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    means = box_mean(rgb, radius)
    luma_means = box_mean(luma, radius)
    luma_sq_means = box_mean(luma * luma, radius)
    variances = np.stack([sq - m * m for sq, m in zip(luma_sq_means, luma_means)])
    best = np.argmin(variances, axis=0)
    stacked = np.stack(means)
    return np.take_along_axis(stacked, best[None, :, :, None], axis=0)[0]


def blur(array, radius):
    if array.ndim == 2:
        return np.asarray(to_image(np.repeat(array[:, :, None], 3, axis=2)).filter(
            ImageFilter.GaussianBlur(radius)), dtype=np.float32)[:, :, 0] / 255.0
    return to_float(to_image(array).filter(ImageFilter.GaussianBlur(radius)))


def ink_lines(rgb, strength, threshold):
    luma = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    soft = blur(luma, 1.2)
    gy, gx = np.gradient(soft)
    magnitude = np.sqrt(gx * gx + gy * gy)
    edges = np.clip((magnitude - threshold) / (threshold * 2.5), 0.0, 1.0)
    edges = blur(edges, 0.8)
    return edges * strength


def brush_texture(shape, rng, angle_degrees, scale):
    """Directional streaks: noise smeared along one angle, normalised to -1..1."""
    height, width = shape
    noise = rng.random((height // 2 + 1, width // 2 + 1)).astype(np.float32)
    image = to_image(np.repeat(noise[:, :, None], 3, axis=2)).resize((width, height), Image.BILINEAR)
    image = image.rotate(angle_degrees, resample=Image.BILINEAR, expand=False)
    streaked = image.filter(ImageFilter.BoxBlur(scale)).resize((width, height))
    values = np.asarray(streaked, dtype=np.float32)[:, :, 0] / 255.0
    values = values - values.mean()
    return values / (np.abs(values).max() + 1e-6)


def grade(rgb, warmth):
    luma = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    saturation = (maximum - minimum) / (maximum + 1e-6)
    # Warm hues (red > green > blue) stay as amber; everything else goes to slate/ivory.
    warm = np.clip((rgb[:, :, 0] - rgb[:, :, 2]) * 3.0, 0.0, 1.0) * np.clip(saturation * 2.0, 0.0, 1.0) * warmth
    tone = np.clip((luma - 0.08) / 0.84, 0.0, 1.0)
    tone = tone * tone * (3.0 - 2.0 * tone) * 0.55 + tone * 0.45  # gentle S-curve
    lower = SHADOW[None, None, :] * (1.0 - np.clip(tone * 2.0, 0, 1))[:, :, None] \
        + MIDTONE[None, None, :] * np.clip(tone * 2.0, 0, 1)[:, :, None]
    upper = MIDTONE[None, None, :] * (1.0 - np.clip(tone * 2.0 - 1.0, 0, 1))[:, :, None] \
        + HIGHLIGHT[None, None, :] * np.clip(tone * 2.0 - 1.0, 0, 1)[:, :, None]
    palette = np.where((tone < 0.5)[:, :, None], lower, upper)
    # Keep some of the source colour so materials (green dado, wood) still read.
    graded = palette * 0.62 + rgb * 0.38
    graded = graded * (1.0 - 0.25 * saturation[:, :, None]) + luma[:, :, None] * 0.25 * saturation[:, :, None]
    amber = AMBER[None, None, :] * (0.55 + 0.6 * tone[:, :, None])
    return graded * (1.0 - warm[:, :, None] * 0.55) + amber * warm[:, :, None] * 0.55


def vignette(shape, amount):
    height, width = shape
    y = np.linspace(-1.0, 1.0, height)[:, None]
    x = np.linspace(-1.0, 1.0, width)[None, :]
    distance = np.sqrt((x * 0.85) ** 2 + y ** 2)
    return 1.0 - amount * np.clip((distance - 0.55) / 0.75, 0.0, 1.0) ** 1.6


def paint(source, plate, size, seed):
    image = Image.open(source).convert("RGB")
    crop = plate.get("crop")
    if crop:
        x, y, w, h = crop
        image = image.crop((x, y, x + w, y + h))
    image = image.resize(size, Image.LANCZOS)
    rgb = to_float(image)
    rng = np.random.default_rng(seed)
    radius = int(plate.get("brush_radius", 5))
    painted = kuwahara(rgb, radius)
    painted = kuwahara(painted, max(2, radius // 2))
    strokes = brush_texture(size[::-1], rng, float(plate.get("brush_angle", 28.0)), 6)
    painted = painted * (1.0 + 0.045 * strokes[:, :, None])
    painted = grade(painted, float(plate.get("warmth", 0.8)))
    # Character plates keep part of the unpainted render so faces are not smeared.
    preserve = float(plate.get("preserve", 0.0))
    if preserve > 0.0:
        painted = painted * (1.0 - preserve) + grade(rgb, float(plate.get("warmth", 0.8))) * preserve
    edges = ink_lines(rgb, float(plate.get("ink", 0.7)), 0.012)
    painted = painted * (1.0 - edges[:, :, None]) + INK[None, None, :] * edges[:, :, None]
    grain = rng.normal(0.0, 1.0, size[::-1]).astype(np.float32)
    grain = blur(np.clip(grain * 0.15 + 0.5, 0, 1), 0.6) - 0.5
    painted = painted * (1.0 + 0.06 * grain[:, :, None])
    painted = painted * vignette(size[::-1], float(plate.get("vignette", 0.35)))[:, :, None]
    return to_image(np.clip(painted, 0.0, 1.0))


def glaze(size, seed):
    """Shared foreground layer: brush-streak glaze and a soft top-light haze, mostly transparent."""
    width, height = size
    rng = np.random.default_rng(seed)
    alpha = np.zeros((height, width), dtype=np.float32)
    haze = np.linspace(0.10, 0.0, height, dtype=np.float32)[:, None] * np.ones((1, width), dtype=np.float32)
    alpha += haze
    streaks = brush_texture((height, width), rng, 28.0, 10)
    alpha += np.clip(streaks, 0.0, 1.0) * 0.05
    alpha = np.clip(alpha, 0.0, 0.35)
    rgba = np.zeros((height, width, 4), dtype=np.float32)
    rgba[:, :, :3] = HIGHLIGHT[None, None, :]
    rgba[:, :, 3] = alpha
    return Image.fromarray(np.clip(rgba * 255.0 + 0.5, 0, 255).astype(np.uint8), "RGBA")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("plates", type=Path, help="plate list JSON")
    parser.add_argument("--only", help="comma-separated plate ids to repaint")
    args = parser.parse_args()
    spec = json.loads(args.plates.read_text(encoding="utf-8"))
    out_dir = ROOT / spec["output_dir"]
    out_dir.mkdir(parents=True, exist_ok=True)
    size = tuple(spec["size"])
    only = set(args.only.split(",")) if args.only else None
    manifest = {
        "schema_version": 1,
        "_note": "Generated by tools/cutscenes/paint_panels.py from %s. Do not edit by hand." % args.plates.as_posix(),
        "review_status": "UNAPPROVED_REVIEW_ONLY",
        "licence": "Original project work: repainted from this repository's own Blender renders and in-game captures.",
        "tool": "tools/cutscenes/paint_panels.py (numpy, Pillow)",
        "assets": [],
    }
    for index, plate in enumerate(spec["plates"]):
        target = out_dir / f"{plate['id']}.png"
        if only is None or plate["id"] in only:
            paint(ROOT / plate["source"], plate, size, spec["seed"] + index).save(target, optimize=True)
            print(f"painted {target.relative_to(ROOT)}")
        manifest["assets"].append({
            "path": target.relative_to(ROOT).as_posix(),
            "source": plate["source"],
            "crop": plate.get("crop"),
            "settings": {k: plate[k] for k in ("brush_radius", "brush_angle", "warmth", "ink", "vignette", "preserve") if k in plate},
            "seed": spec["seed"] + index,
            "depicts": plate["depicts"],
            "likeness_review": plate.get("likeness_review", "none"),
        })
    glaze_path = out_dir / "glaze.png"
    glaze(size, spec["seed"] + 1000).save(glaze_path, optimize=True)
    manifest["assets"].append({"path": glaze_path.relative_to(ROOT).as_posix(), "source": "procedural",
                               "seed": spec["seed"] + 1000, "depicts": "shared brush-streak and haze overlay"})
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {(out_dir / 'manifest.json').relative_to(ROOT)}")


if __name__ == "__main__":
    main()
