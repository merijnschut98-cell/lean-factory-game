"""Build Voltana's connections office with bpy and export game/assets/office/office.glb.

Run with Blender's Python module (see tools/blender/README.md):

    python tools/blender/build_office.py            # full build with the lightmap bake
    python tools/blender/build_office.py --no-bake  # fast: reuse the lightmaps on disk
    python tools/blender/build_office.py --samples 64

Coordinates are Blender's: metres, Z up, the floor is x 0..24, y 0..16 (south wall at
y = 0, entrance in the west wall). glTF export turns this into Godot's Y up:
(x, y, z) -> (x, z, -y).

What goes into the glb:
- the room shell (floor, walls, ceiling, columns) with a baked lightmap (ambient
  occlusion plus sky and ceiling-panel light) in a second UV set, exported as the glTF
  occlusionTexture on TEXCOORD_1; office_import.gd turns it into a multiply detail layer;
- furniture and props with shared meshes (one mesh per kind, many nodes);
- `collision-colonly`: simple boxes Godot turns into a static collision body;
- the interaction empties (`place:connections.intake`, ...) at standing height 0 where
  the player stands, local +Y (Godot -Z, forward) facing the object. Each carries the
  glTF extras `interaction` and `id`, because Godot's importer rewrites ':' and '.' in
  node names.
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy  # first: the bpy module registers bmesh and mathutils on import
import bmesh
import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "game" / "assets" / "office"
TEX = ASSETS / "textures"
OUT_GLB = ASSETS / "office.glb"

W, D = 24.0, 16.0          # interior floor, metres
CEIL = 2.8                 # suspended ceiling height
SLAB = 3.4                 # underside of the roof slab (plenum above the ceiling)
WALL_T = 0.3               # exterior cavity wall
SILL, HEAD = 0.9, 2.6      # ribbon windows (borstwering 0.9 m)
DOOR_Y = (7.45, 8.45)      # entrance door in the west wall, 1.0 x 2.1 m
COLUMNS = [(x, y) for x in (6.0, 12.0, 18.0) for y in (5.4, 10.8)]
COACH = (19.2, 10.8)       # glass-walled coach's room: x 19.2..24, y 10.8..16
COACH_DOOR = (20.0, 21.0)

# Real-world size (m) one repeat of each tileable texture covers (textures.py).
TEX_SIZE = {"carpet": 1.0, "ceiling": 1.2, "wood": 1.2, "plaster": 2.0, "concrete": 2.0,
            "paving": 1.2, "grass": 2.0, "metal": 0.5, "fabric": 0.25}


def srgb(r, g, b, a=1.0):
    """sRGB 0..255 to the linear RGBA Blender's colour sockets want."""
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), a)


VOLTANA_BLUE = srgb(14, 78, 160)

# --------------------------------------------------------------------------- materials

MATS: dict[str, bpy.types.Material] = {}
UV_SIZE: dict[str, float] = {}   # material name -> metres per UV unit (1.0 for atlases)


def _image(name: str, data: bool = False) -> bpy.types.Image:
    path = TEX / f"{name}.png"
    if not path.exists():
        sys.exit(f"missing texture {path}; run tools/blender/textures.py first")
    img = bpy.data.images.load(str(path), check_existing=True)
    if data:
        img.colorspace_settings.name = "Non-Color"
    return img


def _link(nt, a, b):
    nt.links.new(a, b)


def _socket(node, identifier: str):
    return next(s for s in node.inputs if s.identifier == identifier)


