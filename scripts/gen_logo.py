#!/usr/bin/env python3
"""Generate the Brick Collector "Collection Grid" logo.

The mark is an ascending staircase of stylized, stud-free bricks in the brand
orange on the app's dark ground — deliberately NOT a realistic LEGO brick or the
LEGO wordmark (trademark-safe).

Emits vector SVG masters into assets/branding/ and rasterizes them (via
rsvg-convert) to the PNGs that flutter_launcher_icons consumes:
  - app_icon_1024.png       full-bleed (dark ground + grid)  -> iOS/macOS/web/windows
  - app_icon_foreground.png transparent grid, sits in the adaptive safe zone -> Android fg
  - app_icon_background.png dark gradient, full-bleed          -> Android bg

Usage:
  python3 scripts/gen_logo.py        # regenerate art
  dart run flutter_launcher_icons    # then re-slice per-platform icons

Requires: rsvg-convert (brew install librsvg).
"""
import os
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BR = os.path.join(REPO, "assets", "branding")
ORANGE = "#FF6700"
CANVAS = 1024
N = 4              # 4x4 grid
GAP_RATIO = 0.22   # gap relative to module size


def cells(span_frac):
    grid_w = CANVAS * span_frac
    m = grid_w / (N + (N - 1) * GAP_RATIO)      # grid_w = N*m + (N-1)*gap
    gap = GAP_RATIO * m
    gw = N * m + (N - 1) * gap
    x0 = y0 = (CANVAS - gw) / 2
    out = []
    for c in range(N):
        for r in range(N):
            x = x0 + c * (m + gap)
            y = y0 + r * (m + gap)
            filled = r >= (N - 1 - c)            # column heights 1,2,3,4 -> ascending
            out.append((x, y, m, filled))
    return out, m


def svg(span_frac, background, empty_opacity):
    items, m = cells(span_frac)
    rx, sw, inset = m * 0.19, m * 0.07, m * 0.055
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" '
             f'viewBox="0 0 {CANVAS} {CANVAS}">']
    if background:
        parts.append(_GRADIENT + f'<rect width="{CANVAS}" height="{CANVAS}" fill="url(#bg)"/>')
    for (x, y, mm, filled) in items:
        if filled:
            parts.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{mm:.2f}" height="{mm:.2f}" '
                         f'rx="{rx:.2f}" fill="{ORANGE}"/>')
        else:
            parts.append(f'<rect x="{x + inset:.2f}" y="{y + inset:.2f}" '
                         f'width="{mm - 2 * inset:.2f}" height="{mm - 2 * inset:.2f}" '
                         f'rx="{rx * 0.85:.2f}" fill="none" stroke="#FFFFFF" '
                         f'stroke-opacity="{empty_opacity}" stroke-width="{sw:.2f}"/>')
    parts.append('</svg>')
    return "\n".join(parts)


_GRADIENT = ('<defs><linearGradient id="bg" x1="0" y1="0" x2="0.85" y2="1">'
             '<stop offset="0" stop-color="#242424"/>'
             '<stop offset="1" stop-color="#0a0a0a"/></linearGradient></defs>')


def mark_svg(empty_opacity=0.22):
    """Tight-cropped mark (grid only, transparent) for in-app use, e.g. the nav
    drawer header. viewBox hugs the grid so it renders large in a small box."""
    m, gap = 100.0, GAP_RATIO * 100.0
    size = N * m + (N - 1) * gap
    rx, sw, inset = m * 0.19, m * 0.07, m * 0.055
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{size:.0f}" height="{size:.0f}" '
             f'viewBox="0 0 {size:.0f} {size:.0f}">']
    for c in range(N):
        for r in range(N):
            x, y = c * (m + gap), r * (m + gap)
            if r >= (N - 1 - c):
                parts.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{m:.2f}" height="{m:.2f}" '
                             f'rx="{rx:.2f}" fill="{ORANGE}"/>')
            else:
                parts.append(f'<rect x="{x + inset:.2f}" y="{y + inset:.2f}" '
                             f'width="{m - 2 * inset:.2f}" height="{m - 2 * inset:.2f}" '
                             f'rx="{rx * 0.85:.2f}" fill="none" stroke="#FFFFFF" '
                             f'stroke-opacity="{empty_opacity}" stroke-width="{sw:.2f}"/>')
    parts.append('</svg>')
    return "\n".join(parts)


def bg_only():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" '
            f'viewBox="0 0 {CANVAS} {CANVAS}">' + _GRADIENT
            + f'<rect width="{CANVAS}" height="{CANVAS}" fill="url(#bg)"/></svg>')


def write(name, text):
    with open(os.path.join(BR, name), "w") as f:
        f.write(text)


def rasterize(svg_name, png_name):
    subprocess.run(["rsvg-convert", "-w", str(CANVAS), "-h", str(CANVAS),
                    os.path.join(BR, svg_name), "-o", os.path.join(BR, png_name)], check=True)


def main():
    os.makedirs(BR, exist_ok=True)
    # Full-bleed master, grid ~62% of the canvas.
    write("logo.svg", svg(0.62, background=True, empty_opacity=0.17))
    # Adaptive foreground: transparent, grid ~58% so it stays in the 66% safe
    # zone AFTER flutter_launcher_icons applies its 16% inset.
    write("logo_foreground.svg", svg(0.58, background=False, empty_opacity=0.20))
    # Adaptive background: dark gradient only.
    write("logo_background.svg", bg_only())
    # Tight mark for in-app use (nav drawer header). Rendered via flutter_svg.
    write("logo_mark.svg", mark_svg())

    rasterize("logo.svg", "app_icon_1024.png")
    rasterize("logo_foreground.svg", "app_icon_foreground.png")
    rasterize("logo_background.svg", "app_icon_background.png")
    print("Wrote logo art to", BR)


if __name__ == "__main__":
    main()
