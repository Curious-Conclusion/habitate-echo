"""Generate Octomorph pixel sprites (32x32 RGBA PNGs) — original art for Habitat Echo.

4 facing directions x 2 walk frames. Pure-stdlib PNG writer (no Pillow).
Run from the project root:  python art/gen_octomorph.py
"""
import struct
import zlib
import os
import math

W = H = 32

BODY   = (60, 180, 110, 255)
BODY_L = (120, 225, 160, 255)
BODY_D = (30, 110, 65, 255)
TENT   = (45, 140, 85, 255)
TENT_D = (30, 100, 60, 255)
EYE    = (245, 245, 250, 255)
PUP    = (25, 25, 40, 255)
CLEAR  = (0, 0, 0, 0)


def new_buf():
    return [CLEAR] * (W * H)


def put(buf, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        buf[y * W + x] = c


def disc(buf, cx, cy, r, col, outline):
    for y in range(H):
        for x in range(W):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= r:
                buf[y * W + x] = col
            elif d <= r + 1.2:
                buf[y * W + x] = outline


def body(buf):
    cx, cy, r = 16.0, 13.0, 9.0
    disc(buf, cx, cy, r, BODY, BODY_D)
    # soft top-left highlight
    for y in range(H):
        for x in range(W):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= r - 3 and (x + 0.5 - cx) < -1 and (y + 0.5 - cy) < -1:
                buf[y * W + x] = BODY_L


def tentacles(buf, frame):
    bases = [9, 13, 19, 23]
    for i, bx in enumerate(bases):
        sway = 1 if ((i + frame) % 2 == 0) else -1
        for yy in range(20, 28):
            off = sway * (yy - 23) if yy >= 24 else 0
            x = bx + off
            col = TENT_D if yy >= 26 else TENT
            put(buf, x, yy, col)
            put(buf, x + 1, yy, col)


def eye(buf, cx, cy, pdx, pdy):
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            put(buf, cx + dx, cy + dy, EYE)
    put(buf, cx + pdx, cy + pdy, PUP)


def eyes(buf, d):
    if d == "down":
        eye(buf, 12, 14, 0, 1); eye(buf, 20, 14, 0, 1)
    elif d == "up":
        eye(buf, 12, 11, 0, -1); eye(buf, 20, 11, 0, -1)
    elif d == "left":
        eye(buf, 11, 14, -1, 0); eye(buf, 16, 14, -1, 0)
    elif d == "right":
        eye(buf, 16, 14, 1, 0); eye(buf, 21, 14, 1, 0)


def write_png(path, buf):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(H):
        raw.append(0)  # filter: none
        for x in range(W):
            raw += bytes(buf[y * W + x])
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
            buf = new_buf()
            body(buf)
            tentacles(buf, fr)
            eyes(buf, d)
            write_png(os.path.join(out_dir, f"{d}_{fr}.png"), buf)
            print("wrote", d, fr)


if __name__ == "__main__":
    main()