def material(name: str, tex: str | None = None, color=(1, 1, 1, 1), rough: float = 0.5,
             metal: float = 0.0, normal: bool = True, orm: bool = True,
             emission: str | tuple | None = None, alpha: str | float | None = None,
             uv_size: float | None = None) -> bpy.types.Material:
    """A Principled material the glTF exporter maps one to one.

    tex: base name of <tex>_albedo / _normal / _orm; color multiplies the albedo
    (exported as baseColorFactor). alpha: 'clip' (alpha-tested texture) or a float
    for blended glass. emission: an atlas name or an RGB(A) colour.
    """
    mat = bpy.data.materials.new(name)
    mat.use_backface_culling = True   # exported as single-sided; cards are built two-sided
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if tex:
        img = nt.nodes.new("ShaderNodeTexImage")
        img.image = _image(f"{tex}_albedo")
        if tuple(color[:3]) != (1, 1, 1):
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
            _socket(mix, "Factor_Float").default_value = 1.0
            _link(nt, img.outputs["Color"], _socket(mix, "A_Color"))
            _socket(mix, "B_Color").default_value = color
            _link(nt, next(o for o in mix.outputs if o.identifier == "Result_Color"), bsdf.inputs["Base Color"])
        else:
            _link(nt, img.outputs["Color"], bsdf.inputs["Base Color"])
        if alpha == "clip":
            rnd = nt.nodes.new("ShaderNodeMath")
            rnd.operation = "ROUND"
            _link(nt, img.outputs["Alpha"], rnd.inputs[0])
            _link(nt, rnd.outputs[0], bsdf.inputs["Alpha"])
        if orm and (TEX / f"{tex}_orm.png").exists():
            o = nt.nodes.new("ShaderNodeTexImage")
            o.image = _image(f"{tex}_orm", data=True)
            sep = nt.nodes.new("ShaderNodeSeparateColor")
            _link(nt, o.outputs["Color"], sep.inputs["Color"])
            _link(nt, sep.outputs["Green"], bsdf.inputs["Roughness"])
            _link(nt, sep.outputs["Blue"], bsdf.inputs["Metallic"])
        if normal and (TEX / f"{tex}_normal.png").exists():
            n = nt.nodes.new("ShaderNodeTexImage")
            n.image = _image(f"{tex}_normal", data=True)
            nm = nt.nodes.new("ShaderNodeNormalMap")
            _link(nt, n.outputs["Color"], nm.inputs["Color"])
            _link(nt, nm.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        bsdf.inputs["Base Color"].default_value = color
    if isinstance(alpha, float):
        bsdf.inputs["Alpha"].default_value = alpha
        mat.surface_render_method = "BLENDED"
    if emission is not None:
        if isinstance(emission, str):
            e = nt.nodes.new("ShaderNodeTexImage")
            e.image = _image(f"{emission}_albedo")
            _link(nt, e.outputs["Color"], bsdf.inputs["Emission Color"])
        else:
            bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 1.0
    MATS[name] = mat
    UV_SIZE[name] = uv_size if uv_size is not None else TEX_SIZE.get(tex or "", 1.0)
    return mat


def make_materials() -> None:
    m = material
    # shell (each gets its own lightmap node later)
    m("shell_carpet", "carpet")
    m("shell_ceiling", "ceiling")
    m("shell_plaster", "plaster")
    m("shell_accent", "plaster", color=srgb(40, 92, 168))
    m("shell_column", "plaster", color=srgb(246, 246, 244))
    # building exterior, never lit by a lightmap
    m("brick", "concrete", color=srgb(150, 86, 64), normal=True)
    m("concrete", "concrete")
    m("sill", "concrete", color=srgb(230, 228, 222), rough=0.4)
    m("paving", "paving")
    m("asphalt", "concrete", color=srgb(70, 72, 74), normal=False)
    m("glass_dark", None, color=srgb(30, 40, 48), rough=0.08)
    m("grass", "grass", normal=False)
    m("trees", "trees", alpha="clip", rough=0.9, uv_size=1.0)
    # furniture
    m("wood", "wood")
    m("metal_dark", "metal", color=srgb(62, 66, 72))
    m("metal_white", "metal", color=srgb(242, 241, 236))
    m("metal_blue", "metal", color=srgb(18, 82, 166))
    m("alu", None, color=srgb(196, 198, 202), rough=0.32, metal=0.9)
    m("frame", "metal", color=srgb(50, 54, 58))           # window and partition profiles (RAL 7016)
    m("fabric_dark", "fabric", color=srgb(70, 72, 78))
    m("fabric_blue", "fabric", color=srgb(40, 92, 168))
    m("fabric_grey", "fabric", color=srgb(178, 182, 186))
    m("fabric_teal", "fabric", color=srgb(60, 128, 130))
    m("fabric_coat", "fabric", color=srgb(48, 56, 80))
    m("fabric_mat", "fabric", color=srgb(40, 40, 42))
    m("plastic_black", None, color=srgb(22, 23, 25), rough=0.45)
    m("plastic_grey", None, color=srgb(120, 122, 126), rough=0.5)
    m("plastic_white", None, color=srgb(232, 232, 230), rough=0.4)
    m("ceramic", None, color=srgb(244, 244, 240), rough=0.15)
    m("pot", None, color=srgb(58, 60, 62), rough=0.6)
    m("soil", None, color=srgb(48, 36, 28), rough=1.0)
    m("paper", None, color=srgb(244, 243, 238), rough=0.9)
    m("sticky_yellow", None, color=srgb(250, 226, 90), rough=0.85)
    m("sticky_pink", None, color=srgb(246, 140, 170), rough=0.85)
    m("sticky_green", None, color=srgb(150, 220, 120), rough=0.85)
    m("sticky_blue", None, color=srgb(120, 196, 236), rough=0.85)
    m("screens", "screens", color=(0.02, 0.02, 0.02, 1), emission="screens", rough=0.12,
      normal=False, orm=False, uv_size=1.0)
    m("signage", "signage", rough=0.45, normal=False, orm=False, uv_size=1.0)
    m("obeya", "obeya", rough=0.18, normal=False, orm=False, uv_size=1.0)
    m("missions", "missions", rough=0.85, normal=False, orm=False, uv_size=1.0)
    m("posters", "posters", rough=0.35, normal=False, orm=False, uv_size=1.0)
    m("dossier", "dossier", rough=0.85, normal=False, orm=False, uv_size=1.0)
    m("devices", "devices", rough=0.5, normal=False, orm=False, uv_size=1.0)
    m("leaves", "leaves", alpha="clip", rough=0.6, normal=False, orm=False, uv_size=1.0)
    m("glass", None, color=srgb(214, 230, 228), rough=0.05, alpha=0.18)
    m("glass_frost", None, color=srgb(236, 240, 240), rough=0.5, alpha=0.75)
    m("light_panel", None, color=srgb(250, 250, 250), rough=0.5, emission=srgb(255, 250, 240))


# --------------------------------------------------------------------------- mesh building

class MeshBuilder:
    """Accumulates boxes, cylinders and quads in one bmesh with world-scale box UVs."""

    def __init__(self) -> None:
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.mats: list[str] = []

    def _mat(self, name: str) -> int:
        if name not in self.mats:
            self.mats.append(name)
        return self.mats.index(name)

    def _finish(self, faces, mat: str, smooth: bool = False, uv=True) -> None:
        idx, size = self._mat(mat), UV_SIZE[mat]
        for f in faces:
            f.material_index = idx
            f.smooth = smooth
            if not uv:
                continue
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                co = loop.vert.co
                u, v = {0: (co.y * (1 if n.x > 0 else -1), co.z),
                        1: (co.x * (-1 if n.y > 0 else 1), co.z),
                        2: (co.x, co.y)}[ax]
                loop[self.uv].uv = (u / size, v / size)

    def box(self, size, center, mat: str, bevel: float = 0.0, rot: float = 0.0, segs: int = 1):
        """An axis-aligned box (rotated about Z by rot degrees), optionally chamfered."""
        geom = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = geom["verts"]
        bmesh.ops.scale(self.bm, vec=Vector(size), verts=verts)
        if rot:
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(rot), 3, "Z"), verts=verts)
        bmesh.ops.translate(self.bm, vec=Vector(center), verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        if bevel > 0:
            edges = list({e for v in verts for e in v.link_edges})
            res = bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=segs, profile=0.5,
                                  affect="EDGES", clamp_overlap=True)
            faces = {f for f in faces if f.is_valid} | set(res["faces"])
            faces |= {f for v in res["verts"] for f in v.link_faces}
        self._finish(faces, mat)
        return faces

    def cyl(self, radius, depth, center, mat: str, segs: int = 16, radius2=None, axis="Z",
            smooth: bool = True, caps: bool = True):
        geom = bmesh.ops.create_cone(self.bm, cap_ends=caps, cap_tris=False, segments=segs,
                                     radius1=radius, radius2=radius if radius2 is None else radius2,
                                     depth=depth)
        verts = geom["verts"]
        if axis == "X":
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"), verts=verts)
        elif axis == "Y":
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "X"), verts=verts)
        bmesh.ops.translate(self.bm, vec=Vector(center), verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        self._finish(faces, mat)
        for f in faces:  # smooth the sides, keep the caps flat
            f.smooth = smooth and len(f.verts) == 4
        return faces

    def quad(self, corners, mat: str, uv_rect=None):
        """A single face from 4 corners (counter-clockwise seen from the front).
        uv_rect (u0, v0, u1, v1) in pixel-free 0..1 atlas space; None = box mapping."""
        vs = [self.bm.verts.new(Vector(c)) for c in corners]
        f = self.bm.faces.new(vs)
        f.normal_update()
        self._finish([f], mat, uv=uv_rect is None)
        if uv_rect is not None:
            u0, v0, u1, v1 = uv_rect
            for loop, uv in zip(f.loops, [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]):
                loop[self.uv].uv = uv
        return f

    def panel(self, center, w, h, normal_axis: str, mat: str, uv_rect=None, sign: int = 1):
        """A vertical (or ceiling) rectangle facing +/- an axis, e.g. a screen or a board."""
        cx, cy, cz = center
        hw, hh = w / 2, h / 2
        if normal_axis == "X":   # faces +X (sign 1) or -X
            pts = [(cx, cy - hw * sign, cz - hh), (cx, cy + hw * sign, cz - hh),
                   (cx, cy + hw * sign, cz + hh), (cx, cy - hw * sign, cz + hh)]
        elif normal_axis == "Y":  # faces +Y or -Y
            pts = [(cx + hw * sign, cy, cz - hh), (cx - hw * sign, cy, cz - hh),
                   (cx - hw * sign, cy, cz + hh), (cx + hw * sign, cy, cz + hh)]
        else:                     # Z: faces down (sign -1) or up
            pts = [(cx - hw, cy - hh * sign, cz), (cx + hw, cy - hh * sign, cz),
                   (cx + hw, cy + hh * sign, cz), (cx - hw, cy + hh * sign, cz)]
        return self.quad(pts, mat, uv_rect)

    def mesh(self, name: str) -> bpy.types.Mesh:
        me = bpy.data.meshes.new(name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        self.bm.to_mesh(me)
        self.bm.free()
        for mname in self.mats:
            me.materials.append(MATS[mname])
        return me


def put(mesh: bpy.types.Mesh, name: str, loc=(0, 0, 0), rot: float = 0.0, coll=None) -> bpy.types.Object:
    """Link an object using mesh at loc, rotated rot degrees about Z."""
    ob = bpy.data.objects.new(name, mesh)
    ob.location = loc
    ob.rotation_euler = (0, 0, math.radians(rot))
    (coll or bpy.context.scene.collection).objects.link(ob)
    return ob


COLLIDERS: list[tuple[tuple, tuple, float]] = []   # (size, center, rot) boxes


def collide(size, center, rot: float = 0.0) -> None:
    COLLIDERS.append((tuple(size), tuple(center), rot))


def world_box(size, local_center, loc, rot):
    """Transform a local collider box into world space (rot about Z, degrees)."""
    c = Matrix.Rotation(math.radians(rot), 3, "Z") @ Vector(local_center)
    return size, (loc[0] + c.x, loc[1] + c.y, loc[2] + c.z), rot


# --------------------------------------------------------------------------- the shell

def build_shell() -> None:
    """Floor, walls with ribbon windows, columns, ceiling, roof slab and the exterior."""
    # floor (own object: its lightmap maps the whole floor rectangle)
    fb = MeshBuilder()
    fb.quad([(0, 0, 0), (W, 0, 0), (W, D, 0), (0, D, 0)], "shell_carpet")
    floor = put(fb.mesh("floor"), "shell_floor")
    collide((W + 1, D + 1, 0.2), (W / 2, D / 2, -0.1))

    # ceiling
    cb = MeshBuilder()
    cb.quad([(0, 0, CEIL), (0, D, CEIL), (W, D, CEIL), (W, 0, CEIL)], "shell_ceiling")
    put(cb.mesh("ceiling"), "shell_ceiling")

    # walls: box pieces; interior faces stay in the shell, the rest moves to the exterior
    wb = MeshBuilder()
    t = WALL_T
    full = (0, SLAB)

    def wall_x(y0, y1, x, z0, z1, mat):   # wall along y at x (west/east)
        xc = x - t / 2 if x <= 0 else x + t / 2
        wb.box((t, y1 - y0, z1 - z0), (xc, (y0 + y1) / 2, (z0 + z1) / 2), mat)

    def wall_y(x0, x1, y, z0, z1, mat):
        yc = y - t / 2 if y <= 0 else y + t / 2
        wb.box((x1 - x0, t, z1 - z0), ((x0 + x1) / 2, yc, (z0 + z1) / 2), mat)

    for y in (0.0, D):  # window walls: sill band, ribbon window, head band; solid corners
        wall_y(-t, 0.6, y, *full, "shell_plaster")
        wall_y(W - 0.6, W + t, y, *full, "shell_plaster")
        wall_y(0.6, W - 0.6, y, 0, SILL, "shell_plaster")
        wall_y(0.6, W - 0.6, y, HEAD, SLAB, "shell_plaster")
        collide((W + 2 * t, t, SLAB), (W / 2, y - t / 2 if y == 0 else y + t / 2, SLAB / 2))
    # west wall with the entrance door and the blue accent band around it
    acc0, acc1 = 6.4, 11.6
    wall_x(0, acc0, 0, *full, "shell_plaster")
    wall_x(acc0, DOOR_Y[0], 0, *full, "shell_accent")
    wall_x(DOOR_Y[0], DOOR_Y[1], 0, 2.1, SLAB, "shell_accent")
    wall_x(DOOR_Y[1], acc1, 0, *full, "shell_accent")
    wall_x(acc1, D, 0, *full, "shell_plaster")
    wall_x(0, D, W, *full, "shell_plaster")
    collide((t, D, SLAB), (-t / 2, D / 2, SLAB / 2))
    collide((t, D, SLAB), (W + t / 2, D / 2, SLAB / 2))
    for cx, cy in COLUMNS:
        wb.box((0.4, 0.4, CEIL), (cx, cy, CEIL / 2), "shell_column")
        collide((0.4, 0.4, CEIL), (cx, cy, CEIL / 2))
    walls_me = wb.mesh("walls")
    walls = put(walls_me, "shell_walls")
    exterior = split_exterior(walls)

    # roof slab and plinth so the sun only enters through the windows
    xb = MeshBuilder()
    xb.box((W + 2 * t + 0.4, D + 2 * t + 0.4, 0.4), (W / 2, D / 2, SLAB + 0.2), "concrete")
    xb.box((W + 2 * t + 0.1, D + 2 * t + 0.1, 0.5), (W / 2, D / 2, -0.27), "concrete")  # below the floor: no coplanar faces
    put(xb.mesh("roof"), "building_slabs")

    shell_lightmap_uvs(floor, walls)
    return exterior


def split_exterior(walls: bpy.types.Object) -> bpy.types.Object:
    """Move faces nobody sees from inside (outer skin, plenum, tops) to their own object."""
    me = walls.data
    bm = bmesh.new()
    bm.from_mesh(me)
    ext = []
    for f in bm.faces:
        c = f.calc_center_median()
        n = f.normal
        outer = (c.x < -WALL_T + 0.01 or c.x > W + WALL_T - 0.01 or
                 c.y < -WALL_T + 0.01 or c.y > D + WALL_T - 0.01)
        low = min(v.co.z for v in f.verts)
        hidden = low >= CEIL - 0.001 or c.z < 0.001
        if outer or hidden:
            ext.append(f)
    ext_bm = bmesh.new()
    uv_src = bm.loops.layers.uv["UVMap"]
    uv_dst = ext_bm.loops.layers.uv.new("UVMap")
    for f in ext:
        vs = [ext_bm.verts.new(v.co) for v in f.verts]
        nf = ext_bm.faces.new(vs)
        nf.material_index = 0
        for la, lb in zip(f.loops, nf.loops):
            lb[uv_dst].uv = la[uv_src].uv
    bmesh.ops.delete(bm, geom=ext, context="FACES")
    bm.to_mesh(me)
    bm.free()
    em = bpy.data.meshes.new("exterior")
    bmesh.ops.remove_doubles(ext_bm, verts=ext_bm.verts, dist=1e-5)
    ext_bm.to_mesh(em)
    ext_bm.free()
    em.materials.append(MATS["brick"])
    return put(em, "building_exterior")


def shell_lightmap_uvs(floor, walls) -> None:
    """Second UV set 'lightmap': the floor maps 1:1 to its rectangle, the walls and the
    ceiling are unwrapped by Smart UV Project."""
    for ob in (floor, walls, bpy.data.objects["shell_ceiling"]):
        uv = ob.data.uv_layers.new(name="lightmap")
        if ob is floor or ob.name == "shell_ceiling":
            for loop in ob.data.loops:
                co = ob.data.vertices[loop.vertex_index].co
                uv.data[loop.index].uv = (co.x / W, co.y / D)
            continue
        ob.data.uv_layers.active = uv
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0,
                                 scale_to_bounds=True)
        bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
        bpy.ops.object.mode_set(mode="OBJECT")
        ob.select_set(False)
        ob.data.uv_layers["UVMap"].active = True
        ob.data.uv_layers["UVMap"].active_render = True


# --------------------------------------------------------------------------- windows, doors, partitions

def build_windows() -> None:
    """Ribbon windows: anthracite aluminium mullions every 1.8 m, a top-hung vent band,
    stone sills inside and convector radiators below."""
    fb, gb, sb, rb = MeshBuilder(), MeshBuilder(), MeshBuilder(), MeshBuilder()
    x0, x1 = 0.6, W - 0.6
    bays = 13
    bw = (x1 - x0) / bays
    for y, s in ((0.0, -1), (D, 1)):
        yc = y + s * WALL_T * 0.55
        fb.box((x1 - x0, 0.08, 0.07), ((x0 + x1) / 2, yc, SILL + 0.035), "frame")
        fb.box((x1 - x0, 0.08, 0.07), ((x0 + x1) / 2, yc, HEAD - 0.035), "frame")
        fb.box((x1 - x0, 0.08, 0.05), ((x0 + x1) / 2, yc, 2.22), "frame")
        for i in range(bays + 1):
            fb.box((0.06, 0.09, HEAD - SILL), (x0 + i * bw, yc, (SILL + HEAD) / 2), "frame")
        gb.box((x1 - x0, 0.012, HEAD - SILL - 0.1), ((x0 + x1) / 2, yc, (SILL + HEAD) / 2), "glass")
        # inside: stone sill and a convector radiator per bay
        inward = 1 if y == 0 else -1
        sb.box((x1 - x0 + 0.1, 0.3, 0.03), ((x0 + x1) / 2, y + inward * 0.05, SILL - 0.015), "sill", bevel=0.004)
        ry = y + inward * 0.12
        for i in range(bays):
            cx = x0 + (i + 0.5) * bw
            rb.box((bw - 0.3, 0.1, 0.5), (cx, ry, 0.38), "metal_white", bevel=0.01)
            for k in range(-6, 7):
                rb.box((0.012, 0.102, 0.42), (cx + k * (bw - 0.4) / 13, ry, 0.38), "metal_white")
            rb.cyl(0.008, 0.25, (cx + bw / 2 - 0.17, ry - inward * 0.03, 0.2), "metal_white", segs=6)
        collide((x1 - x0, 0.4, SILL), ((x0 + x1) / 2, y + inward * 0.1, SILL / 2))
    # roller blinds (screens), some bays half down: they break the ribbon and cast shadows
    for y, bays_down in ((0.0, {2: 0.9, 3: 0.55, 8: 1.1, 12: 0.4}), (D, {1: 0.5, 6: 1.2, 7: 1.2, 10: 0.7})):
        inward = 1 if y == 0 else -1
        for i in range(bays):
            cx = x0 + (i + 0.5) * bw
            fb.cyl(0.03, bw - 0.08, (cx, y + inward * 0.06, HEAD - 0.06), "metal_white", segs=10, axis="X")
            if i in bays_down:
                drop = bays_down[i]
                fb.box((bw - 0.12, 0.006, drop), (cx, y + inward * 0.08, HEAD - 0.08 - drop / 2), "fabric_grey")
                fb.box((bw - 0.1, 0.02, 0.025), (cx, y + inward * 0.08, HEAD - 0.08 - drop), "metal_white")
    put(fb.mesh("window_frames"), "window_frames")
    put(gb.mesh("window_glass"), "glass_windows")
    put(sb.mesh("window_sills"), "window_sills")
    put(rb.mesh("radiators"), "radiators")


def build_door_and_skirting() -> None:
    b = MeshBuilder()
    y0, y1 = DOOR_Y
    # entrance door: frame and a closed leaf with a vision panel and a lever
    b.box((0.12, 0.05, 2.15), (0.0, y0 - 0.025, 1.075), "frame")
    b.box((0.12, 0.05, 2.15), (0.0, y1 + 0.025, 1.075), "frame")
    b.box((0.12, y1 - y0 + 0.1, 0.05), (0.0, (y0 + y1) / 2, 2.125), "frame")
    b.box((0.045, y1 - y0 - 0.01, 2.09), (-0.05, (y0 + y1) / 2, 1.05), "wood", bevel=0.003)
    b.box((0.05, 0.12, 0.012), (0.0, y1 - 0.12, 1.05), "alu")
    b.box((0.02, 0.012, 0.012), (0.0, y1 - 0.07, 1.05), "alu")
    put(b.mesh("door"), "entrance_door")
    g = MeshBuilder()
    g.box((0.05, 0.22, 1.1), (-0.02, (y0 + y1) / 2 + 0.25, 1.35), "glass")
    put(g.mesh("door_glass"), "glass_door")
    # skirting boards (plinten) along the solid walls
    s = MeshBuilder()
    h, t = 0.07, 0.015
    s.box((t, DOOR_Y[0], h), (t / 2, DOOR_Y[0] / 2, h / 2), "metal_dark")
    s.box((t, D - DOOR_Y[1], h), (t / 2, (D + DOOR_Y[1]) / 2, h / 2), "metal_dark")
    s.box((t, D, h), (W - t / 2, D / 2, h / 2), "metal_dark")
    for cx, cy in COLUMNS:
        s.box((0.43, 0.43, h), (cx, cy, h / 2), "metal_dark")
    put(s.mesh("skirting"), "skirting")


def build_coach_room() -> None:
    """Glass partitions with RAL 7016 profiles, frosted manifestation bands at 1.0 and 1.5 m
    (Bouwbesluit: glass walls need visible marking), and an open door."""
    x0, y0 = COACH
    fb, gb = MeshBuilder(), MeshBuilder()
    h = CEIL
    # front partition along y = y0 from x0 to W, with the door gap
    spans = [((x0, y0), (COACH_DOOR[0], y0)), ((COACH_DOOR[1], y0), (W, y0)), ((x0, y0), (x0, D))]
    for (ax, ay), (bx, by) in spans:
        horiz = ay == by
        length = (bx - ax) if horiz else (by - ay)
        mid = ((ax + bx) / 2, (ay + by) / 2)
        n = max(1, round(length / 1.2))
        for i in range(n + 1):
            p = (ax + (bx - ax) * i / n, ay + (by - ay) * i / n)
            fb.box((0.05, 0.05, h), (p[0], p[1], h / 2), "frame")
        size = (length, 0.05, 0.05) if horiz else (0.05, length, 0.05)
        fb.box(size, (mid[0], mid[1], 0.025), "frame")
        fb.box(size, (mid[0], mid[1], h - 0.025), "frame")
        gsize = (length, 0.012, h - 0.1) if horiz else (0.012, length, h - 0.1)
        gb.box(gsize, (mid[0], mid[1], h / 2), "glass")
        for z in (1.05, 1.5):
            bs = (length, 0.016, 0.08) if horiz else (0.016, length, 0.08)
            gb.box(bs, (mid[0], mid[1], z), "glass_frost")
        csize = (length, 0.06, h) if horiz else (0.06, length, h)
        collide(csize, (mid[0], mid[1], h / 2))
    # door: frame and an open glass leaf
    d0, d1 = COACH_DOOR
    fb.box((d1 - d0 + 0.1, 0.06, 0.06), ((d0 + d1) / 2, y0, 2.13), "frame")
    gb.box((0.012, 0.95, 2.05), (d0 + 0.03, y0 - 0.5, 1.06), "glass")
    fb.box((0.04, 0.95, 0.04), (d0 + 0.03, y0 - 0.5, 0.06), "frame")
    fb.box((0.04, 0.95, 0.04), (d0 + 0.03, y0 - 0.5, 2.06), "frame")
    fb.box((0.04, 0.02, 0.3), (d0 + 0.03, y0 - 0.95, 1.05), "alu")
    put(fb.mesh("coach_frames"), "coach_frames")
    put(gb.mesh("coach_glass"), "glass_coach")


def build_ceiling_fixtures() -> list[tuple[float, float]]:
    """600 x 600 LED panels on a 2.4 m grid, aligned to the ceiling tiles, plus air diffusers."""
    pb, vb = MeshBuilder(), MeshBuilder()
    spots = []
    for i in range(1, 40, 4):
        for j in range(2, 26, 4):
            x, y = i * 0.6 + 0.3, j * 0.6 + 0.3
            if any(abs(x - cx) < 0.6 and abs(y - cy) < 0.6 for cx, cy in COLUMNS):
                continue
            pb.box((0.6, 0.6, 0.012), (x, y, CEIL - 0.006), "metal_white")
            pb.panel((x, y, CEIL - 0.013), 0.56, 0.56, "Z", "light_panel", sign=-1)
            spots.append((x, y))
    for i in range(3, 40, 8):
        for j in range(4, 26, 8):
            x, y = i * 0.6 + 0.3, j * 0.6 + 0.3
            vb.box((0.6, 0.6, 0.01), (x, y, CEIL - 0.005), "metal_white")
            for k in range(4):
                s = 0.5 - k * 0.12
                vb.box((s, s, 0.012), (x, y, CEIL - 0.012 - k * 0.006), "metal_white")
    put(pb.mesh("light_panels"), "light_panels")
    put(vb.mesh("air_diffusers"), "air_diffusers")
    return spots


# --------------------------------------------------------------------------- furniture kits

def kit_desk() -> bpy.types.Mesh:
    """Sit-stand desk 1600 x 800, top at 0.75 m, T-legs, cable tray. User at local -Y."""
    b = MeshBuilder()
    b.box((1.6, 0.8, 0.025), (0, 0, 0.7375), "wood", bevel=0.004)
    for x in (-0.68, 0.68):
        b.box((0.07, 0.05, 0.69), (x, 0.05, 0.37), "metal_dark", bevel=0.003)
        b.box((0.07, 0.07, 0.69), (x, 0.05, 0.36), "metal_dark", bevel=0.003)
        b.box((0.08, 0.7, 0.04), (x, 0.0, 0.02), "metal_dark", bevel=0.006)
        b.box((0.06, 0.65, 0.03), (x, 0.0, 0.71), "metal_dark")
    b.box((1.3, 0.06, 0.05), (0, 0.05, 0.68), "metal_dark")
    b.box((1.1, 0.16, 0.08), (0, 0.22, 0.64), "metal_dark")  # cable tray
    return b.mesh("desk")


def kit_divider() -> bpy.types.Mesh:
    """Acoustic desk screen 1600 x 450 between two facing desks."""
    b = MeshBuilder()
    b.box((1.6, 0.03, 0.45), (0, 0, 0.75 + 0.225 + 0.01), "fabric_grey", bevel=0.012, segs=2)
    for x in (-0.6, 0.6):
        b.box((0.04, 0.05, 0.03), (x, 0, 0.755), "metal_dark")
    return b.mesh("divider")


def kit_chair(fabric: str = "fabric_dark") -> bpy.types.Mesh:
    """Task chair: five-star base with castors, gas lift, seat, mesh-look back, armrests.
    Faces local +Y (the desk)."""
    b = MeshBuilder()
    for k in range(5):
        a = math.radians(90 + k * 72)
        dx, dy = math.cos(a), math.sin(a)
        b.box((0.33, 0.045, 0.035), (dx * 0.17, dy * 0.17, 0.1), "plastic_black", rot=math.degrees(a), bevel=0.008)
        b.cyl(0.028, 0.035, (dx * 0.33, dy * 0.33, 0.04), "plastic_black", segs=10, axis="X")
        b.cyl(0.008, 0.04, (dx * 0.33, dy * 0.33, 0.075), "alu", segs=6)
    b.cyl(0.035, 0.06, (0, 0, 0.11), "plastic_black", segs=12)
    b.cyl(0.024, 0.28, (0, 0, 0.27), "alu", segs=12)
    b.cyl(0.04, 0.12, (0, 0, 0.36), "plastic_black", segs=12)
    b.box((0.3, 0.3, 0.04), (0, 0, 0.42), "plastic_black", bevel=0.01)
    b.box((0.49, 0.47, 0.075), (0, 0.02, 0.48), fabric, bevel=0.025, segs=3)
    # back: frame plus upholstered panel, tilted back 8 degrees
    back = b.box((0.46, 0.06, 0.56), (0, 0, 0), fabric, bevel=0.025, segs=3)
    verts = list({v for f in back for v in f.verts})
    bmesh.ops.rotate(b.bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(-8), 3, "X"), verts=verts)
    bmesh.ops.translate(b.bm, vec=Vector((0, -0.25, 0.86)), verts=verts)
    b.box((0.06, 0.05, 0.36), (0, -0.25, 0.56), "plastic_black", bevel=0.01)
    for x in (-0.26, 0.26):
        b.box((0.03, 0.04, 0.22), (x, -0.02, 0.6), "plastic_black", bevel=0.008)
        b.box((0.07, 0.26, 0.03), (x, 0.0, 0.71), "plastic_black", bevel=0.012, segs=2)
    return b.mesh(f"chair_{fabric}")


