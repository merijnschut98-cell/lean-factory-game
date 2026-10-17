"""Build the yard (de werf) with bpy: game/assets/office/office_yard.glb (PLAN 2.2).

Run with Blender's Python module, like build_office.py (see tools/blender/README.md):

    .bvenv/bin/python tools/blender/build_yard.py

The yard lies west of the head office, in the building's own coordinates (Blender metres,
Z up): the building's west gable stands at x = -18 with the kantine's back door at y = 8,
the yard runs x -50..-18, y -8..24. Two single-storey sheds, the magazijn (north) and the
werkplaats & storingsdienst (south), and the van park along the west fence; the van kanban
wall hangs on the magazijn's west wall, facing the vans. Spec:
docs/superpowers/specs/2026-10-17-the-yard.md.

Outdoors: no lightmaps (Godot's sun and shadows). The ground is `shell_floor` (the game
reads the floor's outline from it) and the sheds' roofs `shell_ceiling` (the camera cuts
them away). Markers as on the floors: `place:<step>`, `room:<id>` with its rect, the seam
`exit:ground` (back inside) and `arrive:exit` where the player steps out. The vans are
`van<k>` (van0 and van1 the storingsbussen on call); the game parks and sends them out by
the hour (office_yard.gd).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_office as bo  # noqa: E402  (materials, kits, MeshBuilder, colliders, markers)
import bpy  # noqa: E402

OUT = bo.ASSETS / "office_yard.glb"
X0, X1, Y0, Y1 = -50.0, -18.0, -8.0, 24.0      # the yard
WALL = 0.2                                     # the sheds' walls
SHED_H = 3.2
DOOR = (8.0, 1.0)                              # the back door: y and width, in the gable at x = -18
MAGAZIJN = (-34.0, 12.0, -24.0, 22.0)          # x0, y0, x1, y1
WERKPLAATS = (-34.0, -6.0, -24.0, 4.0)
VAN_PARK = (-48.0, -6.0, -36.0, 22.0)
VAN_YS = (-3.0, 1.0, 5.0, 9.0, 13.0, 17.0)     # the bays (van0, van1: the storingsbussen)
VAN_X = -44.6                                  # a van's middle; its back doors face east
OPEN_VAN = 3                                   # the van with its back doors open (a tell)


def ground() -> None:
    b = bo.MeshBuilder()
    b.quad([(X0, Y0, 0), (X1, Y0, 0), (X1, Y1, 0), (X0, Y1, 0)], "paving")
    bo.put(b.mesh("shell_floor"), "shell_floor")
    bo.collide((X1 - X0 + 1, Y1 - Y0 + 1, 0.2), ((X0 + X1) / 2, (Y0 + Y1) / 2, -0.1))   # the ground to stand on
    o = bo.MeshBuilder()
    o.quad([(X0 - 30, Y0 - 30, -0.02), (X1 + 50, Y0 - 30, -0.02), (X1 + 50, Y1 + 30, -0.02), (X0 - 30, Y1 + 30, -0.02)], "grass")
    o.quad([(VAN_PARK[0], VAN_PARK[1], 0.003), (VAN_PARK[2], VAN_PARK[1], 0.003), (VAN_PARK[2], VAN_PARK[3], 0.003),
            (VAN_PARK[0], VAN_PARK[3], 0.003)], "asphalt")
    for y in VAN_YS:   # the bays' white lines
        for dy in (-1.6, 1.6):
            o.box((6.4, 0.08, 0.004), (VAN_X + 0.4, y + dy, 0.006), "plastic_white")
    # the fence round the yard (the east side is the building), with a gate south
    for (a, b_, axis, at) in ((Y0, Y1, "x", X0), (X0, -40.0, "y", Y0), (-36.0, X1, "y", Y0), (X0, X1, "y", Y1)):
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


def rack(b: bo.MeshBuilder, x0: float, x1: float, y: float, depth: float, empty_bay: int = -1) -> None:
    """Steel shelving along x with boxed stock on four shelves; `empty_bay` holds nothing."""
    bays = max(1, round((x1 - x0) / 1.8))
    bw = (x1 - x0) / bays
    for i in range(bays + 1):
        b.box((0.05, depth, 2.2), (x0 + i * bw, y, 1.1), "metal_blue")
    for z in (0.15, 0.7, 1.25, 1.8):
        b.box((x1 - x0, depth, 0.03), ((x0 + x1) / 2, y, z), "steel")
        for i in range(bays):
            if i == empty_bay:
                continue
            for k in range(3):
                cx = x0 + i * bw + (k + 0.6) * bw / 3.4
                b.box((bw / 3.8, depth * 0.8, 0.32), (cx, y, z + 0.17), "dossier" if (i + k) % 2 else "plastic_grey")
    bo.collide((x1 - x0, depth, 2.2), ((x0 + x1) / 2, y, 1.1))


def magazijn(kits, plan) -> None:
    x0, y0, x1, y1 = MAGAZIJN
    shed("magazijn", MAGAZIJN, "south", -28.5, plan)
    b = bo.MeshBuilder()
    rack(b, x0 + 0.5, x1 - 0.5, y1 - 0.5, 0.6, empty_bay=2)       # the moffen: one bay empty
    rack(b, x0 + 3.0, x1 - 2.5, 17.0, 0.6)                         # a middle row
    b.box((2.6, 0.6, 1.0), (-31.8, 14.0, 0.5), "wood")             # Dirk's counter
    b.box((2.6, 0.62, 0.04), (-31.8, 14.0, 1.02), "metal_white")
    bo.collide((2.6, 0.6, 1.0), (-31.8, 14.0, 0.5))
    bo.put(kits["meter_shelf"], "magazijn_meter_shelf", (x0 + 0.3, 19.0, 0), 90)
    bo.collide((0.5, 1.85, 2.0), (x0 + 0.35, 19.0, 1.0))
    bo.put(kits["laptop"], "magazijn_laptop", (-31.4, 14.0, 1.04), 180)
    bo.put(b.mesh("magazijn_inside"), "magazijn_inside")
    # the van kanban wall outside, on the west wall, facing the vans: cards in slots
    k = bo.MeshBuilder()
    bo.wall_board(k, "kanban_wall", "X", x0 - WALL / 2, 17.0, -1, 3.0, 1.2, (0, 0, 0.5, 1.0), mat="obeya")
    bo.sticky_notes(k, "X", x0 - WALL / 2 - 0.02, 17.0, -1, 3.0, 23, 22)
    bo.put(k.mesh("kanban_cards"), "kanban_cards")


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
    w = bo.MeshBuilder()   # the storingsdienst's board: last night's callouts
    bo.wall_board(w, "callout_board", "X", x0 + WALL / 2, -0.6, 1, 1.8, 1.0, (0.5, 0, 1.0, 1.0), mat="obeya")
    bo.sticky_notes(w, "X", x0 + WALL / 2 + 0.02, -0.6, 1, 1.8, 41, 9)
    bo.put(w.mesh("callout_cards"), "callout_cards")
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
    return out


class YardPlan:
    """What build_office.build_empties needs: markers and room rects."""

    def __init__(self) -> None:
        self.markers = markers()
        self.rooms = {"magazijn": MAGAZIJN, "werkplaats": WERKPLAATS, "van_park": VAN_PARK}


def main() -> None:
    if not bo.WORLD.exists():
        sys.exit(f"missing {bo.WORLD}; run python tools/build_content.py first")
    bo.BUILDING.update(json.loads(bo.WORLD.read_text(encoding="utf-8")))
    yard_rooms = {r["id"] for r in bo.BUILDING["rooms"] if r["floor"] == "yard"}
    plan = YardPlan()
    if yard_rooms != set(plan.rooms):
        sys.exit(f"the yard builds rooms {sorted(plan.rooms)}, world.json names {sorted(yard_rooms)}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ROOF.__init__()
    bo.MATS.clear()
    bo.UV_SIZE.clear()
    bo.COLLIDERS.clear()
    bo.make_materials()
    kits = bo.build_kits()
    ground()
    magazijn(kits, plan)
    werkplaats(kits, plan)
    van_park_fence(plan)
    for k in range(len(VAN_YS)):
        van(k)
    bo.put(ROOF.mesh("shell_ceiling"), "shell_ceiling")
    bo.build_empties(plan)
    bo.build_collision()
    print(f"yard: triangles: {bo.triangle_count()}  objects: {len(bpy.context.scene.objects)}")
    bpy.ops.export_scene.gltf(
        filepath=str(OUT), export_format="GLB", export_keep_originals=True, export_extras=True,
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=False, export_materials="EXPORT", export_cameras=False, export_lights=False,
        use_selection=False)
    bo.fix_external_images(OUT)
    print(f"wrote {OUT} ({OUT.stat().st_size / 1e6:.1f} MB)", flush=True)


if __name__ == "__main__":
    main()
