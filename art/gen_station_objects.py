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


def generator():
    """Backup generator — heavy amber block, turbine ring, dead until keyed."""
    A, AD, AL = (190, 150, 60, 255), (122, 92, 30, 255), (225, 190, 105, 255)
    c = boxed(A, AD, AL, 5, 8, 26, 26)
    c.disc_ring(16, 17, 6, AD, fill=(70, 56, 22, 255))     # turbine housing
    c.rect(15, 16, 16, 17, (255, 230, 140, 255))           # pilot light
    for x in (8, 23):                                       # cooling fins
        c.rect(x, 10, x, 24, AD)
    c.rect(11, 5, 20, 8, (96, 96, 104, 255))               # cable trunk up
    return c


def vault():
    """Data vault — armored slab, keyed seam, a thin hot line of light."""
    G, GD, GL = (95, 105, 125, 255), (52, 58, 72, 255), (140, 150, 170, 255)
    HOT = (255, 170, 90, 255)
    c = boxed(G, GD, GL, 6, 5, 25, 26)
    c.border(9, 8, 22, 23, GD)                              # inner door
    c.rect(15, 8, 16, 23, HOT)                              # light through the seam
    c.disc_ring(16, 15, 4, GD)                              # lock ring
    return c


def core():
    """Containment core — dark heart in a cage, lit from inside."""
    CAGE, CAGED = (70, 78, 92, 255), (38, 44, 54, 255)
    GLOW, HEART = (170, 90, 200, 255), (30, 10, 36, 255)
    c = C()
    c.rect(8, 6, 23, 27, CAGED)                             # housing
    c.border(8, 6, 23, 27, CAGE)
    for x in (11, 16, 21):                                  # cage bars
        c.rect(x, 7, x, 26, CAGE)
    c.disc_ring(16, 16, 6, GLOW, fill=HEART)                # the core
    c.put(16, 16, (235, 170, 255, 255))                     # too bright to look at
    c.put(14, 14, GLOW); c.put(18, 18, GLOW)
    return c


def elevator():
    """Spine elevator — door pair with a call panel."""
    M, MD, ML = (120, 128, 140, 255), (66, 72, 84, 255), (165, 172, 184, 255)
    c = boxed(M, MD, ML, 6, 4, 25, 27)
    c.rect(15, 6, 16, 25, MD)                               # door split
    c.rect(9, 6, 13, 25, (96, 104, 118, 255))               # door leaves
    c.rect(18, 6, 22, 25, (96, 104, 118, 255))
    c.put(24, 14, (120, 230, 140, 255))                     # call light
    return c


def vent():
    """Crawlway vent — grate pried half-open; something uses this."""
    M, MD = (104, 110, 122, 255), (56, 60, 70, 255)
    DARK = (16, 18, 24, 255)
    c = boxed(M, MD, (150, 156, 168, 255), 7, 9, 24, 24)
    c.rect(9, 11, 22, 22, DARK)                             # the dark behind
    for yy in (12, 15, 18, 21):                             # bent slats
        c.rect(9, yy, 18, yy, MD)
    c.rect(19, 11, 22, 14, MD)                              # pried corner
    return c


def bulkhead():
    """Sealable bulkhead — heavy frame, hazard chevrons."""
    M, MD, ML = (130, 134, 146, 255), (70, 74, 86, 255), (175, 180, 192, 255)
    HAZ = (210, 170, 60, 255)
    c = boxed(M, MD, ML, 5, 4, 26, 27)
    c.rect(8, 7, 23, 24, (88, 92, 104, 255))                # door slab
    c.border(8, 7, 23, 24, MD)
    for i in range(4):                                      # chevron stripe
        c.rect(9 + i * 4, 15, 10 + i * 4, 16, HAZ)
    return c


def hunter(frame):
    """The Skriker — pale, long-limbed, joints in the wrong places, one red eye.
    Two frames for a slow crawling loop."""
    PALE, PALED = (212, 206, 198, 255), (140, 132, 124, 255)
    EYE = (235, 50, 50, 255)
    c = C()
    dy = 0 if frame == 0 else 1
    # low slung torso, too long
    c.rect(7, 14 + dy, 24, 19 + dy, PALE)
    c.rect(7, 19 + dy, 24, 19 + dy, PALED)
    # head hung below the shoulder line
    c.rect(23, 17 + dy, 27, 21 + dy, PALE)
    c.put(26, 19 + dy, EYE)                                  # the eye
    c.put(27, 19 + dy, EYE)
    # limbs — stilted, extra joints
    legs0 = [(9, 20, 7, 26), (13, 20, 15, 27), (18, 20, 16, 26), (22, 20, 24, 27)]
    legs1 = [(9, 21, 11, 27), (13, 21, 12, 26), (18, 21, 20, 27), (22, 21, 21, 26)]
    for (x0, y0, x1, y1) in (legs0 if frame == 0 else legs1):
        # upper segment
        c.rect(min(x0, x1), y0, max(x0, x1), y0 + 2, PALED)
        # lower segment to the foot
        c.rect(x1, y0 + 2, x1, y1, PALE)
        c.put(x1, y1, PALED)
    # spine ridge
    for x in range(8, 24, 3):
        c.put(x, 13 + dy, PALED)
    return c


def main():
    base = os.path.dirname(__file__)
    out = os.path.join(base, "objects")
    os.makedirs(out, exist_ok=True)
    sprites = {
        "pod": pod(), "device": device(), "op_board": op_board(),
        "fabber": fabber(), "psycho": psycho(), "comm": comm(),
        "debrief": debrief(), "stack": stack(), "relay": relay(),
        "researcher": researcher(), "archive": archive(), "specimen": specimen(),
        "generator": generator(), "vault": vault(), "core": core(),
        "elevator": elevator(), "vent": vent(), "bulkhead": bulkhead(),
    }
    for name, c in sprites.items():
        write_png(os.path.join(out, f"{name}.png"), c)
    hunter_dir = os.path.join(base, "hunter")
    os.makedirs(hunter_dir, exist_ok=True)
    for f in (0, 1):
        write_png(os.path.join(hunter_dir, f"{f}.png"), hunter(f))
    print("done:", ", ".join(sprites), "+ hunter x2")


if __name__ == "__main__":
    main()
