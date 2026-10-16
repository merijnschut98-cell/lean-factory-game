"""The character creator's glbs and masks (PLAN 2.7b), from the catalogue the game reads,
game/assets/characters/creator_options.json, so every option it names resolves:

    .bvenv/bin/python tools/blender/build_character.py --creator            # both bodies
    .bvenv/bin/python tools/blender/build_character.py --creator --body f   # one body

Per body (m, f), from the CC0 pack's base body shaped like the cast (pack_character.py):
- <model>.glb (player_m, player_f): skeleton, skin, eyes (the iris its own mesh, to tint), brows
  and the animations idle, walk, jog, sit, talk. No hair and no clothes: those are parts. The
  skin every outfit covers is deleted; what only some outfits cover stays under them.
- parts/outfit_<outfit>_<body>.glb: one outfit (top, trousers, shoes), cut from this same body
  and skinned to its skeleton, so it follows every animation once CharacterModel.attach moves
  it onto the body's skeleton.
- parts/<part>_<body>.glb: hair, beards and glasses, rigid on the Head bone. Built per body
  because the two heads differ (the woman's eyes sit 1.3 cm further back, her skull is taller):
  a part made on one head floats or sinks on the other.
- textures/face_<layer>_<body>.png: greyscale masks over the skin's UV (stubble, make-up), painted
  from the head's landmarks (eye openings, the lips found in the skin texture); the game lays
  the layer's colour over the skin through them (BaseMaterial3D's detail layer).
Materials carry neutral colours; the game tints them (CreatorLook).
"""
from __future__ import annotations

import json
import math
import time
from dataclasses import replace

import bmesh
import bpy
import numpy as np
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree
from PIL import Image, ImageFilter

import build_character as bc
import pack_character as pc

CATALOGUE = bc.OUT / "creator_options.json"
PARTS = pc.PARTS
BODY = {   # the player's body: about the average height of Dutch 20-30 year olds (CBS, rounded), a middle build
    "m": dict(height=1.82, build=0.42),
    "f": dict(height=1.69, build=0.4),
}
NEUTRAL = dict(skin=(220, 172, 138), hair_color=(104, 70, 44), eye_color=(74, 46, 28))   # the game tints these
OUTFITS = {   # catalogue outfit -> (Wardrobe outfit, garment colours)
    "overshirt": ("overshirt", {"overshirt": (86, 96, 66), "tee": (240, 240, 236), "chinos": (198, 180, 144)}),
    "sweater": ("sweater", {"sweater": (38, 64, 58), "shirt": (222, 232, 244), "chinos": (66, 70, 80)}),
    "blazer": ("blazer", {"blazer": (58, 62, 72), "tee": (240, 240, 236)}),
    "quarterzip": ("quarterzip", {"quarterzip": (134, 136, 142), "chinos": (40, 48, 66), "sneaker": (46, 52, 68),
                                  "sneaker_sole": (232, 230, 224)}),
    "polo": ("business", {}),
}
MASK_PX = 1024   # the masks match the skin texture


# ============================================================================= the catalogue

def catalogue() -> dict:
    return json.loads(CATALOGUE.read_text())


def wanted(cat: dict, sex: str) -> dict:
    """What the catalogue needs built for one body: its model, outfits, parts and face layers."""
    out = {"model": None, "outfits": [], "parts": [], "layers": []}
    for trait in cat["traits"]:
        if "per_body" in trait:
            lists = trait["per_body"].values() if trait.get("any_body") else [trait["per_body"][sex]]
            options = [o for opts in lists for o in opts]
        else:
            options = trait["options"]
        for o in options:
            if o.get("body") == sex:
                out["model"] = o["model"]
            for key, field in (("outfits", "outfit"), ("parts", "part"), ("layers", "layer")):
                if o.get(field) and o[field] not in out[key]:
                    out[key].append(o[field])
    missing = [p for p in out["parts"] if p not in RECIPES] + [o for o in out["outfits"] if o not in OUTFITS] + \
        [lay for lay in out["layers"] if lay not in LAYERS]
    if missing or not out["model"]:
        raise SystemExit(f"creator_options.json names what the builder cannot make: {missing or 'no model for ' + sex}")
    return out


# ============================================================================= a head and its landmarks

