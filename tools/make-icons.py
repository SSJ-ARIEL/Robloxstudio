#!/usr/bin/env python3
"""Generate original SVG artwork and matching PNG exports.

Only simple geometry and a small stroke alphabet authored here are used.
Pillow is used to render the same shapes at 3x resolution before export.
This helper is optional: running Color Chaos does not require Python or Pillow.
"""

from html import escape
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets"
SCALE = 3
INK = "#10182d"
PANEL = "#17233d"
GRID = "#263957"
WHITE = "#f5f9ff"
BLUE = "#379bff"
YELLOW = "#ffd642"
GREEN = "#4fe091"
RED = "#ff606a"
GOLD = "#f5b940"

# An original monoline alphabet; each letter is represented by plain strokes.
GLYPHS = {
    "A": [[(0, 7), (2.5, 0), (5, 7)], [(1, 4.5), (4, 4.5)]],
    "B": [[(0, 7), (0, 0), (4, 0), (5, 1), (5, 2.5), (4, 3.5), (0, 3.5)], [(4, 3.5), (5, 4.5), (5, 6), (4, 7), (0, 7)]],
    "C": [[(5, 1), (4, 0), (1, 0), (0, 1), (0, 6), (1, 7), (4, 7), (5, 6)]],
    "D": [[(0, 7), (0, 0), (3, 0), (5, 2), (5, 5), (3, 7), (0, 7)]],
    "E": [[(5, 0), (0, 0), (0, 7), (5, 7)], [(0, 3.5), (4, 3.5)]],
    "H": [[(0, 0), (0, 7)], [(5, 0), (5, 7)], [(0, 3.5), (5, 3.5)]],
    "I": [[(0, 0), (5, 0)], [(2.5, 0), (2.5, 7)], [(0, 7), (5, 7)]],
    "L": [[(0, 0), (0, 7), (5, 7)]],
    "M": [[(0, 7), (0, 0), (2.5, 3.5), (5, 0), (5, 7)]],
    "N": [[(0, 7), (0, 0), (5, 7), (5, 0)]],
    "O": [[(1, 0), (4, 0), (5, 1), (5, 6), (4, 7), (1, 7), (0, 6), (0, 1), (1, 0)]],
    "P": [[(0, 7), (0, 0), (4, 0), (5, 1), (5, 3), (4, 4), (0, 4)]],
    "R": [[(0, 7), (0, 0), (4, 0), (5, 1), (5, 3), (4, 4), (0, 4)], [(2.5, 4), (5, 7)]],
    "S": [[(5, 1), (4, 0), (1, 0), (0, 1), (0, 2.5), (1, 3.5), (4, 3.5), (5, 4.5), (5, 6), (4, 7), (1, 7), (0, 6)]],
    "T": [[(0, 0), (5, 0)], [(2.5, 0), (2.5, 7)]],
    "V": [[(0, 0), (2.5, 7), (5, 0)]],
    "0": [[(1, 0), (4, 0), (5, 1), (5, 6), (4, 7), (1, 7), (0, 6), (0, 1), (1, 0)]],
    "1": [[(1, 1.5), (2.5, 0), (2.5, 7)], [(0.5, 7), (4.5, 7)]],
    "4": [[(3.5, 0), (0, 4.5), (5, 4.5)], [(3.5, 0), (3.5, 7)]],
}


class Art:
    def __init__(self, width=512, height=512):
        self.width = width
        self.height = height
        self.svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">']
        self.im = Image.new("RGB", (width * SCALE, height * SCALE), INK)
        self.draw = ImageDraw.Draw(self.im)

    @staticmethod
    def coords(points):
        return [(round(x * SCALE), round(y * SCALE)) for x, y in points]

    def rectangle(self, x, y, w, h, color, radius=0):
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{color}"/>')
        box = (round(x * SCALE), round(y * SCALE), round((x + w) * SCALE), round((y + h) * SCALE))
        self.draw.rounded_rectangle(box, radius=round(radius * SCALE), fill=color)

    def polygon(self, points, color, outline=None, width=1):
        pair = " ".join(f"{x},{y}" for x, y in points)
        stroke = f' stroke="{outline}" stroke-width="{width}" stroke-linejoin="round"' if outline else ""
        self.svg.append(f'<polygon points="{pair}" fill="{color}"{stroke}/>')
        self.draw.polygon(self.coords(points), fill=color)
        if outline:
            self.draw.line(self.coords(points + [points[0]]), fill=outline, width=max(1, round(width * SCALE)), joint="curve")

    def line(self, points, color, width):
        pair = " ".join(f"{x},{y}" for x, y in points)
        self.svg.append(f'<polyline points="{pair}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')
        self.draw.line(self.coords(points), fill=color, width=max(1, round(width * SCALE)), joint="curve")
        cap = width * SCALE / 2
        for x, y in self.coords(points):
            self.draw.ellipse((round(x - cap), round(y - cap), round(x + cap), round(y + cap)), fill=color)

    def ellipse(self, cx, cy, rx, ry, color, outline=None, width=1):
        stroke = f' stroke="{outline}" stroke-width="{width}"' if outline else ""
        self.svg.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{color}"{stroke}/>')
        box = tuple(round(v * SCALE) for v in (cx - rx, cy - ry, cx + rx, cy + ry))
        self.draw.ellipse(box, fill=color, outline=outline, width=max(1, round(width * SCALE)))

    def text(self, value, cx, top, size, color=WHITE, stroke=None):
        unit = size / 7
        advance = unit * 7.3
        full_width = len(value) * advance - unit * 2.3
        x = cx - full_width / 2
        self.svg.append(f'<g aria-label="{escape(value)}">')
        for char in value:
            if char != " ":
                for path in GLYPHS[char]:
                    self.line([(x + px * unit, top + py * unit) for px, py in path], color, stroke or size * 0.105)
            x += advance
        self.svg.append("</g>")

    def save(self, name):
        DEST.mkdir(exist_ok=True)
        self.svg.append("</svg>")
        (DEST / f"{name}.svg").write_text("\n".join(self.svg) + "\n", encoding="utf-8")
        export = self.im.resize((self.width, self.height), Image.Resampling.LANCZOS)
        export.save(DEST / f"{name}.png", optimize=True)