def kit_monitor() -> bpy.types.Mesh:
    """24-inch monitor (0.54 x 0.32 body) on a stand; screen faces local -Y at y = -0.012."""
    b = MeshBuilder()
    b.box((0.545, 0.022, 0.325), (0, 0, 1.08), "plastic_black", bevel=0.004)
    b.box((0.3, 0.04, 0.2), (0, 0.03, 1.07), "plastic_black", bevel=0.01)
    b.box((0.05, 0.03, 0.26), (0, 0.06, 0.88), "plastic_black", bevel=0.006)
    b.box((0.24, 0.18, 0.012), (0, 0.04, 0.756), "plastic_black", bevel=0.004)
    return b.mesh("monitor")


SCREEN_RECTS = [((i % 2) * 0.5, 1 - (i // 2 + 1) * 288 / 1024, (i % 2) * 0.5 + 0.5, 1 - (i // 2) * 288 / 1024)
                for i in range(6)]


def kit_screen(i: int) -> bpy.types.Mesh:
    b = MeshBuilder()
    b.panel((0, -0.0115, 1.085), 0.528, 0.297, "Y", "screens", uv_rect=SCREEN_RECTS[i], sign=-1)
    return b.mesh(f"screen_{i}")


def kit_keyboard() -> bpy.types.Mesh:
    b = MeshBuilder()
    b.box((0.44, 0.14, 0.018), (0, 0, 0.759), "plastic_black", bevel=0.004)
    b.panel((0, 0, 0.7685), 0.43, 0.13, "Z", "devices", uv_rect=(0.0, 1 - 160 / 512, 1.0, 1.0))
    b.box((0.06, 0.1, 0.03), (0.32, 0.0, 0.765), "plastic_black", bevel=0.012, segs=2)  # mouse
    return b.mesh("keyboard")


def kit_laptop() -> bpy.types.Mesh:
    b = MeshBuilder()
    b.box((0.32, 0.22, 0.012), (0, 0, 0.756), "alu", bevel=0.003)
    lid = b.box((0.32, 0.008, 0.21), (0, 0, 0), "alu", bevel=0.002)
    verts = list({v for f in lid for v in f.verts})
    bmesh.ops.rotate(b.bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(-15), 3, "X"), verts=verts)
    bmesh.ops.translate(b.bm, vec=Vector((0, 0.115, 0.865)), verts=verts)
    return b.mesh("laptop")


def kit_tray() -> bpy.types.Mesh:
    """Two stacked letter trays with incoming applications."""
    b = MeshBuilder()
    for k in range(2):
        z = 0.75 + k * 0.07
        b.box((0.26, 0.34, 0.006), (0, 0, z + 0.003), "plastic_black")
        b.box((0.006, 0.34, 0.06), (-0.127, 0, z + 0.03), "plastic_black")
        b.box((0.006, 0.34, 0.06), (0.127, 0, z + 0.03), "plastic_black")
        b.box((0.26, 0.006, 0.06), (0, 0.167, z + 0.03), "plastic_black")
        b.box((0.21, 0.297, 0.02 + 0.015 * k), (0, -0.01, z + 0.016 + 0.007 * k), "paper")
    return b.mesh("tray")


def kit_phone() -> bpy.types.Mesh:
    b = MeshBuilder()
    b.box((0.2, 0.2, 0.05), (0, 0, 0.775), "plastic_black", bevel=0.01)
    b.panel((0.0, -0.02, 0.8005), 0.16, 0.16, "Z", "devices", uv_rect=(0, 1 - 352 / 512, 160 / 512, 1 - 160 / 512))
    b.box((0.05, 0.2, 0.04), (-0.08, 0, 0.82), "plastic_black", bevel=0.012, segs=2)
    return b.mesh("phone")


def kit_mug(mat: str = "ceramic") -> bpy.types.Mesh:
    b = MeshBuilder()
    b.cyl(0.042, 0.095, (0, 0, 0.7975), mat, segs=16)
    b.cyl(0.036, 0.004, (0, 0, 0.84), "soil", segs=12)
    b.box((0.012, 0.012, 0.05), (0.05, 0, 0.8), mat, bevel=0.004)
    return b.mesh(f"mug_{mat}")


def kit_dossier_stack(h: float, seed: int) -> bpy.types.Mesh:
    """A pile of application dossiers: paper blocks with folders, each slightly rotated."""
    rng = np.random.default_rng(seed)
    b = MeshBuilder()
    z = 0.0
    while z < h:
        t = float(rng.uniform(0.02, 0.06))
        c = Vector((rng.normal(0, 0.01), rng.normal(0, 0.01), z + t / 2))
        band = float(rng.uniform(0.55, 0.9))
        for face in b.box((0.24, 0.32, t), c, "dossier", rot=float(rng.normal(0, 4))):
            n = face.normal
            for loop in face.loops:  # sides: the paper-edge quadrant; top: the form
                d = loop.vert.co - c
                if abs(n.z) > 0.5:
                    uv = (0.5 + (d.x / 0.24 + 0.5) * 0.5, 0.5 + (d.y / 0.32 + 0.5) * 0.5)
                else:
                    horiz = d.x if abs(n.y) > abs(n.x) else d.y
                    uv = (0.25 + horiz * 0.7, band + d.z * 0.8)
                loop[b.uv].uv = uv
        z += t
    return b.mesh(f"dossiers_{seed}")


def kit_binders(n: int) -> bpy.types.Mesh:
    """A row of lever-arch files (ordners) standing on a shelf, spines facing -Y."""
    b = MeshBuilder()
    for k in range(n):
        x = (k - (n - 1) / 2) * 0.08
        faces = b.box((0.075, 0.28, 0.32), (x, 0, 0.16), "dossier")
        rect_u = (k % 8) / 16
        for face in faces:
            if face.normal.y < -0.5:
                for loop, uv in zip(face.loops, [(rect_u, 0), (rect_u + 1 / 16, 0), (rect_u + 1 / 16, 0.5), (rect_u, 0.5)]):
                    loop[b.uv].uv = uv
            else:
                for loop in face.loops:
                    loop[b.uv].uv = (rect_u + 0.01, 0.02)
    return b.mesh(f"binders_{n}")


def kit_rolls() -> bpy.types.Mesh:
    """Rolled-up drawings, a few lying on the desk."""
    b = MeshBuilder()
    for k, (x, y, r) in enumerate([(0, 0, 0.03), (0.05, 0.02, 0.025), (0.02, 0.07, 0.035)]):
        f = b.cyl(r, 0.62, (x, y, 0.75 + r), "dossier", segs=12, axis="X")
        for face in f:
            for loop in face.loops:
                co = loop.vert.co
                loop[b.uv].uv = (0.5 + 0.48 * (co.x + 0.31) / 0.62, 0.02 + 0.46 * ((math.atan2(co.z - 0.75 - r, co.y - y) / math.pi + 1) / 2))
    return b.mesh("rolls")


def kit_cabinet(w: float, h: float = 0.75, d: float = 0.45, mat: str = "metal_white") -> bpy.types.Mesh:
    """Low steel cabinet (roldeurkast look) with a wood top."""
    b = MeshBuilder()
    b.box((w, d, h - 0.025), (0, 0, (h - 0.025) / 2), mat, bevel=0.004)
    b.box((w + 0.01, d + 0.01, 0.025), (0, 0, h - 0.0125), "wood", bevel=0.004)
    for k in range(int(w / 0.4)):
        x = -w / 2 + (k + 0.5) * w / int(w / 0.4)
        b.box((0.012, 0.01, 0.12), (x + 0.12, -d / 2 - 0.005, h * 0.55), "alu")
    b.box((w - 0.01, 0.004, 0.004), (0, -d / 2 - 0.002, h * 0.5), "metal_dark")
    return b.mesh(f"cabinet_{w}_{h}_{mat}")


def kit_plotter() -> bpy.types.Mesh:
    """Large-format plotter (DesignJet class, 1.3 m wide) on its stand, a print hanging out."""
    b = MeshBuilder()
    b.box((1.32, 0.42, 0.3), (0, 0, 0.95), "plastic_grey", bevel=0.02, segs=2)
    b.box((1.25, 0.3, 0.06), (0, 0.02, 1.12), "plastic_black", bevel=0.01)
    b.panel((0.5, -0.211, 0.99), 0.16, 0.1, "Y", "devices", uv_rect=(352 / 512, 1 - 256 / 512, 1, 1 - 160 / 512), sign=-1)
    for x in (-0.6, 0.6):
        b.box((0.05, 0.05, 0.8), (x, 0, 0.4), "metal_dark")
        b.box((0.06, 0.55, 0.04), (x, 0, 0.03), "metal_dark")
    b.box((1.2, 0.03, 0.03), (0, 0, 0.3), "metal_dark")
    b.cyl(0.05, 1.1, (0, 0.1, 0.72), "paper", segs=14, axis="X")
    # a fresh print curling down the front
    b.quad([(-0.42, -0.215, 0.82), (0.42, -0.215, 0.82), (0.42, -0.215, 1.05), (-0.42, -0.215, 1.05)], "dossier",
           uv_rect=(0.5, 0.02, 0.98, 0.48))
    b.quad([(-0.42, -0.36, 0.55), (0.42, -0.36, 0.55), (0.42, -0.215, 0.82), (-0.42, -0.215, 0.82)], "dossier",
           uv_rect=(0.5, 0.02, 0.98, 0.48))
    return b.mesh("plotter")


def kit_plant(height: float, cards: int = 4) -> bpy.types.Mesh:
    """Office plant: a tapered planter, soil and crossed alpha foliage cards."""
    b = MeshBuilder()
    pot_h = 0.42 if height > 1 else 0.16
    r = 0.2 if height > 1 else 0.08
    b.cyl(r * 0.8, pot_h, (0, 0, pot_h / 2), "pot", segs=20, radius2=r)
    b.cyl(r * 0.92, 0.01, (0, 0, pot_h - 0.02), "soil", segs=16)
    fh = height - pot_h + 0.1
    fw = fh * 0.8
    for k in range(cards):
        a = math.pi * k / cards
        dx, dy = math.cos(a) * fw / 2, math.sin(a) * fw / 2
        z0 = pot_h - 0.06
        b.quad([(-dx, -dy, z0), (dx, dy, z0), (dx, dy, z0 + fh), (-dx, -dy, z0 + fh)], "leaves",
               uv_rect=(0, 0, 1, 1))
        b.quad([(dx, dy, z0), (-dx, -dy, z0), (-dx, -dy, z0 + fh), (dx, dy, z0 + fh)], "leaves",
               uv_rect=(1, 0, 0, 1))
    return b.mesh(f"plant_{height}")


def kit_coat() -> bpy.types.Mesh:
    """A jacket draped over a chair back: two slabs folded over the backrest top."""
    b = MeshBuilder()
    for sgn, tilt in ((1, 12), (-1, -14)):
        f = b.box((0.5, 0.03, 0.45), (0, 0, -0.22), "fabric_coat", bevel=0.012, segs=2)
        verts = list({v for face in f for v in face.verts})
        bmesh.ops.rotate(b.bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(tilt), 3, "X"), verts=verts)
        bmesh.ops.translate(b.bm, vec=Vector((0, -0.25 + sgn * 0.05 - 0.04, 1.14)), verts=verts)
    b.box((0.52, 0.12, 0.05), (0, -0.29, 1.15), "fabric_coat", bevel=0.02, segs=2)
    return b.mesh("coat")


