"""Generate deterministic Classic gap-fill and Retro Pixel egg artwork."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
CLASSIC_DIR = ROOT / "assets" / "images" / "eggs"
RETRO_DIR = ROOT / "assets" / "images" / "egg_themes" / "retro_pixel"

THEMES = {
    "basic": ("#f3dca8", "#fff1c9", "#b98b52"),
    "forest": ("#74b86a", "#9bd18c", "#256d35"),
    "farm": ("#d99d64", "#f0bd7e", "#9b3d2f"),
    "magic": ("#8a63c7", "#ad87e2", "#f5cf55"),
    "jungle": ("#3f9d57", "#66c879", "#174f2b"),
    "ocean": ("#49a8c8", "#7bd4e5", "#165d8a"),
    "arctic": ("#a9dced", "#e5f8ff", "#4b91b3"),
    "dino": ("#9caf5c", "#c3d27c", "#55652f"),
    "space": ("#33287b", "#5848a8", "#d6bdf8"),
    "ancient": ("#b98b55", "#d8b477", "#70502f"),
    "royal": ("#7443a7", "#9a65ce", "#f4c542"),
    "celestial": ("#68aeda", "#a8daf3", "#fff0a6"),
    "void": ("#241537", "#4a2869", "#b05cff"),
    "boss_egg": ("#535963", "#777f8c", "#d43832"),
}

CLASSIC_IDS = ("ancient", "royal", "celestial", "void", "boss_egg")


def _motif(draw, egg_id, accent, scale=1):
    def box(x0, y0, x1, y1, fill=accent):
        draw.rectangle(
            tuple(int(value * scale) for value in (x0, y0, x1, y1)),
            fill=fill,
        )

    def line(points, fill=accent, width=1):
        draw.line(
            [(int(x * scale), int(y * scale)) for x, y in points],
            fill=fill,
            width=max(1, int(width * scale)),
        )

    if egg_id == "basic":
        for x, y in ((13, 14), (19, 20), (12, 23)):
            box(x, y, x + 1, y + 1)
    elif egg_id in ("forest", "jungle"):
        line(((10, 23), (20, 11)), width=2)
        box(8, 18, 13, 21)
        box(17, 12, 22, 15)
    elif egg_id == "farm":
        box(9, 15, 23, 18)
        box(12, 11, 20, 14)
        box(14, 19, 18, 24)
    elif egg_id == "magic":
        line(((16, 9), (16, 15)), width=1)
        line(((13, 12), (19, 12)), width=1)
        line(((10, 21), (14, 17), (18, 22), (22, 17)), width=1)
    elif egg_id == "ocean":
        line(((8, 15), (12, 13), (16, 15), (20, 13), (24, 15)), width=2)
        line(((8, 21), (12, 19), (16, 21), (20, 19), (24, 21)), width=2)
    elif egg_id == "arctic":
        line(((16, 10), (16, 24)), width=1)
        line(((10, 17), (22, 17)), width=1)
        line(((11, 12), (21, 22)), width=1)
        line(((21, 12), (11, 22)), width=1)
    elif egg_id == "dino":
        line(((17, 7), (14, 13), (18, 17), (13, 25)), width=1)
        box(9, 14, 11, 16)
        box(21, 20, 23, 22)
    elif egg_id == "space":
        for x, y in ((11, 13), (21, 10), (18, 22), (9, 24)):
            box(x, y, x + 1, y + 1)
        line(((14, 17), (17, 14), (20, 17), (17, 20), (14, 17)), width=1)
    elif egg_id == "ancient":
        line(((10, 12), (22, 12), (19, 16), (22, 20), (10, 20), (13, 16), (10, 12)), width=2)
        box(14, 22, 18, 24)
    elif egg_id == "royal":
        line(((9, 19), (9, 12), (13, 16), (16, 10), (19, 16), (23, 12), (23, 19), (9, 19)), width=2)
        box(10, 20, 22, 22)
    elif egg_id == "celestial":
        draw.ellipse((int(11 * scale), int(10 * scale), int(19 * scale), int(18 * scale)), fill=accent)
        line(((9, 22), (13, 19), (17, 22), (21, 19), (24, 22)), width=2)
    elif egg_id == "void":
        draw.ellipse((int(10 * scale), int(10 * scale), int(22 * scale), int(22 * scale)), fill=accent)
        draw.ellipse((int(14 * scale), int(8 * scale), int(24 * scale), int(20 * scale)), fill="#241537")
    elif egg_id == "boss_egg":
        line(((9, 10), (14, 15), (11, 20), (19, 25)), width=2)
        line(((23, 11), (18, 16), (22, 21)), width=2)


def generate_classic(egg_id):
    factor = 4
    base, light, accent = THEMES[egg_id]
    image = Image.new("RGBA", (96 * factor, 120 * factor), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    ellipse = tuple(value * factor for value in (20, 7, 76, 113))
    draw.ellipse(ellipse, fill=base, outline=accent, width=3 * factor)
    draw.ellipse(tuple(value * factor for value in (31, 18, 51, 32)), fill=light)
    _motif(draw, egg_id, accent, scale=factor * 3)
    asset_name = egg_id if egg_id.endswith("_egg") else f"{egg_id}_egg"
    image.resize((96, 120), Image.Resampling.LANCZOS).save(
        CLASSIC_DIR / f"{asset_name}.png"
    )


def generate_retro(egg_id):
    base, light, accent = THEMES[egg_id]
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    outer = [(16, 1), (12, 2), (9, 6), (7, 12), (6, 19), (8, 26), (12, 30), (16, 31), (20, 30), (24, 26), (26, 19), (25, 12), (23, 6), (20, 2)]
    inner = [(16, 3), (12, 4), (10, 8), (9, 13), (8, 19), (10, 25), (13, 28), (16, 29), (19, 28), (22, 25), (24, 19), (23, 13), (22, 8), (20, 4)]
    draw.polygon(outer, fill=accent)
    draw.polygon(inner, fill=base)
    draw.rectangle((12, 6, 17, 9), fill=light)
    _motif(draw, egg_id, accent)
    image.resize((64, 64), Image.Resampling.NEAREST).save(
        RETRO_DIR / f"{egg_id}.png"
    )


def main():
    CLASSIC_DIR.mkdir(parents=True, exist_ok=True)
    RETRO_DIR.mkdir(parents=True, exist_ok=True)
    for egg_id in CLASSIC_IDS:
        generate_classic(egg_id)
    for egg_id in THEMES:
        generate_retro(egg_id)


if __name__ == "__main__":
    main()
