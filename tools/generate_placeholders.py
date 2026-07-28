#!/usr/bin/env python3
"""Generates placeholder pixel-art sprites for Pixel Crawler.

These are stand-ins that match the folder layout of the real asset pack
(tiles/, objects/, monsters/). Replace any PNG with your own art (same file
name) or remap paths in lib/config/game_assets.dart.

Usage: python3 tools/generate_placeholders.py
Requires: pillow
"""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "images")

# ---------------------------------------------------------------- helpers

def hex_rgba(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def from_ascii(rows, colors):
    """Build an RGBA image from ASCII art. '.' and ' ' are transparent."""
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in ". ":
                continue
            img.putpixel((x, y), colors[ch])
    return img


def strip(frames):
    """Concatenate frames horizontally into a sprite strip."""
    w = sum(f.width for f in frames)
    h = max(f.height for f in frames)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    for f in frames:
        out.paste(f, (x, h - f.height), f)
        x += f.width
    return out


def shifted(img, dy):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, dy), img)
    return out


def save(img, *path):
    p = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print("wrote", os.path.relpath(p, ROOT), img.size)


# ---------------------------------------------------------------- palette
OUT = hex_rgba("#1a1a24")      # outline
FLOOR = hex_rgba("#4a4a63")
FLOOR_D = hex_rgba("#3f3f54")
FLOOR_G = hex_rgba("#33334a")  # grout / cracks
WALL_TOP = hex_rgba("#23232f")
WALL_TOP_EDGE = hex_rgba("#2e2e3d")
BRICK = hex_rgba("#6a6a8c")
BRICK_D = hex_rgba("#55556f")
BRICK_LINE = hex_rgba("#3a3a4f")

# ---------------------------------------------------------------- tiles

def gen_floor():
    frames = []
    crack_sets = [
        [],
        [(3, 4), (4, 4), (4, 5), (11, 10), (12, 10)],
        [(9, 3), (10, 3), (5, 11), (5, 12), (6, 12)],
        [(2, 9), (3, 9), (12, 5), (13, 5), (13, 6), (8, 13)],
    ]
    for cracks in crack_sets:
        img = Image.new("RGBA", (16, 16), FLOOR)
        for x in range(16):
            for y in range(16):
                # subtle checker/dither for texture
                if (x * 7 + y * 13) % 11 == 0:
                    img.putpixel((x, y), FLOOR_D)
        for x in range(16):
            img.putpixel((x, 15), FLOOR_G)
            img.putpixel((x, 0), FLOOR_D)
        for y in range(16):
            img.putpixel((15, y), FLOOR_G)
        for c in cracks:
            img.putpixel(c, FLOOR_G)
        frames.append(img)
    save(strip(frames), "tiles", "floor.png")