def kit_bin() -> bpy.types.Mesh:
    b = MeshBuilder()
    b.cyl(0.15, 0.36, (0, 0, 0.18), "metal_dark", segs=18, radius2=0.17, caps=True)
    return b.mesh("bin")


def kit_board_frame(w: float, h: float) -> bpy.types.Mesh:
    b = MeshBuilder()
    t = 0.025
    b.box((0.02, w + 2 * t, t), (0, 0, h / 2 + t / 2), "alu", bevel=0.003)
    b.box((0.02, w + 2 * t, t), (0, 0, -h / 2 - t / 2), "alu", bevel=0.003)
    b.box((0.02, t, h), (0, w / 2 + t / 2, 0), "alu", bevel=0.003)
    b.box((0.02, t, h), (0, -w / 2 - t / 2, 0), "alu", bevel=0.003)
    b.box((0.06, 0.6, 0.02), (0.03, 0, -h / 2 - 0.035), "alu")  # marker tray
    b.box((0.012, w, h), (-0.004, 0, 0), "metal_white")
    return b.mesh(f"board_frame_{w}_{h}")


# --------------------------------------------------------------------------- areas

def workstation(name: str, loc, rot: float, kits: dict, screens=(0, 1), extras=(), chair="chair",
                coat: bool = False) -> None:
    """A desk with chair, monitors and keyboard; rot 0 means the user faces +Y."""
    put(kits["desk"], f"{name}_desk", loc, rot)
    sx, sy = math.cos(math.radians(rot)), math.sin(math.radians(rot))

    def at(lx, ly):
        return (loc[0] + lx * sx - ly * sy, loc[1] + lx * sy + ly * sx, loc[2])

    for k, si in enumerate(screens):
        off = 0.0 if len(screens) == 1 else (-0.29 + 0.58 * k)
        tilt = 0 if len(screens) == 1 else (-12 if k == 0 else 12)
        put(kits["monitor"], f"{name}_monitor{k}", at(off, 0.18), rot + tilt)
        put(kits[f"screen{si}"], f"{name}_screen{k}", at(off, 0.18), rot + tilt)
    put(kits["keyboard"], f"{name}_keyboard", at(0, -0.15), rot)
    ch = put(kits[chair], f"{name}_chair", at(0.05, -0.62), rot + 6)
    if coat:
        put(kits["coat"], f"{name}_coat", ch.location, rot + 6)
    for kit, lx, ly, r in extras:
        put(kits[kit], f"{name}_{kit}", at(lx, ly), rot + r)
    collide(*world_box((1.6, 0.8, 0.76), (0, 0, 0.38), loc, rot))
    collide(*world_box((0.55, 0.55, 0.9), (0.05, -0.62, 0.45), loc, rot))


