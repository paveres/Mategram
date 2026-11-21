import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SS = 2048

PALETTES = {
    "WhiteFilledIcon": ((255, 255, 255), (235, 235, 240), (0, 0, 0)),
    "BlackIcon": ((0, 0, 0), (0, 0, 0), (255, 255, 255)),
    "BlackClassicIcon": ((28, 28, 30), (0, 0, 0), (255, 255, 255)),
    "BlackFilledIcon": ((0, 0, 0), (0, 0, 0), (255, 255, 255)),
    "BlueIcon": ((10, 132, 255), (0, 88, 214), (255, 255, 255)),
    "BlueClassicIcon": ((52, 170, 255), (10, 110, 230), (255, 255, 255)),
    "BlueFilledIcon": ((10, 132, 255), (10, 132, 255), (255, 255, 255)),
    "New1": ((60, 60, 64), (0, 0, 0), (255, 255, 255)),
    "New2": ((245, 245, 250), (199, 199, 204), (0, 0, 0)),
    "Premium": ((140, 80, 255), (200, 70, 220), (255, 255, 255)),
    "PremiumBlack": ((20, 20, 22), (0, 0, 0), (245, 196, 81)),
    "PremiumTurbo": ((255, 149, 0), (255, 45, 85), (255, 255, 255)),
}

DEFAULT = ((0, 0, 0), (0, 0, 0), (255, 255, 255))


def logo_points():
    pts = [(0.0, -62.0), (62.0, 56.0)]
    p0, p1, p2 = (62.0, 56.0), (0.0, 22.0), (-62.0, 56.0)
    for i in range(1, 25):
        t = i / 24.0
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts


def transform(pts, scale, size):
    angle = math.radians(36.0)
    c, s = math.cos(angle), math.sin(angle)
    k = size / 1024.0
    out = []
    for x, y in pts:
        rx = x * c - y * s
        ry = x * s + y * c
        out.append((512 * k + rx * scale * k, 525 * k + ry * scale * k))
    return out


def render(palette, size=SS):
    top, bottom, fg = palette
    base = Image.new("RGB", (size, size), top)
    if top != bottom:
        px = ImageDraw.Draw(base)
        for y in range(size):
            t = y / (size - 1)
            col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
            px.line([(0, y), (size, y)], fill=col)
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    pts = transform(logo_points(), 1.84, size)
    d.polygon(pts, fill=255)
    r = 52.0 * 1.84 * size / 1024.0
    ring = []
    for i in range(len(pts)):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % len(pts)]
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) / (r / 4.0)))
        for k in range(steps):
            t = k / steps
            ring.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t))
    for x, y in ring:
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    layer = Image.new("RGB", (size, size), fg)
    base.paste(layer, (0, 0), mask)
    return base


def palette_for(path):
    for part in reversed(path.parts):
        name = part.split(".")[0]
        if name in PALETTES:
            return PALETTES[name]
    return DEFAULT


def main():
    root = Path(sys.argv[1])
    cache = {}
    count = 0
    targets = []
    for pattern in ("*.alticon", "AppIcons.xcassets/*.appiconset", "DefaultAppIcon.xcassets/*.appiconset"):
        for folder in root.glob(pattern):
            targets.extend(sorted(folder.glob("*.png")))
    for png in targets:
        try:
            size = Image.open(png).size[0]
        except Exception:
            continue
        palette = palette_for(png.parent)
        key = palette
        if key not in cache:
            cache[key] = render(palette)
        cache[key].resize((size, size), Image.LANCZOS).save(png)
        count += 1
    print("icons written:", count)


if __name__ == "__main__":
    main()
