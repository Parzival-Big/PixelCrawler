#!/usr/bin/env python3
"""Builds the game-ready sprites in assets/images/ from assets/raw_pack/.

The raw pack (1-bit style, 16x16, one file per frame) is the source of
truth; this script composes the animation strips and derived sprites the
game expects. Run it again whenever the raw pack changes:

    python3 tools/prepare_pack.py

Requires: pillow
"""
import os
import glob
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "assets", "raw_pack")
OUT = os.path.join(HERE, "..", "assets", "images")

# Pack palette.
LIGHT = (0xB9, 0xDD, 0xA7, 255)
MID = (0x68, 0xA0, 0x8A, 255)
DARK = (0x1E, 0x42, 0x50, 255)


def raw(*parts):
    return Image.open(os.path.join(RAW, *parts)).convert("RGBA")


def save(img, *path):
    p = os.path.join(OUT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print("wrote", os.path.relpath(p, OUT), img.size)


def strip(frames):
    w = sum(f.width for f in frames)
    h = max(f.height for f in frames)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    for f in frames:
        out.paste(f, (x, h - f.height), f)
        x += f.width
    return out


def clean_junk():
    """Removes macOS AppleDouble (._*) and .DS_Store files from the pack."""
    removed = 0
    for pattern in ("**/._*", "**/.DS_Store"):
        for f in glob.glob(os.path.join(RAW, pattern), recursive=True):
            os.remove(f)
            removed += 1
    print(f"removed {removed} junk files")


# ---------------------------------------------------------------- tiles

def tiles():
    save(strip([
        raw("floor_empty.png"),
        raw("floor_empty.png"),
        raw("floor_cracked.png"),
        raw("floor_flower_tile.png"),
    ]), "tiles", "floor.png")

    save(raw("floor_hole_ladder.png"), "tiles", "stairs.png")

    # Directional wall tiles: 5 texture variants per orientation.
    walls = {
        "wall_top": "wall_stone_top_{}.png",
        "wall_bottom": "wall_stone_bottom_{}.png",
        "wall_left": "wall_stone_left_{}.png",
        "wall_right": "wall_stone_right_{}.png",
        "wall_inner_tl": "wall_stone_inner_corner_topleft_{}.png",
        "wall_inner_tr": "wall_stone_inner_corner_topright_{}.png",
        "wall_inner_bl": "wall_stone_inner_corner_bottomleft_{}.png",
        "wall_inner_br": "wall_stone_inner_corner_bottomright_{}.png",
        "wall_outer_tl": "wall_stone_outer_corner_topleft_{}.png",
        "wall_outer_tr": "wall_stone_outer_corner_topright_{}.png",
        "wall_outer_bl": "wall_stone_outer_corner_bottomleft_{}.png",
        "wall_outer_br": "wall_stone_outer_corner_bottomright_{}.png",
    }
    for name, pattern in walls.items():
        save(strip([raw(pattern.format(i)) for i in range(5)]),
             "tiles", f"{name}.png")

    # Animated torch mounted on a south-facing wall.
    save(strip([raw(f"wall_stone_torch_frame_bottom_{i}.png") for i in range(4)]),
         "tiles", "torch_wall.png")


# -------------------------------------------------------------- objects

def objects():
    save(strip([raw("objects", "chest_closed.png"),
                raw("objects", "chest_opened.png")]),
         "objects", "chest.png")
    save(raw("objects", "small_coin.png"), "objects", "coin.png")
    save(raw("objects", "potion_full.png"), "objects", "potion_red.png")
    # The "+1 heart" pickup is food in this pack.
    save(raw("objects", "meat.png"), "objects", "potion_blue.png")
    save(strip([raw("objects", f"fire_pot_burning_frame_{i}.png")
                for i in range(6)]),
         "objects", "torch.png")
    for decor in ("barrel", "crate", "table"):
        save(raw("objects", f"{decor}.png"), "objects", f"{decor}.png")
    save(raw("objects", "skull_left.png"), "objects", "skull.png")
    save(raw("objects", "bone_right.png"), "objects", "bone.png")
    save(raw("objects", "sword.png"), "objects", "sword.png")
    save(raw("objects", "boot.png"), "objects", "boot.png")
    save(raw("objects", "shield.png"), "objects", "shield.png")


# ------------------------------------------------------------- monsters

def two_frames(name):
    return strip([raw("monsters", f"{name}.png"),
                  raw("monsters", f"{name}_.png")])


def monsters():
    save(two_frames("slime"), "monsters", "slime.png")
    save(two_frames("bat"), "monsters", "bat.png")
    save(two_frames("rat"), "monsters", "rat.png")
    save(two_frames("skeleton_warrior"), "monsters", "skeleton.png")
    save(two_frames("spider"), "monsters", "spider.png")
    save(two_frames("ghost"), "monsters", "ghost.png")


# --------------------------------------------------------------- heroes

def heroes():
    for hero in ("knight", "mage", "hunter", "rogue"):
        save(two_frames(hero), "heroes", f"{hero}.png")

    # The unlockable Slime is the pack slime wearing a little crown.
    frames = []
    for suffix in ("", "_"):
        img = raw("monsters", f"slime{suffix}.png").copy()
        top = _first_opaque_row(img)
        crown_y = max(0, top - 3)
        for dx in (5, 8, 11):
            img.putpixel((dx, crown_y), LIGHT)
        for x in range(5, 12):
            img.putpixel((x, crown_y + 1), LIGHT)
            img.putpixel((x, crown_y + 2), MID)
        frames.append(img)
    save(strip(frames), "heroes", "slime_hero.png")


def _first_opaque_row(img):
    for y in range(img.height):
        for x in range(img.width):
            if img.getpixel((x, y))[3] > 0:
                return y
    return 0


# -------------------------------------------------------------- effects

def from_ascii(rows, colors):
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch not in ". ":
                img.putpixel((x, y), colors[ch])
    return img


def effects():
    save(raw("objects", "arrow_right.png"), "effects", "arrow.png")

    # Slash arc and fireball are drawn in the pack palette (the pack has no
    # dedicated effect sprites).
    W, M = LIGHT, MID
    arcs = [
        ["..W.............", "...W............", "....W...........", ".....W..........",
         "......W.........", "......W.........", ".....W..........", "....W..........."],
        ["....WW..........", ".....WWM........", "......WWM.......", ".......WWM......",
         ".......WWM......", "......WWM.......", ".....WWM........", "....WW.........."],
        ["......MM........", ".......MM.......", "........MM......", "........MM......",
         ".......MM.......", "......MM........", "................", "................"],
    ]
    frames = []
    for a in arcs:
        rows = ["................"] * 4 + a + ["................"] * 4
        frames.append(from_ascii(rows, {"W": W, "M": M}))
    save(strip(frames), "effects", "slash.png")

    fire = [
        "................",
        "................",
        "................",
        "................",
        "................",
        "......MWW.......",
        "....MMWWWW......",
        "...MMWWWWWW.....",
        "...MWWWWWWW.....",
        "....MMWWWW......",
        "......MWW.......",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]
    fb_frames = []
    for i in range(4):
        img = from_ascii(fire, {"W": W, "M": M})
        if i % 2:
            shifted = Image.new("RGBA", img.size, (0, 0, 0, 0))
            shifted.paste(img, (0, -1), img)
            img = shifted
        fb_frames.append(img)
    save(strip(fb_frames), "effects", "fireball.png")


# ------------------------------------------------------------------- ui

def ui():
    variants = {}
    for i in range(5):
        img = raw("objects", f"heart_big_{i}.png")
        light = sum(
            1
            for y in range(img.height)
            for x in range(img.width)
            if img.getpixel((x, y))[:3] == LIGHT[:3] and img.getpixel((x, y))[3] > 0
        )
        variants[i] = (light, img)
    # Most light pixels = full heart, fewest = empty.
    by_light = sorted(variants.items(), key=lambda kv: kv[1][0])
    save(by_light[-1][1][1], "ui", "heart_full.png")
    save(variants[2][1], "ui", "heart_half.png")
    save(by_light[0][1][1], "ui", "heart_empty.png")
    print("heart light-pixel counts:",
          {k: v[0] for k, v in sorted(variants.items())})


def main():
    clean_junk()
    tiles()
    objects()
    monsters()
    heroes()
    effects()
    ui()


if __name__ == "__main__":
    main()