def bench(name: str, cx: float, cy: float, kits, pairs: int, screens, extras_by_desk=None, coats=()) -> None:
    """Facing desk pairs along y; users face +X (west row) and -X (east row)."""
    extras_by_desk = extras_by_desk or {}
    for p in range(pairs):
        y = cy + (p - (pairs - 1) / 2) * 1.6
        for side, (dx, rot) in enumerate(((-0.4, -90), (0.4, 90))):
            k = p * 2 + side
            workstation(f"{name}{k}", (cx + dx, y, 0), rot, kits, screens[k % len(screens)],
                        extras_by_desk.get(k, ()), coat=k in coats)
        put(kits["divider"], f"{name}_divider{p}", (cx, y, 0), 90)


def build_areas(kits) -> None:
    # --- intake corner (connections.intake): 2 desks, trays of applications, a phone
    bench("intake", 3.2, 2.4, kits, 1, [(2,), (0, 4)],
          {0: (("tray", 0.55, 0.1, 0), ("phone", -0.55, 0.05, 15), ("mug_ceramic", 0.45, -0.2, 0)),
           1: (("tray", -0.55, 0.12, 0), ("dossiers_1", 0.52, 0.12, 4))}, coats=(1,))
    put(kits["cabinet_1.2"], "intake_cabinet", (3.2, 3.95, 0), 0)
    collide((1.2, 0.45, 0.75), (3.2, 3.95, 0.375))
    put(kits["tray"], "intake_cabinet_tray", (2.85, 3.95, 0.0), 0)
    for k, (x, rot) in enumerate(((3.3, 3), (3.62, -6))):
        put(kits["dossiers_2"], f"intake_cabinet_dossiers{k}", (x, 3.95, 0.0), rot)
    # --- werkvoorbereiding (connections.design): 4 desks with dual monitors, rolls, plotter, backlog
    bench("design", 9.0, 3.0, kits, 2, [(3, 0), (1, 3), (0, 5), (3, 1)],
          {0: (("rolls", 0.0, 0.2, 80), ("dossiers_3", 0.62, 0.15, 0)),
           1: (("dossiers_1", -0.6, 0.16, 6), ("mug_ceramic", 0.5, -0.25, 0)),
           2: (("dossiers_2", 0.6, 0.14, -4), ("rolls", -0.1, 0.25, 95)),
           3: (("dossiers_3", -0.62, 0.15, 2), ("dossiers_1", -0.62, -0.18, 9))}, coats=(2,))
    put(kits["plotter"], "design_plotter", (11.9, 1.0, 0), 0)
    collide((1.4, 0.6, 1.1), (11.9, 1.0, 0.55))
    put(kits["cabinet_1.6"], "design_sideboard", (11.8, 3.8, 0), 0)
    collide((1.6, 0.45, 0.75), (11.8, 3.8, 0.375))
    for k, (x, y, s) in enumerate(((11.25, 3.8, "dossiers_4"), (11.55, 3.82, "dossiers_5"),
                                   (11.85, 3.78, "dossiers_4"), (12.15, 3.8, "dossiers_5"),
                                   (12.42, 3.82, "dossiers_3"))):
        put(kits[s], f"design_backlog{k}", (x, y, 0.75 - 0.75 + 0.0), (k * 7) % 11 - 5)
    # backlog spilling onto the floor: the visible WIP
    for k, (x, y) in enumerate(((10.6, 4.25), (10.85, 4.3), (12.9, 4.15))):
        put(kits["dossiers_floor"], f"design_backlog_floor{k}", (x, y, 0), k * 13 - 8)
        collide((0.3, 0.36, 0.5), (x, y, 0.25))
    put(kits["bin"], "design_bin", (10.3, 1.4, 0))
    # --- planning (decor): 4 desks
    bench("planning", 15.0, 3.0, kits, 2, [(5, 1), (0, 3), (1, 5), (3, 0)],
          {1: (("mug_ceramic", 0.5, -0.2, 0),), 2: (("dossiers_1", 0.6, 0.15, 0),)}, coats=(0,))
    put(kits["bin"], "planning_bin", (16.3, 4.9, 0))
    # --- north: a second bench (klantcontact), meeting table and lockers
    bench("klant", 14.2, 13.2, kits, 2, [(4,), (1,), (5,), (2,)],
          {0: (("phone", -0.55, 0.05, 0),), 3: (("phone", 0.55, 0.05, 0),)})
    meeting_table(kits)
    put(kits["cabinet_2.4_tall"], "lockers", (6.0, 15.75, 0), 180)
    collide((2.4, 0.45, 1.2), (6.0, 15.75, 0.6))
    for k in range(3):
        put(kits["binders_8"], f"lockers_binders{k}", (5.3 + k * 0.7, 15.75, 1.2), 180)
    # --- coach's room: Ingrid's desk, a round table, a cabinet and a plant
    workstation("coach", (22.4, 14.7, 0), 180, kits, (5,), (("laptop", -0.35, -0.05, 10), ("mug_ceramic", 0.5, -0.15, 0)),
                chair="chair_blue")
    round_table(kits, (21.2, 12.4), "coach_table", chairs=2)
    put(kits["cabinet_1.6"], "coach_cabinet", (23.75, 13.2, 0), 90)
    collide((0.45, 1.6, 0.75), (23.75, 13.2, 0.375))
    put(kits["binders_8"], "coach_binders", (23.75, 13.2, 0.75), 90)
    put(kits["plant_1.5"], "coach_plant", (23.6, 11.3, 0))
    # --- low cabinets with plants between the benches and the main aisle
    for k, (x, y, r) in enumerate(((14.4, 5.25, 180), (15.6, 5.25, 180), (13.6, 10.75, 0), (14.8, 10.75, 0))):
        put(kits["cabinet_1.2"], f"aisle_cabinet{k}", (x, y, 0), r)
        collide((1.2, 0.45, 0.75), (x, y, 0.375))
        put(kits["plant_0.35"] if k % 2 else kits["binders_8"], f"aisle_cabinet_top{k}", (x, y, 0.75), r + 90 * (k % 2))
    # --- plants and bins around the floor
    for k, (x, y, h) in enumerate(((0.45, 0.45, "plant_1.5"), (6.7, 5.4, "plant_1.2"), (17.3, 5.3, "plant_1.5"),
                                   (11.4, 10.8, "plant_1.2"), (18.6, 15.5, "plant_1.5"), (23.5, 0.5, "plant_1.2"),
                                   (4.9, 15.55, "plant_1.2"))):
        put(kits[h], f"plant{k}", (x, y, 0), k * 37)
        collide((0.45, 0.45, 1.2), (x, y, 0.6))
    for k, (x, y) in enumerate(((3.5, 2.2), (9.6, 3.1), (14.6, 2.0))):
        put(kits["plant_0.35"], f"desk_plant{k}", (x, y, 0.75), k * 50)
    coffee_corner(kits)
    lounge_and_lockers(kits)
    walls_dressing(kits)


