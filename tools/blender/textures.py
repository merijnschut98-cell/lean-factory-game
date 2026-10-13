"""Generate the office textures with numpy and PIL (no internet, no Blender needed).

Every texture is tileable unless it is an atlas (screens, signage, boards).
Outputs go to game/assets/office/textures/ as <name>_albedo.png, <name>_normal.png
(OpenGL / glTF convention: +Y up) and <name>_orm.png (R occlusion = 1, G roughness,
B metallic, as glTF expects in its metallicRoughness texture).

The names follow the CC0 libraries' material names (carpet, plaster, concrete, ...)
so a photo texture from Poly Haven or ambientCG can later replace a file one to one.

Real-world size each tileable texture covers (build_office.py uses the same table):
carpet 1.0 m (2 x 2 carpet tiles of 0.5 m), ceiling 1.2 m (2 x 2 tiles of 0.6 m),
wood 1.2 m, plaster 2.0 m, concrete 2.0 m, paving 1.2 m, grass 2.0 m,
metal 0.5 m, fabric 0.25 m.

    python3 tools/blender/textures.py            # all textures
    python3 tools/blender/textures.py carpet obeya   # only these
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parents[2] / "game" / "assets" / "office" / "textures"

# Voltana's house colour (estimate: a utility blue between Enexis and Alliander's).
VOLTANA_BLUE = (14, 78, 160)
VOLTANA_LIGHT = (0, 160, 210)

_FONT_DIRS = [Path("/usr/share/fonts"), Path("/usr/local/share/fonts"), Path.home() / ".fonts"]


# --------------------------------------------------------------------------- helpers

def _font(size: int, bold: bool = False, hand: bool = False) -> ImageFont.ImageFont:
    """A system sans font (DejaVu / Liberation); PIL's own font when none is found."""
    wanted = (["FreeSansOblique.ttf", "DejaVuSans-Oblique.ttf"] if hand else
              ["DejaVuSans-Bold.ttf", "LiberationSans-Bold.ttf"] if bold else
              ["DejaVuSans.ttf", "LiberationSans-Regular.ttf"])
    for name in wanted:
        for root in _FONT_DIRS:
            hits = list(root.rglob(name)) if root.is_dir() else []
            if hits:
                return ImageFont.truetype(str(hits[0]), size)
    return ImageFont.load_default(size=size)


def fit_font(draw, text: str, max_w: float, size: int, bold: bool = True):
    """The largest font up to size whose rendering of text fits max_w pixels."""
    while size > 8:
        f = _font(size, bold=bold)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 2
    return _font(size, bold=bold)


def noise(n: int, seed: int, beta: float = 2.0, stretch=(1.0, 1.0),
          low: float = 1.0, high: float | None = None, shape=None) -> np.ndarray:
    """Tileable fractal noise in [0, 1]: white noise shaped in the FFT domain.

    beta is the spectral slope (0 white, 2 cloudy, 3 smooth); stretch > 1 on an axis
    suppresses variation along it, so stretch=(12, 1) gives streaks along x.
    """
    h, w = shape or (n, n)
    rng = np.random.default_rng(seed)
    fy = np.fft.fftfreq(h)[:, None] * h
    fx = np.fft.fftfreq(w)[None, :] * w
    r = np.sqrt((fx * stretch[0]) ** 2 + (fy * stretch[1]) ** 2)
    amp = 1.0 / np.maximum(r, 1e-6) ** (beta / 2)
    amp[r < low] = 0.0
    if high is not None:
        amp[r > high] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(rng.standard_normal((h, w))) * amp))
    out /= 3.0 * out.std() + 1e-9
    return np.clip(0.5 + 0.5 * out, 0.0, 1.0)


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) == 2 else t
    return np.asarray(a, float) * (1 - t) + np.asarray(b, float) * t


def rgb(c) -> np.ndarray:
    return np.asarray(c, float) / 255.0


def save_rgb(name: str, arr: np.ndarray, scale: float = 1.0) -> None:
    """Save a float sRGB array; scale < 1 downsizes (normal and ORM maps need less detail)."""
    img = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8))
    if scale != 1.0:
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
    img.save(OUT / f"{name}.png", optimize=True)


def save_img(name: str, img: Image.Image) -> None:
    img.save(OUT / f"{name}.png", optimize=True)


def save_normal(name: str, height: np.ndarray, strength: float, scale: float = 0.5) -> None:
    """Height (tileable, 0..1) to a tangent-space normal map, +Y up (glTF/OpenGL)."""
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5
    dup = (np.roll(height, 1, 0) - np.roll(height, -1, 0)) * 0.5  # row above minus below
    nx, ny, nz = -dx * strength, -dup * strength, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    save_rgb(f"{name}_normal", np.stack([nx, ny, nz], -1) / length[..., None] * 0.5 + 0.5, scale)


def save_orm(name: str, rough: np.ndarray, metal: float = 0.0, scale: float = 0.5) -> None:
    ones = np.ones_like(rough)
    save_rgb(f"{name}_orm", np.stack([ones, np.clip(rough, 0.02, 1), ones * metal], -1), scale)


def tile_mask(n: int, count: int, width: float) -> np.ndarray:
    """1 on the seams of a count x count tile grid, 0 inside, with soft edges."""
    p = np.arange(n) * count / n
    d = np.minimum(p % 1.0, 1.0 - p % 1.0) * n / count  # pixels to the nearest seam
    edge = np.clip(1.0 - d / width, 0.0, 1.0)
    return np.maximum(edge[None, :], edge[:, None])