class Head:
    """One shaped body's head (rest pose): the rig, the skin, the eyes, and the landmarks the
    parts and the face masks are placed by."""

    def __init__(self, paths, sex, rig, body, eyes):
        self.paths, self.sex, self.rig, self.body, self.eyes = paths, sex, rig, body, eyes
        self.bone = pc.head_of(rig, "Head")
        V, W = pc.verts(body), pc.weights(body)
        self.V = V
        head = V[W["Head"] > 0.5]
        self.top = float(head[:, 2].max())
        self.bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get(), deform=False)
        E = pc.verts(eyes)
        self.eyes_at = [E[np.sign(E[:, 0]) == s].mean(0) for s in (1, -1)]
        self.eye_z = float(np.mean([c[2] for c in self.eyes_at]))
        self.margins = self._eye_openings()
        self.mouth, self.lip_half = self._mouth()
        print(f"  head {sex}: crown {self.top:.3f}, eyes z {self.eye_z:.3f}, mouth {np.round(self.mouth, 3)}, "
              f"eye openings {[len(m) for m in self.margins]} verts")

    def nearest(self, p) -> tuple[np.ndarray, np.ndarray]:
        loc, nrm, _, _ = self.bvh.find_nearest(Vector(p))
        return np.array(loc), np.array(nrm)

    def _eye_openings(self) -> list[np.ndarray]:
        """The lid margins: the pack's skin is closed, folding into the socket behind each eye; the
        margin is the ring of skin where it passes inside the eyeball at the front."""
        E = pc.verts(self.eyes)
        out = []
        for side, c in zip((1, -1), self.eyes_at):
            r = float(np.linalg.norm(E[np.sign(E[:, 0]) == side] - c, axis=1).max())
            rel = self.V - c
            ring = (rel[:, 1] > -0.016) & (rel[:, 1] < -0.006) & (np.linalg.norm(rel, axis=1) < r - 0.0015) & \
                (np.abs(rel[:, 0]) < 0.017) & (np.abs(rel[:, 2]) < 0.013)
            out.append(self.V[ring])
        return out

    def _mouth(self) -> tuple[np.ndarray, float]:
        """The lips: front-of-face skin below the nose whose texture is the reddest (the pack
        paints the lips), their middle and half width."""
        me = self.body.data
        uv = me.uv_layers.active.data
        n = len(me.vertices)
        vuv, cnt = np.zeros((n, 2)), np.zeros(n)
        for poly in me.polygons:
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                vuv[vi] += uv[li].uv
                cnt[vi] += 1
        vuv /= np.maximum(cnt, 1)[:, None]
        tex = self.skin_tex = np.asarray(Image.open(bc.TEX / f"skin_{self.sex}_albedo.png").convert("RGB"), np.float32) / 255
        h, w, _ = tex.shape
        px = np.clip((vuv[:, 0] * w).astype(int), 0, w - 1)
        py = np.clip(((1 - vuv[:, 1]) * h).astype(int), 0, h - 1)
        red = tex[py, px, 0] - 0.5 * (tex[py, px, 1] + tex[py, px, 2])
        front = float(np.min([c[1] for c in self.eyes_at]))
        V = self.V
        cand = (np.abs(V[:, 0]) < 0.032) & (V[:, 2] < self.eye_z - 0.045) & (V[:, 2] > self.eye_z - 0.11) & (V[:, 1] < front + 0.005)
        idx = np.nonzero(cand)[0]
        lips = idx[red[idx] >= np.percentile(red[idx], 70)]
        self.red_lo, self.red_hi = float(np.percentile(red[idx], 45)), float(np.percentile(red[idx], 85))
        return V[lips].mean(0), float(np.abs(V[lips, 0]).max())


# ============================================================================= hair recipes

def pack_style(h: Head, coll, style: str):
    return pc.import_part(h.paths, style, h.rig, coll)


def reshape_hair(h: Head, ob, fn) -> None:
    """Move each vertex of a hair mesh: fn(p, skin point, skin normal) -> new p."""
    V = pc.verts(ob)
    for i, p in enumerate(V):
        loc, nrm = h.nearest(p)
        V[i] = fn(p, loc, nrm)
    pc.set_verts(ob, V)