def meeting_table(kits) -> None:
    b = MeshBuilder()
    b.box((2.4, 1.0, 0.03), (0, 0, 0.735), "wood", bevel=0.005)
    for x in (-1.0, 1.0):
        b.box((0.06, 0.8, 0.06), (x, 0, 0.03), "metal_dark", bevel=0.005)
        b.box((0.06, 0.06, 0.68), (x, 0, 0.38), "metal_dark", bevel=0.005)
    put(b.mesh("meeting_table"), "meeting_table", (9.6, 13.4, 0))
    collide((2.4, 1.0, 0.75), (9.6, 13.4, 0.375))
    for k, (dx, dy, r) in enumerate(((-0.7, -0.75, 0), (0.0, -0.75, 4), (0.7, -0.78, -3), (-0.7, 0.75, 180),
                                     (0.05, 0.8, 176), (0.7, 0.75, 183))):
        put(kits["chair_teal"], f"meeting_chair{k}", (9.6 + dx, 13.4 + dy, 0), r)
    put(kits["laptop"], "meeting_laptop", (9.2, 13.3, 0), -20)
    put(kits["mug_ceramic"], "meeting_mug", (10.1, 13.6, 0))


def round_table(kits, at, name: str, chairs: int) -> None:
    b = MeshBuilder()
    b.cyl(0.5, 0.03, (0, 0, 0.735), "wood", segs=32)
    b.cyl(0.04, 0.7, (0, 0, 0.37), "metal_dark", segs=12)
    b.cyl(0.3, 0.02, (0, 0, 0.01), "metal_dark", segs=24)
    put(b.mesh(f"{name}_mesh"), name, (at[0], at[1], 0))
    collide((1.0, 1.0, 0.75), (at[0], at[1], 0.375))
    for k in range(chairs):
        a = math.radians(200 + k * 140)
        put(kits["chair_blue"], f"{name}_chair{k}", (at[0] + math.cos(a) * 0.75, at[1] + math.sin(a) * 0.75, 0),
            math.degrees(a) - 90 + 180)


def coffee_corner(kits) -> None:
    """Pantry along the west wall: base and wall cabinets, a sink, a bean-to-cup machine,
    a fridge, and a high table with stools."""
    b = MeshBuilder()
    y0, y1 = 12.3, 15.4
    b.box((0.6, y1 - y0, 0.86), (0.31, (y0 + y1) / 2, 0.43 + 0.05), "metal_white", bevel=0.004)
    b.box((0.55, y1 - y0, 0.1), (0.29, (y0 + y1) / 2, 0.05), "metal_dark")
    b.box((0.64, y1 - y0 + 0.02, 0.035), (0.32, (y0 + y1) / 2, 0.9175), "concrete", bevel=0.004)
    for k in range(5):  # door seams and handles
        y = y0 + (k + 0.5) * (y1 - y0) / 5
        b.box((0.004, 0.004, 0.75), (0.612, y0 + k * (y1 - y0) / 5, 0.5), "metal_dark")
        b.box((0.02, 0.16, 0.012), (0.615, y, 0.82), "alu")
    b.box((0.36, (y1 - y0), 0.7), (0.18, (y0 + y1) / 2, 1.85), "metal_white", bevel=0.004)  # wall cabinets
    for k in range(5):
        b.box((0.004, 0.004, 0.66), (0.362, y0 + k * (y1 - y0) / 5, 1.85), "metal_dark")
    b.box((0.02, y1 - y0, 0.5), (0.01, (y0 + y1) / 2, 1.2), "ceramic")  # splashback
    b.box((0.45, 0.5, 0.01), (0.33, 13.0, 0.937), "alu")  # sink
    b.cyl(0.012, 0.3, (0.12, 13.0, 1.08), "alu", segs=8)
    b.box((0.2, 0.025, 0.025), (0.21, 13.0, 1.22), "alu")
    # coffee machine
    b.box((0.45, 0.4, 0.6), (0.34, 14.1, 1.235), "plastic_black", bevel=0.015, segs=2)
    b.panel((0.566, 14.1, 1.3), 0.3, 0.42, "X", "devices", uv_rect=(160 / 512, 0, 352 / 512, 1 - 160 / 512))
    b.box((0.2, 0.25, 0.01), (0.5, 14.1, 0.95), "alu")
    # fridge (tall unit at the end)
    b.box((0.62, 0.62, 2.1), (0.32, 15.68, 1.05), "metal_white", bevel=0.006)
    b.box((0.02, 0.03, 0.4), (0.64, 15.45, 1.2), "alu")
    put(b.mesh("pantry"), "coffee_pantry")
    collide((0.65, y1 - y0 + 0.62, 0.95), (0.33, (y0 + y1 + 0.62) / 2, 0.475))
    for k, y in enumerate((14.32, 14.42)):
        put(kits["mug_ceramic"], f"coffee_mug{k}", (0.42, y, 0.17), k * 40)
    # high table and stools
    t = MeshBuilder()
    t.cyl(0.4, 0.03, (0, 0, 1.085), "wood", segs=32)
    t.cyl(0.04, 1.06, (0, 0, 0.55), "metal_dark", segs=12)
    t.cyl(0.28, 0.02, (0, 0, 0.01), "metal_dark", segs=24)
    put(t.mesh("high_table"), "coffee_table", (2.4, 13.8, 0))
    collide((0.8, 0.8, 1.1), (2.4, 13.8, 0.55))
    s = MeshBuilder()
    s.cyl(0.18, 0.05, (0, 0, 0.76), "fabric_blue", segs=20)
    s.cyl(0.022, 0.72, (0, 0, 0.38), "alu", segs=10)
    s.cyl(0.2, 0.012, (0, 0, 0.3), "alu", segs=20, caps=False)
    s.cyl(0.22, 0.015, (0, 0, 0.008), "metal_dark", segs=20)
    stool = s.mesh("stool")
    for k, a in enumerate((30, 160, 280)):
        put(stool, f"coffee_stool{k}", (2.4 + math.cos(math.radians(a)) * 0.55, 13.8 + math.sin(math.radians(a)) * 0.55, 0))
    put(kits["mug_ceramic"], "coffee_table_mug", (2.5, 13.7, 0.335))
    put(kits["bin"], "coffee_bin", (0.35, 11.95, 0))


SIGN_RECTS = {  # (u0, v0, u1, v1) of signage_albedo.png (1024 x 512, v up)
    "logo": (0, 320 / 512, 1, 1),
    "Intake": (0, 224 / 512, 0.25, 320 / 512),
    "Werkvoorbereiding": (0.25, 224 / 512, 0.5, 320 / 512),
    "Obeya": (0.5, 224 / 512, 0.75, 320 / 512),
    "Koffie": (0.75, 224 / 512, 1.0, 320 / 512),
    "door": (0, 128 / 512, 0.5, 224 / 512),
    "exit": (0.5, 128 / 512, 0.75, 224 / 512),
    "Planning": (0.75, 128 / 512, 1.0, 224 / 512),
}


def kit_sofa() -> bpy.types.Mesh:
    """Two-seat lounge sofa (1.6 m) on steel legs, facing local -Y."""
    b = MeshBuilder()
    b.box((1.6, 0.8, 0.2), (0, 0, 0.32), "fabric_blue", bevel=0.03, segs=3)
    for x in (-0.39, 0.39):
        b.box((0.76, 0.62, 0.14), (x, -0.06, 0.48), "fabric_blue", bevel=0.04, segs=3)
    b.box((1.6, 0.18, 0.5), (0, 0.31, 0.62), "fabric_blue", bevel=0.05, segs=3)
    for x in (-0.76, 0.76):
        b.box((0.1, 0.8, 0.36), (x, 0, 0.48), "fabric_blue", bevel=0.04, segs=3)
    for x in (-0.7, 0.7):
        for y in (-0.3, 0.3):
            b.cyl(0.015, 0.22, (x, y, 0.11), "metal_dark", segs=8)
    return b.mesh("sofa")


