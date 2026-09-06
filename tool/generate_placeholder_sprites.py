"""Generate cute placeholder PNG sprites for Nestarium."""

from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    raise SystemExit('Install Pillow: pip install pillow')

ROOT = Path(__file__).resolve().parent.parent / 'assets' / 'images'

ANIMALS = {
    'chicken': ((255, 220, 120), (255, 180, 60), 'body'),
    'mouse': ((180, 180, 190), (120, 120, 130), 'round'),
    'rabbit': ((245, 230, 240), (220, 180, 200), 'round'),
    'fox': ((255, 150, 90), (200, 90, 40), 'pointy'),
    'cow': ((240, 240, 245), (60, 60, 70), 'body'),
    'dragon': ((120, 200, 120), (40, 120, 60), 'pointy'),
    'unicorn': ((255, 200, 255), (180, 120, 255), 'round'),
}

EGGS = {
    'basic_egg': ((255, 248, 220), (255, 220, 160)),
    'forest_egg': ((200, 235, 200), (120, 180, 120)),
    'farm_egg': ((255, 235, 200), (220, 180, 120)),
    'magic_egg': ((230, 210, 255), (160, 120, 255)),
}


def draw_egg(draw: ImageDraw.ImageDraw, colors: tuple) -> None:
    fill, outline = colors
    draw.ellipse((28, 20, 100, 118), fill=fill, outline=outline, width=4)
    draw.ellipse((48, 36, 72, 58), fill=(255, 255, 255, 90))


def draw_body(draw: ImageDraw.ImageDraw, fill, outline, shape: str) -> None:
    if shape == 'round':
        draw.ellipse((24, 36, 104, 112), fill=fill, outline=outline, width=4)
        draw.ellipse((44, 52, 58, 66), fill=(255, 255, 255, 120))
        draw.ellipse((70, 52, 84, 66), fill=(255, 255, 255, 120))
    elif shape == 'pointy':
        draw.polygon([(64, 18), (104, 70), (88, 112), (40, 112), (24, 70)], fill=fill, outline=outline)
        draw.ellipse((48, 48, 60, 60), fill=(255, 255, 255, 120))
        draw.ellipse((68, 48, 80, 60), fill=(255, 255, 255, 120))
    else:
        draw.ellipse((30, 44, 98, 112), fill=fill, outline=outline, width=4)
        draw.ellipse((46, 58, 58, 70), fill=(255, 255, 255, 120))
        draw.ellipse((70, 58, 82, 70), fill=(255, 255, 255, 120))
        draw.polygon([(64, 24), (54, 44), (74, 44)], fill=outline)


def save_sprite(path: Path, draw_fn) -> None:
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_fn(draw)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, 'PNG')


def main() -> None:
    for name, colors in ANIMALS.items():
        fill, outline, shape = colors
        save_sprite(
            ROOT / 'animals' / f'{name}.png',
            lambda d, f=fill, o=outline, s=shape: draw_body(d, f, o, s),
        )

    for name, colors in EGGS.items():
        save_sprite(
            ROOT / 'eggs' / f'{name}.png',
            lambda d, c=colors: draw_egg(d, c),
        )

    for folder in ('mutations', 'ui'):
        target = ROOT / folder
        target.mkdir(parents=True, exist_ok=True)
        keep = target / '.gitkeep'
        if not keep.exists():
            keep.write_text('', encoding='utf-8')

    print('Generated placeholder sprites in', ROOT)


if __name__ == '__main__':
    main()
