"""Generate Octomorph sprites (32x32 RGBA PNGs) — a cyborg uplifted octopus.

Eclipse Phase octomorph: bulbous mantle, eight arms, large cephalopod eyes with
slit pupils, plus cybernetics (a glowing optic, a cortical/mesh implant port,
circuit traces). 4 facing directions x 2 swim/walk frames. Pure-stdlib PNG.
Run from project root:  python art/gen_octomorph.py
"""
import struct
import zlib
import os
import math

W = H = 32

G    = (58, 168, 104, 255)   # mantle
G_D  = (34, 116, 70, 255)    # shade / chromatophore mottle
G_L  = (122, 216, 152, 255)  # highlight
T    = (48, 150, 90, 255)    # tentacle
T_D  = (30, 104, 62, 255)    # tentacle tip
MET  = (158, 163, 174, 255)  # cyberware metal
MET_D = (96, 101, 114, 255)
CY   = (95, 215, 240, 255)   # cybernetic glow
CY_C = (210, 248, 255, 255)  # glow core
EYE  = (243, 243, 249, 255)
PUP  = (20, 25, 35, 255)
CLEAR = (0, 0, 0, 0)


class C:
    def __init__(self):
        self.buf = [CLEAR] * (W * H)

    def put(self, x, y, c):
        x = int(round(x)); y = int(round(y))
        if 0 <= x < W and 0 <= y < H and c[3] > 0:
            self.buf[y * W + x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def ellipse(self, cx, cy, rx, ry, col, outline=None):
        for y in range(H):
            for x in range(W):
                v = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
                if v <= 1.0:
                    self.put(x, y, col)
                elif outline and v <= 1.32:
                    self.put(x, y, outline)


def arm(c, bx, by, tx, ty):
    n = int(max(abs(tx - bx), abs(ty - by), 1))
    for s in range(n + 1):
        t = s / n
        x = bx + (tx - bx) * t
        y = by + (ty - by) * t
        col = T if t < 0.55 else T_D
        c.put(x, y, col)
        if t < 0.45:            # a touch thicker near the base
            c.put(x + 1, y, col)


def tentacles(c, frame):
    cx = 16.0
    for i in range(8):
        spread = i - 3.5                    # -3.5 .. 3.5
        bx = cx + spread * 1.4
        by = 17
        wig = (1 if (i + frame) % 2 == 0 else -1)
        tx = cx + spread * 3.5 + wig
        ty = 25 + abs(spread) * 0.7
        arm(c, bx, by, tx, ty)


def mantle(c):
    c.ellipse(16, 11, 8, 9, G, G_D)
    # top-left highlight
    for (x, y) in [(12, 5), (13, 5), (12, 6), (11, 7)]:
        c.put(x, y, G_L)
    # chromatophore mottle
    for (x, y) in [(19, 6), (14, 8), (20, 10), (12, 10)]:
        c.put(x, y, G_D)


def cyberware(c):
    # cortical / mesh port on the crown of the mantle
    c.rect(15, 2, 17, 3, MET)
    c.put(16, 2, CY_C)
    # circuit trace down the mantle
    for (x, y) in [(16, 4), (16, 5), (15, 6), (19, 7), (19, 8)]:
        c.put(x, y, CY)


def organic_eye(c, ex, ey):
    for dy in (-1, 0, 1):
        c.rect(ex - 1, ey + dy, ex + 1, ey + dy, EYE)
    c.rect(ex - 1, ey, ex + 1, ey, PUP)     # horizontal slit pupil


def cyber_eye(c, ex, ey):
    for dy in (-1, 0, 1):
        c.rect(ex - 1, ey + dy, ex + 1, ey + dy, CY)
    c.put(ex, ey, CY_C)                      # bright optic core
    c.put(ex, ey - 2, MET_D)                 # housing


def eyes(c, d):
    # one organic cephalopod eye + one cybernetic optic (the cyborg tell)
    if d == "down":
        organic_eye(c, 12, 12); cyber_eye(c, 20, 12)
    elif d == "up":
        c.rect(12, 8, 20, 9, G_D)            # back of the mantle
        c.put(13, 8, CY); c.put(19, 8, CY)   # rear sensor dots
    elif d == "left":
        cyber_eye(c, 11, 12); organic_eye(c, 16, 12)
    elif d == "right":
        organic_eye(c, 15, 12); cyber_eye(c, 20, 12)


def write_png(path, c):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        for x in range(W):
            raw += bytes(c.buf[y * W + x])
    out = b"\x89PNG\r\n\x1a\n"
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    out += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "octomorph")
    os.makedirs(out_dir, exist_ok=True)
    for d in ("down", "up", "left", "right"):
        for fr in (0, 1):
            c = C()
            tentacles(c, fr)     # arms behind the mantle
            mantle(c)
            cyberware(c)
            eyes(c, d)
            write_png(os.path.join(out_dir, f"{d}_{fr}.png"), c)
    print("wrote cyborg octomorph: 4 dirs x 2 frames")


if __name__ == "__main__":
    main()
