"""Crop Dream Echoes asset sheets into individually named PNG assets.

Expected source sheets:
  art/source_sheets/sheet_1_characters.png  (4x2)
  art/source_sheets/sheet_2_enemies.png    (3x3)
  art/source_sheets/sheet_3_scenes.png     (3x2)
  art/source_sheets/sheet_4_events.png     (4x3)
  art/source_sheets/sheet_5_items_nodes.png (6x5)

The script keeps a small margin inside each grid cell and optionally turns
near-background pixels (#111827) transparent. It never overwrites an existing
file unless --overwrite is supplied.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable

from PIL import Image


SHEETS = {
    "sheet_1_characters.png": (
        3, 3, True,
        [
            "char_warrior.png", "char_ranger.png", "char_mage.png",
            "char_cleric.png", "char_guardian.png", "char_assassin.png",
            "char_channeler.png", "char_alchemist.png", "char_blade_dancer.png",
        ],
    ),
    "sheet_2_enemies.png": (
        3, 3, True,
        [
            "enemy_rage.png", "enemy_envy.png", "enemy_pride.png",
            "enemy_gluttony.png", "enemy_fear.png", "enemy_sentinel.png",
            "enemy_mender.png", "enemy_greed_elite.png", "enemy_void_boss.png",
        ],
    ),
    "sheet_3_scenes.png": (
        4, 2, False,
        [
            "bg_title.png", "bg_map.png", "bg_battle.png", "bg_equipment.png",
            "bg_reward.png", "bg_recruit.png", "bg_shop.png", "bg_settle.png",
        ],
    ),
    "sheet_4_events.png": (
        4, 3, False,
        [
            "event_lost_caravan.png", "event_cracked_mirror_hall.png",
            "event_dream_orchard.png", "event_echo_library.png",
            "event_nameless_gatekeeper.png", "event_forgotten_station.png",
            "event_last_train.png", "event_sleeping_theater.png",
            "event_inverted_ward.png", "event_deep_dream_well.png",
            "event_false_awakening_room.png", "event_memory_auction.png",
        ],
    ),
    "sheet_5_items_nodes.png": (
        4, 8, True,
        [
            "item_potion_small.png", "item_potion_big.png",
            "item_stamina_tonic.png", "item_mana_tonic.png",
            "item_scroll.png", "item_bleed_needle.png",
            "item_thunder_rune.png", "item_ward_orb.png",
            "item_cleansing_incense.png", "item_dream_bomb.png",
            "item_rage_blade.png", "item_moon_staff.png",
            "item_shadow_bow.png", "item_ward_cloak.png",
            "item_iron_armor.png", "item_dreamweave_robe.png",
            "item_rage_charm.png", "item_echo_ring.png",
            "item_guardian_badge.png", "item_traveler_boots.png",
            "item_blood_contract.png", "item_healing_lantern.png",
            "item_mirror_blade.png", "item_resonant_core.png",
            "node_battle.png", "node_event.png", "node_reward.png",
            "node_recruit.png", "node_shop.png", "node_rest.png",
            "node_elite.png", "node_boss.png",
        ],
    ),
}

def crop_cells(image: Image.Image, columns: int, rows: int, margin: int) -> Iterable[Image.Image]:
    cell_w = image.width // columns
    cell_h = image.height // rows
    for row in range(rows):
        for col in range(columns):
            left = col * cell_w + margin
            top = row * cell_h + margin
            right = (col + 1) * cell_w - margin
            bottom = (row + 1) * cell_h - margin
            yield image.crop((left, top, right, bottom))


def remove_key_background(image: Image.Image, tolerance: int = 10) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    key = (0x11, 0x18, 0x27)
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if max(abs(r - key[0]), abs(g - key[1]), abs(b - key[2])) <= tolerance:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("art/source_sheets"))
    parser.add_argument("--output", type=Path, default=Path("art/generated"))
    parser.add_argument("--margin", type=int, default=24)
    parser.add_argument("--keep-background", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    missing = []
    written = 0
    for sheet_name, (columns, rows, remove_background, names) in SHEETS.items():
        source = args.source / sheet_name
        if not source.exists():
            missing.append(str(source))
            continue
        with Image.open(source) as image:
            cells = list(crop_cells(image, columns, rows, max(0, args.margin)))
        if len(cells) != len(names):
            raise RuntimeError(f"{sheet_name}: expected {len(names)} cells, got {len(cells)}")
        for cell, name in zip(cells, names):
            destination = args.output / name
            if destination.exists() and not args.overwrite:
                print(f"skip existing: {destination}")
                continue
            if remove_background and not args.keep_background:
                cell = remove_key_background(cell)
            cell.save(destination)
            written += 1

    if missing:
        print("missing sheets:")
        for path in missing:
            print(f"  {path}")
    print(f"wrote {written} assets to {args.output}")


if __name__ == "__main__":
    main()