def background(art):
    art.rectangle(0, 0, art.width, art.height, INK)
    art.rectangle(16, 16, art.width - 32, art.height - 32, PANEL, 36)
    if art.width == 512:
        for x in (42, 470):
            art.line([(x, 100), (x, 190), (x + (18 if x < 256 else -18), 208)], GRID, 3)
            art.line([(x, 328), (x, 390)], GRID, 3)
            art.ellipse(x, 88, 5, 5, GRID)
        for x, color in zip((211, 241, 271, 301), (BLUE, YELLOW, GREEN, RED)):
            art.rectangle(x - 9, 34, 18, 5, color, 2)


def diamond(cx, cy, radius):
    return [(cx, cy - radius), (cx + radius, cy), (cx, cy + radius), (cx - radius, cy)]


def reactor(art, cx, cy, radius, symbols=True):
    art.polygon(diamond(cx, cy, radius + 12), INK, GRID, 3)
    points = diamond(cx, cy, radius)
    for index, color in enumerate((BLUE, YELLOW, GREEN, RED)):
        art.polygon([points[index], points[(index + 1) % 4], (cx, cy)], color)
    art.line([points[0], points[2]], INK, radius * 0.045)
    art.line([points[1], points[3]], INK, radius * 0.045)
    art.polygon(points, color=INK, outline=WHITE, width=3) if radius < 20 else None
    if radius >= 20:
        art.line(points + [points[0]], WHITE, max(2, radius * 0.025))
    art.polygon(diamond(cx, cy, radius * 0.22), INK, WHITE, max(2, radius * 0.025))
    art.polygon(diamond(cx, cy, radius * 0.095), WHITE)
    if symbols:
        for letter, dx, dy in (("A", 1, -1), ("D", -1, -1), ("C", -1, 1), ("B", 1, 1)):
            size = radius * 0.17
            art.text(letter, cx + dx * radius * 0.40, cy + dy * radius * 0.40 - size / 2, size, INK, size * 0.14)
    for x, y in points:
        art.ellipse(x, y, radius * 0.023, radius * 0.023, WHITE)


def logo():
    art = Art()
    background(art)
    reactor(art, 256, 218, 139)
    art.text("COLOR", 256, 387, 35)
    art.text("CHAOS", 256, 439, 37)
    art.save("logo")


def vip():
    art = Art()
    background(art)
    # A simple crown belongs to the cosmetic VIP treatment, not gameplay power.
    art.polygon([(197, 95), (197, 58), (228, 79), (256, 49), (284, 79), (315, 58), (315, 95)], GOLD, YELLOW, 3)
    art.line([(199, 104), (313, 104)], YELLOW, 5)
    reactor(art, 256, 244, 116)
    art.text("VIP", 256, 391, 32, YELLOW)
    art.text("PRISMA", 256, 444, 29)
    art.save("vip-prisma")


def coin(art, cx, cy, rx=96, ry=69):
    art.ellipse(cx, cy + 18, rx, ry, "#a96c20")
    art.ellipse(cx, cy + 10, rx, ry, GOLD)
    art.ellipse(cx, cy, rx, ry, YELLOW, GOLD, 3)
    art.ellipse(cx, cy, rx * 0.77, ry * 0.72, GOLD, "#fff2ab", 3)
    art.polygon(diamond(cx, cy, ry * 0.49), INK, "#fff2ab", 2)
    art.polygon(diamond(cx, cy, ry * 0.20), YELLOW)


def coins(amount, count):
    art = Art()
    background(art)
    reactor(art, 256, 146, 87)
    for level in range(count):
        coin(art, 146, 306 - level * 14, 64, 33)
        coin(art, 369, 316 - level * 14, 53, 29)
    coin(art, 256, 290, 98, 65)
    art.text(str(amount), 256, 385, 57 if amount < 1000 else 51)
    art.text("MONEDAS", 256, 462, 19, YELLOW)
    art.save(f"coins{amount}")


def banner():
    art = Art(1920, 1080)
    background(art)
    # Abstract promotional art, deliberately not presented as an engine screenshot.
    for y in (202, 878):
        art.line([(65, y), (350, y), (455, y + (95 if y == 202 else -95))], GRID, 8)
        art.ellipse(65, y, 11, 11, BLUE if y == 202 else GREEN)
    reactor(art, 468, 530, 330)
    art.text("COLOR", 1340, 280, 112)
    art.text("CHAOS", 1340, 443, 112)
    art.text("ACTIVA LOS COLORES", 1340, 641, 30)
    art.text("REPARA EL REACTOR", 1340, 708, 26, "#aab9d0")
    for x, color in zip((1238, 1306, 1374, 1442), (BLUE, YELLOW, GREEN, RED)):
        art.rectangle(x - 23, 810, 46, 10, color, 4)
    art.save("banner")


if __name__ == "__main__":
    logo()
    vip()
    coins(100, 1)
    coins(400, 3)
    coins(1000, 5)
    banner()
    print("Generated 6 original SVG sources and 6 matching PNG exports in assets/.")