def fade(h: Head, ob, keep: float, gone: float, floor: float, gap: float = 0.002) -> None:
    """Short back and sides: hair more than `keep` m below the crown thins towards `floor` of its
    thickness by `gone` m below it; the front (the fringe) keeps more."""
    def fn(p, loc, nrm):
        depth = h.top - p[2] - 0.03 * bc.smoothstep(0.02, 0.06, h.bone[1] - p[1])
        f = floor + (1 - floor) * (1 - bc.smoothstep(keep, gone, depth))
        d = max(float((p - loc) @ nrm), gap)   # a vertex inside the skull (the other body's head) comes out
        return loc + nrm * (gap + (d - gap) * f)
    reshape_hair(h, ob, fn)


def off_skin(h: Head, ob, margin_neck: float = 0.02, margin: float = 0.003) -> None:
    """Hair stays at least `margin` off the skin, and `margin_neck` below the jaw (where collars
    stand and the head turns against the shoulders)."""
    jaw = h.mouth[2] - 0.03

    def fn(p, loc, nrm):
        want = margin + (margin_neck - margin) * bc.smoothstep(jaw, jaw - 0.05, p[2])
        d = float((p - loc) @ nrm)
        return p + nrm * (want - d) if d < want else p
    for _ in range(2):
        reshape_hair(h, ob, fn)


def subdivide(ob, cuts: int = 1) -> None:
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True, smooth=0.6)
    bm.to_mesh(ob.data)
    bm.free()


def stretch(h: Head, ob, below: float, factor: float, back: float = 0.0) -> None:
    """Lengthen hair under the height `below`: each vertex's drop under it times `factor`; strands
    in front of `back` m behind the head's middle swing back (behind the shoulders) as they fall."""
    V = pc.verts(ob)
    low = V[:, 2] < below
    drop = (below - V[low, 2]) * factor
    V[low, 2] = below - drop
    if back:
        fall = bc.smoothstep(0.0, 0.18, drop)
        y0 = h.bone[1] + back
        V[low, 1] = V[low, 1] + np.maximum(0.0, y0 - V[low, 1]) * fall
    pc.set_verts(ob, V)


def join(objs):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    return objs[0]


def hair_fade(h, coll):
    """Korte fade: a short side part on top, the sides and back cut close."""
    ob = pack_style(h, coll, "Hair_SimpleParted")
    fade(h, ob, 0.035, 0.075, 0.22)
    return ob


def hair_buzzcut(h, coll):
    ob = pack_style(h, coll, "Hair_Buzzed")
    fade(h, ob, 0.0, 0.12, 0.7, gap=0.0015)
    return ob


def hair_crop(h, coll):
    """Textured crop: a choppy top pushed forward into a short straight fringe, faded sides."""
    ob = pack_style(h, coll, "Hair_Buzzed")
    subdivide(ob)
    front = h.bone[1] - 0.03

    def fn(p, loc, nrm):
        depth = h.top - p[2]
        top = 1 - bc.smoothstep(0.03, 0.07, depth)
        chop = noise.noise(Vector(p * 70.0)) * 0.5 + 0.5
        t = 0.003 + top * (0.012 + 0.007 * chop)
        q = loc + nrm * t
        fringe = top * bc.smoothstep(0.0, 0.05, front - p[1])
        return q + np.array([0, -0.01, -0.012]) * fringe
    reshape_hair(h, ob, fn)
    off_skin(h, ob, margin=0.002)
    return ob


def hair_curtains(h, coll):
    """Middenscheiding (curtains): the centre-parted bob cut to the cheekbones, less volume."""
    ob = pack_style(h, coll, "Hair_Long")
    stretch(h, ob, h.eye_z + 0.005, 0.42)
    reshape_hair(h, ob, lambda p, loc, nrm: loc + (p - loc) * 0.8)
    off_skin(h, ob, margin_neck=0.004)
    return ob


def curl(h: Head, ob, amount: float, size: float, seed: int) -> None:
    """Curls on a hair mass: each vertex pushed outwards (away from the middle of the head, so
    the pack's separate strand pieces move together and no seam opens) by ridged noise (`size` m
    across a curl): the surface breaks into small round coils instead of strands."""
    V = pc.verts(ob)
    centre = np.array([0.0, h.bone[1], h.eye_z])
    off = Vector((seed * 3.1, seed * 1.7, seed * 2.3))
    for i, p in enumerate(V):
        out = p - centre
        out /= max(float(np.linalg.norm(out)), 1e-6)
        t = noise.turbulence(Vector(p / size) + off, 3, True, noise_basis="PERLIN_ORIGINAL")
        V[i] = p + out * amount * min(1.0, t)
    pc.set_verts(ob, V)


