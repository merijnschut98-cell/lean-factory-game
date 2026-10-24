"""Build the yard (de werf) with bpy: game/assets/office/office_yard.glb (PLAN 2.2).

Run with Blender's Python module, like build_office.py (see tools/blender/README.md):

    .bvenv/bin/python tools/blender/build_yard.py

The yard lies west of the head office, in the building's own coordinates (Blender metres,
Z up): the building's west gable stands at x = -18 with the kantine's back door at y = 8,
the yard runs x -50..-18, y -8..24, with the opleidingsterrein (PLAN 2.3) fenced off south of
it. Two single-storey sheds, the magazijn (north) and the
werkplaats & storingsdienst (south), and the van park along the west fence; the uitgiftelijst
(where the monteurs sign out parts) lies on Dirk's counter in the magazijn. Spec:
docs/superpowers/specs/2026-10-17-the-yard.md.

Outdoors: no lightmaps (Godot's sun and shadows). The ground is `shell_floor` (the game
reads the floor's outline from it) and the sheds' roofs `shell_ceiling` (the camera cuts
them away). Markers as on the floors: `place:<step>`, `room:<id>` with its rect, the seam
`exit:ground` (back inside) and `arrive:exit` where the player steps out. The vans are
`van<k>` (van0 and van1 the storingsbussen on call); the game parks and sends them out by
the hour (office_yard.gd); at each van `driver:van<k>` is where its monteur stands (by its back) and
`ride:van<k>` the passenger door, where the van ride starts (van_ride.gd). The tells (PLAN 2.6), as
on the floors: `tell_uitgiftelijst` (the issue list), `tell_magazijn_rack` (the joint shelf),
`tell_van_returns` (the returns pallet), `tell_storingsbord` and `tell_measurement_tray` (the
werkplaats), each with `_low`, `_mid` and `_high` variants.

It also builds the van's cab from inside for the van ride: game/assets/office/van_cab.glb (the
cab faces Blender +Y, Godot -Z; `seat:driver` and `seat:passenger` where the two sit).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_office as bo  # noqa: E402  (materials, kits, MeshBuilder, colliders, markers)
import bpy  # noqa: E402
import numpy as np  # noqa: E402

OUT = bo.ASSETS / "office_yard.glb"
CAB_OUT = bo.ASSETS / "van_cab.glb"
X0, X1, Y0, Y1 = -50.0, -18.0, -8.0, 24.0      # the yard
WALL = 0.2                                     # the sheds' walls
SHED_H = 3.2
DOOR = (8.0, 1.0)                              # the back door: y and width, in the gable at x = -18
MAGAZIJN = (-34.0, 12.0, -24.0, 22.0)          # x0, y0, x1, y1
WERKPLAATS = (-34.0, -6.0, -24.0, 4.0)
VAN_PARK = (-48.0, -6.0, -36.0, 22.0)
VAN_YS = (-3.0, 1.0, 5.0, 9.0, 13.0, 17.0)     # the bays (van0, van1: the storingsbussen)
VAN_X = -44.6                                  # a van's middle; its back doors face east
OPEN_VAN = 1                                   # a storingsbus (on call, in all day) with its back doors open (a tell)
TRAINING = (-32.0, -19.0, -20.0, Y0)           # the opleidingsterrein (PLAN 2.3), off the yard's south fence
TRAINING_GATE = (-23.0, -21.0)                 # its gate in that fence (the room's door)
TRENCH = (-30.0, -23.0, -12.5, 0.9)            # the practice trench: x0, x1, y, width
JOINT_X = -25.5                                # the joint (mof) on the cable in the trench


def ground() -> None:
    b = bo.MeshBuilder()
    b.quad([(X0, Y0, 0), (X1, Y0, 0), (X1, Y1, 0), (X0, Y1, 0)], "paving")
    tx0, ty0, tx1, ty1 = TRAINING   # the training ground's concrete slab
    b.quad([(tx0, ty0, 0), (tx1, ty0, 0), (tx1, ty1, 0), (tx0, ty1, 0)], "concrete")
    bo.put(b.mesh("shell_floor"), "shell_floor")
    bo.collide((X1 - X0 + 1, Y1 - Y0 + 1, 0.2), ((X0 + X1) / 2, (Y0 + Y1) / 2, -0.1))   # the ground to stand on
    bo.collide((tx1 - tx0 + 1, ty1 - ty0, 0.2), ((tx0 + tx1) / 2, (ty0 + ty1) / 2, -0.1))
    o = bo.MeshBuilder()
    o.quad([(X0 - 30, Y0 - 30, -0.02), (X1 + 50, Y0 - 30, -0.02), (X1 + 50, Y1 + 30, -0.02), (X0 - 30, Y1 + 30, -0.02)], "grass")
    o.quad([(VAN_PARK[0], VAN_PARK[1], 0.003), (VAN_PARK[2], VAN_PARK[1], 0.003), (VAN_PARK[2], VAN_PARK[3], 0.003),
            (VAN_PARK[0], VAN_PARK[3], 0.003)], "asphalt")
    for y in VAN_YS:   # the bays' white lines
        for dy in (-1.6, 1.6):
            o.box((6.4, 0.08, 0.004), (VAN_X + 0.4, y + dy, 0.006), "plastic_white")
    # the fence round the yard (the east side is the building), with a gate south and the
    # opleidingsterrein's gate (opleidingsterrein())
    for (a, b_, axis, at) in ((Y0, Y1, "x", X0), (X0, -40.0, "y", Y0), (-36.0, TRAINING_GATE[0], "y", Y0),
                              (TRAINING_GATE[1], X1, "y", Y0), (X0, X1, "y", Y1)):
        length = b_ - a
        mid = (a + b_) / 2
        size = (0.06, length, 1.8) if axis == "x" else (length, 0.06, 1.8)
        centre = (at, mid, 0.9) if axis == "x" else (mid, at, 0.9)
        o.box(size, centre, "metal_dark")
        bo.collide(size, centre)
    # the head office's west gable and its back door
    o.box((4.0, 16.6, 10.4), (X1 + 2.0, 8.0, 5.2), "shell_plaster")
    o.box((0.06, DOOR[1] + 0.16, 2.2), (X1 - 0.03, DOOR[0], 1.1), "frame")
    o.box((0.05, DOOR[1], 2.1), (X1 - 0.06, DOOR[0], 1.05), "metal_dark")
    o.panel((X1 - 0.07, DOOR[0], 2.35), 0.5, 0.18, "X", "signage", uv_rect=bo.SIGN_RECTS["exit"], sign=-1)
    o.box((1.6, 2.0, 0.12), (X1 - 0.8, DOOR[0], 0.06), "concrete")
    bo.collide((4.0, 16.6, 3.0), (X1 + 2.0, 8.0, 1.5))
    bo.put(o.mesh("outside"), "outside")


ROOF = bo.MeshBuilder()   # both sheds' roofs, one mesh: shell_ceiling (the camera cuts it away)


def shed(name: str, rect, door_side: str, door_x: float, plan) -> None:
    """A single-storey shed: four walls, its door (the room's: the game opens it when a
    mission needs the room, as the floors' doors), a roof the camera cuts away."""
    x0, y0, x1, y1 = rect
    b = bo.MeshBuilder()
    gap = (door_x - 1.0, door_x + 1.0)
    for y, side in ((y0, "south"), (y1, "north")):
        spans = [(x0, gap[0]), (gap[1], x1)] if side == door_side else [(x0, x1)]
        for a, c in spans:
            size, centre = (c - a, WALL, SHED_H), ((a + c) / 2, y, SHED_H / 2)
            b.box(size, centre, "brick")
            bo.collide(size, centre)
    for x in (x0, x1):
        size, centre = (WALL, y1 - y0 + WALL, SHED_H), (x, (y0 + y1) / 2, SHED_H / 2)
        b.box(size, centre, "brick")
        bo.collide(size, centre)
    bo.put(b.mesh(f"{name}_walls"), f"{name}_walls")
    d = bo.MeshBuilder()   # swing +1 opens north: the marker stands south of the wall
    bo.door(d, plan, "h", y0 if door_side == "south" else y1, WALL,
            bo.opening(gap[0], gap[1], room=name, swing=1 if door_side == "south" else -1))
    bo.put(d.mesh(f"{name}_door"), f"{name}_door")
    ROOF.box((x1 - x0 + 0.6, y1 - y0 + 0.6, 0.2), ((x0 + x1) / 2, (y0 + y1) / 2, SHED_H + 0.1), "metal_dark")
    f = bo.MeshBuilder()
    f.quad([(x0, y0, 0.004), (x1, y0, 0.004), (x1, y1, 0.004), (x0, y1, 0.004)], "concrete")
    bo.put(f.mesh(f"{name}_floor"), f"{name}_floor")


SHELVES = (0.15, 0.7, 1.25, 1.8)   # a rack's shelf heights


def rack(b: bo.MeshBuilder, x0: float, x1: float, y: float, depth: float, stocked: bool = True) -> None:
    """Steel shelving along x on four shelves, with boxed stock (`stocked`) or empty (its stock
    is a tell's: rack_boxes)."""
    bays = max(1, round((x1 - x0) / 1.8))
    bw = (x1 - x0) / bays
    for i in range(bays + 1):
        b.box((0.05, depth, 2.2), (x0 + i * bw, y, 1.1), "metal_blue")
    for z in SHELVES:
        b.box((x1 - x0, depth, 0.03), ((x0 + x1) / 2, y, z), "steel")
    if stocked:
        rack_boxes(b, x0, x1, y, depth, set())
    bo.collide((x1 - x0, depth, 2.2), ((x0 + x1) / 2, y, 1.1))


def rack_boxes(b: bo.MeshBuilder, x0: float, x1: float, y: float, depth: float, gone: set) -> list[tuple]:
    """The boxes on a rack (three a bay a shelf), but those in `gone`; returns every box's key
    (bay, shelf, k)."""
    bays = max(1, round((x1 - x0) / 1.8))
    bw = (x1 - x0) / bays
    keys = []
    for s, z in enumerate(SHELVES):
        for i in range(bays):
            for k in range(3):
                keys.append((i, s, k))
                if (i, s, k) in gone:
                    continue
                cx = x0 + i * bw + (k + 0.6) * bw / 3.4
                b.box((bw / 3.8, depth * 0.8, 0.32), (cx, y, z + 0.17), "dossier" if (i + k) % 2 else "plastic_grey")
    return keys


def magazijn(kits, plan) -> None:
    x0, y0, x1, y1 = MAGAZIJN
    shed("magazijn", MAGAZIJN, "south", -28.5, plan)
    b = bo.MeshBuilder()
    rack(b, x0 + 0.5, x1 - 0.5, y1 - 0.5, 0.6, stocked=False)     # the moffen: their boxes are a tell
    rack(b, x0 + 3.0, x1 - 2.5, 17.0, 0.6)                         # a middle row
    b.box((2.6, 0.6, 1.0), (-31.8, 14.0, 0.5), "wood")             # Dirk's counter
    b.box((2.6, 0.62, 0.04), (-31.8, 14.0, 1.02), "metal_white")
    bo.collide((2.6, 0.6, 1.0), (-31.8, 14.0, 0.5))
    bo.put(kits["meter_shelf"], "magazijn_meter_shelf", (x0 + 0.3, 19.0, 0), 90)
    bo.collide((0.5, 1.85, 2.0), (x0 + 0.35, 19.0, 1.0))
    bo.put(kits["laptop"], "magazijn_laptop", (-31.4, 14.0, 1.04), 180)
    bo.put(b.mesh("magazijn_inside"), "magazijn_inside")
    joint_shelf(x0 + 0.5, x1 - 0.5, y1 - 0.5, 0.6)
    uitgiftelijst(COUNTER_LIST)


# --------------------------------------------------------------------------- tells (PLAN 2.6, S3-Y)
# The yard's props that read the simulation, as on the floors (build_office.tell): a `tell_<id>`
# empty with `_low`, `_mid` and `_high` variants; game/src/world/office/office_tells.gd shows one.
# Outdoors there is no bake to keep them out of.

def joint_shelf(x0: float, x1: float, y: float, depth: float) -> None:
    """The magazijn's joint shelf (the rack on its back wall): its boxes per band, emptying bay by
    bay from the middle as the moffen run low (low: half a bay gone; mid: two bays and some;
    high: a few boxes left)."""
    keys = rack_boxes(bo.MeshBuilder(), x0, x1, y, depth, set())
    order = sorted(keys, key=lambda key: ([2, 4, 0, 3, 1].index(key[0]), -key[1], key[2]))
    variants = {}
    for band, n in zip(bo.TELL_VARIANTS, (6, 30, 51)):
        b = bo.MeshBuilder()
        rack_boxes(b, x0, x1, y, depth, set(order[:n]))
        variants[band] = [(b.mesh(f"joint_shelf_{band}"), (0, 0, 0), 0)]
    bo.tell("magazijn_rack", (0, 0, 0), 0, variants)


COUNTER_LIST = (-32.85, 13.92, 1.04)   # the uitgiftelijst: the west end of the counter (clear of the joint)
LIST_ROW = 0.0165                      # a written line's pitch on the A4


def _list_sheet(b: bo.MeshBuilder, lines: int, z: float, seed: int, dx: float = 0.0, dy: float = 0.0,
                rot: float = 0.0) -> None:
    """An A4 sheet of the list (top of the page at local +Y) with `lines` lines written on it in
    pen: what was taken, by which bus, and a paraaf at the end."""
    b.box((0.21, 0.297, 0.0015), (dx, dy - 0.01, z), "paper", rot=rot)
    a = np.radians(rot)
    rng = np.random.default_rng(seed)

    def at(x: float, y: float) -> tuple[float, float, float]:
        return dx + x * np.cos(a) - y * np.sin(a), dy + x * np.sin(a) + y * np.cos(a), z + 0.001

    b.box((0.17, 0.003, 0.0005), at(0.0, 0.112), "metal_blue", rot=rot)   # the printed heading
    for r in range(lines):
        y = 0.09 - r * LIST_ROW
        length = float(rng.uniform(0.09, 0.14))
        b.box((length, 0.003, 0.0005), at(-0.085 + length / 2, y), "plastic_black", rot=rot)
        b.box((0.022, 0.004, 0.0005), at(0.07, y + float(rng.normal(0, 0.001))), "plastic_black",
              rot=rot + float(rng.normal(0, 8)))


def uitgiftelijst(at) -> None:
    """The magazijn's uitgiftelijst on Dirk's counter, a clipboard with this week's list: a line
    per part a monteur signed out (date, bus, what, paraaf). Low a few lines; mid a full sheet;
    high the third sheet begun, the first two folded back under the board (their edges show).
    It is what anyone keeps at a counter, never the van kanban (two_bin_van_kanban, a fix)."""
    b = bo.MeshBuilder()
    b.box((0.23, 0.32, 0.004), (0, 0, 0.0055), "wood")   # the board, on whatever sheets lie under it
    b.box((0.1, 0.03, 0.012), (0, 0.145, 0.0135), "alu")  # its clip
    b.cyl(0.004, 0.14, (0.16, -0.02, 0.004), "plastic_black", segs=8, axis="Y")  # the pen beside it
    fixed = [("board", b.mesh("uitgifte_board"), (0, 0, 0), 0)]
    variants = {}
    for band, lines, under in (("low", 4, 0), ("mid", 15, 0), ("high", 9, 2)):
        v = bo.MeshBuilder()
        for k in range(under):   # folded back under the board: their edges stick out
            v.box((0.21, 0.297, 0.0015), (0.006 - 0.012 * k, -0.026 - 0.008 * k, 0.00075 + 0.0016 * k), "paper",
                  rot=2.5 - 4.0 * k)
        _list_sheet(v, lines, 0.0083, 41 + lines)
        variants[band] = [(v.mesh(f"uitgifte_{band}"), (0, 0, 0), 0)]
    bo.tell("uitgiftelijst", at, 0, variants, fixed=fixed)


def storingsbord(at) -> None:
    """The storingsdienst's whiteboard on the werkplaats's west wall (front at local -X, facing
    the room): this week's callouts, a line each in marker, a green tick when it went well, a red
    stroke when it took long, and at the highest a second time behind some (searched again).
    Low seven lines, all ticked; mid fifteen, three red; high the board full, eleven red."""
    w, h, zc = 1.8, 1.0, 1.5
    rng = np.random.default_rng(37)
    rows = [(col, row) for col in range(3) for row in range(9)]
    lines = [(float(rng.uniform(0.24, 0.34)), float(rng.normal(0, 0.004))) for _ in rows]
    reds = {band: set(rng.choice(n, size=k, replace=False).tolist())
            for band, n, k in (("low", 7, 0), ("mid", 15, 3), ("high", 27, 11))}
    variants = {}
    for band, n in zip(bo.TELL_VARIANTS, (7, 15, 27)):
        b = bo.MeshBuilder()
        b.box((0.003, 0.5, 0.018), (-0.004, 0.6, zc + h / 2 - 0.07), "metal_blue")   # the heading
        for i, ((col, row), (length, dz)) in enumerate(list(zip(rows, lines))[:n]):
            y0, z = 0.84 - col * 0.58, zc + h / 2 - 0.15 - row * 0.09 + dz
            b.box((0.003, length, 0.011), (-0.004, y0 - length / 2, z), "plastic_black")
            red = i in reds[band]
            b.box((0.003, 0.06 if red else 0.025, 0.012), (-0.004, y0 - length - 0.06, z),
                  "card_red" if red else "card_green")
            if red and band == "high" and i % 2:   # a second time: the fault searched for again
                b.box((0.003, 0.07, 0.009), (-0.004, y0 - length - 0.16, z), "plastic_black")
        variants[band] = [(b.mesh(f"storingsbord_{band}"), (0, 0, 0), 0)]
    bo.tell("storingsbord", at, 180, variants, fixed=[("frame", bo.kit_board_frame(w, h), (0, 0, zc), 180)])


def measurement_tray(kits, at) -> None:
    """The tray of voltage complaints on the cabinet by the measuring kit (local x along the
    cabinet): low the tray, mid a pile on it, high a full tray and two piles beside it."""
    def pile(h: float, seed: int, base: float = 0.75) -> bpy.types.Mesh:
        return bo._raise(bo.kit_dossier_stack(h, 60 + seed), base)

    on_tray = 0.75 + 0.145
    bo.tell("measurement_tray", at, 90, {
        "low": [(kits["tray"], (0.25, 0, 0), 0)],
        "mid": [(kits["tray"], (0.25, 0, 0), 0), (pile(0.12, 0, on_tray), (0.25, 0, 0), 4)],
        "high": [(kits["tray"], (0.25, 0, 0), 0), (pile(0.3, 1, on_tray), (0.25, 0, 0), 4),
                 (pile(0.22, 2), (-0.12, 0.02, 0), -7), (pile(0.14, 3), (-0.42, 0, 0), 5)]})


RETURNS = (-37.2, 20.4)   # the returns pallet: in the van park's north-east corner, clear of the bays


def van_returns() -> None:
    """The returns pallet at the van park: what came back from a visit that failed, meter boxes
    (cardboard) and connection kits (a coil of cable on a box), each with its slip. Low three
    boxes, mid a stack and a kit, high a full pallet and a second one beside it."""
    def load(b: bo.MeshBuilder, x: float, n_boxes: int, kits_: int) -> None:
        b.box((1.2, 0.8, 0.14), (x, 0, 0.07), "wood")
        spots = [(x - 0.4 + (k % 3) * 0.4, -0.2 + (k // 3 % 2) * 0.4, k // 6) for k in range(12)]
        for k, (sx, sy, layer) in enumerate(spots[:n_boxes]):
            z = 0.14 + layer * 0.26 + 0.13
            b.box((0.36, 0.36, 0.25), (sx, sy, z), "card_old", rot=float((k * 37) % 7 - 3))
            b.box((0.08, 0.002, 0.1), (sx, sy - 0.181, z), "paper")   # its slip, facing the yard (east)
        for k in range(kits_):
            sx, sy, layer = spots[n_boxes + k] if n_boxes + k < len(spots) else (x, 0, 2)
            z = 0.14 + layer * 0.26
            b.box((0.36, 0.36, 0.12), (sx, sy, z + 0.06), "plastic_grey")
            b.cyl(0.15, 0.08, (sx, sy, z + 0.16), "plastic_black", segs=14)
    variants = {}
    for band, boxes, kits_, second in (("low", 3, 0, 0), ("mid", 7, 1, 0), ("high", 10, 2, 6)):
        b = bo.MeshBuilder()
        load(b, 0.0, boxes, kits_)
        if second:
            load(b, 0.0 - 1.35, second, 1)
        variants[band] = [(b.mesh(f"returns_{band}"), (0, 0, 0), 0)]
    bo.tell("van_returns", (*RETURNS, 0.0), 90, variants)
    bo.collide((0.8, 1.2, 0.6), (*RETURNS, 0.3))   # the first pallet (the second comes and goes)


def werkplaats(kits, plan) -> None:
    x0, y0, x1, y1 = WERKPLAATS
    shed("werkplaats", WERKPLAATS, "north", -28.5, plan)
    b = bo.MeshBuilder()
    b.box((3.2, 0.8, 0.9), (-26.5, y0 + 0.6, 0.45), "wood")         # the workbench (execution)
    b.box((3.2, 0.05, 0.9), (-26.5, y0 + 0.22, 1.35), "metal_white")  # its tool wall
    bo.collide((3.2, 0.8, 0.9), (-26.5, y0 + 0.6, 0.45))
    for i, y in enumerate((-1.2, 0.6, 2.4)):                          # cable drums (commissioning)
        b.cyl(0.55, 0.5, (x1 - 0.6, y, 0.55), "wood", segs=20, axis="X")
        bo.collide((0.6, 1.1, 1.1), (x1 - 0.6, y, 0.55))
    b.box((1.8, 0.9, 0.75), (-31.0, -0.6, 0.375), "wood")             # the on-call table (locate)
    bo.collide((1.8, 0.9, 0.75), (-31.0, -0.6, 0.375))
    rack(b, x0 + 0.4, x0 + 1.0, -4.3, 1.6)                             # measuring kit (measurement)
    b.box((1.0, 0.8, 1.2), (-29.0, y0 + 1.1, 0.6), "metal_dark")       # a small transformer (tap change)
    bo.collide((1.0, 0.8, 1.2), (-29.0, y0 + 1.1, 0.6))
    bo.put(b.mesh("werkplaats_inside"), "werkplaats_inside")
    storingsbord((x0 + WALL / 2 + 0.011, -0.6, 0.0))
    cabinet = (x0 + WALL / 2 + 0.235, -2.6)   # by the measuring kit: the voltage complaints' tray
    bo.put(kits["cabinet_1.2"], "werkplaats_cabinet", (*cabinet, 0), 90)
    bo.collide((0.45, 1.2, 0.75), (*cabinet, 0.375))
    measurement_tray(kits, (*cabinet, 0.0))
    for k, (x, y) in enumerate(((-33.4, 3.4), (-24.6, -5.4))):
        bo.put(kits["chair"], f"werkplaats_chair{k}", (x, y, 0), 45 * k)


def van_park_fence(plan) -> None:
    """The van park's fence on its east side with the gate (the room's door: open once a
    mission needs the vans)."""
    x = VAN_PARK[2]
    gate = (7.0, 10.0)
    b = bo.MeshBuilder()
    for a, c in ((VAN_PARK[1], gate[0]), (gate[1], VAN_PARK[3])):
        size, centre = (0.06, c - a, 1.8), (x, (a + c) / 2, 0.9)
        b.box(size, centre, "metal_dark")
        bo.collide(size, centre)
    bo.put(b.mesh("van_park_fence"), "van_park_fence")
    d = bo.MeshBuilder()   # swing -1 opens west, into the park: the marker stands east
    bo.door(d, plan, "v", x, 0.06, bo.opening(gate[0], gate[1], room="van_park", swing=-1))
    bo.put(d.mesh("van_park_gate"), "van_park_gate")


def van(k: int) -> None:
    """A Voltana van at bay k, its back doors east (open on OPEN_VAN, the shelves inside)."""
    y = VAN_YS[k]
    b = bo.MeshBuilder()
    b.box((4.4, 2.0, 2.1), (VAN_X + 0.5, y, 1.35), "metal_white", bevel=0.05)    # the box
    b.box((1.3, 1.95, 1.4), (VAN_X - 2.3, y, 1.0), "metal_white", bevel=0.08)    # the cab
    b.box((0.05, 1.7, 0.6), (VAN_X - 2.96, y, 1.35), "glass_dark")               # the windscreen
    for side in (-1, 1):
        b.panel((VAN_X + 0.6, y + side * 1.01, 1.6), 2.6, 0.62, "Y", "signage", uv_rect=bo.SIGN_RECTS["logo"], sign=side)
        for wx in (VAN_X - 2.0, VAN_X + 1.8):
            b.cyl(0.36, 0.25, (wx, y + side * 0.92, 0.36), "plastic_black", segs=14, axis="Y")
    rear = VAN_X + 2.7
    if k == OPEN_VAN:
        for side in (-1, 1):   # the doors swung open, the bins a jumble
            b.box((0.95, 0.05, 1.9), (rear + 0.47, y + side * 1.0, 1.3), "metal_white")
        for i in range(5):
            b.box((0.4, 0.3, 0.25), (rear - 0.4 - (i % 2) * 0.3, y - 0.6 + i * 0.3, 0.6 + (i % 3) * 0.35),
                  "plastic_grey" if i % 2 else "dossier")
    else:
        b.box((0.05, 1.9, 1.9), (rear, y, 1.3), "metal_white")
    bo.put(b.mesh(f"van{k}"), f"van{k}")
    bo.collide((5.7, 2.1, 2.4), (VAN_X - 0.15, y, 1.2))


def opleidingsterrein(plan) -> None:
    """The training ground (PLAN 2.3): a fenced concrete yard off the yard's south fence, its
    gate the room's door (open once a mission needs it). A practice trench with a cable and a
    joint on it and the spoil beside it, a meterkast on a stand, a trafohuisje mock-up."""
    x0, y0, x1, y1 = TRAINING
    b = bo.MeshBuilder()
    for size, centre in (((0.06, y1 - y0, 1.8), (x0, (y0 + y1) / 2, 0.9)),
                         ((0.06, y1 - y0, 1.8), (x1, (y0 + y1) / 2, 0.9)),
                         ((x1 - x0, 0.06, 1.8), ((x0 + x1) / 2, y0, 0.9))):
        b.box(size, centre, "metal_dark")
        bo.collide(size, centre)
    tx0, tx1, ty, tw = TRENCH
    b.quad([(tx0, ty - tw / 2, 0.006), (tx1, ty - tw / 2, 0.006), (tx1, ty + tw / 2, 0.006),
            (tx0, ty + tw / 2, 0.006)], "soil")
    for side in (-1, 1):   # the trench's timber edging
        b.box((tx1 - tx0 + 0.2, 0.12, 0.16), ((tx0 + tx1) / 2, ty + side * (tw / 2 + 0.06), 0.08), "wood")
    b.box((tx1 - tx0 - 0.6, 1.0, 0.5), ((tx0 + tx1) / 2, ty - tw / 2 - 0.7, 0.25), "soil", bevel=0.2, segs=2)  # the spoil
    b.cyl(0.035, tx1 - tx0, ((tx0 + tx1) / 2, ty, 0.12), "plastic_black", segs=10, axis="X")   # the cable
    b.cyl(0.09, 0.7, (JOINT_X, ty, 0.14), "plastic_grey", segs=16, axis="X")                     # the joint
    for dx in (-0.38, 0.38):
        b.cyl(0.06, 0.1, (JOINT_X + dx, ty, 0.14), "plastic_black", segs=12, axis="X")
    bo.collide((tx1 - tx0 + 0.2, tw + 1.4, 0.6), ((tx0 + tx1) / 2, ty - 0.5, 0.3))
    mx, my = -22.4, -16.0      # the meterkast on its stand, its front north
    b.box((0.7, 0.5, 0.05), (mx, my, 0.025), "metal_dark")
    b.box((0.08, 0.08, 1.0), (mx, my, 0.55), "metal_dark")
    b.box((0.62, 0.26, 0.82), (mx, my, 1.4), "metal_white", bevel=0.01)
    b.box((0.2, 0.02, 0.26), (mx - 0.13, my + 0.135, 1.5), "plastic_black")   # the meter
    b.box((0.16, 0.02, 0.1), (mx + 0.15, my + 0.135, 1.5), "plastic_grey")    # the fuses
    bo.collide((0.7, 0.5, 1.8), (mx, my, 0.9))
    hx, hy = -28.4, -16.4      # the trafohuisje mock-up, its doors north
    b.box((2.6, 2.0, 2.3), (hx, hy, 1.15), "concrete", bevel=0.02)
    b.box((2.8, 2.2, 0.12), (hx, hy, 2.36), "metal_dark")
    for dx in (-0.6, 0.6):
        b.box((1.0, 0.04, 1.9), (hx + dx, hy + 1.01, 0.98), "metal_dark")
    b.panel((hx, hy + 1.04, 2.12), 1.1, 0.2, "Y", "signage", uv_rect=bo.SIGN_RECTS["logo"], sign=1)
    bo.collide((2.6, 2.0, 2.3), (hx, hy, 1.15))
    bo.put(b.mesh("opleidingsterrein"), "opleidingsterrein")
    d = bo.MeshBuilder()   # swing -1 opens south, into the ground: the marker stands north, on the yard
    bo.door(d, plan, "h", Y0, 0.06, bo.opening(TRAINING_GATE[0], TRAINING_GATE[1], room="opleidingsterrein", swing=-1))
    bo.put(d.mesh("opleidingsterrein_gate"), "opleidingsterrein_gate")


def markers() -> list[tuple]:
    out = [("exit:ground", {"interaction": "exit", "id": "ground"}, (X1 - 0.9, DOOR[0]), (X1, DOOR[0])),
           ("arrive:exit", {"interaction": "arrive", "id": "exit"}, (X1 - 1.6, DOOR[0]), (X1 - 8.0, DOOR[0]))]
    p = bo.place
    out += [p("outages.joint", (-31.8, 12.9), (-31.8, 14.0)),
            p("connections.materials", (-27.5, 20.4), (-27.5, 21.5)),
            p("meters.reserve_meter", (-32.6, 19.6), (-34.0, 19.6)),
            p("outages.locate", (-31.0, 1.2), (-31.0, -0.6)),
            p("connections.execution", (-25.6, -4.0), (-25.6, -5.4)),
            p("connections.commissioning", (-25.6, 1.5), (-24.0, 1.5)),
            p("voltage_complaints.measurement", (-32.4, -4.3), (-34.0, -4.3)),
            p("voltage_complaints.tap_change", (-29.0, -2.6), (-29.0, -4.9)),
            p("outages.repair", (VAN_X + 4.0, VAN_YS[OPEN_VAN]), (VAN_X + 2.7, VAN_YS[OPEN_VAN])),
            p("meters.visit", (VAN_X + 4.0, VAN_YS[5]), (VAN_X + 2.7, VAN_YS[5]))]
    for k, y in enumerate(VAN_YS):   # the monteur by the van's back (loading it, facing the yard), the ride at the passenger's door
        out += [(f"driver:van{k}", {"interaction": "driver", "id": f"van{k}"}, (VAN_X + 3.3, y - 1.35), (VAN_X + 6.0, y - 1.8)),
                (f"ride:van{k}", {"interaction": "ride", "id": f"van{k}"}, (VAN_X - 2.0, y + 1.55), (VAN_X - 2.0, y))]
    return out


class YardPlan:
    """What build_office.build_empties needs: markers and room rects."""

    def __init__(self) -> None:
        self.markers = markers()
        self.rooms = {"magazijn": MAGAZIJN, "werkplaats": WERKPLAATS, "van_park": VAN_PARK,
                      "opleidingsterrein": TRAINING}


CAB_W, CAB_H = 1.9, 1.5               # the cab inside: width, roof
CAB_REAR, CAB_FRONT = -0.85, 0.95     # the bulkhead behind the seats, the windscreen's foot
CAB_SEAT_X, CAB_SEAT_Y = 0.45, -0.25  # the seats' middles (the driver left: Dutch traffic)
CAB_SILL = 0.95                       # the side windows' sill


class CabPlan:
    """The cab's markers: where the driver and the passenger sit (facing the windscreen)."""

    def __init__(self) -> None:
        self.markers = [("seat:driver", {"interaction": "seat", "id": "driver"}, (-CAB_SEAT_X, CAB_SEAT_Y),
                         (-CAB_SEAT_X, 1.0)),
                        ("seat:passenger", {"interaction": "seat", "id": "passenger"}, (CAB_SEAT_X, CAB_SEAT_Y),
                         (CAB_SEAT_X, 1.0))]
        self.rooms: dict = {}


def cab() -> None:
    """A Voltana van's cab seen from inside (the van ride): floor, the bulkhead behind the
    two seats, the door trims up to the windows, the pillars, the roof, the dashboard with
    the wheel on the left, the bonnet out front. The side windows are open frames: the ride
    shows the edge of town going by outside (van_ride.gd). Faces +Y."""
    b = bo.MeshBuilder()
    w, h, sill = CAB_W, CAB_H, CAB_SILL
    length = CAB_FRONT - CAB_REAR
    mid = (CAB_FRONT + CAB_REAR) / 2
    b.box((w + 0.12, length + 0.2, 0.06), (0, mid, -0.03), "plastic_black")         # the floor
    b.box((w + 0.12, 0.06, h), (0, CAB_REAR - 0.03, h / 2), "plastic_grey")          # the bulkhead
    b.box((w + 0.12, length + 0.2, 0.06), (0, mid, h + 0.03), "plastic_grey")       # the roof lining
    for side in (-1, 1):
        x = side * (w / 2 + 0.03)
        b.box((0.06, length + 0.2, sill), (x, mid, sill / 2), "plastic_grey")       # the door trim
        b.box((0.08, 0.14, h - sill), (x, CAB_REAR + 0.07, (sill + h) / 2), "plastic_grey")   # B pillar
        b.box((0.08, 0.12, h - sill), (x, CAB_FRONT - 0.04, (sill + h) / 2), "plastic_grey")  # A pillar
        b.box((0.05, 0.22, 0.14), (x + side * 0.16, CAB_FRONT, 1.08), "plastic_black")       # the mirror
        b.box((0.3, 0.12, 0.04), (side * (w / 2 - 0.2), mid, 0.7), "plastic_black")         # the armrest
    b.box((w, 0.5, 0.34), (0, CAB_FRONT - 0.2, 0.78), "plastic_black", bevel=0.04)  # the dashboard
    b.box((w, 0.24, 0.04), (0, CAB_FRONT - 0.06, 0.96), "plastic_grey")
    b.cyl(0.19, 0.035, (-CAB_SEAT_X, CAB_FRONT - 0.5, 0.95), "plastic_black", segs=24, axis="Y")   # the wheel
    b.cyl(0.035, 0.3, (-CAB_SEAT_X, CAB_FRONT - 0.36, 0.9), "plastic_black", segs=10, axis="Y")
    b.box((0.03, 0.03, 0.08), (0.0, CAB_FRONT - 0.06, h - 0.09), "plastic_black")   # the rear-view mirror
    b.box((0.26, 0.03, 0.08), (0.0, CAB_FRONT - 0.08, h - 0.17), "plastic_black", bevel=0.015)
    b.box((w + 0.12, 0.1, 0.1), (0, CAB_FRONT, h - 0.05), "plastic_grey")           # the windscreen's top
    for x in (-CAB_SEAT_X, CAB_SEAT_X):                                              # the seats
        b.box((0.4, 0.4, 0.4), (x, CAB_SEAT_Y, 0.2), "plastic_black")
        b.box((0.52, 0.5, 0.12), (x, CAB_SEAT_Y + 0.02, 0.46), "fabric_dark", bevel=0.03, segs=2)
        b.box((0.5, 0.12, 0.62), (x, CAB_SEAT_Y - 0.3, 0.84), "fabric_dark", bevel=0.03, segs=2)
        b.box((0.26, 0.1, 0.2), (x, CAB_SEAT_Y - 0.32, 1.27), "fabric_dark", bevel=0.03, segs=2)
    b.box((w + 0.16, 0.8, 0.2), (0, CAB_FRONT + 0.42, 0.82), "metal_white", bevel=0.06)   # the bonnet
    bo.put(b.mesh("cab"), "cab")
    g = bo.MeshBuilder()   # a faint windscreen
    g.quad([(-w / 2, CAB_FRONT, sill), (w / 2, CAB_FRONT, sill), (w / 2, CAB_FRONT, h - 0.1),
            (-w / 2, CAB_FRONT, h - 0.1)], "glass")
    bo.put(g.mesh("glass_windscreen"), "glass_windscreen")
    bo.build_empties(CabPlan())


def _fresh_scene() -> dict:
    """An empty Blender scene with the office's materials; the office's kits."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ROOF.__init__()
    bo.MATS.clear()
    bo.UV_SIZE.clear()
    bo.COLLIDERS.clear()
    bo.make_materials()
    return bo.build_kits()


def _export(path: Path) -> None:
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", export_keep_originals=True, export_extras=True,
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=False, export_materials="EXPORT", export_cameras=False, export_lights=False,
        use_selection=False)
    bo.fix_external_images(path)
    print(f"wrote {path} ({path.stat().st_size / 1e6:.1f} MB)", flush=True)


def build_cab() -> None:
    _fresh_scene()
    cab()
    print(f"cab: triangles: {bo.triangle_count()}")
    _export(CAB_OUT)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--only", choices=["yard", "cab"], help="build only the yard or only the cab")
    args = parser.parse_args()
    if not bo.WORLD.exists():
        sys.exit(f"missing {bo.WORLD}; run python tools/build_content.py first")
    bo.BUILDING.update(json.loads(bo.WORLD.read_text(encoding="utf-8")))   # the kits' signs read it
    if args.only != "cab":
        build_yard()
    if args.only != "yard":
        build_cab()


def build_yard() -> None:
    yard_rooms = {r["id"] for r in bo.BUILDING["rooms"] if r["floor"] == "yard"}
    plan = YardPlan()
    if yard_rooms != set(plan.rooms):
        sys.exit(f"the yard builds rooms {sorted(plan.rooms)}, world.json names {sorted(yard_rooms)}")
    kits = _fresh_scene()
    ground()
    magazijn(kits, plan)
    werkplaats(kits, plan)
    van_park_fence(plan)
    van_returns()
    opleidingsterrein(plan)
    for k in range(len(VAN_YS)):
        van(k)
    bo.put(ROOF.mesh("shell_ceiling"), "shell_ceiling")
    bo.build_empties(plan)
    bo.build_collision()
    print(f"yard: triangles: {bo.triangle_count()}  objects: {len(bpy.context.scene.objects)}")
    _export(OUT)


if __name__ == "__main__":
    main()