def lounge_and_lockers(kits) -> None:
    """The middle band between the column rows: personal lockers, a stand-up table by the
    teams and a small lounge by the coach's room. The main aisle (y 7..9) stays clear."""
    lockers = MeshBuilder()
    for k in range(6):
        x = (k - 2.5) * 0.4
        lockers.box((0.4, 0.45, 1.2), (x, 0, 0.6), "metal_white", bevel=0.003)
        lockers.box((0.36, 0.005, 1.12), (x, -0.226, 0.6), "metal_white")
        lockers.box((0.03, 0.01, 0.03), (x + 0.13, -0.232, 0.7), "metal_dark")
        lockers.box((0.08, 0.004, 0.03), (x, -0.23, 1.05), "paper")
    me = lockers.mesh("lockers")
    put(me, "lockers_a", (8.4, 10.35, 0), 0)
    put(me, "lockers_b", (10.8, 10.35, 0), 0)
    collide((4.8, 0.45, 1.2), (9.6, 10.35, 0.6))
    put(kits["plant_0.35"], "lockers_plant", (9.3, 10.35, 1.2), 20)
    put(kits["binders_8"], "lockers_top_binders", (11.3, 10.35, 1.2), 0)
    # stand-up table for the daily huddle, by werkvoorbereiding
    put(bpy.data.meshes["high_table"], "huddle_table", (6.9, 6.6, 0))
    collide((0.8, 0.8, 1.1), (6.9, 6.6, 0.55))
    put(kits["mug_ceramic"], "huddle_mug", (6.95, 6.5, 0.335))
    # lounge
    put(kits["sofa"], "lounge_sofa", (16.6, 10.0, 0), 0)
    collide((1.6, 0.8, 0.8), (16.6, 10.0, 0.4))
    t = MeshBuilder()
    t.box((0.9, 0.5, 0.025), (0, 0, 0.4), "wood", bevel=0.004)
    for x in (-0.4, 0.4):
        t.box((0.03, 0.45, 0.39), (x, 0, 0.195), "metal_dark")
    put(t.mesh("low_table"), "lounge_table", (16.6, 9.1, 0))
    collide((0.9, 0.5, 0.42), (16.6, 9.1, 0.21))
    put(kits["dossiers_1"], "lounge_magazines", (16.4, 9.1, -0.35), 30)
    put(kits["plant_1.5"], "lounge_plant", (17.7, 10.1, 0), 70)


def walls_dressing(kits) -> None:
    """Obeya boards with sticky notes, the mission board, the logo and the zone signs."""
    b = MeshBuilder()
    # obeya: two 2.4 x 1.2 boards on the east wall, centre 1.55 m
    boards = [((W - 0.035, 2.1, 1.55), (0, 0.5, 1, 1.0)), ((W - 0.035, 4.7, 1.55), (0, 0.0, 1, 0.5))]
    frame = kit_board_frame(2.4, 1.2)
    for k, (c, rect) in enumerate(boards):
        put(frame, f"obeya_board{k}", (W - 0.02, c[1], c[2]), 180)
        b.panel((W - 0.032, c[1], c[2]), 2.4, 1.2, "X", "obeya", uv_rect=rect, sign=-1)
    rng = np.random.default_rng(7)
    notes = ["sticky_yellow", "sticky_pink", "sticky_green", "sticky_blue"]
    for k in range(34):  # sticky notes clustered on the problem column and the action list
        if k < 14:
            y, z = 2.1 + rng.uniform(-0.1, 0.35), 1.55 + rng.uniform(-0.45, 0.4)
        else:
            y, z = 4.7 + rng.uniform(-1.1, 1.1), 1.55 + rng.uniform(-0.55, -0.05)
        b.box((0.004, 0.076, 0.076), (W - 0.036, y, z), notes[k % 4 if k > 3 else 0], rot=0)
    # an A3 sheet taped next to the boards
    b.panel((W - 0.03, 6.25, 1.55), 0.297, 0.42, "X", "dossier", uv_rect=(0.5, 0.5, 1.0, 1.0), sign=-1)
    b.panel((W - 0.03, 2.1 + 0.0, 2.38), 0.9, 0.34, "X", "signage", uv_rect=SIGN_RECTS["Obeya"], sign=-1)
    # mission board by the entrance: cork 1.8 x 0.9 in an aluminium frame
    put(kit_board_frame(1.8, 0.9), "mission_board_frame", (0.02, 9.9, 1.5), 0)
    b.panel((0.032, 9.9, 1.5), 1.8, 0.9, "X", "missions", uv_rect=(0, 0, 1, 1))
    # logo wall at the end of the main aisle and the exit sign over the door
    b.box((0.03, 3.2, 0.6), (W - 0.015, 8.1, 1.95), "metal_white")
    b.panel((W - 0.031, 8.1, 1.95), 3.2, 0.6, "X", "signage", uv_rect=SIGN_RECTS["logo"], sign=-1)
    b.box((0.06, 0.4, 0.15), (0.03, sum(DOOR_Y) / 2, 2.3), "plastic_white")
    b.panel((0.061, sum(DOOR_Y) / 2, 2.3), 0.38, 0.14, "X", "signage", uv_rect=SIGN_RECTS["exit"])
    # coach's door sign on the glass next to the door
    b.panel((COACH_DOOR[0] - 0.3, COACH[1] - 0.012, 1.55), 0.36, 0.068, "Y", "signage",
            uv_rect=SIGN_RECTS["door"], sign=-1)
    b.panel((COACH_DOOR[0] - 0.3, COACH[1] + 0.012, 1.55), 0.36, 0.068, "Y", "signage",
            uv_rect=SIGN_RECTS["door"], sign=1)
    # hanging zone signs, double sided, readable along the x aisles
    for name, (x, y) in (("Intake", (3.2, 2.4)), ("Werkvoorbereiding", (9.0, 3.0)), ("Planning", (15.0, 3.0)),
                         ("Koffie", (1.6, 13.8))):
        b.box((0.02, 1.0, 0.36), (x, y, 2.3), "metal_blue")
        b.panel((x - 0.0105, y, 2.3), 0.98, 0.34, "X", "signage", uv_rect=SIGN_RECTS[name], sign=-1)
        b.panel((x + 0.0105, y, 2.3), 0.98, 0.34, "X", "signage", uv_rect=SIGN_RECTS[name], sign=1)
        for dy in (-0.4, 0.4):
            b.cyl(0.0015, CEIL - 2.48, (x, y + dy, (CEIL + 2.48) / 2), "alu", segs=4)
    # posters: the grid map behind intake and a safety poster on a column
    b.box((0.02, 1.24, 1.24), (0.01, 3.2, 1.55), "alu")
    b.panel((0.021, 3.2, 1.55), 1.2, 1.2, "X", "posters", uv_rect=(0, 0, 0.5, 1))
    b.panel((18.0, 10.8 - 0.201, 1.5), 0.36, 0.36, "Y", "posters", uv_rect=(0.5, 0, 1, 1), sign=-1)
    # entrance mat and an MFP printer
    b.box((1.0, 1.5, 0.012), (0.6, sum(DOOR_Y) / 2, 0.006), "fabric_mat")
    put(b.mesh("wall_dressing"), "wall_dressing")
    p = MeshBuilder()
    p.box((0.62, 0.68, 0.9), (0, 0, 0.45), "plastic_white", bevel=0.02, segs=2)
    p.box((0.6, 0.6, 0.25), (0, 0.02, 1.0), "plastic_grey", bevel=0.02, segs=2)
    p.box((0.42, 0.3, 0.01), (0, 0.05, 1.13), "paper")
    p.panel((0.0, -0.33, 1.1), 0.2, 0.12, "Y", "devices", uv_rect=(352 / 512, 1 - 256 / 512, 1, 1 - 160 / 512), sign=-1)
    put(p.mesh("mfp"), "mfp_printer", (0.5, 5.4, 0), -90)
    collide((0.7, 0.7, 1.2), (0.5, 5.4, 0.6))


def build_outside() -> None:
    """Paving and grass around the building and a row of trees, for the view out."""
    b = MeshBuilder()
    b.quad([(-30, -30, -0.5), (W + 30, -30, -0.5), (W + 30, D + 30, -0.5), (-30, D + 30, -0.5)], "grass")
    for y0, y1 in ((-4, -0.3), (D + 0.3, D + 4)):
        b.quad([(-4, y0, -0.49), (W + 4, y0, -0.49), (W + 4, y1, -0.49), (-4, y1, -0.49)], "paving")
    for k, (y, s) in enumerate(((-22, 1), (D + 22, -1), (-14, 1), (D + 16, -1))):
        x0 = -10 + k * 3
        for i in range(3):
            xa = x0 + i * 16
            b.quad([(xa + 16, y, -0.6), (xa, y, -0.6), (xa, y, 7.4), (xa + 16, y, 7.4)] if s > 0 else
                   [(xa, y, -0.6), (xa + 16, y, -0.6), (xa + 16, y, 7.4), (xa, y, 7.4)], "trees", uv_rect=(0, 0, 1, 1))
    # the street on the south side and a neighbouring office block to the north
    b.quad([(-30, -12, -0.48), (W + 30, -12, -0.48), (W + 30, -6, -0.48), (-30, -6, -0.48)], "asphalt")
    b.box((44, 12, 10), (W / 2, D + 34, 4.5), "brick")
    for z in (1.4, 4.6, 7.8):
        b.box((40, 0.1, 1.6), (W / 2, D + 27.97, z), "glass_dark")
    b.box((30, 10, 7), (W / 2 + 6, -36, 3.0), "brick")
    for z in (1.6, 4.4):
        b.box((26, 0.1, 1.4), (W / 2 + 6, -30.97, z), "glass_dark")
    put(b.mesh("outside"), "outside")


# --------------------------------------------------------------------------- empties and collision

INTERACTIONS = [  # name, extras, standing point (x, y), point it faces
    ("place:connections.intake", {"interaction": "place", "id": "connections.intake"}, (3.2, 4.75), (3.2, 2.4)),
    ("place:connections.design", {"interaction": "place", "id": "connections.design"}, (9.0, 5.4), (9.0, 3.0)),
    ("obeya", {"interaction": "obeya", "id": "obeya"}, (22.6, 3.4), (W, 3.4)),
    ("coach", {"interaction": "coach", "id": "coach"}, (22.4, 13.0), (22.4, 14.7)),
    ("mission_board", {"interaction": "mission_board", "id": "mission_board"}, (1.3, 9.9), (0.0, 9.9)),
    ("spawn", {"interaction": "spawn", "id": "spawn"}, (1.6, 7.95), (8.0, 7.95)),
]