def hair_curls_top(h, coll):
    """Krullen bovenop: a high top of tight curls, the sides faded."""
    ob = pack_style(h, coll, "Hair_Buzzed")
    subdivide(ob, 2)
    top_of = lambda p: 1 - bc.smoothstep(0.035, 0.075, h.top - p[2] - 0.02 * (p[1] < h.bone[1] - 0.04))  # noqa: E731

    def fn(p, loc, nrm):
        return loc + nrm * (0.0025 + 0.022 * top_of(p))
    reshape_hair(h, ob, fn)
    V = pc.verts(ob)
    top = np.array([top_of(p) for p in V])
    before = V.copy()
    curl(h, ob, 0.012, 0.011, 7)
    pc.set_verts(ob, before + (pc.verts(ob) - before) * top[:, None])
    return ob


def long_base(h, coll, end: float, back: float, fine: bool = False):
    """The centre-parted bob lengthened to `end` m under the Head bone, swung back `back`
    (`fine`: subdivided first, for a shape that needs more rows, like waves)."""
    ob = pack_style(h, coll, "Hair_Long")
    if fine:
        subdivide(ob)
    low = float(pc.verts(ob)[:, 2].min())
    below = h.mouth[2] + 0.01
    stretch(h, ob, below, (below - (h.bone[2] - end)) / (below - low), back)
    return ob


def hair_long(h, coll):
    """Lang en steil: straight, centre-parted, falling behind the shoulders."""
    ob = long_base(h, coll, 0.29, 0.07)
    off_skin(h, ob)
    return ob


def hair_waves(h, coll):
    """Lange slagen: long, with loose waves and a little more volume below the ears."""
    ob = long_base(h, coll, 0.27, 0.07, fine=True)
    V = pc.verts(ob)
    below = h.mouth[2] + 0.02
    axis = np.array([0.0, h.bone[1] + 0.02])
    for i, p in enumerate(V):
        if p[2] < below:
            drop = below - p[2]
            r = p[:2] - axis
            n = np.linalg.norm(r)
            if n > 1e-6:
                grow = 0.1 * bc.smoothstep(0, 0.08, drop) + 0.012 * math.sin(drop / 0.065 * math.tau) / max(n, 0.05)
                V[i, :2] = axis + r * (1 + grow)
    pc.set_verts(ob, V)
    off_skin(h, ob)
    return ob


def hair_lob(h, coll):
    """Schouderlengte (lob): the bob grown to just above the shoulders."""
    ob = long_base(h, coll, 0.125, 0.0)
    off_skin(h, ob, margin_neck=0.012)
    return ob


def hair_ponytail(h, coll):
    """Strakke staart: the hair pulled back sleek and tied."""
    base = pack_style(h, coll, "Hair_BuzzedFemale")
    fade(h, base, 0.0, 0.2, 0.8, gap=0.0015)
    tail = pc.ponytail("tail", h.bone, coll)
    return join([base, tail])


def hair_curls(h, coll):
    """Krullen: a full head of curls to the shoulders."""
    ob = long_base(h, coll, 0.13, 0.0, fine=True)
    reshape_hair(h, ob, lambda p, loc, nrm: loc + (p - loc) * 1.25 + nrm * 0.006)   # volume
    curl(h, ob, 0.016, 0.014, 11)
    off_skin(h, ob, margin_neck=0.015)
    return ob


def beard_full(h, coll):
    return pack_style(h, coll, "Hair_Beard")


def beard_short(h, coll):
    ob = pack_style(h, coll, "Hair_Beard")
    pc.short_beard(ob, h.body)
    return ob


def moustache(h, coll):
    """Snor: the beard's upper lip only, trimmed."""
    ob = pack_style(h, coll, "Hair_Beard")
    m = h.mouth
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    dead = [f for f in bm.faces if not (m[2] + 0.001 < f.calc_center_median().z < m[2] + 0.033
                                        and abs(f.calc_center_median().x) < h.lip_half + 0.008)]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(ob.data)
    bm.free()
    pc.short_beard(ob, h.body, keep=0.85)
    return ob


def glasses(style: str):
    return lambda h, coll: pc.glasses("glasses", style, h.body, h.eyes, coll)