def gen_wall_front():
    img = Image.new("RGBA", (16, 16), BRICK)
    for y in range(16):
        for x in range(16):
            if y % 4 == 3:
                img.putpixel((x, y), BRICK_LINE)
            elif ((x + (0 if (y // 4) % 2 == 0 else 4)) % 8) == 7:
                img.putpixel((x, y), BRICK_LINE)
            elif y % 4 == 0:
                img.putpixel((x, y), hex_rgba("#7a7a9e"))
    for x in range(16):
        img.putpixel((x, 15), OUT)
        img.putpixel((x, 14), BRICK_D)
    save(img, "tiles", "wall_front.png")


def gen_wall_top():
    img = Image.new("RGBA", (16, 16), WALL_TOP)
    for x in range(16):
        img.putpixel((x, 0), WALL_TOP_EDGE)
        if (x * 5) % 7 == 0:
            img.putpixel((x, (x * 3) % 16), WALL_TOP_EDGE)
    save(img, "tiles", "wall_top.png")


def gen_stairs():
    img = Image.new("RGBA", (16, 16), FLOOR_G)
    steps = [hex_rgba("#6a6a8c"), hex_rgba("#5a5a78"), hex_rgba("#4a4a63"),
             hex_rgba("#3a3a50"), hex_rgba("#2a2a3c"), hex_rgba("#1e1e2c")]
    for i, c in enumerate(steps):
        y0 = 2 + i * 2
        for y in (y0, y0 + 1):
            for x in range(2 + i, 14 - i):
                img.putpixel((x, y), c)
    for x in range(16):
        img.putpixel((x, 0), OUT)
        img.putpixel((x, 15), OUT)
    for y in range(16):
        img.putpixel((0, y), OUT)
        img.putpixel((15, y), OUT)
    save(img, "tiles", "stairs.png")


# ---------------------------------------------------------------- objects

def gen_chest():
    W = hex_rgba("#8a5a32")   # wood
    Wd = hex_rgba("#6b4425")
    G = hex_rgba("#f8d848")   # gold trim
    K = OUT
    I = hex_rgba("#3a3a4f")   # interior
    closed = from_ascii([
        "................",
        "................",
        "................",
        "................",
        "...KKKKKKKKKK...",
        "..KWWWWWWWWWWK..",
        "..KWwwwwwwwwWK..".replace("w", "W"),
        "..KGGGGGGGGGGK..",
        "..KWWWWGGWWWWK..",
        "..KWWWWGGWWWWK..",
        "..KWdWWWWWWdWK..".replace("d", "d"),
        "..KddddddddddK..",
        "..KKKKKKKKKKKK..",
        "................",
        "................",
        "................",
    ], {"K": K, "W": W, "G": G, "d": Wd})
    open_ = from_ascii([
        "................",
        "..KKKKKKKKKKKK..",
        "..KddddddddddK..",
        "..KWWWWWWWWWWK..",
        "..KGGGGGGGGGGK..",
        "..KKKKKKKKKKKK..",
        "..KIIIGGGGIIIK..",
        "..KIIGGGGGGIIK..",
        "..KIIIGGGGIIIK..",
        "..KWWWWWWWWWWK..",
        "..KWdWWWWWWdWK..",
        "..KddddddddddK..",
        "..KKKKKKKKKKKK..",
        "................",
        "................",
        "................",
    ], {"K": K, "W": W, "G": G, "d": Wd, "I": I})
    save(strip([closed, open_]), "objects", "chest.png")


def _potion(body_hex, light_hex, name):
    B = hex_rgba(body_hex)
    L = hex_rgba(light_hex)
    G = hex_rgba("#cfd8e8")  # glass
    C = hex_rgba("#8a5a32")  # cork
    img = from_ascii([
        "................",
        "................",
        "......CCCC......",
        "......CCCC......",
        ".....GGGGGG.....",
        ".....G....G.....",
        "....G......G....",
        "...G..BBBB..G...",
        "...G.BBLBBB.G...",
        "...G.BLBBBB.G...",
        "...G.BBBBBB.G...",
        "....GBBBBBBG....",
        ".....GBBBBG.....",
        "......GGGG......",
        "................",
        "................",
    ], {"B": B, "L": L, "G": G, "C": C})
    save(img, "objects", name)


def gen_coin():
    G = hex_rgba("#f8d848")
    Gd = hex_rgba("#c8a428")
    K = OUT
    frames = []
    for half_w in (5, 3, 1, 3):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        cx, cy, r = 8, 8, 5
        for y in range(16):
            for x in range(16):
                dx = (x - cx) / half_w if half_w else 99
                dy = (y - cy) / r
                d = dx * dx + dy * dy
                if d <= 1.0:
                    img.putpixel((x, y), G if d < 0.55 else Gd)
                elif d <= 1.45:
                    img.putpixel((x, y), K)
        frames.append(img)
    save(strip(frames), "objects", "coin.png")


def gen_torch():
    H = hex_rgba("#8a5a32")
    Hd = hex_rgba("#6b4425")
    O = hex_rgba("#ff9e3d")
    Y = hex_rgba("#ffd83d")
    R = hex_rgba("#e8642c")
    flames = [
        ["......YY........", ".....YYOO.......", ".....OYYO.......", "......OO........"],
        ["........YY......", ".......OOYY.....", ".......OYYO.....", "........OO......"],
        ["......YYY.......", ".....YOOYY......", ".....ROYYO......", "......OOR......."],
        [".......YY.......", "......YYOO......", "......OYYR......", ".......OO......."],
    ]
    frames = []
    for fl in flames:
        rows = ["................"] * 2 + fl + [
            ".......RR.......",
            "......HHHH......",
            ".......HH.......",
            ".......Hd.......".replace("d", "d"),
            ".......Hd.......",
            ".......Hd.......",
            ".......dd.......",
            "................",
            "................",
            "................",
        ]
        frames.append(from_ascii(rows, {"H": H, "d": Hd, "O": O, "Y": Y, "R": R}))
    save(strip(frames), "objects", "torch.png")


# ---------------------------------------------------------------- monsters

def _two_frame(f1, f2):
    return strip([f1, f2, f1, f2])


def gen_slime(body_hex, dark_hex, name, folder="monsters", crown=False):
    B = hex_rgba(body_hex)
    D = hex_rgba(dark_hex)
    L = hex_rgba("#ffffff", 160)
    E = OUT
    C = hex_rgba("#f8d848")
    tall_rows = [
        "................",
        "................",
        "................",
        "................",
        "......BBBB......",
        "....BBBBBBBB....",
        "...BBLBBBBBBB...",
        "...BLBBBBBBBB...",
        "..BBBBBBBBBBBB..",
        "..BBEEBBBBEEBB..",
        "..BBEEBBBBEEBB..",
        "..BBBBBDDBBBBB..",
        ".BBBBBBBBBBBBBB.",
        ".BDBBBBBBBBBBDB.",
        "..DDBBBBBBBBDD..",
        "...DDDDDDDDDD...",
    ]
    squash_rows = [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        ".....BBBBBB.....",
        "...BBBLBBBBB....",
        "..BBLBBBBBBBB...",
        ".BBBBBBBBBBBBB..",
        ".BBEEBBBBBBEEB..",
        ".BBEEBBBBBBEEB..",
        "BBBBBBDDBBBBBBB.",
        "BBBBBBBBBBBBBBBB",
        "BDBBBBBBBBBBBBDB",
        ".DDDDDDDDDDDDDD.",
    ]
    cmap = {"B": B, "D": D, "L": L, "E": E, "C": C}
    f1 = from_ascii(tall_rows, cmap)
    f2 = from_ascii(squash_rows, cmap)
    if crown:
        crown_rows = [
            "....C..CC..C....",
            "....CCCCCCCC....",
        ]
        cimg = from_ascii(crown_rows, cmap)
        f1.paste(cimg, (0, 2), cimg)
        f2.paste(cimg, (0, 4), cimg)
    save(_two_frame(f1, f2), folder, name)


def gen_bat():
    B = hex_rgba("#6a5a8c")
    D = hex_rgba("#4a3f63")
    E = hex_rgba("#ff5a5a")
    up = from_ascii([
        "................",
        "................",
        "................",
        "..D..........D..",
        ".DDD........DDD.",
        ".DDDD..BB..DDDD.",
        ".DDDDDBBBBDDDDD.",
        "..DDDBBBBBBDDD..",
        "...DBBEBBEBBD...",
        "....BBBBBBBB....",
        ".....BBBBBB.....",
        "......B..B......",
        "................",
        "................",
        "................",
        "................",
    ], {"B": B, "D": D, "E": E})
    down = from_ascii([
        "................",
        "................",
        "................",
        "................",
        "................",
        ".......BB.......",
        "..DD.BBBBBB.DD..",
        ".DDDDBBBBBBDDDD.",
        ".DDDDBEBBEBDDDD.",
        "..DD.BBBBBB.DD..",
        ".....BBBBBB.....",
        "......B..B......",
        "................",
        "................",
        "................",
        "................",
    ], {"B": B, "D": D, "E": E})
    save(_two_frame(up, down), "monsters", "bat.png")


def gen_skeleton():
    B = hex_rgba("#e8e8dc")
    D = hex_rgba("#b8b8a8")
    K = OUT
    R = hex_rgba("#8c1a1a")
    base = from_ascii([
        "................",
        "................",
        "....KKKKKKKK....",
        "...KBBBBBBBBK...",
        "...KBBBBBBBBK...",
        "...KBKKBBKKBK...",
        "...KBKKBBKKBK...",
        "...KBBBBBBBBK...",
        "....KBKKKKB.....",
        "....KKBBBBKK....",
        "......KBBK......",
        "...KBBBBBBBBK...",
        "..KBKBDDDDBKBK..",
        "..KBKBBBBBBKBK..",
        "..KBKBDDDDBKBK..",
        "...K.BBBBBB.K...",
        ".....KBKKBK.....",
        ".....KBKKBK.....",
        ".....KBKKBK.....",
        ".....BBKKBB.....",
        "................",
        "................",
        "................",
        "................",
    ], {"B": B, "D": D, "K": K, "R": R})
    save(_two_frame(base, shifted(base, -1)), "monsters", "skeleton.png")


def gen_goblin():
    S = hex_rgba("#5c9a3f")   # skin
    Sd = hex_rgba("#457a2c")
    C = hex_rgba("#8a5a32")   # cloth
    K = OUT
    E = hex_rgba("#ffd83d")   # eyes
    base = from_ascii([
        "................",
        "................",
        "................",
        "................",
        ".K............K.",
        ".KSK..KKKK..KSK.",
        ".KSSKKSSSSKKSSK.",
        "..KSSSSSSSSSSK..",
        "...KSESSSSESK...",
        "...KSESSSSESK...",
        "...KSSSKKSSSK...",
        "....KSSSSSSK....",
        ".....KSSSSK.....",
        "....KCCCCCCK....",
        "...KSCCCCCCSK...",
        "...KSKCCCCKSK...",
        "....KKCCCCKK....",
        ".....KSKKSK.....",
        ".....KSKKSK.....",
        "....KSSKKSSK....",
        "................",
        "................",
        "................",
        "................",
    ], {"S": S, "d": Sd, "C": C, "K": K, "E": E})
    save(_two_frame(base, shifted(base, -1)), "monsters", "goblin.png")


# ---------------------------------------------------------------- heroes

def _hero(rows, cmap, name):
    base = from_ascii(rows, cmap)
    save(_two_frame(base, shifted(base, -1)), "heroes", name)


def gen_knight():
    S = hex_rgba("#c0c8d8")   # steel
    Sd = hex_rgba("#8892a8")
    R = hex_rgba("#d84c4c")   # plume
    K = OUT
    V = hex_rgba("#2a3040")   # visor
    G = hex_rgba("#f8d848")
    _hero([
        "................",
        "......RRRR......",
        ".....RRRRRR.....",
        "....KSSSSSSK....",
        "...KSSSSSSSSK...",
        "...KSSSSSSSSK...",
        "...KSVVVVVVSK...",
        "...KSVVVVVVSK...",
        "...KSSSSSSSSK...",
        "....KSSSSSSK....",
        "...KSdSSSSdSK...".replace("d", "d"),
        "..KSSKSSSSKSSK..",
        "..KSdKSGGSKdSK..",
        "..KSdKSSSSKdSK..",
        "..KSSKSddSKSSK..",
        "...KK.KSSK.KK...",
        "......KddK......",
        ".....KSSSSK.....",
        ".....KSKKSK.....",
        "....KSSKKSSK....",
        "....KddKKddK....",
        "................",
        "................",
        "................",
    ], {"S": S, "d": Sd, "R": R, "K": K, "V": V, "G": G}, "knight.png")


def gen_mage():
    P = hex_rgba("#7a4cd8")   # robe
    Pd = hex_rgba("#5a36a8")
    F = hex_rgba("#f0c8a0")   # face
    W = hex_rgba("#e8e8e8")   # beard
    K = OUT
    Y = hex_rgba("#f8d848")   # star / staff tip
    _hero([
        "................",
        ".......KK.......",
        "......KPPK......",
        ".....KPPPPK.....",
        "....KPPYPPPK....",
        "...KPPPPPPPPK...",
        "..KPPPPPPPPPPK..",
        ".KKKKKKKKKKKKKK.",
        "...KFFFFFFFFK...",
        "...KFKFFFFKFK...",
        "...KWFFFFFFWK...",
        "....KWWWWWWK....",
        "...KPPWWWWPPK...",
        "..KPdPPPPPPdPK..",
        "..KPdPPYYPPdPK..",
        "..KPdPPPPPPdPK..",
        "..KPPPPPPPPPPK..",
        "..KPdPPPPPPdPK..",
        "..KPPPPPPPPPPK..",
        ".KPPPPPPPPPPPPK.",
        ".KddddddddddddK.",
        "................",
        "................",
        "................",
    ], {"P": P, "d": Pd, "F": F, "W": W, "K": K, "Y": Y}, "mage.png")


def gen_hunter():
    G = hex_rgba("#4ca85c")   # tunic
    Gd = hex_rgba("#357a42")
    H = hex_rgba("#8a6a42")   # leather
    Hd = hex_rgba("#6b4f2e")
    F = hex_rgba("#f0c8a0")
    K = OUT
    E = hex_rgba("#2a3040")
    _hero([
        "................",
        "................",
        "....KGGGGGGK....",
        "...KGGGGGGGGK...",
        "..KGGGGGGGGGGK..",
        "..KGdKKKKKKdGK..",
        "..KGKFFFFFFKGK..",
        "..KGKFEFFEFKGK..",
        "...KKFFFFFFKK...",
        "....KFFddFFK....",
        ".....KFFFFK.....",
        "....KGGGGGGK....",
        "...KHGGGGGGHK...",
        "..KFKGdGGdGKFK..",
        "..KFKHHHHHHKFK..",
        "...KKGGGGGGKK...",
        "....KGdGGdGK....",
        ".....KHKKHK.....",
        ".....KHKKHK.....",
        "....KHHKKHHK....",
        "....KddKKddK....".replace("d", "H"),
        "................",
        "................",
        "................",
    ], {"G": G, "d": Gd, "H": H, "F": F, "K": K, "E": E}, "hunter.png")


def gen_rogue():
    C = hex_rgba("#4a4a5a")   # cloak
    Cd = hex_rgba("#34343f")
    F = hex_rgba("#f0c8a0")
    K = OUT
    E = hex_rgba("#c8e0ff")   # sharp eyes
    M = hex_rgba("#8c1a1a")   # mask
    _hero([
        "................",
        "................",
        "....KCCCCCCK....",
        "...KCCCCCCCCK...",
        "..KCCCCCCCCCCK..",
        "..KCdCCCCCCdCK..",
        "..KCKFFFFFFKCK..",
        "..KCKEFFFFEKCK..",
        "..KCKMMMMMMKCK..",
        "...KKMMMMMMKK...",
        "....KKKKKKKK....",
        "....KCCCCCCK....",
        "...KCCCCCCCCK...",
        "..KFKCdCCdCKFK..",
        "..KKKCCCCCCKKK..",
        "...KCCdCCdCCK...",
        "....KCCCCCCK....",
        ".....KCKKCK.....",
        ".....KCKKCK.....",
        "....KCdKKdCK....".replace("d", "C"),
        "....KKK..KKK....",
        "................",
        "................",
        "................",
    ], {"C": C, "d": Cd, "F": F, "K": K, "E": E, "M": M}, "rogue.png")


# ---------------------------------------------------------------- effects

def gen_slash():
    W = hex_rgba("#ffffff")
    B = hex_rgba("#c8e0ff")
    frames = []
    arcs = [
        ["..W.............", "...W............", "....W...........", ".....W..........",
         "......W.........", "......W.........", ".....W..........", "....W..........."],
        ["....WW..........", ".....WWB........", "......WWB.......", ".......WWB......",
         ".......WWB......", "......WWB.......", ".....WWB........", "....WW.........."],
        ["......BB........", ".......BB.......", "........BB......", "........BB......",
         ".......BB.......", "......BB........", "................", "................"],
    ]
    for a in arcs:
        rows = ["................"] * 4 + a + ["................"] * 4
        frames.append(from_ascii(rows, {"W": W, "B": B}))
    save(strip(frames), "effects", "slash.png")


def gen_fireball():
    Y = hex_rgba("#ffd83d")
    O = hex_rgba("#ff9e3d")
    R = hex_rgba("#e8642c")
    frames = []
    for i in range(4):
        rows = [
            "................",
            "................",
            "................",
            "................",
            "................",
            "......ROO.......",
            "....RROOYO......",
            "...RROYYYYO.....",
            "...ROYYYYYO.....",
            "....RROYYO......",
            "......ROO.......",
            "................",
            "................",
            "................",
            "................",
            "................",
        ]
        img = from_ascii(rows, {"Y": Y, "O": O, "R": R})
        frames.append(shifted(img, -1 if i % 2 else 0))
    save(strip(frames), "effects", "fireball.png")


def gen_arrow():
    W = hex_rgba("#8a5a32")
    T = hex_rgba("#c0c8d8")
    F = hex_rgba("#d84c4c")
    img = from_ascii([
        "................",
        "................",
        "................",
        "................",
        "................",
        "..............T.",
        "............TTT.",
        ".FFWWWWWWWWWTTT.",
        "..F.........TT..",
        ".F........T.....",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {"W": W, "T": T, "F": F})
    save(img, "effects", "arrow.png")


def gen_blob_shot():
    B = hex_rgba("#4ca8e8")
    D = hex_rgba("#3579b8")
    img = from_ascii([
        "................",
        "................",
        "................",
        "................",
        "................",
        "......BBB.......",
        ".....BBBBB......",
        "....BBBBBBB.....",
        ".....BBBDB......",
        "......BDB.......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {"B": B, "D": D})
    save(img, "effects", "blob.png")


# ---------------------------------------------------------------- ui

def _heart(fill_cols, name):
    R = hex_rgba("#e83c4c")
    Rd = hex_rgba("#b01e30")
    E = hex_rgba("#3a3a4f")
    K = OUT
    rows = [
        "................",
        "................",
        "..KKK....KKK....",
        ".KRRRK..KRRRK...",
        "KRRRRRKKRRRRRK..",
        "KRRRRRRRRRRRRK..",
        "KRRRRRRRRRRRRK..",
        "KRdRRRRRRRRdRK..",
        ".KRRRRRRRRRRK...",
        "..KRRRRRRRRK....",
        "...KRRRRRRK.....",
        "....KRRRRK......",
        ".....KRRK.......",
        "......KK........",
        "................",
        "................",
    ]
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    src = from_ascii(rows, {"R": R, "d": Rd, "K": K})
    for y in range(16):
        for x in range(16):
            p = src.getpixel((x, y))
            if p[3] == 0:
                continue
            if p == K:
                img.putpixel((x, y), K)
            elif x < fill_cols:
                img.putpixel((x, y), p)
            else:
                img.putpixel((x, y), E)
    save(img, "ui", name)


def main():
    gen_floor()
    gen_wall_front()
    gen_wall_top()
    gen_stairs()
    gen_chest()
    _potion("#e83c4c", "#ff8a94", "potion_red.png")
    _potion("#3c78e8", "#8ab4ff", "potion_blue.png")
    gen_coin()
    gen_torch()
    gen_slime("#5cc85c", "#3f9a3f", "slime.png")
    gen_bat()
    gen_skeleton()
    gen_goblin()
    gen_knight()
    gen_mage()
    gen_hunter()
    gen_rogue()
    gen_slime("#4ca8e8", "#3579b8", "slime_hero.png", folder="heroes", crown=True)
    gen_slash()
    gen_fireball()
    gen_arrow()
    gen_blob_shot()
    _heart(16, "heart_full.png")
    _heart(8, "heart_half.png")
    _heart(0, "heart_empty.png")


if __name__ == "__main__":
    main()
