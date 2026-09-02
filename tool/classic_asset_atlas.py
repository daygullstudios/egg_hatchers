"""Build and unpack fixed-grid atlases used to redraw Classic game art."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ANIMAL_DIR = ROOT / "assets" / "images" / "animals"
EGG_DIR = ROOT / "assets" / "images" / "eggs"
WORK_DIR = ROOT / ".codex-run" / "classic-atlases"
SPECIAL_ANIMALS = {"boba_bazooka", "crossword_beast", "the_hatched_egg"}
GRID_SIZE = 4
CELL_SIZE = 256
ATLAS_SIZE = GRID_SIZE * CELL_SIZE


def _groups() -> dict[str, list[Path]]:
    animals = [
        path
        for path in sorted(ANIMAL_DIR.glob("*.png"))
        if path.stem not in SPECIAL_ANIMALS
    ]
    eggs = sorted(EGG_DIR.glob("*_v2.png"))
    return {
        "animals-1": animals[0:16],
        "animals-2": animals[16:32],
        "animals-3": animals[32:48],
        "eggs": eggs,
    }


def build() -> None:
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    for group_name, paths in _groups().items():
        atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
        for index, path in enumerate(paths):
            sprite = Image.open(path).convert("RGBA")
            sprite.thumbnail((220, 220), Image.Resampling.LANCZOS)
            column = index % GRID_SIZE
            row = index // GRID_SIZE
            x = column * CELL_SIZE + (CELL_SIZE - sprite.width) // 2
            y = row * CELL_SIZE + (CELL_SIZE - sprite.height) // 2
            atlas.alpha_composite(sprite, (x, y))
        atlas.save(WORK_DIR / f"{group_name}-input.png", optimize=True)
        (WORK_DIR / f"{group_name}-manifest.txt").write_text(
            "\n".join(path.name for path in paths) + "\n",
            encoding="ascii",
        )


def _remove_generated_checkerboard(atlas: Image.Image) -> Image.Image:
    rgb = atlas.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    background = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def is_background_color(x: int, y: int) -> bool:
        red, green, blue = pixels[x, y]
        return min(red, green, blue) >= 205 and max(red, green, blue) - min(
            red, green, blue
        ) <= 18

    def enqueue(x: int, y: int) -> None:
        offset = y * width + x
        if background[offset] or not is_background_color(x, y):
            return
        background[offset] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = Image.new("L", (width, height), 255)
    alpha.putdata([0 if value else 255 for value in background])
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.45))
    result = rgb.convert("RGBA")
    result.putalpha(alpha)
    return result


def apply(
    group_name: str,
    generated_path: Path,
    output_dir: Path | None = None,
) -> None:
    groups = _groups()
    if group_name not in groups:
        raise ValueError(f"Unknown atlas group: {group_name}")

    atlas = _remove_generated_checkerboard(Image.open(generated_path))
    if atlas.width != atlas.height:
        edge = min(atlas.size)
        left = (atlas.width - edge) // 2
        top = (atlas.height - edge) // 2
        atlas = atlas.crop((left, top, left + edge, top + edge))
    atlas = atlas.resize((ATLAS_SIZE, ATLAS_SIZE), Image.Resampling.LANCZOS)

    for index, asset_path in enumerate(groups[group_name]):
        column = index % GRID_SIZE
        row = index // GRID_SIZE
        sprite = atlas.crop(
            (
                column * CELL_SIZE,
                row * CELL_SIZE,
                (column + 1) * CELL_SIZE,
                (row + 1) * CELL_SIZE,
            )
        )
        destination = output_dir / asset_path.name if output_dir else asset_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        sprite.save(destination, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("build")
    apply_parser = subparsers.add_parser("apply")
    apply_parser.add_argument("group", choices=_groups().keys())
    apply_parser.add_argument("generated_path", type=Path)
    apply_parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()

    if args.command == "build":
        build()
    else:
        apply(args.group, args.generated_path, args.output_dir)


if __name__ == "__main__":
    main()
