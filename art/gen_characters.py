"""Generate the remaining Habitat Echo character sprites (original pixel art).

Outputs PNGs under art/:
  synth/<dir>_<frame>.png      32x32, 4 dirs x 2 walk frames  (durable grey robot)
  biomorph/<dir>_<frame>.png   32x32, 4 dirs x 2 walk frames  (humanoid w/ cyberbrain)
  npc/crew.png                 32x32, single frame            (scared sleeved crew)
  swarm/<frame>.png            24x24, 2 frames                (nanite swarm)

Pure stdlib (no Pillow). Run from project root:  python art/gen_characters.py
"""
import struct
import zlib
import os
import math
import random

CLEAR = (0, 0, 0, 0)


class C:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.buf = [CLEAR] * (w * h)

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c[3] > 0:
            self.buf[y * self.w + x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def disc(self, cx, cy, r, col, outline=None):
        for y in range(self.h):
            for x in range(self.w):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d <= r:
                    self.put(x, y, col)
                elif outline and d <= r + 1.2:
                    self.put(x, y, outline)


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


def eye(c, cx, cy, pdx, pdy, white=(245, 245, 250, 255), pup=(25, 25, 40, 255), big=False):
    rng = range(-1, 2)
    for dy in rng:
        for dx in rng:
            c.put(cx + dx, cy + dy, white)
    c.put(cx + pdx, cy + pdy, pup)
    if big:
        c.put(cx + pdx, cy + pdy + 1, pup)


# ---------------------------------------------------------------------------
# Synth — durable grey robot
# ---------------------------------------------------------------------------
M = (140, 140, 152, 255)
M_L = (185, 185, 196, 255)
M_D = (88, 88, 100, 255)
VISOR = (90, 205, 235, 255)


def synth(direction, frame):
    c = C(32, 32)
    # legs (walk bob)
    lyl = 29 if frame == 0 else 27
    lyr = 27 if frame == 0 else 29
    c.rect(12, 23, 14, lyl, M_D)
    c.rect(18, 23, 20, lyr, M_D)
    # torso
    c.rect(10, 13, 21, 23, M)
    c.rect(10, 13, 21, 14, M_L)          # shoulder highlight
    c.rect(15, 16, 16, 22, M_D)          # central panel seam
    # head
    c.rect(11, 5, 20, 13, M_L)
    c.rect(11, 5, 20, 5, M)              # top edge
    c.put(15, 3, M); c.put(16, 3, M)     # antenna stub
    # visor by facing
    if direction == "down":
        c.rect(12, 9, 19, 10, VISOR)
    elif direction == "up":
        c.rect(12, 7, 19, 8, M_D)
    elif direction == "left":
        c.rect(11, 9, 15, 10, VISOR)
    elif direction == "right":
        c.rect(16, 9, 20, 10, VISOR)
    return c


# ---------------------------------------------------------------------------
# Biomorph — sleek humanoid with a cyberbrain implant
# ---------------------------------------------------------------------------
SKIN = (222, 168, 132, 255)
SKIN_D = (180, 128, 95, 255)
SUIT = (200, 110, 60, 255)
SUIT_D = (150, 78, 42, 255)
HAIR = (58, 40, 30, 255)
IMPLANT = (150, 210, 235, 255)


GLOW = (95, 215, 240, 255)     # cybernetic glow (eyes, circuitry)
GLOW_C = (205, 248, 255, 255)
CAP = (44, 48, 62, 255)        # neural cap / synthskull


def biomorph(direction, frame):
    c = C(32, 32)
    # legs
    lyl = 29 if frame == 0 else 27
    lyr = 27 if frame == 0 else 29
    c.rect(13, 23, 15, lyl, SUIT_D)
    c.rect(17, 23, 19, lyr, SUIT_D)
    # arms
    c.rect(9, 14, 11, 21, SUIT)
    c.rect(21, 14, 23, 21, SUIT)
    # sleek bodysuit: torso + glowing collar + chest seam
    c.rect(12, 13, 20, 23, SUIT)
    c.rect(12, 13, 20, 14, (225, 140, 90, 255))
    c.rect(13, 13, 19, 13, GLOW)                     # collar light
    for yy in (16, 18, 20):
        c.put(16, yy, GLOW)                          # chest seam nodes
    # head
    c.disc(16, 9, 5, SKIN, SKIN_D)
    # neural cap (replaces hair) with a circuit line
    c.rect(12, 4, 20, 6, CAP)
    c.put(11, 6, CAP); c.put(21, 6, CAP)
    c.rect(13, 5, 19, 5, GLOW)
    # cyberbrain implant plate at the temple
    c.rect(20, 7, 20, 10, GLOW)
    c.put(19, 8, GLOW_C)

    def glow_eye(cx, cy):
        c.rect(cx - 1, cy, cx + 1, cy, GLOW)
        c.put(cx, cy, GLOW_C)

    # glowing optics by facing
    if direction == "down":
        glow_eye(14, 10); glow_eye(18, 10)
    elif direction == "up":
        c.rect(12, 7, 20, 8, CAP)            # back of synthskull
        c.rect(13, 8, 19, 8, GLOW)           # nape circuit
    elif direction == "left":
        glow_eye(13, 10)
    elif direction == "right":
        glow_eye(19, 10)
    return c


# ---------------------------------------------------------------------------
# Crew NPC — a frightened sleeved crew member (single front frame)
# ---------------------------------------------------------------------------
N_SUIT = (70, 130, 140, 255)
N_SUIT_D = (45, 95, 105, 255)
N_SKIN = (228, 180, 150, 255)


def npc():
    """A frightened crew member huddled inside an open supply crate, peeking out."""
    CRATE = (112, 118, 128, 255)
    CRATE_D = (66, 71, 82, 255)
    CRATE_L = (152, 158, 168, 255)
    INSIDE = (34, 36, 44, 255)
    HAIR = (40, 35, 45, 255)
    BROW = (120, 70, 70, 255)
    c = C(32, 32)
    # supply crate (occupies the lower half)
    c.rect(5, 14, 26, 30, CRATE)
    c.rect(5, 14, 26, 15, CRATE_L)         # top lid rim
    for x0 in range(5, 27):                # outline
        c.put(x0, 30, CRATE_D)
    for y0 in range(14, 31):
        c.put(5, y0, CRATE_D); c.put(26, y0, CRATE_D)
    for sx in (11, 16, 21):                # slat seams
        c.rect(sx, 17, sx, 29, CRATE_D)
    # dark interior the crew member is crouched in
    c.rect(11, 14, 20, 17, INSIDE)
    # head peeking over the rim
    c.disc(16, 10, 4, N_SKIN, (185, 140, 112, 255))
    c.rect(12, 5, 20, 8, HAIR)             # hair
    eye(c, 14, 10, 0, 1, big=True)         # wide, worried eyes
    eye(c, 18, 10, 0, 1, big=True)
    c.put(15, 13, BROW); c.put(16, 13, BROW)   # frown
    # hands gripping the crate rim
    c.rect(9, 14, 11, 15, N_SKIN)
    c.rect(21, 14, 23, 15, N_SKIN)
    return c


# ---------------------------------------------------------------------------
# Nanite swarm — seething red/purple cloud (2 frames)
# ---------------------------------------------------------------------------
SW1 = (205, 45, 85, 255)
SW2 = (150, 35, 150, 255)
SW_D = (90, 20, 55, 255)


def swarm(frame):
    c = C(24, 24)
    cx, cy = 12.0, 12.0
    rng = random.Random(100 + frame)
    base_r = 7.0
    for y in range(24):
        for x in range(24):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            jag = math.sin(math.atan2(y - cy, x - cx) * 6.0 + frame * 1.7) * 2.0
            if d <= base_r + jag:
                col = SW1 if (x + y + frame) % 3 != 0 else SW2
                c.put(x, y, col)
            elif d <= base_r + jag + 1.2:
                c.put(x, y, SW_D)
    # scattered nanite motes
    for _ in range(7):
        ang = rng.uniform(0, math.tau)
        rr = rng.uniform(base_r + 1.5, 11.0)
        x = int(cx + math.cos(ang) * rr)
        y = int(cy + math.sin(ang) * rr)
        c.put(x, y, SW2 if rng.random() < 0.5 else SW1)
    return c


def main():
    root = os.path.dirname(__file__)
    for sub in ("synth", "biomorph", "npc", "swarm"):
        os.makedirs(os.path.join(root, sub), exist_ok=True)
    for d in ("down", "up", "left", "right"):
        for fr in (0, 1):
            write_png(os.path.join(root, "synth", f"{d}_{fr}.png"), synth(d, fr))
            write_png(os.path.join(root, "biomorph", f"{d}_{fr}.png"), biomorph(d, fr))
    write_png(os.path.join(root, "npc", "crew.png"), npc())
    for fr in (0, 1):
        write_png(os.path.join(root, "swarm", f"{fr}.png"), swarm(fr))
    print("done: synth(8) biomorph(8) npc(1) swarm(2)")


if __name__ == "__main__":
    main()
