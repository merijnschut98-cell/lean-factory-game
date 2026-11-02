"""Build the street (de Zonnestraat) with bpy: game/assets/office/street.glb (slice 3.2, spec §4).

Run with Blender's Python module, like build_office.py (see tools/blender/README.md):

    python tools/build_content.py        # game/data/town.json, the street graph (content/town.yaml)
    .bvenv/bin/python tools/blender/build_street.py --samples 64
    .bvenv/bin/python tools/blender/build_street.py --no-bake      # seconds: reuses lightmap_*_street.png

The street runs +X from its west end (x = 0), the road's centre on y = 0, the even (north) side
at +Y; Godot sees (x, z = -y). Everything comes from game/data/town.json: a lot's `at` is its
distance along x, a prop's likewise. A plain look is the goal (spec §4): flat ground (a
woonerf-style street without kerbs), box houses with pitched roofs, no interiors.

Static geometry is merged per material so the draw budget holds (a test pins it): `shell_floor`
(the walkable ground: road, pavements, garden paths; lightmap on UV2), `shell_walls` (the house
fronts and sides; lightmap on UV2), `outside` (gardens, grass, hedges, the canal, doorsteps,
lamp posts, the Peeters van), `roofs`, `glass_windows` (casts no shadow), `light_pools` (quads
the game shows at night), `lamp_heads` (emissive) and `collision-colonly`. There are no lights:
night is the game's runtime dim plus these emissive parts.

Nodes the game switches, by name: `kerb_van`, `heat_pump_9` (child `fan`: a cross-shaped blade
disc on its own pivot, spin it about Godot's X), `card_7`, `trench_marks`, `klic_board`,
`trafo_vent`, `windows_lit` (an empty; one child `windows_lit_<n>` per house with lit panes) and
the tells `tell_street_lamp` (each `_low`/`_mid`/`_high` holds a `..._bulb` mesh),
`tell_dug_pavement`, `tell_window_note`.

Markers (empties with glTF extras, as on the floors): `arrive:van`, `ride:street`,
`room:zonnestraat` (extras `rect`), `lot:<id>` (extras `n`), `bell:<n>`, `doorstep:<n>`
(houses 4, 7, 9, 14), `home:<resident>`, `field:<step>`, `explain:transformator` and `spot:<id>`.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_office as bo  # noqa: E402  (materials, MeshBuilder, colliders, markers, the bake)
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
from textures import street_sign_rects  # noqa: E402

OUT = bo.ASSETS / "street.glb"
TOWN = bo.ROOT / "game" / "data" / "town.json"
FLOOR_ID = "street"
STREET_LIGHTMAPS = {"shell_floor": ("lightmap_floor", (4096, 1024)), "shell_walls": ("lightmap_walls", (2048, 2048))}
SIGNS = street_sign_rects()
LOGO = bo.SIGN_RECTS["logo"]
WALL_H, ROOF_RISE, EAVE = 5.2, 2.3, 0.45      # two storeys of 2.6 m, the ridge, the roof's overhang
SHOP_DOOR_U = 10.0                            # the shop's door, metres along its 12 m lot
FENCE_H = 1.1                                 # the garden fences in the gaps between the houses
BRICK_BUFF = {3, 6, 8, 11, 14}                # the houses faced in buff brick, the rest in red
DOORS = (4, 7, 9, 14)                         # the houses with a bell (the residents and Sandra's door 7)
POOL_RADIUS = 3.4                             # a lamp's pool of light


class Street:
    """The street graph (town.json) in Blender metres: the cross-section and where things stand."""

    def __init__(self, town: dict) -> None:
        seg = town["segments"][0]
        self.x0, self.y0 = seg["from"]
        self.length = seg["to"][0] - self.x0
        self.road = seg["carriageway"] / 2
        self.pave = self.road + seg["pavement"]
        self.front = self.pave + seg["front_garden"]    # the house fronts' distance from the road's centre
        self.depth = seg["house_depth"]
        self.lots = {lot["id"]: lot for lot in town["lots"]}
        self.props = {prop["id"]: prop for prop in town["props"]}
        self.fields = town["fields"]
        across = sorted((p for p in town["props"] if p.get("across")), key=lambda p: p["at"])
        self.west, self.canal = across[0], next(p for p in across if p["kind"] == "canal")
        self.gx0 = self.x(self.west["at"]) + 1.0            # the walkable ground: from inside the west hedge
        self.gx1 = self.x(self.canal["at"])                 # to the canal's bank

    def x(self, at: float) -> float:
        return self.x0 + at

    @staticmethod
    def sign(side: str) -> int:
        return 1 if side == "even" else -1

    def lot_span(self, lot: dict) -> tuple[float, float]:
        return self.x(lot["at"]), self.x(lot["at"]) + lot.get("width", 9)

    def house(self, n: int) -> dict:
        return next(lot for lot in self.lots.values() if lot.get("n") == n)

    def facade(self, lot: dict) -> dict:
        """Where a house's front is: the side, the front line's y, the way out (toward the road) and its door."""
        x0, x1 = self.lot_span(lot)
        sgn = self.sign(lot["side"])
        shop = lot["kind"] == "shop"
        mirror = (lot["n"] // 2) % 2 == 1
        door_u = SHOP_DOOR_U if shop else (2.4 if mirror else 6.6)
        win_u = 4.5 if shop else (6.6 if mirror else 2.4)
        return {"x0": x0, "x1": x1, "sgn": sgn, "out": -sgn, "yf": sgn * self.front, "yb": sgn * (self.front + self.depth),
                "door": x0 + door_u, "win": x0 + win_u, "toward": 1 if door_u < (x1 - x0) / 2 else -1}


# --------------------------------------------------------------------------- materials

def make_street_materials() -> None:
    m, srgb = bo.material, bo.srgb
    for name in ("klinkers", "paving", "brick_red", "brick_buff", "concrete"):
        m(f"shell_{name}", name, normal=not name.startswith("brick"))   # the lightmapped shell has its own materials: the bake wires a map into each
    m("roof_tiles", "roof_tiles")
    m("hedge", "hedge", rough=0.95)
    m("water", "water", rough=0.1)
    m("paving_dark", "paving", color=srgb(112, 110, 106))
    m("street_signs", "street_signs", rough=0.45, normal=False, orm=False, uv_size=1.0)
    m("yellow", None, color=srgb(242, 196, 28), rough=0.5)
    m("paint_orange", None, color=srgb(255, 120, 20), rough=0.9)
    m("paint_blue", None, color=srgb(30, 100, 230), rough=0.9)
    m("paint_red", None, color=srgb(220, 40, 40), rough=0.9)
    m("window_lit", None, color=srgb(40, 34, 24), rough=0.2, emission=srgb(255, 206, 130))
    m("lamp_head", None, color=srgb(60, 60, 60), rough=0.3, emission=srgb(255, 236, 200))
    m("bulb_on", None, color=srgb(255, 240, 210), rough=0.2, emission=srgb(255, 226, 160))
    m("bulb_dim", None, color=srgb(120, 80, 40), rough=0.3, emission=srgb(190, 110, 40))
    m("bulb_off", None, color=srgb(60, 56, 50), rough=0.2)
    pool = m("light_pool", None, color=srgb(255, 214, 140), rough=1.0, alpha=1.0, emission=srgb(255, 214, 140))
    img = pool.node_tree.nodes.new("ShaderNodeTexImage")    # the pool's soft edge: the texture's alpha
    img.image = bo._image("light_pool_albedo")
    bo._link(pool.node_tree, img.outputs["Alpha"], pool.node_tree.nodes["Principled BSDF"].inputs["Alpha"])


def quad_out(b: bo.MeshBuilder, pts: list, mat: str, outward: tuple) -> None:
    """A face whose front looks along `outward` (the materials are single-sided)."""
    p0, p1, p2 = (Vector(p) for p in pts[:3])
    b.quad(pts if (p1 - p0).cross(p2 - p0).dot(Vector(outward)) >= 0 else pts[::-1], mat)


def ground_quad(b: bo.MeshBuilder, x0: float, y0: float, x1: float, y1: float, z: float, mat: str) -> None:
    b.quad([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], mat)


def node(builder: bo.MeshBuilder, name: str, loc=(0, 0, 0), rot: float = 0.0, parent=None) -> bpy.types.Object:
    ob = bo.put(builder.mesh(name), name, loc, rot)
    ob.parent = parent
    return ob


# --------------------------------------------------------------------------- the ground

def trench_hole(st: Street) -> tuple[float, float, float, float]:
    """The pit in the north pavement: x0, y0, x1, y1."""
    t = st.props["trench"]
    mid = (st.road + st.pave) / 2
    return st.x(t["at"]), mid - 0.4, st.x(t["at"]) + t["length"], mid + 0.4


def ground(st: Street) -> tuple[bo.MeshBuilder, tuple[float, float, float, float]]:
    """The walkable ground: the clinker road, the pavements (the trench cut out of the north one)
    and the garden paths. Returns the builder and the ground's bounds (the lightmap's rectangle)."""
    b = bo.MeshBuilder()
    gx0, gx1, r, p = st.gx0, st.gx1, st.road, st.pave
    ground_quad(b, gx0, -r, gx1, r, 0, "shell_klinkers")
    hx0, hy0, hx1, hy1 = trench_hole(st)
    ground_quad(b, gx0, -p, gx1, -r, 0, "shell_paving")
    ground_quad(b, gx0, r, hx0, p, 0, "shell_paving")
    ground_quad(b, hx1, r, gx1, p, 0, "shell_paving")
    ground_quad(b, hx0, r, hx1, hy0, 0, "shell_paving")
    ground_quad(b, hx0, hy1, hx1, p, 0, "shell_paving")
    for lot in st.lots.values():    # a path from the pavement to each door
        if lot["kind"] != "trafohuisje":
            f = st.facade(lot)
            lo, hi = sorted((st.sign(lot["side"]) * p, f["yf"]))
            ground_quad(b, f["door"] - 0.6, lo, f["door"] + 0.6, hi, 0, "shell_paving")
    return b, (gx0, -st.front, gx1, st.front)


def lightmap_uvs(floor: bpy.types.Object, walls: bpy.types.Object, bounds: tuple) -> None:
    """Second UV set 'lightmap': the ground maps 1:1 to its rectangle, the walls are unwrapped by Smart UV Project."""
    x0, y0, x1, y1 = bounds
    uv = floor.data.uv_layers.new(name="lightmap")
    for loop in floor.data.loops:
        co = floor.data.vertices[loop.vertex_index].co
        uv.data[loop.index].uv = ((co.x - x0) / (x1 - x0), (co.y - y0) / (y1 - y0))
    walls.data.uv_layers.new(name="lightmap")
    walls.data.uv_layers.active = walls.data.uv_layers["lightmap"]
    bpy.context.view_layer.objects.active = walls
    walls.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0, scale_to_bounds=True)
    bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    walls.select_set(False)
    walls.data.uv_layers["UVMap"].active = True
    walls.data.uv_layers["UVMap"].active_render = True


# --------------------------------------------------------------------------- the houses

class Parts:
    """The builders the houses and props draw into, one per output node."""

    def __init__(self) -> None:
        self.walls, self.roofs, self.outside = bo.MeshBuilder(), bo.MeshBuilder(), bo.MeshBuilder()
        self.glass = bo.MeshBuilder()
        self.lit: dict[int, bo.MeshBuilder] = {}        # house number -> its lit panes
        self.pools, self.heads = bo.MeshBuilder(), bo.MeshBuilder()


def window(parts: Parts, f: dict, n: int, x: float, sill: float, w: float, h: float) -> None:
    """A window in a front wall: dark frame, glass in front of it, a lit pane between them (the game shows it at night)."""
    o, yf = f["out"], f["yf"]
    parts.outside.box((w + 0.12, 0.05, h + 0.12), (x, yf + o * 0.025, sill + h / 2), "frame")
    parts.outside.box((w + 0.2, 0.12, 0.05), (x, yf + o * 0.06, sill - 0.025), "sill")
    parts.glass.box((w, 0.02, h), (x, yf + o * 0.06, sill + h / 2), "glass")
    parts.lit.setdefault(n, bo.MeshBuilder()).panel((x, yf + o * 0.052, sill + h / 2), w, h, "Y", "window_lit", sign=o)


def house_walls(parts: Parts, f: dict, mat: str, pitched: bool, depth: float) -> None:
    x0, x1, yf, yb, sgn = f["x0"], f["x1"], f["yf"], f["yb"], f["sgn"]
    h, ym = WALL_H, (yf + yb) / 2
    b = parts.walls
    quad_out(b, [(x0, yf, 0), (x1, yf, 0), (x1, yf, h), (x0, yf, h)], mat, (0, -sgn, 0))
    quad_out(b, [(x0, yb, 0), (x1, yb, 0), (x1, yb, h), (x0, yb, h)], mat, (0, sgn, 0))
    for x, d in ((x0, -1), (x1, 1)):
        quad_out(b, [(x, yf, 0), (x, yb, 0), (x, yb, h), (x, yf, h)], mat, (d, 0, 0))
        if pitched:
            quad_out(b, [(x, yf, h), (x, yb, h), (x, ym, h + ROOF_RISE)], mat, (d, 0, 0))
    if pitched:
        run = depth / 2
        drop = EAVE * ROOF_RISE / run
        for edge, d in ((yf - sgn * EAVE, -sgn), (yb + sgn * EAVE, sgn)):
            quad_out(parts.roofs, [(x0 - 0.3, edge, h - drop), (x1 + 0.3, edge, h - drop),
                                   (x1 + 0.3, ym, h + ROOF_RISE), (x0 - 0.3, ym, h + ROOF_RISE)], "roof_tiles", (0, d, 1))
    else:
        parts.roofs.box((x1 - x0 + 0.5, abs(yb - yf) + 0.5, 0.2), ((x0 + x1) / 2, ym, h + 0.1), "metal_dark")


def front_door(parts: Parts, f: dict, n: int) -> None:
    """The door, its frame, canopy, doorstep, bell and number plate."""
    o, yf, xd, t = f["out"], f["yf"], f["door"], f["toward"]
    b = parts.outside
    b.box((1.2, 0.04, 2.2), (xd, yf + o * 0.02, 1.1), "frame")
    b.box((1.0, 0.06, 2.1), (xd, yf + o * 0.05, 1.05), "wood")
    b.box((0.05, 0.05, 0.14), (xd - t * 0.35, yf + o * 0.1, 1.0), "alu")
    b.box((1.8, 1.0, 0.1), (xd, yf + o * 0.5, 2.45), "frame")
    b.box((1.6, 0.9, 0.1), (xd, yf + o * 0.45, 0.05), "concrete")
    b.box((0.06, 0.03, 0.1), (xd + t * 0.62, yf + o * 0.03, 1.2), "alu")
    b.panel((xd + t * 1.05, yf + o * 0.025, 1.75), 0.22, 0.11, "Y", "street_signs", uv_rect=SIGNS[f"n{n}"], sign=o)


def build_house(st: Street, parts: Parts, lot: dict) -> None:
    f, n, shop = st.facade(lot), lot["n"], lot["kind"] == "shop"
    mat = "shell_brick_buff" if n in BRICK_BUFF else "shell_brick_red"
    house_walls(parts, f, mat, pitched=not shop, depth=st.depth)
    o, yf = f["out"], f["yf"]
    front_door(parts, f, n)
    if shop:    # a shut corner shop: two big windows papered over from inside
        for dx in (-1.3, 1.3):
            x = f["win"] + dx
            window(parts, f, n, x, 0.5, 2.4, 2.0)
            parts.outside.panel((x, yf + o * 0.04, 1.5), 2.4, 1.6, "Y", "street_signs", uv_rect=SIGNS["papered"], sign=o)
        for u in (2.4, 6.6):
            window(parts, f, n, f["x0"] + u, 3.4, 1.2, 1.3)
    else:
        window(parts, f, n, f["win"], 0.9, 1.8, 1.3)
        window(parts, f, n, f["win"], 3.4, 1.2, 1.3)
        window(parts, f, n, f["door"], 3.4, 1.2, 1.3)
    bo.collide((f["x1"] - f["x0"], st.depth, WALL_H), ((f["x0"] + f["x1"]) / 2, (f["yf"] + f["yb"]) / 2, WALL_H / 2))


def build_trafohuisje(st: Street, parts: Parts, lot: dict) -> dict:
    """A free-standing transformer station at the edge of the pavement: concrete box, double doors
    and a vent grille (`trafo_vent`) facing the road."""
    x0, x1 = st.lot_span(lot)
    w = x1 - x0
    sgn = st.sign(lot["side"])
    yf = sgn * (st.pave + 0.3)                  # its doors face the pavement
    yb = yf + sgn * w
    xc, o, h = (x0 + x1) / 2, -sgn, 3.0
    b = parts.walls
    quad_out(b, [(x0, yf, 0), (x1, yf, 0), (x1, yf, h), (x0, yf, h)], "shell_concrete", (0, o, 0))
    quad_out(b, [(x0, yb, 0), (x1, yb, 0), (x1, yb, h), (x0, yb, h)], "shell_concrete", (0, -o, 0))
    for x, d in ((x0, -1), (x1, 1)):
        quad_out(b, [(x, yf, 0), (x, yb, 0), (x, yb, h), (x, yf, h)], "shell_concrete", (d, 0, 0))
    parts.roofs.box((w + 0.4, w + 0.4, 0.15), (xc, (yf + yb) / 2, h + 0.075), "metal_dark")
    for dx in (-0.45, 0.45):
        parts.outside.box((0.88, 0.04, 2.1), (xc + dx, yf + o * 0.02, 1.05), "metal_dark")
    parts.outside.panel((xc, yf + o * 0.03, 2.33), 1.2, 0.2, "Y", "signage", uv_rect=LOGO, sign=o)
    parts.outside.panel((xc + 1.1, yf + o * 0.03, 1.6), 0.28, 0.28, "Y", "yellow", sign=o)
    vent = bo.MeshBuilder()
    vent.box((1.0, 0.03, 0.4), (0, 0, 0), "frame")
    for k in range(5):
        vent.box((0.96, 0.05, 0.03), (0, o * 0.01, -0.16 + k * 0.08), "metal_dark")
    node(vent, "trafo_vent", (xc, yf + o * 0.03, 2.75))
    bo.collide((w, w, h), (xc, (yf + yb) / 2, h / 2))
    return {"x": xc, "y": yf, "out": o}


# --------------------------------------------------------------------------- props

def fences(st: Street, parts: Parts) -> None:
    """Garden fences in the gaps between the houses (and to the street's ends) along both front lines."""
    for side in ("even", "odd"):
        sgn = st.sign(side)
        spans = sorted(st.lot_span(lot) for lot in st.lots.values() if lot["kind"] != "trafohuisje" and lot["side"] == side)
        x = st.gx0
        for lo, hi in spans + [(st.gx1, st.gx1)]:
            if lo - x > 0.5:
                size, centre = (lo - x, 0.06, FENCE_H), ((lo + x) / 2, sgn * st.front, FENCE_H / 2)
                parts.outside.box(size, centre, "wood")
                bo.collide((size[0], 0.3, 2.0), (centre[0], centre[1], 1.0))
            x = max(x, hi)


def hedges(st: Street, parts: Parts) -> None:
    b = parts.outside
    west = st.x(st.west["at"])
    span = 2 * (st.front + 1.0)
    b.box((0.8, span, 1.8), (west, 0, 0.9), "hedge", bevel=0.1)
    bo.collide((1.0, span, 2.0), (west, 0, 1.0))
    for h in (p for p in st.props.values() if p["kind"] == "hedge" and "side" in p):
        sgn = st.sign(h["side"])
        x0 = st.x(h["at"])
        size, centre = (h["length"], 0.8, 1.5), (x0 + h["length"] / 2, sgn * (st.pave + 0.5), 0.75)
        b.box(size, centre, "hedge", bevel=0.1)
        bo.collide((size[0], 1.0, 2.0), (centre[0], centre[1], 1.0))


def canal(st: Street, parts: Parts) -> None:
    """The canal that closes the east end: water below the street, concrete banks, a low wall at the street's edge."""
    b, c = parts.outside, st.canal
    x0, x1 = st.x(c["at"]), st.x(c["at"]) + c["length"]
    half, bed = st.front + 40, -0.35
    ground_quad(b, x0, -half, x1, half, bed, "water")
    for x, d in ((x0, 1), (x1, -1)):
        quad_out(b, [(x, -half, bed), (x, half, bed), (x, half, -0.02), (x, -half, -0.02)], "concrete", (d, 0, 0))
    b.box((0.4, 2 * st.front, 0.5), (x0 - 0.2, 0, 0.25), "concrete")
    bo.collide((0.8, 2 * (st.front + 1.0), 1.5), (x0 + 0.2, 0, 0.75))


def lamps(st: Street, parts: Parts) -> None:
    for lamp in (p for p in st.props.values() if p["kind"] == "lamp"):
        sgn, x = st.sign(lamp["side"]), st.x(lamp["at"])
        y = sgn * (st.road + 0.4)
        parts.outside.cyl(0.06, 5.0, (x, y, 2.5), "metal_dark", segs=10)
        parts.outside.box((0.08, 0.8, 0.06), (x, y - sgn * 0.4, 5.0), "metal_dark")
        parts.heads.box((0.55, 0.25, 0.1), (x, y - sgn * 0.8, 4.97), "lamp_head")
        parts.pools.quad([(x - POOL_RADIUS, y - sgn * 1.4 - POOL_RADIUS, 0.02), (x + POOL_RADIUS, y - sgn * 1.4 - POOL_RADIUS, 0.02),
                          (x + POOL_RADIUS, y - sgn * 1.4 + POOL_RADIUS, 0.02), (x - POOL_RADIUS, y - sgn * 1.4 + POOL_RADIUS, 0.02)],
                         "light_pool", uv_rect=(0, 0, 1, 1))
        bo.collide((0.25, 0.25, 5.0), (x, y, 2.5))


def van_parts(b: bo.MeshBuilder, cx: float, cy: float, facing: int, livery: str) -> None:
    """A van parked along x, its cab toward `facing` (+1 east, -1 west): box, cab, glass, wheels, the livery on both sides."""
    f = facing
    b.box((4.4, 2.0, 2.1), (cx - f * 0.5, cy, 1.35), "metal_white", bevel=0.05)
    b.box((1.3, 1.95, 1.4), (cx + f * 2.3, cy, 1.0), "metal_white", bevel=0.08)
    b.box((0.05, 1.7, 0.6), (cx + f * 2.96, cy, 1.35), "glass_dark")
    b.box((0.05, 1.9, 1.9), (cx - f * 2.7, cy, 1.3), "metal_white")
    for side in (-1, 1):
        rect = {"voltana": LOGO, "peeters": SIGNS["peeters"]}[livery]
        mat, w, h = ("signage", 2.6, 0.62) if livery == "voltana" else ("street_signs", 2.6, 0.65)
        b.panel((cx - f * 0.6, cy + side * 1.01, 1.6), w, h, "Y", mat, uv_rect=rect, sign=side)
        for wx in (cx + f * 2.0, cx - f * 1.8):
            b.cyl(0.36, 0.25, (wx, cy + side * 0.92, 0.36), "plastic_black", segs=14, axis="Y")


def vans(st: Street, parts: Parts) -> dict:
    """The kerb van (its own node) and the Peeters van (static); returns the kerb van's standing data."""
    out = {}
    for prop in (p for p in st.props.values() if p["kind"] == "van"):
        sgn = st.sign(prop["side"])
        cx, cy = st.x(prop["at"]), sgn * (st.road - 1.2)
        facing = -sgn                      # right-hand traffic: east on the south side, west on the north side
        if prop.get("kerb"):
            b = bo.MeshBuilder()
            van_parts(b, 0, 0, facing, prop["livery"])
            node(b, "kerb_van", (cx, cy, 0))
            out = {"x": cx, "y": cy, "facing": facing, "sgn": sgn}
        else:
            van_parts(parts.outside, cx, cy, facing, prop["livery"])
        bo.collide((5.7, 2.1, 2.4), (cx + facing * 0.1, cy, 1.2))
    return out


def trench(st: Street, parts: Parts) -> None:
    """Gert's trench in the north pavement: the pit with a cable in it, spoil and paving stones beside it, a
    red-white barrier round it, planks over it; the spray marks of the cable's route and the KLIC board are nodes."""
    b = parts.outside
    hx0, hy0, hx1, hy1 = trench_hole(st)
    pit = -1.0
    ground_quad(b, hx0, hy0, hx1, hy1, pit, "soil")
    for (a, c, d) in (((hx0, hy0), (hx1, hy0), (0, 1)), ((hx1, hy1), (hx0, hy1), (0, -1)),
                      ((hx0, hy1), (hx0, hy0), (1, 0)), ((hx1, hy0), (hx1, hy1), (-1, 0))):
        quad_out(b, [(a[0], a[1], pit), (c[0], c[1], pit), (c[0], c[1], 0), (a[0], a[1], 0)], "soil", (d[0], d[1], 0))
    b.cyl(0.04, hx1 - hx0, ((hx0 + hx1) / 2, (hy0 + hy1) / 2, pit + 0.15), "plastic_black", segs=10, axis="X")
    for k in range(3):    # the spoil on the garden side
        b.box((6.0, 1.0, 0.45), (hx0 + 4 + k * 8.5, st.pave + 0.8, 0.22), "soil", bevel=0.2, segs=2)
    for k in range(2):    # planks over the pit
        b.box((0.3, hy1 - hy0 + 0.8, 0.04), (hx0 + 6 + k * 12, (hy0 + hy1) / 2, 0.02), "wood")
    for k in range(4):    # a stack of paving stones
        b.box((0.6, 0.6, 0.07), (hx1 + 1.2, st.pave + 0.6, 0.04 + k * 0.07), "paving_dark")
    bx0, bx1, by0, by1 = hx0 - 0.5, hx1 + 0.5, st.road + 0.05, st.pave - 0.05    # the barrier's rectangle
    for (cx, cy, sx, sy) in (((bx0 + bx1) / 2, by0, bx1 - bx0, 0.05), ((bx0 + bx1) / 2, by1, bx1 - bx0, 0.05),
                             (bx0, (by0 + by1) / 2, 0.05, by1 - by0), (bx1, (by0 + by1) / 2, 0.05, by1 - by0)):
        b.box((sx, sy, 0.12), (cx, cy, 0.9), "plastic_white")
        b.box((sx, sy, 0.12), (cx, cy, 0.6), "plastic_white")
        n = max(1, int(max(sx, sy) / 1.0))
        for k in range(n):    # the red stripes
            t = (k + 0.5) / n - 0.5
            at = (cx + t * sx, cy) if sx > sy else (cx, cy + t * sy)
            b.box((0.4, sy, 0.13) if sx > sy else (sx, 0.4, 0.13), (at[0], at[1], 0.9), "card_red")
        bo.collide((sx + 0.1, sy + 0.1, 1.0), (cx, cy, 0.5))
    for x in (bx0, (bx0 + bx1) / 2, bx1):
        for y in (by0, by1):
            b.box((0.06, 0.06, 1.0), (x, y, 0.5), "metal_dark")
    marks = bo.MeshBuilder()    # the spray paint on the pavement: where the cable and the pipe run; pegs at the bends
    mid = (st.road + st.pave) / 2
    marks.box((8.0, 0.06, 0.006), (hx0 - 4, mid, 0.004), "paint_orange")
    marks.box((12.0, 0.06, 0.006), (hx1 + 6, mid + 0.25, 0.004), "paint_orange")
    marks.box((9.0, 0.06, 0.006), (hx0 + 5, mid - 0.45, 0.004), "paint_blue")
    for k in range(4):
        marks.box((0.5, 0.05, 0.006), (hx0 - 6 + k * 2.2, mid - 0.2 + (k % 2) * 0.4, 0.004), "paint_red")
    for px in (hx0 - 8, hx0 - 3, hx1 + 4, hx1 + 9):
        marks.cyl(0.015, 0.25, (px, mid + 0.55, 0.12), "metal_dark", segs=6)
        marks.cyl(0.02, 0.04, (px, mid + 0.55, 0.26), "paint_orange", segs=6)
    node(marks, "trench_marks")
    klic = bo.MeshBuilder()
    klic.box((0.06, 0.06, 1.5), (-0.4, 0, 0.75), "metal_dark")
    klic.box((0.06, 0.06, 1.5), (0.4, 0, 0.75), "metal_dark")
    klic.box((1.0, 0.04, 0.72), (0, 0, 1.2), "wood")
    klic.panel((0, 0.025, 1.2), 0.46, 0.65, "Y", "street_signs", uv_rect=SIGNS["klic"], sign=1)
    klic.panel((0, -0.025, 1.2), 0.46, 0.65, "Y", "street_signs", uv_rect=SIGNS["klic"], sign=-1)
    node(klic, "klic_board", (hx0 - 1.5, st.pave - 0.3, 0))
    bo.collide((1.0, 0.2, 1.6), (hx0 - 1.5, st.pave - 0.3, 0.8))


def heat_pump(st: Street) -> None:
    """House 9's heat pump on its east side wall: the unit and, on its own pivot, the fan (a blade cross)."""
    f = st.facade(st.house(9))
    x = f["x1"] + 0.2 + 0.2
    y = f["yf"] + f["sgn"] * 1.8
    body = bo.MeshBuilder()
    body.box((0.4, 0.95, 0.85), (0, 0, 0.425), "metal_white", bevel=0.02)
    body.box((0.03, 0.8, 0.7), (0.205, 0, 0.45), "metal_dark")
    unit = node(body, "heat_pump_9", (x, y, 0))
    fan = bo.MeshBuilder()
    fan.box((0.02, 0.56, 0.07), (0, 0, 0), "plastic_black")
    fan.box((0.02, 0.07, 0.56), (0, 0, 0), "plastic_black")
    node(fan, "fan", (0.23, 0, 0.45), parent=unit)
    bo.collide((0.45, 1.0, 0.9), (x, y, 0.45))


def door_extras(st: Street) -> None:
    """The 'helaas niet thuis' card in door 7."""
    f = st.facade(st.house(7))
    card = bo.MeshBuilder()
    card.panel((0, 0, 0), 0.24, 0.12, "Y", "street_signs", uv_rect=SIGNS["card"], sign=f["out"])
    node(card, "card_7", (f["door"] + 0.2, f["yf"] + f["out"] * 0.09, 1.5))


# --------------------------------------------------------------------------- tells

def tell_street_lamp(st: Street) -> None:
    """House 14's porch lamp (a voltage tell): the bulb is bright at low, dimmed at mid, dark at high."""
    f = st.facade(st.house(14))
    housing = bo.MeshBuilder()
    housing.box((0.14, 0.1, 0.3), (0, 0, 0), "metal_dark")
    variants = {}
    for band, mat in zip(bo.TELL_VARIANTS, ("bulb_on", "bulb_dim", "bulb_off")):
        v = bo.MeshBuilder()
        v.cyl(0.05, 0.1, (0, f["out"] * 0.09, 0), mat, segs=10)
        variants[band] = [(v.mesh(f"street_lamp_{band}"), (0, 0, 0), 0)]
    bo.tell("street_lamp", (f["door"] - f["toward"] * 1.4, f["yf"] + f["out"] * 0.05, 2.0), 0, variants,
            fixed=[("housing", housing.mesh("street_lamp_housing"), (0, 0, 0), 0)])
    for band in bo.TELL_VARIANTS:
        bpy.data.objects[f"tell_street_lamp_{band}0"].name = f"tell_street_lamp_{band}_bulb"


def tell_dug_pavement(st: Street) -> None:
    """The south pavement near x 36, dug before and patched: one patch at low, a longer patch with asphalt at
    mid, a long sunken, cracked strip at high."""
    mid = -(st.road + st.pave) / 2
    x = st.x(36)
    variants = {}
    for band in bo.TELL_VARIANTS:
        b = bo.MeshBuilder()
        if band == "low":
            b.box((1.2, 0.9, 0.012), (0, 0, 0.006), "paving_dark")
        elif band == "mid":
            b.box((3.4, 1.2, 0.012), (0, 0, 0.006), "paving_dark")
            b.box((1.6, 0.8, 0.014), (0.4, 0.1, 0.007), "asphalt")
        else:
            b.box((7.0, 1.5, 0.012), (0, 0, 0.006), "paving_dark")
            b.box((3.2, 0.9, 0.014), (-0.8, 0.1, 0.007), "asphalt")
            for k in range(4):    # slabs that sank: tilted edges, dark cracks
                b.box((0.6, 0.6, 0.02), (-2.8 + k * 1.9, 0.45 - (k % 2) * 0.9, 0.016), "paving", rot=6.0 * (k % 3 + 1))
            for k in range(5):
                b.box((0.9, 0.012, 0.016), (-3.0 + k * 1.5, -0.4 + (k % 3) * 0.4, 0.018), "plastic_black", rot=20.0 * k - 40)
        variants[band] = [(b.mesh(f"dug_pavement_{band}"), (0, 0, 0), 0)]
    bo.tell("dug_pavement", (x, mid, 0), 0, variants)


def tell_window_note(st: Street) -> None:
    """WANNEER? notes in the windows of 3, 5 and 11 (the ones nobody was told when): one at low, two at mid, three at high."""
    notes = []
    for n in (3, 5, 11):
        f = st.facade(st.house(n))
        notes.append((f["win"], f["yf"] + f["out"] * 0.075, f["out"]))
    variants = {}
    for band, count in zip(bo.TELL_VARIANTS, (1, 2, 3)):
        b = bo.MeshBuilder()
        for x, y, o in notes[:count]:
            b.panel((x, y, 1.55), 0.4, 0.3, "Y", "street_signs", uv_rect=SIGNS["wanneer"], sign=o)
        variants[band] = [(b.mesh(f"window_note_{band}"), (0, 0, 0), 0)]
    bo.tell("window_note", (0, 0, 0), 0, variants)


# --------------------------------------------------------------------------- markers

class StreetPlan:
    """What build_empties needs: markers and the room's rect."""

    def __init__(self, st: Street, van: dict, trafo: dict, bounds: tuple) -> None:
        self.markers: list[tuple] = []
        add = self.markers.append
        for lot in st.lots.values():
            if lot["kind"] == "trafohuisje":
                x = trafo["x"]
                add((f"lot:{lot['id']}", {"interaction": "lot", "id": lot["id"]}, (x, trafo["y"] + trafo["out"] * 1.2), (x, trafo["y"])))
                continue
            f = st.facade(lot)
            extras = {"interaction": "lot", "id": lot["id"], "n": lot["n"]}
            add((f"lot:{lot['id']}", extras, ((f["x0"] + f["x1"]) / 2, f["yf"] + f["out"] * 1.5), ((f["x0"] + f["x1"]) / 2, f["yf"])))
        residents = {}
        for n in DOORS:
            lot = st.house(n)
            f = st.facade(lot)
            xd, yf, o = f["door"], f["yf"], f["out"]
            add((f"bell:{n}", {"interaction": "bell", "id": str(n)}, (xd, yf + o * 1.2), (xd, yf)))
            add((f"doorstep:{n}", {"interaction": "doorstep", "id": str(n)}, (xd, yf + o * 0.5), (xd, yf + o * 5)))
            if "resident" in lot:
                residents[lot["resident"]] = f
                add((f"home:{lot['resident']}", {"interaction": "home", "id": lot["resident"]}, (xd, yf - o * 1.2), (xd, yf + o * 3)))
        f7 = st.facade(st.house(7))
        hx0, hy0, hx1, hy1 = trench_hole(st)
        mid_x, edge_y = (hx0 + hx1) / 2, st.road - 0.35    # the road's edge by the barrier
        for field in st.fields:
            at = field["at"]
            if at in st.lots:   # a house's field marker stands on its path
                f = st.facade(st.lots[at])
                where, faces = (f["door"], f["yf"] + f["out"] * 2.2), (f["door"], f["yf"])
            else:
                where, faces = (mid_x + 4, edge_y), (mid_x + 4, hy0)
            add((f"field:{field['step']}", {"interaction": "field", "id": field["step"]}, where, faces))
        tx, ty, to = trafo["x"], trafo["y"], trafo["out"]
        add(("explain:transformator", {"interaction": "explain", "id": "transformator"}, (tx, ty + to * 1.1), (tx, ty)))
        spots = {"gert_trench": ((mid_x - 1.0, edge_y), (mid_x - 1.0, hy0)),
                 "ahmed_trench": ((hx0 + 5, edge_y), (hx0 + 5, hy0)),
                 "sandra_door7": ((f7["door"] + 1.4, st.sign("odd") * (st.pave + 0.9)), (f7["door"], f7["yf"]))}
        for resident, name in (("de_jong", "de_jong_garden"), ("el_amrani", "el_amrani_garden"), ("wim", "wim_garden")):
            f = residents[resident]
            spots[name] = ((f["door"] + f["toward"] * 1.8, f["yf"] + f["out"] * 2.2), (f["door"] + f["toward"] * 1.8, f["yf"] + f["out"] * 6))
        for spot, (where, faces) in spots.items():
            add((f"spot:{spot}", {"interaction": "spot", "id": spot}, where, faces))
        # the van: the player steps out on the pavement beside the passenger door and rides back from the door
        door_x = van["x"] + van["facing"] * 2.0
        side = van["sgn"]    # the passenger's side is the kerb's: the pavement lies beyond the van, on its own side
        y_door = van["y"] + side * (1.0 + 0.55)
        add(("ride:street", {"interaction": "ride", "id": "street"}, (door_x, y_door), (door_x, van["y"])))
        add(("arrive:van", {"interaction": "arrive", "id": "van"}, (door_x, y_door + side * 0.9), (door_x - 8.0, y_door + side * 0.9)))
        x0, y0, x1, y1 = bounds
        self.rooms = {"zonnestraat": (x0, y0, x1, y1)}


# --------------------------------------------------------------------------- the scene

def _fresh_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bo.MATS.clear()
    bo.UV_SIZE.clear()
    bo.COLLIDERS.clear()
    bo.make_materials()
    make_street_materials()


def build_scene(st: Street) -> StreetPlan:
    _fresh_scene()
    parts = Parts()
    floor_b, bounds = ground(st)
    gx0, gx1, front = st.gx0, st.gx1, st.front
    out = parts.outside
    for side in (-1, 1):    # the front gardens' lawns, the grass beyond (not under the canal), the kerb stones
        ground_quad(out, gx0, min(side * st.pave, side * front), gx1, max(side * st.pave, side * front), -0.004, "grass")
        out.box((gx1 - gx0, 0.15, 0.04), ((gx0 + gx1) / 2, side * (st.road + 0.075), 0.02), "concrete")
    c0, c1 = st.x(st.canal["at"]), st.x(st.canal["at"]) + st.canal["length"]
    half = front + 40
    for x0, x1 in ((gx0 - 45, c0), (c1, c1 + 45)):
        ground_quad(out, x0, -half, x1, half, -0.02, "grass")
    for lot in st.lots.values():
        if lot["kind"] != "trafohuisje":
            build_house(st, parts, lot)
    trafo = build_trafohuisje(st, parts, next(l for l in st.lots.values() if l["kind"] == "trafohuisje"))
    fences(st, parts)
    hedges(st, parts)
    canal(st, parts)
    lamps(st, parts)
    van = vans(st, parts)
    trench(st, parts)
    heat_pump(st)
    door_extras(st)
    tell_street_lamp(st)
    tell_dug_pavement(st)
    tell_window_note(st)
    bo.collide((gx1 - gx0 + 2, 2 * front + 2, 0.2), ((gx0 + gx1) / 2, 0, -0.1))     # the ground to stand on
    floor = bo.put(floor_b.mesh("shell_floor"), "shell_floor")
    walls = bo.put(parts.walls.mesh("shell_walls"), "shell_walls")
    bo.put(out.mesh("outside"), "outside")
    bo.put(parts.roofs.mesh("roofs"), "roofs")
    bo.put(parts.glass.mesh("glass_windows"), "glass_windows")
    bo.put(parts.pools.mesh("light_pools"), "light_pools")
    bo.put(parts.heads.mesh("lamp_heads"), "lamp_heads")
    lit = bpy.data.objects.new("windows_lit", None)
    bpy.context.scene.collection.objects.link(lit)
    for n, b in sorted(parts.lit.items()):
        bo.put(b.mesh(f"windows_lit_{n}"), f"windows_lit_{n}").parent = lit
    lightmap_uvs(floor, walls, bounds)
    plan = StreetPlan(st, van, trafo, bounds)
    bo.build_empties(plan)
    bo.build_collision()
    return plan


def bake(samples: int) -> None:
    """Bake the ground and the walls (sky only, plus contact AO); what the game switches stays out of the bake."""
    quiet = [o for o in bpy.context.scene.objects if o.name.startswith(("windows_lit", "light_pools", "lamp_heads", "trench_marks", "card_"))]
    for o in quiet:
        o.hide_render = True
    bo.bake_lightmaps([], samples, FLOOR_ID, maps=STREET_LIGHTMAPS)
    for o in quiet:
        o.hide_render = False


def export(path: Path) -> None:
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", export_keep_originals=True, export_extras=True,
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=False, export_materials="EXPORT", export_cameras=False, export_lights=False,
        use_selection=False)
    bo.fix_external_images(path)
    print(f"wrote {path} ({path.stat().st_size / 1e6:.1f} MB)", flush=True)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--no-bake", action="store_true", help="reuse the lightmap PNGs on disk")
    ap.add_argument("--samples", type=int, default=64, help="Cycles samples per lightmap texel")
    ap.add_argument("--blend", type=Path, help="also save the scene as a .blend (for inspection)")
    args = ap.parse_args()
    if not TOWN.exists():
        sys.exit(f"missing {TOWN}; run python tools/build_content.py first")
    st = Street(json.loads(TOWN.read_text(encoding="utf-8")))
    build_scene(st)
    if not args.no_bake:
        bake(args.samples)
    bo.attach_lightmaps(FLOOR_ID, maps=STREET_LIGHTMAPS)
    print(f"street: triangles: {bo.triangle_count()}  objects: {len(bpy.context.scene.objects)}")
    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(args.blend))
    export(OUT)


if __name__ == "__main__":
    main()