# part -> recipe(head, collection) -> mesh object (on the Head bone)
RECIPES = {
    "hair_fade": hair_fade, "hair_crop": hair_crop, "hair_curtains": hair_curtains, "hair_buzzcut": hair_buzzcut,
    "hair_curls_top": hair_curls_top, "hair_long": hair_long, "hair_waves": hair_waves, "hair_lob": hair_lob,
    "hair_ponytail": hair_ponytail, "hair_curls": hair_curls,
    "beard_full": beard_full, "beard_short": beard_short, "moustache": moustache,
    "glasses_round": glasses("round"), "glasses_rect": glasses("rect"), "glasses_clear": glasses("clear"),
    "glasses_large": glasses("large"),
}


def part_material(name: str, ob) -> bpy.types.Material:
    """One material per part (the game tints surface 0): hair takes the pack texture its mesh
    came with (curls: the strand texture), glasses a plain frame."""
    if name.startswith("glasses"):
        return bc.material(f"{name}__frame", (40, 40, 46), rough=0.3, metal=0.6 if name == "glasses_round" else 0.0)
    tex = "hairpack_1" if any(m and m.name.startswith("MI_Hair_1") for m in ob.data.materials) else "hairpack_2"
    return bc.material(f"{name}__hair", NEUTRAL["hair_color"], tex=tex, rough=0.55)


# ============================================================================= face layers

def raster(h: Head, fn) -> np.ndarray:
    """A mask over the skin's UV (MASK_PX square): fn(points (N, 3), pixel x, pixel y) -> 0..1 for
    the skin at those pixels, evaluated on every head triangle."""
    me = h.body.data
    uvl = me.uv_layers.active.data
    img = np.zeros((MASK_PX, MASK_PX), np.float32)
    zmin = h.mouth[2] - 0.12
    for poly in me.polygons:
        vi = list(poly.vertices)
        if h.V[vi, 2].max() < zmin:
            continue
        li = list(poly.loop_indices)
        P = h.V[[me.loops[k].vertex_index for k in li]]
        T = np.array([uvl[k].uv[:] for k in li]) * [MASK_PX, -MASK_PX] + [0, MASK_PX]
        for k in range(1, len(li) - 1):
            _triangle(img, T[[0, k, k + 1]], P[[0, k, k + 1]], fn)
    return img


def _triangle(img, T, P, fn) -> None:
    lo = np.floor(T.min(0)).astype(int)
    hi = np.ceil(T.max(0)).astype(int)
    xs, ys = np.meshgrid(np.arange(lo[0], hi[0] + 1) + 0.5, np.arange(lo[1], hi[1] + 1) + 0.5)
    a, b, c = T
    den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(den) < 1e-9:
        return
    l1 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
    l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
    l3 = 1 - l1 - l2
    inside = (l1 >= -0.05) & (l2 >= -0.05) & (l3 >= -0.05)   # a little over the edge: no seams
    if not inside.any():
        return
    pts = l1[inside, None] * P[0] + l2[inside, None] * P[1] + l3[inside, None] * P[2]
    xi, yi = xs[inside].astype(int), ys[inside].astype(int)
    ok = (xi >= 0) & (xi < img.shape[1]) & (yi >= 0) & (yi < img.shape[0])
    vals = np.asarray(fn(pts[ok], xi[ok], yi[ok]), np.float32)
    np.maximum.at(img, (yi[ok], xi[ok]), vals)


def seg_dist(P: np.ndarray, A: np.ndarray, B: np.ndarray) -> np.ndarray:
    """Distance of each point to the nearest of the segments A[i]-B[i]."""
    d = B - A
    t = np.clip(np.einsum("nsk,sk->ns", P[:, None, :] - A[None], d) / np.maximum((d * d).sum(1), 1e-12), 0, 1)
    q = A[None] + t[..., None] * d[None]
    return np.linalg.norm(P[:, None, :] - q, axis=2).min(1)


def margin_dist(h: Head, P: np.ndarray, upper: bool) -> np.ndarray:
    """Distance to the upper (or lower) lid margin of the nearer eye."""
    out = np.full(len(P), 1.0)
    for c, M in zip(h.eyes_at, h.margins):
        part = M[(M[:, 2] > c[2] - 0.0015) if upper else (M[:, 2] < c[2] + 0.0015)]
        if len(part) < 2:
            continue
        order = np.argsort(np.arctan2(part[:, 2] - c[2], part[:, 0] - c[0]))
        part = part[order]
        out = np.minimum(out, seg_dist(P, part[:-1], part[1:]))
    return out