def build_empties() -> None:
    for name, extras, (x, y), (tx, ty) in INTERACTIONS:
        ob = bpy.data.objects.new(name, None)
        ob.empty_display_type = "SINGLE_ARROW"
        ob.location = (x, y, 0.0)
        # local +Y must point at the target: rotate +Y onto the direction
        ob.rotation_euler = (0, 0, math.atan2(ty - y, tx - x) - math.pi / 2)
        for k, v in extras.items():
            ob[k] = v
        bpy.context.scene.collection.objects.link(ob)


def build_collision() -> None:
    b = MeshBuilder()
    for size, center, rot in COLLIDERS:
        b.box(size, center, "plastic_black", rot=rot)
    me = b.mesh("collision")
    me.materials.clear()
    put(me, "collision-colonly")


# --------------------------------------------------------------------------- lightmap bake

LIGHTMAPS = {"shell_floor": "lightmap_floor", "shell_walls": "lightmap_walls", "shell_ceiling": "lightmap_ceiling"}


def _gltf_output_group() -> bpy.types.NodeTree:
    """The node group the glTF exporter reads extra outputs from (occlusion)."""
    ng = bpy.data.node_groups.get("glTF Material Output")
    if ng is None:
        ng = bpy.data.node_groups.new("glTF Material Output", "ShaderNodeTree")
        ng.interface.new_socket("Occlusion", in_out="INPUT", socket_type="NodeSocketFloat")
    return ng


def bake_lightmaps(spots, samples: int, size: int = 1024) -> None:
    """Bake diffuse irradiance (sky through the windows + the ceiling panels, no sun:
    Godot adds the sun) into one image per shell object and normalise it."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 4
    scene.cycles.diffuse_bounces = 3
    scene.render.bake.margin = 6
    world = bpy.data.worlds.new("bake_sky")
    scene.world = world
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.62, 0.74, 0.95, 1)
    bg.inputs["Strength"].default_value = 1.6
    lights = []
    for k, (x, y) in enumerate(spots):
        ld = bpy.data.lights.new(f"panel{k}", "AREA")
        ld.size = 0.56
        ld.energy = 9.0
        ld.color = (1.0, 0.97, 0.92)
        lo = bpy.data.objects.new(f"panel_light{k}", ld)
        lo.location = (x, y, CEIL - 0.02)
        scene.collection.objects.link(lo)
        lights.append(lo)
    hidden = [o for o in scene.objects if o.name.startswith("glass") or o.name.startswith("collision")
              or o.name == "light_panels"]
    for o in hidden:
        o.hide_render = True
    for obname, imname in LIGHTMAPS.items():
        ob = bpy.data.objects[obname]
        img = bpy.data.images.new(imname, size, size, alpha=False, float_buffer=True)
        for mat in ob.data.materials:
            nt = mat.node_tree
            node = nt.nodes.new("ShaderNodeTexImage")
            node.name = "lightmap"
            node.image = img
            uvn = nt.nodes.new("ShaderNodeUVMap")
            uvn.uv_map = "lightmap"
            _link(nt, uvn.outputs["UV"], node.inputs["Vector"])
            nt.nodes.active = node
        ob.data.uv_layers["lightmap"].active = True
        for o in scene.objects:
            o.select_set(False)
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        print(f"baking {obname} ({samples} samples) ...", flush=True)
        bpy.ops.object.bake(type="DIFFUSE", pass_filter={"DIRECT", "INDIRECT"}, margin=6, use_clear=True)
        ob.data.uv_layers["UVMap"].active = True
        save_lightmap(img, TEX / f"{imname}.png", blur=1.0 if obname == "shell_walls" else 2.5)
    for o in hidden:
        o.hide_render = False
    for lo in lights:
        bpy.data.objects.remove(lo)


def _blur(a: np.ndarray, sigma: float) -> np.ndarray:
    """Gaussian-ish blur (three box passes per axis) to remove Monte Carlo noise."""
    r = max(1, int(round(sigma * 1.2)))
    for axis in (0, 1):
        for _ in range(3):
            pad = [(0, 0)] * a.ndim
            pad[axis] = (r + 1, r)
            c = np.cumsum(np.pad(a, pad, mode="edge"), axis=axis)
            a = (np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis)
                 - np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)) / (2 * r + 1)
    return a


def save_lightmap(img: bpy.types.Image, path: Path, blur: float) -> None:
    """Irradiance -> 0..1 multiplier: denoise, divide by a high percentile, keep a floor
    (Godot's ambient still fills the room), gamma for an sRGB PNG."""
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = _blur(px.reshape(h, w, 4)[..., :3], blur)
    lum = px.mean(-1)
    valid = lum[lum > 1e-4]
    ref = np.percentile(valid, 99.5) if valid.size else 1.0
    lm = np.clip(px / ref, 0, 1) ** 0.8
    lm = 0.15 + 0.85 * lm                    # never black: Godot's ambient still fills
    out = np.clip(lm, 0, 1) ** (1 / 2.2)
    write_png(path, out[::-1])


def write_png(path: Path, rgb01: np.ndarray) -> None:
    h, w, _ = rgb01.shape
    img = bpy.data.images.new(path.stem + "_out", w, h, alpha=False)
    rgba = np.concatenate([rgb01, np.ones((h, w, 1))], -1)[::-1].astype(np.float32)
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = str(path)
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def attach_lightmaps() -> None:
    """Wire each shell material's lightmap into the glTF occlusion output (TEXCOORD_1)."""
    group = _gltf_output_group()
    for obname, imname in LIGHTMAPS.items():
        path = TEX / f"{imname}.png"
        if not path.exists():
            print(f"warning: no {path.name}; run without --no-bake once", file=sys.stderr)
            continue
        img = bpy.data.images.load(str(path), check_existing=True)
        img.reload()
        img.colorspace_settings.name = "Non-Color"
        for mat in bpy.data.objects[obname].data.materials:
            nt = mat.node_tree
            node = nt.nodes.get("lightmap") or nt.nodes.new("ShaderNodeTexImage")
            node.name = "lightmap"
            node.image = img
            if not node.inputs["Vector"].is_linked:
                uvn = nt.nodes.new("ShaderNodeUVMap")
                uvn.uv_map = "lightmap"
                _link(nt, uvn.outputs["UV"], node.inputs["Vector"])
            sep = nt.nodes.new("ShaderNodeSeparateColor")
            _link(nt, node.outputs["Color"], sep.inputs["Color"])
            gn = nt.nodes.new("ShaderNodeGroup")
            gn.node_tree = group
            _link(nt, sep.outputs["Red"], gn.inputs["Occlusion"])


# --------------------------------------------------------------------------- main

def build_kits() -> dict:
    kits = {"desk": kit_desk(), "divider": kit_divider(), "chair": kit_chair(),
            "chair_blue": kit_chair("fabric_blue"), "chair_teal": kit_chair("fabric_teal"),
            "monitor": kit_monitor(), "keyboard": kit_keyboard(), "laptop": kit_laptop(),
            "tray": kit_tray(), "phone": kit_phone(), "mug_ceramic": kit_mug(), "rolls": kit_rolls(),
            "plotter": kit_plotter(), "coat": kit_coat(), "bin": kit_bin(), "sofa": kit_sofa(),
            "cabinet_1.2": kit_cabinet(1.2), "cabinet_1.6": kit_cabinet(1.6),
            "cabinet_2.4_tall": kit_cabinet(2.4, 1.2, 0.45, "metal_white"),
            "binders_8": kit_binders(8),
            "plant_1.5": kit_plant(1.5), "plant_1.2": kit_plant(1.2, 3), "plant_0.35": kit_plant(0.35, 2)}
    for i in range(6):
        kits[f"screen{i}"] = kit_screen(i)
    for i, h in ((1, 0.12), (2, 0.2), (3, 0.16)):
        kits[f"dossiers_{i}"] = _raise(kit_dossier_stack(h, i), 0.75)
    for i, h in ((4, 0.3), (5, 0.24)):
        kits[f"dossiers_{i}"] = _raise(kit_dossier_stack(h, i), 0.75)
    kits["dossiers_floor"] = kit_dossier_stack(0.5, 9)
    return kits


def _raise(me: bpy.types.Mesh, dz: float) -> bpy.types.Mesh:
    me.transform(Matrix.Translation((0, 0, dz)))
    return me


def triangle_count() -> int:
    tris = 0
    for ob in bpy.context.scene.objects:
        if ob.type == "MESH" and not ob.name.endswith("-colonly"):
            tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
    return tris


def fix_external_images(path: Path) -> None:
    """Blender 5.2's exporter writes both 'uri' and a 250-byte placeholder 'bufferView' for
    images kept as external files; Godot warns about that. Keep only the uri."""
    import json
    import struct
    data = path.read_bytes()
    json_len = struct.unpack_from("<I", data, 12)[0]
    doc = json.loads(data[20:20 + json_len])
    for image in doc.get("images", []):
        if "uri" in image:
            image.pop("bufferView", None)
            image.pop("mimeType", None)
    chunk = json.dumps(doc, separators=(",", ":")).encode()
    chunk += b" " * (-len(chunk) % 4)
    rest = data[20 + json_len:]
    out = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(chunk) + len(rest))
    out += struct.pack("<I4s", len(chunk), b"JSON") + chunk + rest
    path.write_bytes(out)


def main(argv: list[str]) -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--no-bake", action="store_true", help="reuse the lightmap PNGs on disk")
    ap.add_argument("--samples", type=int, default=128, help="Cycles samples per lightmap texel")
    ap.add_argument("--blend", type=Path, help="also save the .blend here (for inspection)")
    args = ap.parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    make_materials()
    build_shell()
    build_windows()
    build_door_and_skirting()
    build_coach_room()
    spots = build_ceiling_fixtures()
    build_areas(build_kits())
    build_outside()
    build_empties()
    build_collision()
    if not args.no_bake:
        bake_lightmaps(spots, args.samples)
    attach_lightmaps()
    print(f"triangles: {triangle_count()}  objects: {len(bpy.context.scene.objects)}")
    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(args.blend))
    bpy.ops.export_scene.gltf(
        filepath=str(OUT_GLB), export_format="GLB", export_keep_originals=True, export_extras=True,
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=False, export_materials="EXPORT", export_cameras=False, export_lights=False,
        use_selection=False)
    fix_external_images(OUT_GLB)
    print(f"wrote {OUT_GLB} ({OUT_GLB.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main(sys.argv[1:])
