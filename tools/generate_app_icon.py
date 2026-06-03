"""Generate the master 1024x1024 app icon.

Composition:
  - Dark surface background (#1A1A1A) matching AppColors.surface
  - 1x1 brick (3005.png) from test data, white background keyed out
  - Material-style outlined shopping cart below in app accent orange (#FF6700)

Run from repo root:
  python3 tools/generate_app_icon.py
Output: assets/branding/app_icon_1024.png
"""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
BRICK_PATH = REPO / "assets" / "parts_1" / "3005.png"
OUT_DIR = REPO / "assets" / "branding"
OUT_PATH = OUT_DIR / "app_icon_1024.png"

SIZE = 1024
BG = (0x1A, 0x1A, 0x1A, 255)        # AppColors.surface
ORANGE = (0xFF, 0x67, 0x00, 255)    # AppColors.highlightColor


def load_brick_transparent() -> Image.Image:
    """Load 3005.png and key the pure-white background to transparent.

    Floodfill from every corner so only the connected background is keyed —
    avoids haloing on antialiased edges that a simple white-threshold produces.
    """
    rgb = Image.open(BRICK_PATH).convert("RGB").copy()
    sentinel = (1, 2, 3)  # an unused color
    for corner in ((0, 0), (rgb.width - 1, 0), (0, rgb.height - 1), (rgb.width - 1, rgb.height - 1)):
        ImageDraw.floodfill(rgb, corner, sentinel, thresh=40)

    arr = np.array(rgb)
    bg_mask = (arr[:, :, 0] == sentinel[0]) & (arr[:, :, 1] == sentinel[1]) & (arr[:, :, 2] == sentinel[2])

    orig = np.array(Image.open(BRICK_PATH).convert("RGB"))
    out = np.zeros((arr.shape[0], arr.shape[1], 4), dtype=np.uint8)
    out[:, :, :3] = orig
    out[:, :, 3] = np.where(bg_mask, 0, 255)

    im = Image.fromarray(out, "RGBA")
    # Soften the hard mask edge by ~1px so resizing doesn't expose jaggies.
    alpha = im.split()[3].filter(ImageFilter.GaussianBlur(0.8))
    im.putalpha(alpha)
    return im


def draw_cart(canvas: Image.Image, cx: int, cy: int, width: int, color):
    """Draw an outlined shopping cart, centered on (cx, cy) with the given width."""
    # Local 460 x 340 design space, rounded-cap stroked.
    LW, LH = 460, 340
    scale = width / LW
    stroke = max(6, int(34 * scale))

    # Work on an oversized layer for clean rounded caps via dots-at-endpoints trick.
    layer = Image.new("RGBA", (int(LW * scale) + stroke * 2, int(LH * scale) + stroke * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    pad = stroke  # offset so strokes don't clip
    def p(x, y):
        return (int(x * scale) + pad, int(y * scale) + pad)

    # Geometry in local coords
    handle_tip = (10, 30)
    handle_attach = (110, 30)
    basket_tl = (150, 110)
    basket_tr = (430, 110)
    basket_br = (370, 250)
    basket_bl = (170, 250)
    wheel_l = (210, 295)
    wheel_r = (350, 295)
    wheel_r_px = max(4, int(28 * scale))

    segments = [
        (handle_tip, handle_attach),
        (handle_attach, basket_tl),
        (basket_tl, basket_tr),
        (basket_tr, basket_br),
        (basket_br, basket_bl),
        (basket_bl, basket_tl),
    ]
    for a, b in segments:
        d.line([p(*a), p(*b)], fill=color, width=stroke)
    # Rounded caps + joins: drop filled discs at every vertex.
    cap_r = stroke // 2
    for v in (handle_tip, handle_attach, basket_tl, basket_tr, basket_br, basket_bl):
        x, y = p(*v)
        d.ellipse((x - cap_r, y - cap_r, x + cap_r, y + cap_r), fill=color)

    # Wheels (filled discs)
    for wx, wy in (wheel_l, wheel_r):
        x, y = p(wx, wy)
        d.ellipse((x - wheel_r_px, y - wheel_r_px, x + wheel_r_px, y + wheel_r_px), fill=color)

    # Paste centered.
    lw, lh = layer.size
    canvas.alpha_composite(layer, (cx - lw // 2, cy - lh // 2))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    canvas = Image.new("RGBA", (SIZE, SIZE), BG)

    # --- Brick (upper portion) ---
    brick = load_brick_transparent()
    target_brick_w = 500
    bw, bh = brick.size
    brick = brick.resize(
        (target_brick_w, int(bh * target_brick_w / bw)),
        Image.LANCZOS,
    )

    # Soft contact shadow under the brick to anchor it visually.
    shadow_w = int(target_brick_w * 0.72)
    shadow_h = int(target_brick_w * 0.12)
    shadow = Image.new("RGBA", (shadow_w + 80, shadow_h + 80), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((40, 40, 40 + shadow_w, 40 + shadow_h), fill=(0, 0, 0, 140))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))

    brick_cx = SIZE // 2
    brick_top = 110
    brick_x = brick_cx - brick.width // 2
    shadow_y = brick_top + brick.height - 40
    canvas.alpha_composite(shadow, (brick_cx - shadow.width // 2, shadow_y))
    canvas.alpha_composite(brick, (brick_x, brick_top))

    # --- Cart (lower portion) ---
    cart_cx = SIZE // 2
    cart_cy = 760
    draw_cart(canvas, cart_cx, cart_cy, width=520, color=ORANGE)

    canvas.convert("RGB").save(OUT_PATH, "PNG", optimize=True)
    print(f"wrote {OUT_PATH}  ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
