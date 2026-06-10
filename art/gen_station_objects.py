"""Generate station/hub object sprites (32x32 RGBA PNGs) for Habitat Echo.

Outputs under art/objects/: pod, device, op_board, fabber, psycho, comm,
debrief, stack, relay. Each keeps the object's established placeholder colour
so players' associations carry over (hub stations, the resleeving pod, the
suspicious device, and the Op 1 hauler objects).
Pure stdlib. Run from project root:  python art/gen_station_objects.py
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


def pod():
    """Resleeving pod — cyan upright capsule with a viewing window."""
    CY, CYD, CYL = (40, 200, 205, 255), (18, 120, 126, 255), (120, 235, 240, 255)
    GLASS, BODY = (16, 50, 60, 255), (28, 160, 168, 255)
    c = C()
    c.rect(10, 8, 21, 27, BODY)                     # capsule body
    c.disc_ring(16, 9, 6, CYD, fill=BODY)           # rounded crown
    c.border(10, 8, 21, 27, CYD)
    c.rect(11, 8, 20, 9, CYL)                       # highlight
    c.rect(12, 11, 19, 20, GLASS)                   # window
    c.border(12, 11, 19, 20, CYD)
    c.rect(15, 13, 16, 18, CY)                      # sleeper silhouette glow
    c.rect(11, 23, 20, 24, CYD)                     # base seam
    return c


def device():
    """Suspicious device — purple casing, single lens, crooked antennae."""
    P, PD, PL = (150, 30, 150, 255), (92, 14, 92, 255), (200, 80, 200, 255)
    c = boxed(P, PD, PL, 7, 11, 24, 25)
    c.disc_ring(16, 18, 4, PD, fill=(60, 8, 60, 255))   # lens
    c.put(16, 18, (255, 120, 255, 255))                 # lens glint
    c.rect(10, 7, 10, 10, PD); c.put(9, 6, PL)          # antenna L (crooked)
    c.rect(21, 5, 21, 10, PD); c.put(22, 4, PL)         # antenna R
    return c


def op_board():
    """Hub op board — blue wall board with pinned contract cards."""
    B, BD, BL = (50, 130, 205, 255), (24, 70, 120, 255), (110, 175, 235, 255)
    CARD, HOT = (215, 225, 235, 255), (235, 200, 90, 255)
    c = boxed(B, BD, BL, 4, 7, 27, 24)
    c.rect(7, 10, 12, 16, CARD)                     # contract cards
    c.rect(14, 10, 19, 18, HOT)                     # the active contract
    c.rect(21, 10, 25, 15, CARD)
    c.rect(7, 19, 12, 21, CARD)
    for x0, y0 in ((9, 10), (16, 10), (23, 10)):    # pins
        c.put(x0, y0, BD)
    return c


def fabber():
    """Quartermaster fabber — amber frame printing a part."""
    A, AD, AL = (210, 165, 55, 255), (140, 102, 24, 255), (240, 205, 110, 255)
    CAV, PART = (50, 38, 14, 255), (120, 220, 230, 255)
    c = boxed(A, AD, AL, 5, 5, 26, 26)
    c.rect(8, 10, 23, 22, CAV)                      # build cavity
    c.border(8, 10, 23, 22, AD)
    c.rect(8, 13, 23, 13, AD)                       # gantry rail
    c.rect(14, 13, 17, 15, A)                       # print head
    c.put(15, 16, PART); c.put(16, 16, PART)        # deposition beam
    c.rect(12, 19, 19, 21, PART)                    # half-built part
    return c


def psycho():
    """Psychosurgery cradle — magenta recliner with a neural halo."""
    M, MD, ML = (170, 75, 170, 255), (104, 38, 104, 255), (215, 130, 215, 255)
    HALO = (255, 200, 255, 255)
    c = C()
    c.rect(9, 12, 22, 26, M)                        # couch
    c.border(9, 12, 22, 26, MD)
    c.rect(10, 12, 21, 13, ML)
    c.rect(12, 15, 19, 24, MD)                      # cushion recess
    c.disc_ring(16, 8, 5, HALO)                     # neural halo
    c.rect(15, 11, 16, 12, MD)                      # halo mount
    return c


def comm():
    """Handler comm console — teal screen carrying a voice waveform."""
    T, TD, TL = (70, 170, 170, 255), (32, 104, 104, 255), (130, 215, 215, 255)
    SCRN, WAVE = (14, 52, 56, 255), (140, 255, 245, 255)
    c = boxed(T, TD, TL, 6, 7, 25, 24)
    c.rect(8, 9, 23, 19, SCRN)
    c.border(8, 9, 23, 19, TD)
    for i, x in enumerate(range(10, 22)):           # waveform
        h = (1, 2, 4, 2, 5, 3, 1, 4, 2, 3, 1, 2)[i]
        c.rect(x, 14 - h // 2, x, 14 + (h - h // 2) - 1, WAVE)
    c.rect(13, 21, 18, 22, TD)                      # speaker grille
    return c


def debrief():
    """Debrief terminal — grey console showing stat bars."""
    G, GD, GL = (150, 150, 160, 255), (90, 90, 100, 255), (195, 195, 205, 255)
    SCRN = (38, 40, 48, 255)
    BAR = (120, 200, 130, 255)
    c = boxed(G, GD, GL, 6, 6, 25, 25)
    c.rect(8, 8, 23, 19, SCRN)
    c.border(8, 8, 23, 19, GD)
    for y, w in ((10, 10), (13, 6), (16, 12)):      # stat bars
        c.rect(10, y, 10 + w, y + 1, BAR)
    c.rect(9, 21, 22, 23, (115, 115, 125, 255))     # keys
    return c


def stack():
    """Cortical stack — small yellow cylinder glinting in a frosted cradle."""
    Y, YD, YL = (225, 200, 55, 255), (150, 130, 24, 255), (250, 235, 130, 255)
    CRADLE, FROST = (70, 75, 88, 255), (170, 200, 225, 255)
    c = C()
    c.rect(8, 18, 23, 24, CRADLE)                   # cradle base
    c.border(8, 18, 23, 24, (44, 48, 58, 255))
    c.rect(13, 10, 18, 19, Y)                       # the stack
    c.border(13, 10, 18, 19, YD)
    c.rect(14, 10, 17, 11, YL)
    c.rect(13, 14, 18, 14, YD)                      # segment seam
    c.put(15, 12, (255, 255, 220, 255))             # glint
    for x, y in ((10, 16), (21, 15), (11, 26), (20, 26)):   # frost motes
        c.put(x, y, FROST)
    return c


def relay():
    """Egocast relay — cyan mast and dish casting the ego out."""
    CY, CYD, CYL = (50, 200, 225, 255), (22, 116, 134, 255), (130, 235, 250, 255)
    c = C()
    c.rect(15, 12, 16, 27, CYD)                     # mast
    c.rect(10, 26, 21, 27, CYD)                     # base
    c.disc_ring(16, 10, 6, CY, fill=(20, 60, 72, 255))   # dish
    c.put(16, 10, CYL)                              # feed point
    for r in (8, 10):                               # emission arcs
        for a in (-0.6, 0.0, 0.6):
            x = int(16 + math.sin(a) * r)
            y = int(10 - math.cos(a) * r)
            c.put(x, y, CYL)
    return c


def researcher():
    """Dr. Okafor, infected — hunched figure, lab coat, one eye lit wrong."""
    SKIN, COAT, COATD = (196, 168, 142, 255), (205, 210, 218, 255), (130, 136, 148, 255)
    HAIR, EYE = (40, 34, 30, 255), (235, 60, 60, 255)
    c = C()
    c.rect(12, 14, 20, 27, COAT)                    # hunched body
    c.border(12, 14, 20, 27, COATD)
    c.rect(15, 16, 16, 26, COATD)                   # coat seam
    c.rect(12, 8, 19, 14, SKIN)                     # head, tilted low
    c.rect(12, 7, 19, 9, HAIR)
    c.put(14, 11, (30, 26, 24, 255))                # dark eye
    c.put(17, 11, EYE)                              # the wrong one
    c.put(18, 11, EYE)
    c.rect(10, 16, 11, 23, COAT)                    # arms hanging long
    c.rect(21, 16, 22, 24, COAT)
    c.put(10, 24, SKIN); c.put(22, 25, SKIN)        # hands a touch too low
    return c


def archive():
    """Archive server rack — cold stack of drives, one status light wrong."""
    B, BD, BL = (70, 95, 125, 255), (36, 50, 70, 255), (115, 145, 175, 255)
    OK, BAD = (90, 220, 140, 255), (235, 70, 70, 255)
    c = boxed(B, BD, BL, 8, 4, 23, 27)
    for i, yy in enumerate((7, 11, 15, 19, 23)):    # drive sleds
        c.rect(10, yy, 21, yy + 2, (52, 72, 96, 255))
        c.border(10, yy, 21, yy + 2, BD)
        c.put(20, yy + 1, BAD if i == 2 else OK)    # one light burns red
    return c


def specimen():
    """Specimen tank — sickly fluid, a dark shape, a crack running through."""
    GLASS, GLD = (120, 190, 170, 200), (60, 110, 96, 255)
    FLUID, SHAPE = (62, 130, 96, 230), (24, 40, 30, 255)
    BASE, CRACK = (88, 92, 104, 255), (210, 240, 230, 255)
    c = C()
    c.rect(10, 24, 21, 27, BASE)                    # base
    c.border(10, 24, 21, 27, (50, 52, 60, 255))
    c.rect(11, 5, 20, 23, FLUID)                    # tank
    c.border(11, 5, 20, 23, GLD)
    c.rect(12, 5, 19, 6, GLASS)                     # glass shine
    c.rect(14, 11, 17, 19, SHAPE)                   # the shape
    c.put(13, 14, SHAPE); c.put(18, 16, SHAPE)      # ...with protrusions
    for x, y in ((12, 9), (13, 12), (14, 15), (14, 18), (15, 21)):  # crack
        c.put(x, y, CRACK)
    return c


def main():
    out = os.path.join(os.path.dirname(__file__), "objects")
    os.makedirs(out, exist_ok=True)
    sprites = {
        "pod": pod(), "device": device(), "op_board": op_board(),
        "fabber": fabber(), "psycho": psycho(), "comm": comm(),
        "debrief": debrief(), "stack": stack(), "relay": relay(),
        "researcher": researcher(), "archive": archive(), "specimen": specimen(),
    }
    for name, c in sprites.items():
        write_png(os.path.join(out, f"{name}.png"), c)
    print("done:", ", ".join(sprites))


if __name__ == "__main__":
    main()
