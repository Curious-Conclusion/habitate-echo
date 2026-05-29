"""Generate interactable-object sprites (32x32 RGBA PNGs) for Habitat Echo.

Outputs under art/objects/: hatch, autodoc, terminal, locker, airlock, datapad.
Each keeps the object's established colour so players' associations carry over.
Pure stdlib. Run from project root:  python art/gen_objects.py
"""
import struct
import zlib
import os
import math

CLEAR = (0, 0, 0, 0)


class C:
    def __init__(self, w=32, h=32):
        self.w, self.h = w, h
        self.buf = [CLEAR] * (w * h)

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c[3] > 0:
            self.buf[y * self.w + x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def border(self, x0, y0, x1, y1, c):
        for x in range(x0, x1 + 1):
            self.put(x, y0, c); self.put(x, y1, c)
        for y in range(y0, y1 + 1):
            self.put(x0, y, c); self.put(x1, y, c)

    def disc_ring(self, cx, cy, r, c, fill=None):
        for y in range(self.h):
            for x in range(self.w):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d <= r - 1.5 and fill:
                    self.put(x, y, fill)
                elif r - 1.5 < d <= r:
                    self.put(x, y, c)


def write_png(path, c):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(c.h):
        raw.append(0)
        for x in range(c.w):
            raw += bytes(c.buf[y * c.w + x])
    out = b"\x89PNG\r\n\x1a\n"
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", c.w, c.h, 8, 6, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    out += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)


def boxed(col, dark, light, x0=6, y0=6, x1=25, y1=25):
    c = C()
    c.rect(x0, y0, x1, y1, col)
    c.rect(x0, y0, x1, y0 + 1, light)      # top highlight
    c.border(x0, y0, x1, y1, dark)
    return c


def hatch():
    M, MD, ML = (140, 140, 152, 255), (80, 80, 92, 255), (185, 185, 196, 255)
    c = boxed(M, MD, ML)
    for (bx, by) in [(9, 9), (22, 9), (9, 22), (22, 22)]:   # corner bolts
        c.rect(bx, by, bx + 1, by + 1, MD)
    for yy in (13, 16, 19):                                 # central grille
        c.rect(11, yy, 20, yy, MD)
    return c


def autodoc():
    T, TD = (45, 160, 140, 255), (26, 105, 92, 255)
    WH = (235, 245, 245, 255)
    c = boxed(T, TD, (95, 200, 180, 255))
    c.rect(14, 9, 17, 22, WH)   # medical cross
    c.rect(9, 13, 22, 18, WH)
    return c


def terminal():
    BODY, BD = (40, 80, 100, 255), (22, 46, 60, 255)
    SCRN, GLOW = (35, 60, 75, 255), (70, 205, 235, 255)
    c = boxed(BODY, BD, (70, 120, 145, 255))
    c.rect(9, 8, 22, 18, SCRN)          # screen
    c.border(9, 8, 22, 18, BD)
    for yy in (11, 13, 15):             # glowing text lines
        c.rect(11, yy, 19, yy, GLOW)
    c.rect(8, 21, 23, 24, (60, 100, 120, 255))   # base / keyboard
    return c


def locker():
    A, AD = (200, 170, 50, 255), (148, 122, 28, 255)
    c = boxed(A, AD, (230, 205, 90, 255), 7, 4, 24, 28)
    c.rect(16, 5, 16, 27, AD)           # door seam
    c.rect(18, 14, 20, 17, AD)          # handle
    c.rect(11, 14, 13, 17, AD)
    return c


def airlock():
    O, OD = (210, 120, 40, 255), (148, 80, 24, 255)
    c = boxed(O, OD, (240, 160, 80, 255))
    c.disc_ring(16, 16, 7, OD, fill=(190, 105, 32, 255))   # valve wheel
    c.rect(15, 8, 16, 24, OD)           # spokes
    c.rect(8, 15, 24, 16, OD)
    c.rect(15, 15, 16, 16, (90, 50, 16, 255))   # hub
    return c


def datapad():
    G, GD = (60, 150, 70, 255), (32, 95, 42, 255)
    SCRN = (140, 225, 150, 255)
    c = boxed(G, GD, (100, 200, 110, 255), 9, 5, 22, 26)
    c.rect(11, 8, 20, 19, SCRN)         # screen
    c.border(11, 8, 20, 19, GD)
    c.rect(15, 22, 16, 23, GD)          # button
    return c


def main():
    out = os.path.join(os.path.dirname(__file__), "objects")
    os.makedirs(out, exist_ok=True)
    sprites = {
        "hatch": hatch(), "autodoc": autodoc(), "terminal": terminal(),
        "locker": locker(), "airlock": airlock(), "datapad": datapad(),
    }
    for name, c in sprites.items():
        write_png(os.path.join(out, f"{name}.png"), c)
    print("done:", ", ".join(sprites))


if __name__ == "__main__":
    main()