def per_tile(n: int, count: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    vals = rng.uniform(-1, 1, (count, count))
    idx = (np.arange(n) * count // n)
    return vals[idx[:, None], idx[None, :]]


# --------------------------------------------------------------------------- tileable materials

def carpet(n=1024):
    """Loop-pile carpet tiles, 2 x 2 tiles of 0.5 m, laid quarter-turn (Dutch office norm)."""
    yy, xx = np.mgrid[0:n, 0:n]
    half = n // 2
    quarter = ((xx // half + yy // half) % 2).astype(bool)
    streak_x = noise(n, 1, beta=0.8, stretch=(6, 1))
    streak_y = noise(n, 2, beta=0.8, stretch=(1, 6))
    streak = np.where(quarter, streak_y, streak_x)
    loops = 0.5 + 0.25 * (np.sin(xx * 2 * np.pi / 3.2) + np.sin(yy * 2 * np.pi / 3.2))
    fine = noise(n, 3, beta=0.2)
    fleck = noise(n, 4, beta=0.4)
    soil = noise(n, 5, beta=3.0, low=1)
    base = rgb((84, 86, 90))       # anthracite-grey loop pile with blue-grey and light flecks
    blue = rgb((74, 82, 98))
    light = rgb((140, 142, 146))
    col = mix(base, blue, np.clip((streak - 0.35) * 2.0, 0, 1))
    col = mix(col, light, np.clip((fleck - 0.78) * 6.0, 0, 1))
    col *= (0.82 + 0.3 * fine * loops)[..., None]
    col *= (1.0 + 0.025 * per_tile(n, 2, 6) + 0.015 * np.where(quarter, 1.0, -1.0))[..., None]
    col *= (0.96 + 0.06 * soil)[..., None]
    seam = tile_mask(n, 2, 2.0)
    col *= (1.0 - 0.35 * seam)[..., None]
    save_rgb("carpet_albedo", col)
    height = 0.55 * loops * fine + 0.25 * streak - 0.5 * seam
    save_normal("carpet", height, 6.0, scale=1.0)
    save_orm("carpet", 0.9 + 0.08 * fine)


def ceiling(n=1024):
    """Mineral-fibre ceiling tiles 600 x 600 in a white exposed T-bar grid (2 x 2 tiles)."""
    rng = np.random.default_rng(11)
    img = Image.new("L", (n, n), 0)
    draw = ImageDraw.Draw(img)
    for _ in range(2600):  # the fissures of a 'fissured' mineral tile
        x, y = rng.uniform(0, n, 2)
        ang = rng.uniform(0, 2 * np.pi)
        pts = [(x, y)]
        for _ in range(rng.integers(2, 5)):
            ang += rng.normal(0, 0.8)
            x += math.cos(ang) * rng.uniform(2, 6)
            y += math.sin(ang) * rng.uniform(2, 6)
            pts.append((x, y))
        draw.line(pts, fill=int(rng.uniform(90, 200)), width=1)
    for _ in range(5000):
        x, y = rng.uniform(0, n, 2)
        draw.point((x, y), fill=int(rng.uniform(80, 255)))
    fiss = np.asarray(img.filter(ImageFilter.GaussianBlur(0.6)), float) / 255.0
    fine = noise(n, 12, beta=1.0)
    grid = tile_mask(n, 2, 11.0)  # 24 mm T-bar at 0.85 px / mm (half each side)
    bevel = np.clip(tile_mask(n, 2, 18.0) - grid, 0, 1)
    col = rgb((236, 235, 231)) * (0.96 + 0.05 * fine)[..., None]
    col *= (1.0 - 0.28 * fiss)[..., None]
    col *= (1.0 - 0.08 * bevel)[..., None]
    col = mix(col, rgb((242, 242, 240)), (grid > 0.5).astype(float))
    save_rgb("ceiling_albedo", col)
    height = 0.6 * fine - 0.8 * fiss - 0.5 * bevel + 0.4 * (grid > 0.5)
    save_normal("ceiling", height, 2.0)
    save_orm("ceiling", np.where(grid > 0.5, 0.45, 0.95 - 0.05 * fine))


def wood(n=1024):
    """Light oak-look laminate for desk tops; grain along x, covers 1.2 m."""
    yy, _ = np.mgrid[0:n, 0:n].astype(float)
    warp = noise(n, 21, beta=3.5, stretch=(6, 1))
    rings = np.sin((yy / n * 34 + warp * 3.0) * 2 * np.pi)
    grain = noise(n, 22, beta=1.2, stretch=(24, 1))
    pores = noise(n, 23, beta=0.3, stretch=(30, 1))
    patch = noise(n, 24, beta=3.0)
    t = np.clip(0.5 + 0.12 * rings + 0.7 * (grain - 0.5) + 0.25 * (patch - 0.5), 0, 1)
    col = mix(rgb((224, 200, 162)), rgb((192, 160, 118)), t)
    col *= (1.0 - 0.28 * np.clip((pores - 0.74) * 5.0, 0, 1))[..., None]
    save_rgb("wood_albedo", col)
    save_normal("wood", 0.3 * grain - 0.4 * np.clip((pores - 0.74) * 5, 0, 1), 1.5)
    save_orm("wood", 0.42 + 0.12 * patch + 0.08 * grain)


def plaster(n=1024):
    """White latex paint on plaster ('spuitwerk' fine texture); covers 2 m. Tint via factor."""
    mottle = noise(n, 31, beta=2.6)
    fine = noise(n, 32, beta=0.6)
    bumps = noise(n, 33, beta=1.4, low=40)
    col = rgb((238, 236, 231)) * (0.975 + 0.035 * mottle + 0.012 * fine)[..., None]
    save_rgb("plaster_albedo", col)
    save_normal("plaster", 0.7 * bumps + 0.3 * fine, 2.2)
    save_orm("plaster", 0.82 + 0.1 * mottle)


def concrete(n=1024):
    """Smooth cast concrete with stains and air pores; columns and the plinth. Covers 2 m."""
    rng = np.random.default_rng(41)
    big = noise(n, 42, beta=2.8)
    mid = noise(n, 43, beta=1.6)
    fine = noise(n, 44, beta=0.4)
    pores = np.zeros((n, n))
    for _ in range(900):
        x, y = rng.integers(0, n, 2)
        r = rng.integers(1, 4)
        pores[max(0, y - r):y + r, max(0, x - r):x + r] = rng.uniform(0.5, 1.0)
    col = rgb((168, 166, 160)) * (0.82 + 0.22 * big + 0.1 * mid + 0.05 * fine)[..., None]
    col *= (1.0 - 0.45 * pores)[..., None]
    save_rgb("concrete_albedo", col)
    save_normal("concrete", 0.4 * mid + 0.2 * fine - 0.8 * pores, 3.0)
    save_orm("concrete", 0.7 + 0.2 * mid - 0.1 * big)


def paving(n=1024):
    """Grey concrete pavers 300 x 300 outside the windows; covers 1.2 m (4 x 4 stones)."""
    stones = per_tile(n, 4, 51)
    mid = noise(n, 52, beta=1.8)
    fine = noise(n, 53, beta=0.3)
    joint = tile_mask(n, 4, 3.0)
    col = rgb((150, 148, 142)) * (0.9 + 0.06 * stones + 0.12 * mid + 0.06 * fine)[..., None]
    col = mix(col, rgb((70, 72, 66)), joint)
    save_rgb("paving_albedo", col)
    save_normal("paving", 0.3 * fine + 0.2 * mid - 1.0 * joint, 4.0)
    save_orm("paving", 0.85 + 0.1 * fine)


def grass(n=512):
    """Mown municipal grass seen through the windows; covers 2 m."""
    a = noise(n, 61, beta=0.3)
    b = noise(n, 62, beta=2.5)
    col = mix(rgb((62, 92, 38)), rgb((104, 132, 58)), np.clip(0.6 * a + 0.6 * b - 0.1, 0, 1))
    save_rgb("grass_albedo", col)
    save_orm("grass", 0.95 - 0.05 * a)


def metal(n=512):
    """Powder-coated steel (orange peel); neutral so one texture serves every colour. 0.5 m."""
    peel = noise(n, 71, beta=2.0, low=20, high=200)
    mottle = noise(n, 72, beta=3.0)
    col = np.ones((n, n, 3)) * rgb((214, 214, 214)) * (0.98 + 0.03 * mottle)[..., None]
    save_rgb("metal_albedo", col)
    save_normal("metal", peel, 1.2)
    save_orm("metal", 0.34 + 0.12 * mottle + 0.04 * peel)


def fabric(n=512):
    """Woven upholstery (chairs, screens); neutral mid grey, tinted per material. 0.25 m."""
    yy, xx = np.mgrid[0:n, 0:n].astype(float)
    weave = 0.5 + 0.5 * np.sin(xx * 2 * np.pi / 6) * np.sin(yy * 2 * np.pi / 6)
    slub = noise(n, 81, beta=0.8, stretch=(5, 1))
    fine = noise(n, 82, beta=0.2)
    col = np.ones((n, n, 3)) * (0.42 + 0.12 * weave + 0.1 * slub + 0.06 * fine)[..., None]
    save_rgb("fabric_albedo", col)
    save_normal("fabric", 0.6 * weave + 0.4 * fine, 3.0)
    save_orm("fabric", 0.92 + 0.06 * fine)


def glass(n=256):
    """Roughness only: faint smudges on otherwise clean glazing."""
    smudge = noise(n, 91, beta=2.4)
    save_orm("glass", 0.04 + 0.1 * np.clip((smudge - 0.55) * 2.5, 0, 1))


# --------------------------------------------------------------------------- drawn atlases

def _marker_line(draw, pts, fill, width=3, seed=0):
    """A slightly wobbly hand-drawn line through pts."""
    rng = np.random.default_rng(seed)
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) / 12))
        for i in range(steps):
            t = i / steps
            out.append((x0 + (x1 - x0) * t + rng.normal(0, 0.6), y0 + (y1 - y0) * t + rng.normal(0, 0.6)))
    out.append(pts[-1])
    draw.line(out, fill=fill, width=width, joint="curve")


def _scribble(draw, x, y, w, fill, rng, width=2, h=10):
    """Handwriting-like scribble: a wavy line standing in for unreadable small text."""
    pts = []
    for i in range(int(w / 3)):
        pts.append((x + i * 3, y + h / 2 + math.sin(i * 1.7 + rng.uniform(0, 3)) * h * 0.35
                    + rng.normal(0, 0.8)))
    draw.line(pts, fill=fill, width=width)


def obeya(w=1024, h=1024):
    """Two whiteboards of 2.4 x 1.2 m stacked in one atlas.

    Top: the KPI board (Veiligheid, Kwaliteit, Levering, Kosten, Mensen) with hand-drawn
    run charts against a dashed target. Bottom: the value stream of the connections process
    and an action list.
    """
    img = Image.new("RGB", (w, h), (246, 247, 246))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(101)
    title, head, hand = _font(30, bold=True, hand=True), _font(22, hand=True), _font(17, hand=True)
    black, blue, red, green = (30, 32, 40), (24, 64, 160), (196, 40, 36), (30, 130, 60)
    # --- top board: KPI board
    d.text((24, 14), "KPI-bord Aansluitingen Zuidmark", font=title, fill=blue)
    d.text((620, 22), "week 41", font=head, fill=black)
    cols = ["Veiligheid", "Kwaliteit", "Levering", "Kosten", "Mensen"]
    sub = ["incidenten", "first time right %", "doorlooptijd (dagen)", "uren / aansluiting",
           "bezetting %"]
    cw = (w - 40) // 5
    for i, (c, s) in enumerate(zip(cols, sub)):
        x0 = 20 + i * cw
        _marker_line(d, [(x0, 60), (x0, 490)], black, 2, seed=i)
        d.text((x0 + 10, 66), c, font=head, fill=black)
        d.text((x0 + 10, 94), s, font=hand, fill=(90, 90, 100))
        # axes and a run chart
        ox, oy, cw2, ch = x0 + 22, 440, cw - 44, 300
        _marker_line(d, [(ox, oy - ch), (ox, oy), (ox + cw2, oy)], black, 2, seed=10 + i)
        target = oy - ch * (0.35 if i == 2 else 0.55)
        for k in range(0, cw2, 14):
            d.line([(ox + k, target), (ox + k + 7, target)], fill=green, width=2)
        pts = []
        val = rng.uniform(0.4, 0.7)
        for k in range(8):
            val = np.clip(val + rng.normal(0.02 if i == 2 else 0, 0.08), 0.1, 0.95)
            pts.append((ox + 8 + k * (cw2 - 16) / 7, oy - ch * val))
        bad = (i == 2)  # lead time is above target: the problem the player solves
        if bad:
            pts = [(x, min(y, target - 10 - j * 6)) for j, (x, y) in enumerate(pts)]
        _marker_line(d, pts, red if bad else blue, 3, seed=20 + i)
        for x, y in pts:
            d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=red if bad else blue)
        # status dot
        d.ellipse([x0 + cw - 40, 70, x0 + cw - 16, 94], fill=red if bad or i == 1 else green)
        _scribble(d, x0 + 12, 455, cw - 40, black, rng)
    _marker_line(d, [(20, 60), (w - 20, 60)], black, 2, seed=30)
    _marker_line(d, [(20, 490), (w - 20, 490)], black, 2, seed=31)
    # --- bottom board: value stream and actions
    y0 = 512
    d.line([(0, y0), (w, y0)], fill=(200, 200, 200), width=4)
    d.text((24, y0 + 14), "Waardestroom aansluiting (huidige situatie)", font=title, fill=blue)
    steps = ["Aanvraag", "Intake", "Werkvoor-\nbereiding", "Planning", "Uitvoering"]
    bx = 30
    for i, s in enumerate(steps):
        x = bx + i * 196
        _marker_line(d, [(x, y0 + 80), (x + 150, y0 + 80), (x + 150, y0 + 170), (x, y0 + 170),
                         (x, y0 + 80)], black, 3, seed=40 + i)
        d.multiline_text((x + 12, y0 + 92), s, font=head, fill=black, spacing=2)
        if i < 4:
            _marker_line(d, [(x + 152, y0 + 125), (x + 192, y0 + 125)], black, 3, seed=50 + i)
            d.polygon([(x + 192, y0 + 125), (x + 182, y0 + 118), (x + 182, y0 + 132)], fill=black)
            # inventory triangle with the queue size underneath
            tx = x + 172
            d.polygon([(tx, y0 + 180), (tx - 14, y0 + 205), (tx + 14, y0 + 205)], outline=red)
            d.text((tx - 12, y0 + 208), ["12", "9", "47", "15"][i], font=hand, fill=red)
        d.text((x + 10, y0 + 232), "C/T", font=hand, fill=(90, 90, 100))
        _scribble(d, x + 50, y0 + 232, 90, (90, 90, 100), rng)
    # timeline ladder
    pts = []
    for i in range(5):
        x = bx + i * 196
        pts += [(x, y0 + 290), (x + 150, y0 + 290), (x + 150, y0 + 320), (x + 196, y0 + 320)]
    _marker_line(d, pts[:-1], black, 2, seed=60)
    d.text((24, y0 + 340), "Acties", font=head, fill=blue)
    for r in range(5):
        y = y0 + 372 + r * 26
        d.rectangle([28, y + 4, 42, y + 18], outline=black, width=2)
        if r < 2:
            _marker_line(d, [(30, y + 10), (35, y + 16), (44, y + 2)], green, 3, seed=70 + r)
        _scribble(d, 54, y + 2, int(rng.uniform(220, 420)), black, rng)
        _scribble(d, 600, y + 2, 120, black, rng)
    d.text((600, y0 + 340), "wie / wanneer", font=hand, fill=(90, 90, 100))
    # marker ghosting: old wiped text
    ghost = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(ghost)
    for _ in range(30):
        _scribble(gd, rng.uniform(0, w - 200), rng.uniform(0, h - 20), rng.uniform(80, 260),
                  255, rng, width=3)
    ghost = ghost.filter(ImageFilter.GaussianBlur(2))
    arr = np.asarray(img, float) / 255.0
    arr *= (1.0 - 0.06 * np.asarray(ghost, float)[..., None] / 255.0)
    save_rgb("obeya_albedo", arr)