class Layers:
    """The face layers' masks of one head (0 bare .. 1 fully covered)."""

    def __init__(self, h: Head):
        self.h = h
        self.tex = h.skin_tex   # the skin albedo is written at MASK_PX
        self.grain = np.random.default_rng(5).uniform(0.6, 1.0, (MASK_PX, MASK_PX)).astype(np.float32)

    def lips(self, P, x, y):
        h = self.h
        m = h.mouth
        e = ((P[:, 0] - m[0]) / (h.lip_half + 0.004)) ** 2 + ((P[:, 2] - m[2]) / 0.014) ** 2
        t = self.tex[y, x]
        red = t[:, 0] - 0.5 * (t[:, 1] + t[:, 2])
        return (1 - bc.smoothstep(0.7, 1.0, e)) * bc.smoothstep(h.red_lo, h.red_hi, red) * (P[:, 1] < m[1] + 0.01)

    def stubble(self, P, x, y):
        h = self.h
        m = h.mouth
        X = np.abs(P[:, 0])
        line = np.interp(X, [0, 0.014, 0.034, 0.05, 0.066, 0.08], [m[2] + 0.017, m[2] + 0.019, m[2] + 0.022, m[2] + 0.034, h.eye_z - 0.036, h.eye_z - 0.004])
        cover = bc.smoothstep(line + 0.006, line - 0.008, P[:, 2]) * bc.smoothstep(m[2] - 0.1, m[2] - 0.08, P[:, 2]) * \
            bc.smoothstep(h.bone[1] + 0.015, h.bone[1] - 0.005, P[:, 1])
        return 0.5 * cover * (1 - self.lips(P, x, y)) * self.grain[y, x]

    def natural(self, P, x, y):
        h = self.h
        blush = np.zeros(len(P))
        for c in h.eyes_at:
            cheek = np.array([c[0] * 1.3, c[1], c[2] - 0.032])
            d = np.linalg.norm((P - cheek) * [1, 0.5, 1], axis=1)
            blush = np.maximum(blush, 0.22 * np.exp(-(d / 0.016) ** 2))
        return np.maximum(0.38 * self.lips(P, x, y), blush)

    def lipstick(self, P, x, y):
        return 0.88 * self.lips(P, x, y)

    def mascara(self, P, x, y):
        h = self.h
        return np.maximum(0.95 * (1 - bc.smoothstep(0.0011, 0.0022, margin_dist(h, P, True))),
                          0.45 * (1 - bc.smoothstep(0.0006, 0.0014, margin_dist(h, P, False))))

    def eyeliner(self, P, x, y):
        h = self.h
        line = 1 - bc.smoothstep(0.003, 0.0045, margin_dist(h, P, True))
        wing = np.zeros(len(P))
        for c, M in zip(h.eyes_at, h.margins):
            if not len(M):
                continue
            s = np.sign(c[0])
            corner = M[np.argmax(M[:, 0] * s)]
            tip, _ = h.nearest(corner + np.array([s * 0.011, 0.005, 0.0055]))
            wing = np.maximum(wing, 1 - bc.smoothstep(0.0013, 0.0024, seg_dist(P, corner[None], tip[None])))
        return np.maximum(line, wing)


LAYERS = ("stubble", "natural", "lipstick", "mascara", "eyeliner")


def face_masks(h: Head, layers: list[str]) -> None:
    lay = Layers(h)
    for name in layers:
        img = raster(h, getattr(lay, name))
        im = Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8), "L")
        im = im.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
        path = bc.TEX / f"face_{name}_{h.sex}.png"
        im.save(path, optimize=True)
        print(f"  wrote {path.name} ({path.stat().st_size / 1e3:.0f} kB, covers {np.mean(img > 0.1) * 100:.2f} % of the map)")


# ============================================================================= build

def scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = pc.FPS
    bpy.context.preferences.edit.keyframe_new_interpolation_type = "LINEAR"


def collection(name: str, rig) -> bpy.types.Collection:
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    coll.objects.link(rig)
    return coll


def discard(coll, keep) -> None:
    for ob in list(coll.objects):
        if ob is not keep:
            bpy.data.objects.remove(ob)
    coll.objects.unlink(keep)
    bpy.data.collections.remove(coll)


def export_part(coll, name: str) -> None:
    path = PARTS / f"{name}.glb"
    pc.export(coll, path, animations=False)
    bc.write_import(path, "parts/")


def iris_object(eyes, name: str) -> bpy.types.Object:
    """The iris faces of the eye mesh (material 1) as their own mesh, so the game can tint them."""
    iris = eyes.copy()   # its vertex groups, parent and armature modifier come along
    iris.data = eyes.data.copy()
    iris.name = name
    for c in eyes.users_collection:
        c.objects.link(iris)
    for ob, keep in ((eyes, 0), (iris, 1)):
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != keep], context="FACES")
        bm.to_mesh(ob.data)
        bm.free()
    iris.data.materials.pop(index=0)
    for poly in iris.data.polygons:
        poly.material_index = 0
    eyes.data.materials.pop(index=1)
    return iris


def build_body(paths, sex: str, want: dict) -> None:
    t0 = time.time()
    scene()
    model = want["model"]
    sp = bc.Spec(model, sex, BODY[sex]["height"], BODY[sex]["build"], NEUTRAL["skin"], "", NEUTRAL["hair_color"], "business",
                 eye_color=NEUTRAL["eye_color"])
    coll = bpy.data.collections.new(model)
    bpy.context.scene.collection.children.link(coll)
    mats = pc.make_materials(sp)
    rig, parts = pc.base_body(paths, sex, coll)
    body, eyes, brows = parts["body"], parts["eyes"], parts["brows"]
    pc.rename_rig(rig, [body, eyes, brows])
    for o in (body, eyes, brows):
        pc.bind(o, rig)
    pc.soften(body)
    pc.narrow_shoulders(rig, [body], pc.SHOULDER_IN[sex])
    pc.reshape(rig, [body, eyes, brows], sp.height, pc.girth_for(sp))
    pc.set_material(body, mats["skin"][0])
    pc.set_material(brows, mats["brow"][0])
    pc.set_material(eyes, mats["eye"][0])
    eyes.data.materials.append(bpy.data.materials[mats["iris"][0]])
    pc.split_iris(eyes, 1)

    covered = None
    for outfit in want["outfits"]:
        kind, colours = OUTFITS[outfit]
        name = f"outfit_{outfit}_{sex}"
        osp = replace(sp, name=name, colors=colours)
        oc = collection(name, rig)
        w = pc.Wardrobe(osp, rig, body, oc, pc.make_materials(osp))
        for ob in w.dress(kind):
            pc.lean_mesh(ob)
        covered = w.covered if covered is None else covered & w.covered
        export_part(oc, name)
        discard(oc, rig)

    h = Head(paths, sex, rig, body, eyes)
    for part in want["parts"]:
        name = f"{part}_{sex}"
        pcoll = collection(name, rig)
        ob = RECIPES[part](h, pcoll)
        ob.name = name
        pc.set_material(ob, part_material(part, ob).name)
        pc.bind(ob, rig)
        pc.only_head(ob)
        pc.lean_mesh(ob)
        export_part(pcoll, name)
        discard(pcoll, rig)
    face_masks(h, want["layers"])

    iris = iris_object(eyes, f"{model}_iris")
    if covered is not None:
        pc.delete_covered(body, covered)
    for key, ob in (("body", body), ("eyes", eyes), ("brows", brows)):
        ob.name = f"{model}_{key}"
    for ob in (body, eyes, iris, brows):
        pc.lean_mesh(ob)
    sources = {"ual1": pc.Source(paths["ual1"], pc.UAL1_TO_UE)}
    pc.animate(sp, rig, sources)
    for src in sources.values():
        bpy.data.objects.remove(src.rig)
    path = bc.OUT / f"{model}.glb"
    pc.export(coll, path)
    bc.write_import(path)
    print(f"{model}: {len(want['outfits'])} outfits, {len(want['parts'])} parts, {len(want['layers'])} layers, {time.time() - t0:.0f} s")


def run(pack, bodies: list[str]) -> None:
    paths = pc.pack_paths(pack)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bc.make_textures()
    pc.make_pack_textures(paths)
    PARTS.mkdir(parents=True, exist_ok=True)
    cat = catalogue()
    for sex in bodies:
        build_body(paths, sex, wanted(cat, sex))