def missions(w=1024, h=512):
    """The mission board: a cork pinboard with mission cards (decorative; the UI shows the real ones)."""
    cork = noise(w, 111, beta=0.9, shape=(h, w))
    big = noise(w, 112, beta=2.6, shape=(h, w))
    col = mix(rgb((170, 128, 82)), rgb((128, 88, 52)), np.clip(cork * 0.8 + big * 0.4 - 0.1, 0, 1))
    img = Image.fromarray((col * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(113)
    head = _font(54, bold=True)
    d.rectangle([24, 18, 330, 92], fill=VOLTANA_BLUE)
    d.text((44, 24), "MISSIES", font=head, fill=(255, 255, 255))
    labels = [("HOOFDMISSIE", VOLTANA_BLUE, (255, 255, 255)), ("ZIJMISSIE", (250, 214, 60), (40, 40, 40)),
              ("ZIJMISSIE", (250, 214, 60), (40, 40, 40)), ("AFGEROND", (90, 160, 90), (255, 255, 255))]
    small = _font(20, bold=True)
    cards = [(40, 120, 0), (290, 130, 1), (540, 116, 2), (790, 128, 3), (60, 320, 0), (320, 318, 3),
             (580, 326, 3)]
    for x, y, kind in cards:
        x += int(rng.integers(-6, 6))
        card = Image.new("RGBA", (200, 160), (250, 249, 244, 255))
        cd = ImageDraw.Draw(card)
        name, band, ink = labels[kind]
        cd.rectangle([0, 0, 200, 34], fill=band)
        cd.text((10, 6), name, font=small, fill=ink)
        for r in range(4):
            _scribble(cd, 12, 48 + r * 24, int(rng.uniform(110, 175)), (40, 40, 60), rng)
        if kind == 3:
            _marker_line(cd, [(140, 120), (155, 140), (188, 100)], (30, 130, 60), 5, seed=x)
        card = card.rotate(rng.uniform(-4, 4), expand=True, resample=Image.BICUBIC)
        shadow = Image.new("RGBA", card.size, (0, 0, 0, 0))
        shadow.paste((0, 0, 0, 90), mask=card.split()[3])
        img.paste(shadow.filter(ImageFilter.GaussianBlur(4)), (x + 4, y + 6), shadow.filter(ImageFilter.GaussianBlur(4)))
        img.paste(card, (x, y), card)
        px, py = x + card.size[0] // 2, y + 8
        d.ellipse([px - 7, py - 7, px + 7, py + 7], fill=(200, 30, 30), outline=(120, 10, 10))
    save_img("missions_albedo", img)


def signage(w=1024, h=512):
    """Voltana logo wall, zone signs, the coach's door sign and a green exit sign.

    Layout (pixels): logo 0..1024 x 0..192; zone signs 256 x 96 in row 192..288
    (Intake, Werkvoorbereiding, Obeya, Koffie); row 288..384: door sign 512 wide, exit
    sign 256, 'Planning' sign 256; row 384..512: the screen wallpaper strip.
    build_office.py maps its quads to these rectangles (SIGN_RECTS).
    """
    img = Image.new("RGB", (w, h), (255, 255, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, 192], fill=VOLTANA_BLUE)
    _logo(d, 96, 96, 70)
    d.text((190, 44), "Voltana", font=_font(84, bold=True), fill=(255, 255, 255))
    d.text((560, 66), "Netbeheer", font=_font(64), fill=(190, 222, 255))
    d.text((192, 140), "Klantzaken & Aansluitingen  ·  regio Zuidmark", font=_font(26), fill=(210, 230, 255))
    zones = ["Intake", "Werkvoorbereiding", "Obeya", "Koffie"]
    for i, z in enumerate(zones):
        x = i * 256
        d.rectangle([x, 192, x + 255, 287], fill=VOLTANA_BLUE)
        d.rectangle([x, 192, x + 10, 287], fill=VOLTANA_LIGHT)
        f = fit_font(d, z, 226, 40)
        tw = d.textlength(z, font=f)
        d.text((x + 10 + (246 - tw) / 2, 240 - f.size * 0.6), z, font=f, fill=(255, 255, 255))
    # door sign (white with blue band)
    d.rectangle([0, 288, 511, 383], fill=(244, 246, 248))
    d.rectangle([0, 288, 14, 383], fill=VOLTANA_BLUE)
    d.text((32, 300), "Ingrid", font=_font(36, bold=True), fill=(30, 34, 44))
    d.text((32, 344), "Manager Aansluitingen", font=_font(26), fill=(70, 76, 90))
    # exit sign (NEN-EN-ISO 7010 E001 green)
    d.rectangle([512, 288, 767, 383], fill=(0, 140, 70))
    f = fit_font(d, "NOODUITGANG", 230, 30)
    d.text((524, 318), "NOODUITGANG", font=f, fill=(255, 255, 255))
    d.rectangle([768, 288, 1023, 383], fill=VOLTANA_BLUE)
    d.rectangle([768, 288, 778, 383], fill=VOLTANA_LIGHT)
    d.text((820, 312), "Planning", font=_font(40, bold=True), fill=(255, 255, 255))
    # wallpaper strip for locked screens
    grad = np.linspace(0, 1, w)[None, :, None]
    strip = mix(rgb((8, 40, 96)), rgb((20, 110, 190)), np.broadcast_to(grad, (128, w, 1))[..., 0])
    img.paste(Image.fromarray((strip * 255).astype(np.uint8)), (0, 384))
    d = ImageDraw.Draw(img)
    _logo(d, 470, 448, 34)
    d.text((520, 422), "Voltana", font=_font(40, bold=True), fill=(255, 255, 255))
    save_img("signage_albedo", img)


def _logo(d, cx, cy, r):
    """Voltana mark: a ring with a lightning bolt."""
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255), width=max(3, r // 7))
    s = r / 70
    bolt = [(10, -52), (-26, 6), (-2, 6), (-12, 52), (28, -10), (4, -10), (16, -52)]
    d.polygon([(cx + x * s, cy + y * s) for x, y in bolt], fill=(255, 210, 40))


def screens(w=1024, h=1024):
    """Six monitor screens of 512 x 288 (16:9) in a 2 x 3 grid, Dutch work content."""
    img = Image.new("RGB", (w, h), (10, 10, 12))
    rng = np.random.default_rng(121)
    makers = [_screen_gis, _screen_queue, _screen_form, _screen_cad, _screen_mail, _screen_sheet]
    for i, make in enumerate(makers):
        sc = Image.new("RGB", (512, 288), (240, 240, 240))
        make(sc, ImageDraw.Draw(sc), rng)
        _taskbar(ImageDraw.Draw(sc))
        img.paste(sc, ((i % 2) * 512, (i // 2) * 288))
    save_img("screens_albedo", img)


def _window(d, title):
    d.rectangle([0, 0, 512, 22], fill=(250, 250, 250))
    d.text((8, 4), title, font=_font(12), fill=(40, 40, 40))
    for k, c in enumerate([(200, 200, 200), (200, 200, 200), (220, 70, 60)]):
        d.rectangle([440 + k * 24, 6, 454 + k * 24, 16], fill=c)


def _taskbar(d):
    d.rectangle([0, 270, 512, 288], fill=(32, 36, 44))
    d.rectangle([6, 273, 18, 285], fill=VOLTANA_LIGHT)
    for k in range(5):
        d.rectangle([40 + k * 22, 274, 54 + k * 22, 284], fill=(90 + k * 20, 120, 160))
    d.text((452, 273), "09:42", font=_font(11), fill=(230, 230, 230))


def _screen_gis(sc, d, rng):
    _window(d, "GIS Netkaart – Zuidmark  |  Lagen: LS / MS / aansluitingen")
    d.rectangle([0, 22, 512, 270], fill=(236, 233, 222))
    for _ in range(14):  # parcels
        x, y = rng.uniform(100, 500), rng.uniform(30, 260)
        d.rectangle([x, y, x + rng.uniform(20, 60), y + rng.uniform(15, 40)], outline=(200, 196, 180),
                    fill=(226, 222, 208))
    for y in (90, 190):
        d.line([(90, y), (512, y + 20)], fill=(255, 255, 255), width=9)
    d.line([(300, 22), (280, 270)], fill=(255, 255, 255), width=9)
    for col, wdt in (((220, 120, 20), 2), ((190, 20, 120), 3)):
        pts = [(rng.uniform(100, 500), rng.uniform(30, 260)) for _ in range(6)]
        d.line(sorted(pts), fill=col, width=wdt)
    for _ in range(25):
        x, y = rng.uniform(100, 500), rng.uniform(30, 260)
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(20, 90, 200))
    d.rectangle([330, 140, 342, 152], fill=(200, 30, 30))
    d.rectangle([0, 22, 90, 270], fill=(248, 248, 248))
    for k, (name, col) in enumerate([("LS-kabel", (220, 120, 20)), ("MS-kabel", (190, 20, 120)),
                                     ("Aansluiting", (20, 90, 200)), ("Station", (200, 30, 30))]):
        d.rectangle([6, 34 + k * 18, 14, 42 + k * 18], fill=col)
        d.text((18, 32 + k * 18), name, font=_font(10), fill=(40, 40, 40))


def _screen_queue(sc, d, rng):
    _window(d, "Werkvoorraad Werkvoorbereiding – 47 open")
    d.rectangle([0, 22, 512, 44], fill=VOLTANA_BLUE)
    heads = ["Aanvraag", "Adres", "Type", "Binnen", "Dagen"]
    xs = [8, 90, 250, 330, 420]
    for x, t in zip(xs, heads):
        d.text((x, 27), t, font=_font(11, bold=True), fill=(255, 255, 255))
    streets = ["Dorpsstraat", "Kerkweg", "Molenlaan", "Industrieweg", "Beukenlaan", "Stationsplein",
               "Havenkade", "Lindelaan", "De Hoven", "Esdoornstraat"]
    for r in range(11):
        y = 48 + r * 20
        if r % 2:
            d.rectangle([0, y - 2, 512, y + 16], fill=(230, 234, 240))
        days = int(rng.integers(3, 38))
        vals = [f"AAN-{24100 + r * 7}", f"{streets[r % 10]} {int(rng.integers(1, 90))}",
                ["3x25A", "3x35A", "3x80A", "MS 630kVA"][r % 4], f"{int(rng.integers(1, 28)):02d}-09", str(days)]
        for x, t in zip(xs, vals):
            fill = (200, 30, 30) if (t == vals[4] and days > 18) else (30, 30, 30)
            d.text((x, y), t, font=_font(11), fill=fill)


def _screen_form(sc, d, rng):
    _window(d, "Aansluitaanvraag – AAN-24133")
    d.text((16, 32), "Nieuwe aansluiting – bedrijventerrein De Hoven", font=_font(15, bold=True), fill=VOLTANA_BLUE)
    fields = ["Aanvrager", "EAN-code", "Gevraagde capaciteit", "Locatie", "Gewenste datum", "Status"]
    vals = ["Bakkerij Verhoeven BV", "871687120054xxxxxx", "3x80A", "Havenkade 14, Nova",
            "01-12", "Wacht op ontwerp"]
    for k, (f, v) in enumerate(zip(fields, vals)):
        y = 62 + k * 32
        d.text((16, y + 4), f, font=_font(12), fill=(80, 80, 80))
        d.rectangle([170, y, 490, y + 22], outline=(170, 170, 170), fill=(255, 255, 255))
        d.text((176, y + 4), v, font=_font(12), fill=(30, 30, 30))
    d.rectangle([360, 248, 490, 266], fill=VOLTANA_BLUE)
    d.text((380, 250), "Doorzetten", font=_font(12, bold=True), fill=(255, 255, 255))


def _screen_cad(sc, d, rng):
    d.rectangle([0, 0, 512, 270], fill=(22, 26, 34))
    d.text((8, 4), "Ontwerp LS-aansluiting  –  tekening 24-117", font=_font(12), fill=(200, 200, 210))
    for k in range(0, 512, 32):
        d.line([(k, 22), (k, 270)], fill=(32, 38, 48))
    for k in range(22, 270, 32):
        d.line([(0, k), (512, k)], fill=(32, 38, 48))
    d.line([(40, 220), (200, 220), (200, 90), (420, 90)], fill=(255, 200, 40), width=2)
    d.line([(200, 160), (330, 160), (330, 230)], fill=(80, 220, 120), width=2)
    for x, y in ((420, 90), (330, 230), (40, 220)):
        d.rectangle([x - 6, y - 6, x + 6, y + 6], outline=(255, 90, 90), width=2)
    d.rectangle([380, 200, 500, 262], outline=(160, 160, 170))
    d.text((386, 206), "Voltana Netbeheer\nschaal 1:500", font=_font(10), fill=(160, 160, 170))


def _screen_mail(sc, d, rng):
    _window(d, "Postvak IN – aansluitingen@voltana.nl")
    d.rectangle([0, 22, 130, 270], fill=(236, 240, 246))
    for k, f in enumerate(["Postvak IN (23)", "Verzonden", "Aanvragen", "Gemeente", "Archief"]):
        d.text((10, 32 + k * 20), f, font=_font(11), fill=(40, 40, 60))
    subj = ["RE: aanvullende gegevens aanvraag", "Vergunning Molenlaan afgewezen", "Planning week 42",
            "Vraag over offerte 3x80A", "Herinnering: ontbrekende tekening", "Storing Kerkweg opgelost",
            "Klant belt voor de 3e keer", "Overleg aannemer"]
    for k, s in enumerate(subj):
        y = 30 + k * 29
        d.text((140, y), ["Gemeente Nova", "Klantcontact", "Planning", "M. Jansen"][k % 4],
               font=_font(11, bold=(k < 3)), fill=(30, 30, 40))
        d.text((140, y + 13), s, font=_font(10), fill=(90, 90, 100))
        d.line([(136, y + 27), (512, y + 27)], fill=(225, 225, 230))


def _screen_sheet(sc, d, rng):
    _window(d, "Capaciteit_monteurs_Q4.xlsx")
    d.rectangle([0, 22, 512, 270], fill=(255, 255, 255))
    for k in range(0, 512, 64):
        d.line([(k, 22), (k, 270)], fill=(215, 215, 215))
    for k in range(22, 270, 18):
        d.line([(0, k), (512, k)], fill=(215, 215, 215))
    d.rectangle([0, 22, 512, 40], fill=(220, 234, 220))
    for c, t in enumerate(["Week", "Vraag", "Capaciteit", "Tekort", "Ingehuurd", "Backlog", "Doel", "%"]):
        d.text((4 + c * 64, 25), t, font=_font(10, bold=True), fill=(30, 60, 30))
    for r in range(1, 12):
        for c in range(8):
            v = str(40 + r) if c == 0 else str(int(rng.integers(5, 140)))
            d.text((4 + c * 64, 25 + r * 18), v, font=_font(10), fill=(30, 30, 30))
    # small bar chart
    for k in range(8):
        hgt = rng.uniform(20, 70)
        d.rectangle([330 + k * 20, 260 - hgt, 344 + k * 20, 260], fill=(60, 140, 80) if k < 5 else (200, 60, 50))


def dossier(n=512):
    """Paper and folder atlas (256 x 256 quadrants):
    TL paper stack edges, TR printed application form (top sheet), BL lever-arch file spines,
    BR rolled drawing paper.
    """
    img = Image.new("RGB", (n, n), (240, 238, 230))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(131)
    q = n // 2
    for y in range(q):  # stack edges: thin sheets with folders between
        tone = int(rng.uniform(205, 245))
        col = (tone, tone - 2, tone - 8)
        if rng.random() < 0.06:
            col = [(196, 160, 90), (120, 150, 190), (220, 120, 110), (200, 200, 120)][int(rng.integers(0, 4))]
        d.line([(0, y), (q, y)], fill=col)
    d.rectangle([q, 0, n, q], fill=(248, 247, 242))
    d.rectangle([q + 14, 12, q + 70, 30], fill=VOLTANA_BLUE)
    d.text((q + 78, 14), "Aanvraag aansluiting", font=fit_font(d, "Aanvraag aansluiting", q - 90, 16),
           fill=(30, 30, 40))
    for k in range(9):
        y = 46 + k * 21
        d.text((q + 14, y), ["Naam", "Adres", "EAN", "Capaciteit", "Datum", "Handt.", "", "", ""][k],
               font=_font(11), fill=(90, 90, 100))
        d.line([(q + 90, y + 14), (n - 14, y + 14)], fill=(170, 170, 180))
        if k < 6:
            _scribble(d, q + 96, y, int(rng.uniform(60, 130)), (30, 50, 140), rng, width=1, h=9)
    spines = [(30, 70, 140), (180, 40, 40), (60, 60, 64), (230, 190, 40), (40, 120, 70), (14, 78, 160),
              (120, 120, 126), (30, 70, 140)]
    sw = q // len(spines)
    for k, c in enumerate(spines):
        x = k * sw
        d.rectangle([x, q, x + sw - 2, n], fill=c)
        d.rectangle([x + 5, q + 30, x + sw - 7, q + 110], fill=(245, 245, 240))
        _scribble(d, x + 7, q + 50, sw - 16, (30, 30, 30), rng, width=1, h=8)
        d.ellipse([x + sw // 2 - 8, q + 170, x + sw // 2 + 6, q + 184], fill=(25, 25, 25))
    d.rectangle([q, q, n, n], fill=(236, 240, 246))
    for k in range(q, n, 16):
        d.line([(q, k), (n, k)], fill=(150, 175, 215))
    save_img("dossier_albedo", img)


def devices(n=512):
    """Device atlas: keyboard (0..512 x 0..160), desk phone keypad (0..160 x 160..352),
    coffee machine front (160..352 x 160..512), plotter control strip (352..512 x 160..256),
    monitor back / plastic grain (352..512 x 256..512)."""
    img = Image.new("RGB", (n, n), (34, 35, 38))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, n, 160], fill=(30, 31, 34))
    rows = [15, 14, 13, 12, 9]
    for r, cnt in enumerate(rows):
        kw = 470 / 15
        x = 8 + r * 6
        for k in range(cnt):
            w = kw * (6 if (r == 4 and k == 3) else 1) - 4
            d.rounded_rectangle([x, 8 + r * 30, x + w, 34 + r * 30], 3, fill=(52, 53, 58))
            d.rounded_rectangle([x + 1, 9 + r * 30, x + w - 1, 31 + r * 30], 3, fill=(60, 61, 66))
            x += w + 4
    d.rectangle([0, 160, 160, 352], fill=(44, 45, 48))
    d.rectangle([14, 172, 146, 214], fill=(160, 180, 150))
    d.text((22, 184), "Intern 4412", font=_font(14), fill=(30, 40, 30))
    for k in range(12):
        x, y = 22 + (k % 3) * 42, 226 + (k // 3) * 30
        d.rounded_rectangle([x, y, x + 32, y + 22], 4, fill=(70, 71, 76))
        d.text((x + 11, y + 3), "123456789*0#"[k], font=_font(13), fill=(220, 220, 220))
    d.rectangle([160, 160, 352, 512], fill=(26, 27, 30))
    d.rounded_rectangle([180, 180, 332, 260], 6, fill=(8, 10, 14))
    d.text((196, 196), "Kies je drank", font=_font(15), fill=(120, 200, 255))
    for k, t in enumerate(["Koffie", "Espresso", "Cappuccino", "Thee"]):
        y = 278 + k * 44
        d.rounded_rectangle([184, y, 328, y + 34], 6, fill=(56, 57, 62))
        d.text((196, y + 8), t, font=_font(15), fill=(230, 230, 230))
    d.rectangle([352, 160, 512, 256], fill=(210, 210, 212))
    d.rectangle([366, 172, 446, 214], fill=(30, 50, 70))
    for k in range(3):
        d.ellipse([456 + k * 0, 172 + k * 26, 476, 192 + k * 26], fill=(80, 80, 86))
    plastic = noise(160, 141, beta=0.4, shape=(256, 160))
    pl = (0.13 + 0.03 * plastic)[..., None] * np.ones(3)
    img.paste(Image.fromarray((pl * 255).astype(np.uint8)), (352, 256))
    save_img("devices_albedo", img)


def leaves(n=512):
    """Alpha foliage card for the office plants (ficus-like): leaves fanning out from the
    bottom centre, darker inside the crown. RGBA, used with alpha clip."""
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(151)
    base = (n / 2, n * 0.98)
    for k in range(70):
        # leaf centres fill an upper ellipse; inner leaves are drawn first and darker
        r = math.sqrt(rng.uniform(0.05, 1.0))
        a = rng.uniform(-math.pi * 0.95, -math.pi * 0.05)
        cx = n / 2 + math.cos(a) * r * n * 0.42
        cy = n * 0.52 + math.sin(a) * r * n * 0.44 + n * 0.1
        rot = math.atan2(cy - base[1], cx - base[0]) + rng.normal(0, 0.5)
        length = rng.uniform(55, 95)
        width = length * rng.uniform(0.38, 0.48)
        pts = []
        for j in range(20):
            t = j / 20 * 2 * math.pi
            px = math.cos(t) * length / 2
            py = math.sin(t) * width / 2 * (1 - 0.3 * math.cos(t))
            pts.append((cx + px * math.cos(rot) - py * math.sin(rot), cy + px * math.sin(rot) + py * math.cos(rot)))
        g = (0.55 + 0.45 * r) * rng.uniform(0.85, 1.15)
        d.line([base, (cx, cy)], fill=(int(60 * g), int(66 * g), int(34 * g), 255), width=2)
        d.polygon(pts, fill=(int(52 * g), int(104 * g), int(40 * g), 255))
        tip = (cx + math.cos(rot) * length / 2, cy + math.sin(rot) * length / 2)
        back = (cx - math.cos(rot) * length / 2, cy - math.sin(rot) * length / 2)
        d.line([back, tip], fill=(int(86 * g), int(130 * g), int(62 * g), 255), width=1)
    arr = np.asarray(img).astype(float)
    shade = noise(n, 152, beta=2.0)
    arr[..., :3] *= (0.85 + 0.3 * shade)[..., None]
    save_img("leaves_albedo", Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA"))


def trees(w=1024, h=512):
    """A row of street trees (lime / plane, 6-8 m) for the view out of the windows.
    RGBA with alpha clip; the card is 16 x 8 m."""
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    rng = np.random.default_rng(161)
    canopy = np.full((h, w), -10.0)
    trunk = np.zeros((h, w))
    for k in range(5):
        cx = (k + 0.5) * w / 5 + rng.uniform(-30, 30)
        cy = rng.uniform(170, 210)
        rx, ry = rng.uniform(120, 160), rng.uniform(130, 165)
        for _ in range(6):  # a crown is a cluster of lobes
            ox, oy = rng.normal(0, rx * 0.35), rng.normal(0, ry * 0.3)
            lr = rng.uniform(0.45, 0.7)
            canopy = np.maximum(canopy, 1.0 - ((xx - cx - ox) / (rx * lr)) ** 2 - ((yy - cy - oy) / (ry * lr)) ** 2)
        tw = rng.uniform(7, 10)
        lean = rng.normal(0, 0.04)
        x_at = cx + (yy - h) * lean
        trunk = np.maximum(trunk, ((np.abs(xx - x_at) < tw * (1 + (h - yy) / h * 0.3)) & (yy > cy + ry * 0.3)).astype(float))
    edge = noise(w, 162, beta=1.6, shape=(h, w))
    alpha = (canopy + 0.6 * (edge - 0.5) > 0.12).astype(float)
    alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5)), float) / 255
    dapple = noise(w, 163, beta=1.0, shape=(h, w))
    light = np.clip((220 - yy) / 260 + 0.6 * (dapple - 0.5) + 0.3, 0, 1)
    leaf = mix(rgb((34, 52, 26)), rgb((104, 132, 62)), light)
    col = np.where((trunk[..., None] > 0) & (alpha[..., None] < 0.5) | (trunk[..., None] > 0) & (yy[..., None] > 330),
                   rgb((74, 66, 56)) * (0.8 + 0.3 * dapple[..., None]), leaf)
    a = np.maximum(alpha, trunk)
    rgba = np.concatenate([col, a[..., None]], -1)
    save_img("trees_albedo", Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA"))


def posters(w=1024, h=512):
    """Two wall posters, 512 x 512 each: the Zuidmark grid map (left) and a safety poster (right)."""
    img = Image.new("RGB", (w, h), (250, 250, 248))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(171)
    # map: land, a river, towns, MS ring cables and substations
    d.rectangle([0, 0, 511, 511], fill=(240, 238, 228))
    d.rectangle([0, 0, 511, 70], fill=VOLTANA_BLUE)
    d.text((20, 12), "Netkaart Zuidmark", font=_font(34, bold=True), fill=(255, 255, 255))
    d.line([(0, 380), (120, 340), (260, 400), (400, 360), (511, 420)], fill=(150, 190, 230), width=14)
    towns = [(130, 170, "Nova"), (330, 150, "Hoven"), (250, 270, "Beek"), (420, 270, "Esdonk"), (110, 300, "Molenrijk")]
    for x, y, name in towns:
        d.ellipse([x - 26, y - 20, x + 26, y + 20], fill=(222, 214, 196))
        d.text((x - 24, y + 22), name, font=_font(14), fill=(60, 60, 60))
    for (x0, y0, _), (x1, y1, _) in zip(towns, towns[1:] + towns[:1]):
        d.line([(x0, y0), (x1, y1)], fill=(190, 20, 120), width=3)
    for x, y, _ in towns:
        for _ in range(5):
            d.line([(x, y), (x + rng.uniform(-60, 60), y + rng.uniform(-50, 50))], fill=(220, 120, 20), width=2)
        d.rectangle([x - 6, y - 6, x + 6, y + 6], fill=(200, 30, 30))
    d.rectangle([20, 440, 220, 500], fill=(255, 255, 255), outline=(120, 120, 120))
    for k, (t, c) in enumerate([("MS-ring", (190, 20, 120)), ("LS-net", (220, 120, 20)), ("station", (200, 30, 30))]):
        d.rectangle([30, 448 + k * 17, 44, 458 + k * 17], fill=c)
        d.text((52, 445 + k * 17), t, font=_font(13), fill=(40, 40, 40))
    # safety poster
    d.rectangle([512, 0, 1023, 511], fill=(255, 204, 0))
    d.rectangle([536, 24, 999, 487], fill=(255, 255, 255))
    d.text((560, 46), "Veilig werken", font=_font(48, bold=True), fill=(20, 20, 20))
    d.text((560, 104), "doen we samen", font=_font(40), fill=(20, 20, 20))
    d.polygon([(768, 170), (680, 330), (856, 330)], fill=(255, 204, 0), outline=(20, 20, 20))
    d.text((754, 220), "!", font=_font(90, bold=True), fill=(20, 20, 20))
    for k, t in enumerate(["Spanningsloos? Eerst meten.", "Stop bij twijfel.", "Meld onveilige situaties."]):
        d.text((570, 360 + k * 36), "• " + t, font=_font(24), fill=(30, 30, 30))
    save_img("posters_albedo", img)


GENERATORS = {f.__name__: f for f in (carpet, ceiling, wood, plaster, concrete, paving, grass, metal,
                                       fabric, glass, obeya, missions, signage, screens, dossier,
                                       devices, leaves, trees, posters)}


def main(names: list[str]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    unknown = [n for n in names if n not in GENERATORS]
    if unknown:
        sys.exit(f"unknown texture(s): {', '.join(unknown)}; known: {', '.join(GENERATORS)}")
    for name in names or GENERATORS:
        GENERATORS[name]()
        print("wrote", name)


if __name__ == "__main__":
    main(sys.argv[1:])
