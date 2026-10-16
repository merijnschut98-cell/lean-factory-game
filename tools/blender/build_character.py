"""Build the people of Spanning with bpy: game/assets/characters/<id>.glb.

Script-built characters, a trial (Merijn decides between this, an AI generator and asset
packs, PLAN 7 Q1). Who they are and how they look is data: game/assets/characters/cast.json,
one list the world reads too, so another method can replace this builder without touching
the game. Run with Blender's Python module (see tools/blender/README.md):

    .bvenv/bin/python tools/blender/build_character.py --no-render  # every glb (~4 min each)
    .bvenv/bin/python tools/blender/build_character.py --only joost --only anouk --no-render
    .bvenv/bin/python tools/blender/build_character.py --only ruud --only player --samples 32

How a person is made:
- Body, head, hair, clothes and shoes are signed distance fields (SDFs): ellipsoids and round
  cones blended with smooth unions (eye sockets and the ear bowls are smooth subtractions),
  polygonised with marching cubes and decimated to a triangle budget. Garments are the body
  field pushed outward and cut by planes (hem, neckline, sleeve end), smoothed over a looser
  hull so fabric bridges hollows instead of hugging them. Skin under clothes and hair is
  deleted, so nothing pokes through and the budget goes to what is seen.
- Skin has no texture: its colour (tone, lips, blush, stubble, baked ambient occlusion) is a
  vertex colour; Godot's glTF importer uses COLOR_0 as albedo.
- Clothes and hair use small tileable greyscale textures generated here, shared by everyone:
  game/assets/characters/textures/. A glb carries no images, only plain materials named
  <person>__<key> with the garment colour and an extras tag {"texture": <name>};
  game/assets/characters/character_import.gd puts the shared texture under that colour
  (so nine people cost one set of textures, and a glb is ~1 MB instead of ~4).
- A humanoid rig with Godot SkeletonProfileHumanoid bone names (Hips, Spine, Chest, Neck,
  Head, LeftUpperArm, ...), rest pose an A-pose (arms 40 degrees from vertical). Weights come
  from the same primitives: each vertex belongs to the bones whose primitives' surfaces are
  nearest (a soft-min over SDF distances). Four looping actions, each on its own rig's NLA
  track: `idle_loop` (4 s, standing), `walk_loop` (in place, a brisk stride; its pace in m/s is
  printed, and the game measures it from the animation to match its feet to the floor),
  `sit_loop` (4 s, seated at a desk, typing) and `talk_loop` (3 s, standing, a hand gesture).
  The export writes the tracks (not every action in the file, which would hand one person the
  others' moves). Godot imports them as looping `idle`, `walk`, `sit` and `talk`.

Coordinates are Blender's: metres, Z up, the person faces -Y (Godot +Z, the model front).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import bpy  # first: registers mathutils
import bmesh
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from PIL import Image, ImageDraw
from skimage.measure import marching_cubes

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_office import srgb  # noqa: E402
from textures import _font, _logo, noise  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "assets" / "characters"
TEX = OUT / "textures"   # shared by every person (the glbs carry no images)
CAST = OUT / "cast.json"
SHOTS = ROOT / "docs" / "screenshots"
TEX_PX = 256             # texture size: a person is a few hundred pixels tall on screen
WALK_FRAMES = 24         # one stride cycle at 30 fps (0.8 s)
VOXEL = 1.0              # voxel size factor (--draft: 2, coarse but 8x faster, for pose checks)


# =========================================================================== the people

@dataclass
class Spec:
    """Everything that makes one person. Colours are sRGB 0..255."""
    name: str
    sex: str                  # "f" or "m": shoulders, hips, chest, jaw, brow
    height: float             # metres, crown to sole (shoes add ~2 cm)
    build: float              # 0 slim .. 1 heavy
    skin: tuple
    hair_style: str           # "bob", "short", "receding", "buzz", "ponytail"
    hair_color: tuple
    outfit: str               # "business" (polo), "shirt", "manager" (blazer), "monteur" (PPE)
    eye_color: tuple = (92, 64, 40)
    brow_color: tuple | None = None
    stubble: float = 0.0      # 0..1 beard shadow
    glasses: bool = False
    helmet: bool = True       # a monteur's safety helmet
    stoop: float = 0.0        # 0..1: age in the posture (back rounded, head forward)
    colors: dict = field(default_factory=dict)  # garment colour overrides


def load_cast(path: Path = CAST) -> dict[str, Spec]:
    """id -> Spec from the cast list (lists become the tuples the builder expects)."""
    out = {}
    for person in json.loads(path.read_text())["characters"]:
        look = {k: tuple(v) if isinstance(v, list) else v for k, v in person["look"].items()}
        look["colors"] = {k: tuple(v) for k, v in look.get("colors", {}).items()}
        out[person["id"]] = Spec(person["id"], **look)
    return out


CAST_SPECS = load_cast()

GARMENT_COLORS = {
    "polo": (24, 62, 128), "chinos": (196, 176, 140), "shoe": (92, 58, 36),
    "shirt": (176, 204, 232), "trousers": (84, 88, 96), "blazer": (34, 44, 70),
    "belt": (52, 36, 26), "workshirt": (40, 52, 78), "worktrousers": (44, 50, 62),
    "boot": (34, 32, 30), "hivis": (255, 255, 255), "helmet": (240, 240, 236), "sole": (40, 38, 36),
}


# =========================================================================== SDF primitives

def unit(v) -> np.ndarray:
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def axes(z, hint=(1.0, 0.0, 0.0)) -> np.ndarray:
    """An orthonormal frame (columns x, y, z) with z along `z` and x towards `hint`."""
    z = unit(z)
    h = np.asarray(hint, float)
    if abs(np.dot(h, z)) > 0.95:
        h = np.array([0.0, 1.0, 0.0]) if abs(z[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    x = unit(h - z * np.dot(h, z))
    return np.stack([x, np.cross(z, x), z], 1)


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


class Prim:
    """An ellipsoid ('ball'), a round cone ('cone') or a rounded box ('box') in a local frame,
    optionally clipped by a half-space; `bone` names the bone that carries it."""

    def __init__(self, kind, origin, frame, size, bone=None, clip=None):
        self.kind, self.o, self.M, self.size, self.bone, self.clip = kind, np.asarray(origin, float), frame, size, bone, clip
        if kind == "ball":
            ext = max(size)
        elif kind == "cone":
            ext = max(size[1], size[2]) + size[0]
        else:
            ext = (max(size[0]) + size[1]) * 1.75
        self.lo, self.hi = self.o - ext, self.o + ext

    def dist(self, P: np.ndarray) -> np.ndarray:
        q = (P - self.o) @ self.M
        if self.kind == "ball":
            r = np.asarray(self.size)
            k0 = np.linalg.norm(q / r, axis=1)
            k1 = np.linalg.norm(q / (r * r), axis=1)
            d = k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
        elif self.kind == "cone":
            length, r1, r2, sx, sy = self.size
            q = q / np.array([sx, sy, 1.0])
            d = _round_cone(q, length, r1, r2) * min(sx, sy, 1.0)
        else:
            half, rad = np.asarray(self.size[0]), self.size[1]
            v = np.abs(q) - half
            d = np.linalg.norm(np.maximum(v, 0.0), axis=1) + np.minimum(v.max(1), 0.0) - rad
        if self.clip is not None:
            n, p0 = self.clip
            d = np.maximum(d, (P - p0) @ n)
        return d


def _round_cone(q, h, r1, r2):
    """Inigo Quilez's round cone along +z from 0 (radius r1) to h (radius r2)."""
    b = (r1 - r2) / h
    a = math.sqrt(max(1.0 - b * b, 1e-9))
    x = np.hypot(q[:, 0], q[:, 1])
    y = q[:, 2]
    k = -b * x + a * y   # dot(q2, (-b, a))
    return np.where(k < 0.0, np.hypot(x, y) - r1,
                    np.where(k > a * h, np.hypot(x, y - h) - r2, x * a + y * b - r1))


def ball(c, r, z=None, hint=(1, 0, 0), bone=None, clip=None) -> Prim:
    return Prim("ball", c, np.eye(3) if z is None else axes(z, hint), tuple(r), bone, clip)


def cone(a, b, r1, r2, flat=(1.0, 1.0), hint=(1, 0, 0), bone=None) -> Prim:
    a, b = np.asarray(a, float), np.asarray(b, float)
    return Prim("cone", a, axes(b - a, hint), (float(np.linalg.norm(b - a)), r1, r2, flat[0], flat[1]), bone)


def rbox(c, half, rad, z=(0, 0, 1), hint=(1, 0, 0), bone=None) -> Prim:
    return Prim("box", c, axes(z, hint), (tuple(half), rad), bone)


class Field:
    """A sequence of smooth CSG operations: ('add' | 'sub', prim, k)."""

    def __init__(self):
        self.ops: list[tuple[str, Prim, float]] = []

    def add(self, prim: Prim, k: float = 0.0) -> Prim:
        self.ops.append(("add", prim, k))
        return prim

    def sub(self, prim: Prim, k: float = 0.0) -> Prim:
        self.ops.append(("sub", prim, k))
        return prim

    def __call__(self, P: np.ndarray) -> np.ndarray:
        f = np.full(len(P), 0.25)
        for op, prim, k in self.ops:
            pad = k + 0.02
            m = np.all((P > prim.lo - pad) & (P < prim.hi + pad), axis=1)
            if not m.any():
                continue
            d = prim.dist(P[m])
            f[m] = smin(f[m], d, k) if op == "add" else smax(f[m], -d, k)
        return f

    def bones(self) -> list[Prim]:
        return [p for op, p, _ in self.ops if op == "add" and p.bone]


def polygonize(fn, lo, hi, h: float) -> tuple[np.ndarray, np.ndarray]:
    """Marching cubes of fn's zero set inside [lo, hi] with voxel size h. The field is first
    sampled on a 4h grid; only cells near the surface are evaluated at full resolution."""
    h *= VOXEL
    lo = np.asarray(lo, float)
    nc = np.ceil((np.asarray(hi, float) - lo) / (4 * h)).astype(int) + 1
    gc = [lo[i] + np.arange(nc[i]) * 4 * h for i in range(3)]
    C = np.stack(np.meshgrid(*gc, indexing="ij"), -1).reshape(-1, 3)
    fc = np.concatenate([fn(C[i:i + 400_000]) for i in range(0, len(C), 400_000)]).reshape(nc)
    corners = [fc[a:a + nc[0] - 1, b:b + nc[1] - 1, c:c + nc[2] - 1] for a in (0, 1) for b in (0, 1) for c in (0, 1)]
    cmin, cmax = np.min(corners, 0), np.max(corners, 0)
    near = (cmin < 4 * h * 1.8 + 0.006) & (cmax > -4 * h * 1.8 - 0.006)
    sign = np.where(cmin > 0, 1.0, -1.0)

    def up(a):
        for ax in range(3):
            a = np.repeat(a, 4, axis=ax)
        return np.pad(a, ((0, 1), (0, 1), (0, 1)), mode="edge")

    mask = up(near)
    F = (up(sign) * 0.05).astype(np.float32)
    idx = np.nonzero(mask)
    P = lo + np.stack(idx, 1) * h
    vals = np.concatenate([fn(P[i:i + 400_000]) for i in range(0, len(P), 400_000)]) if len(P) else np.zeros(0)
    F[idx] = vals
    F[0, :, :] = F[-1, :, :] = F[:, 0, :] = F[:, -1, :] = F[:, :, 0] = F[:, :, -1] = 0.05
    verts, faces, _, _ = marching_cubes(F, level=0.0, spacing=(h, h, h), gradient_direction="descent")
    return verts + lo, faces


# =========================================================================== the body

class Body:
    """Landmarks, rig and SDF of one person, all in metres for spec.height."""

    def __init__(self, sp: Spec):
        self.sp = sp
        f = sp.sex == "f"
        s = self.s = sp.height / 1.75
        self.wb = (0.9 + 0.24 * sp.build)          # torso width
        self.lb = (0.92 + 0.16 * sp.build)          # limb girth
        self.belly = max(0.0, sp.build - 0.45) * 0.08
        self.head_c = np.array([0.0, 0.004, 1.655]) * s
        self.hs = s * (0.95 if f else 1.0) * 1.06   # head scale (a touch large, Sims-like)
        sh = 0.168 if f else 0.184
        self.SJ = np.array([sh, 0.0, 1.425]) * s    # left shoulder joint (left = +X)
        a = math.radians(40)
        self.d = np.array([math.sin(a), 0.0, -math.cos(a)])   # left arm direction, A-pose
        self.n_palm = np.array([-math.cos(a), 0.0, -math.sin(a)])
        self.E = self.SJ + self.d * 0.295 * s
        self.W = self.E + self.d * 0.255 * s
        self.HJ = np.array([0.092 if f else 0.088, 0.0, 0.915]) * s
        self.K = np.array([0.094, -0.01, 0.5]) * s
        self.A = np.array([0.1, 0.028, 0.085]) * s
        self.TOE = np.array([0.106, -0.135, 0.02]) * s
        self.field = Field()
        self._torso()
        self._head()
        for side in (1, -1):
            self._arm(side)
            self._leg(side)
        self.bones = self._bones()

    # ---- helpers
    def m(self, p, side):
        """Mirror a left-side point for side -1."""
        p = np.asarray(p, float).copy()
        p[0] *= side
        return p

    def H(self, x, y, z):
        """A point given in head-local coordinates (male head, origin at the head centre)."""
        return self.head_c + np.array([x, y, z]) * self.hs

    def side_name(self, side, bone):
        return ("Left" if side > 0 else "Right") + bone

    # ---- parts
    def _torso(self):
        F, s, wb, f = self.field, self.s, self.wb, self.sp.sex == "f"
        hip = 1.1 if f else 1.0
        F.add(ball(np.array([0, 0.012, 0.955]) * s, np.array([0.152 * wb * hip, 0.102 * wb, 0.115]) * s, bone="torso"))
        F.add(ball(np.array([0, -0.004, 1.105]) * s - [0, self.belly * 0.6, 0],
                   np.array([0.128 * wb * (0.86 if f else 1.0), 0.092 * wb + self.belly, 0.135]) * s, bone="torso"), 0.06 * s)
        F.add(ball(np.array([0, 0.008, 1.285]) * s, np.array([0.146 * wb * (0.9 if f else 1.0), 0.099 * wb, 0.165]) * s,
                   bone="torso"), 0.06 * s)
        for side in (1, -1):
            if f:
                F.add(ball(self.m([0.058, -0.072, 1.262], side) * s, np.array([0.056, 0.048, 0.054]) * s * (0.9 + 0.2 * self.sp.build),
                           bone="torso"), 0.035 * s)
            else:
                F.add(ball(self.m([0.064, -0.068, 1.335], side) * s, np.array([0.066, 0.036, 0.058]) * s * wb,
                           bone="torso"), 0.03 * s)
            F.add(ball(self.m([0.072, 0.07, 1.33], side) * s, np.array([0.06, 0.032, 0.075]) * s, bone="torso"), 0.04 * s)
            F.add(ball(self.m([0.062, 0.062, 0.9], side) * s,
                       np.array([0.07 * (1.1 if f else 1.0), 0.058 * (1.15 if f else 1.0), 0.078]) * s * self.lb, bone="torso"), 0.035 * s)
            F.add(cone(np.array([0, 0.024, 1.455]) * s, self.m([0.15 * (0.92 if f else 1), 0.014, 1.438], side) * s,
                       0.06 * s, 0.042 * s, bone=self.side_name(side, "Shoulder")), 0.04 * s)
            F.add(ball(self.m(self.SJ, side) + self.m([0.006, 0, -0.012], side) * s, np.array([0.05, 0.052, 0.066]) * s * self.lb,
                       z=self.m(self.d, side), bone=self.side_name(side, "UpperArm")), 0.035 * s)
        F.add(cone(np.array([0, 0.02, 1.4]) * s, np.array([0, 0.012, 1.57]) * s, 0.056 * s * (0.86 if f else 1.0),
                   0.05 * s * (0.88 if f else 1.0), flat=(1.0, 0.95), bone="Neck"), 0.035 * s)

    def _head(self):
        F, H, hs, f = self.field, self.H, self.hs, self.sp.sex == "f"
        bone = "Head"
        add = lambda p, k: F.add(p, k * hs)  # noqa: E731
        add(ball(H(0, 0.012, 0), np.array([0.074, 0.094, 0.093]) * hs, bone=bone), 0)
        add(ball(H(0, -0.038, 0.03), np.array([0.066, 0.05, 0.055]) * hs, bone=bone), 0.02)
        if not f:
            add(ball(H(0, -0.072, 0.004), np.array([0.05, 0.018, 0.012]) * hs, bone=bone), 0.015)
        for sd in (1, -1):
            add(ball(H(0.045 * sd, -0.054, -0.03), np.array([0.026, 0.024, 0.02]) * hs * (1.12 if f else 1.0), bone=bone), 0.02)
            jaw_in = 0.02 if f else 0.024
            add(cone(H(0.057 * sd, 0.008, -0.058), H(jaw_in * sd, -0.058, -0.108 if f else -0.114), 0.021 * hs,
                     0.017 * hs, bone=bone), 0.025)
        add(ball(H(0, -0.03, -0.083), np.array([0.056, 0.055, 0.05]) * hs, bone=bone), 0.03)
        for sd in (1, -1):   # cheeks: fill between cheekbone and jaw
            add(ball(H(0.043 * sd, -0.042, -0.062), np.array([0.03, 0.034, 0.034]) * hs * (1.06 if f else 1.0), bone=bone), 0.03)
        add(ball(H(0, -0.058, -0.058), np.array([0.035, 0.034, 0.034]) * hs, bone=bone), 0.025)
        add(ball(H(0, -0.066, -0.113 if f else -0.119), np.array([0.022 if f else 0.025, 0.02, 0.019]) * hs, bone=bone), 0.02)
        # nose
        add(cone(H(0, -0.083, -0.006), H(0, -0.104, -0.05), 0.0068 * hs, 0.0098 * hs, flat=(1.0, 1.0), bone=bone), 0.012)
        add(ball(H(0, -0.094, -0.056), np.array([0.0145, 0.011, 0.0085]) * hs, bone=bone), 0.009)
        for sd in (1, -1):
            add(ball(H(0.0125 * sd, -0.088, -0.054), np.array([0.0085, 0.0085, 0.0075]) * hs, bone=bone), 0.006)
        # lips
        lf = 1.15 if f else 1.0
        add(ball(H(0, -0.087, -0.0795), np.array([0.0235, 0.0092, 0.0068 * lf]) * hs, bone=bone), 0.007)
        add(ball(H(0, -0.0845, -0.093), np.array([0.021, 0.0098, 0.008 * lf]) * hs, bone=bone), 0.007)
        F.sub(ball(H(0, -0.094, -0.0862), np.array([0.026, 0.013, 0.0013]) * hs), 0.0015 * hs)
        # eyes: sockets, then lids over the eyeball (the eyeballs are separate meshes)
        for sd in (1, -1):
            F.sub(ball(H(0.032 * sd, -0.079, -0.019), np.array([0.019, 0.016, 0.0135]) * hs), 0.008 * hs)
            add(ball(H(0.032 * sd, -0.0635, -0.0195), np.array([0.0156, 0.0148, 0.0147]) * hs, bone=bone,
                     clip=(np.array([0, 0, -1.0]), H(0, 0, -0.0151))), 0.003)
            add(ball(H(0.032 * sd, -0.0632, -0.0205), np.array([0.015, 0.0142, 0.0137]) * hs, bone=bone,
                     clip=(np.array([0, 0, 1.0]), H(0, 0, -0.0253))), 0.003)
        # ears
        for sd in (1, -1):
            add(ball(H(0.075 * sd, 0.014, -0.022), np.array([0.011, 0.02, 0.031]) * hs, z=(0.25 * sd, 0.3, 1), bone=bone), 0.006)
            F.sub(ball(H(0.083 * sd, 0.016, -0.022), np.array([0.0045, 0.012, 0.019]) * hs, z=(0, 0.3, 1)), 0.003 * hs)

    def _arm(self, side):
        F, s, lb, m = self.field, self.s, self.lb, self.m
        d, n = m(self.d, side), m(self.n_palm, side)
        SJ, E, W = m(self.SJ, side), m(self.E, side), m(self.W, side)
        y = np.array([0, 1.0, 0])
        ua, la, hd = (self.side_name(side, b) for b in ("UpperArm", "LowerArm", "Hand"))
        F.add(cone(SJ, E, 0.047 * s * lb, 0.036 * s * lb, bone=ua), 0.02 * s)
        F.add(ball(SJ + d * 0.15 * s - y * 0.01 * s, np.array([0.039, 0.041, 0.095]) * s * lb, z=d, hint=n, bone=ua), 0.02 * s)
        F.add(ball(E + y * 0.012 * s, np.array([0.026, 0.026, 0.03]) * s, z=d, hint=n, bone=la), 0.015 * s)
        F.add(cone(E, W, 0.037 * s * lb, 0.025 * s, flat=(0.78, 1.0), hint=n, bone=la), 0.015 * s)
        F.add(ball(E + d * 0.075 * s, np.array([0.034, 0.04, 0.085]) * s * lb, z=d, hint=n, bone=la), 0.02 * s)
        # hand: palm, four fingers held together (a mitten with grooves), thumb
        F.add(ball(W + d * 0.052 * s, np.array([0.016, 0.042, 0.052]) * s, z=d, hint=n, bone=hd), 0.012 * s)
        for off, length in ((-0.026, 0.074), (-0.0087, 0.082), (0.0087, 0.078), (0.026, 0.064)):
            a = W + d * 0.088 * s + y * off * s
            b = a + d * length * s + n * 0.014 * s
            F.add(cone(a, b, 0.0098 * s, 0.0082 * s, bone=hd), 0.004 * s)
        t0 = W + d * 0.02 * s - y * 0.024 * s + n * 0.006 * s
        t1 = W + d * 0.06 * s - y * 0.05 * s + n * 0.014 * s
        F.add(cone(t0, t1, 0.0125 * s, 0.0095 * s, bone=hd), 0.009 * s)
        F.add(cone(t1, t1 + d * 0.026 * s - y * 0.008 * s + n * 0.004 * s, 0.0095 * s, 0.0082 * s, bone=hd), 0.003 * s)

    def _leg(self, side):
        F, s, lb, m, f = self.field, self.s, self.lb, self.m, self.sp.sex == "f"
        ul, ll, ft = (self.side_name(side, b) for b in ("UpperLeg", "LowerLeg", "Foot"))
        HJ, K, A = m(self.HJ, side), m(self.K, side), m(self.A, side)
        tf = 1.06 if f else 1.0
        F.add(cone(HJ + np.array([0, 0, 0.01]) * s, K, 0.088 * s * lb * tf, 0.054 * s * lb, bone=ul), 0.04 * s)
        F.add(ball(m([0.094, -0.022, 0.72], side) * s, np.array([0.062, 0.055, 0.13]) * s * lb * tf, bone=ul), 0.03 * s)
        F.add(ball(K + np.array([0, -0.022, 0.0]) * s, np.array([0.045, 0.04, 0.048]) * s * lb, bone=ll), 0.02 * s)
        F.add(cone(K, A, 0.05 * s * lb, 0.031 * s, bone=ll), 0.02 * s)
        F.add(ball(m([0.096, 0.03, 0.37], side) * s, np.array([0.046, 0.046, 0.095]) * s * lb, bone=ll), 0.03 * s)
        F.add(cone(m([0.1, 0.035, 0.04], side) * s, m([0.105, -0.11, 0.028], side) * s, 0.032 * s, 0.03 * s,
                   flat=(1.0, 0.8), hint=(1, 0, 0), bone=ft), 0.02 * s)
        F.add(ball(m([0.106, -0.15, 0.022], side) * s, np.array([0.036, 0.04, 0.02]) * s, bone=ft), 0.015 * s)

    def _bones(self) -> dict:
        s, m = self.s, self.m
        b = {"Root": ((0, 0, 0), (0, 0, 0.15 * s), None),
             "Hips": ((0, 0.01 * s, 0.93 * s), (0, 0.01 * s, 1.03 * s), "Root"),
             "Spine": ((0, 0.01 * s, 1.03 * s), (0, 0.0, 1.18 * s), "Hips"),
             "Chest": ((0, 0.0, 1.18 * s), (0, 0.01 * s, 1.4 * s), "Spine"),
             "Neck": ((0, 0.02 * s, 1.42 * s), (0, 0.012 * s, 1.56 * s), "Chest"),
             "Head": ((0, 0.012 * s, 1.56 * s), tuple(self.head_c + np.array([0, 0, 0.095]) * self.hs), "Neck")}
        for side in (1, -1):
            n = lambda bone: self.side_name(side, bone)  # noqa: E731
            d = m(self.d, side)
            b[n("Shoulder")] = (tuple(m([0.025, 0.01, 1.41], side) * s), tuple(m(self.SJ, side)), "Chest")
            b[n("UpperArm")] = (tuple(m(self.SJ, side)), tuple(m(self.E, side)), n("Shoulder"))
            b[n("LowerArm")] = (tuple(m(self.E, side)), tuple(m(self.W, side)), n("UpperArm"))
            b[n("Hand")] = (tuple(m(self.W, side)), tuple(m(self.W, side) + d * 0.17 * s), n("LowerArm"))
            b[n("UpperLeg")] = (tuple(m(self.HJ, side)), tuple(m(self.K, side)), "Hips")
            b[n("LowerLeg")] = (tuple(m(self.K, side)), tuple(m(self.A, side)), n("UpperLeg"))
            b[n("Foot")] = (tuple(m(self.A, side)), tuple(m(self.TOE, side)), n("LowerLeg"))
        return b

    def torso_split(self, z: np.ndarray) -> dict:
        """Weights of Hips / Spine / Chest for torso primitives, by height."""
        s = self.s
        a = smoothstep(0.99 * s, 1.07 * s, z)
        c = smoothstep(1.16 * s, 1.26 * s, z)
        return {"Hips": 1 - a, "Spine": a * (1 - c), "Chest": a * c}

    def bbox(self):
        s = self.s
        return np.array([-0.72, -0.24, -0.02]) * s, np.array([0.72, 0.22, 1.79]) * s


# =========================================================================== skin weights

def skin_weights(body: Body, verts: np.ndarray, tau: float = 0.012, rigid: str | None = None) -> dict:
    """Bone name -> per-vertex weight (top 4, normalised). rigid puts everything on one bone."""
    if rigid:
        return {rigid: np.ones(len(verts))}
    prims = body.field.bones()
    names = sorted({p.bone for p in prims})
    D = np.full((len(verts), len(names)), 9.0)
    for p in prims:
        j = names.index(p.bone)
        D[:, j] = np.minimum(D[:, j], p.dist(verts))
    W = np.exp(-(D - D.min(1, keepdims=True)) / (tau * body.s))
    W /= W.sum(1, keepdims=True)
    out: dict[str, np.ndarray] = {}
    for j, name in enumerate(names):
        if name == "torso":
            for b, w in body.torso_split(verts[:, 2]).items():
                out[b] = out.get(b, 0) + W[:, j] * w
        else:
            out[name] = out.get(name, 0) + W[:, j]
    keys = list(out)
    M = np.stack([out[k] for k in keys], 1)
    if M.shape[1] > 4:
        cut = -np.sort(-M, 1)[:, 3:4]
        M = np.where(M >= cut, M, 0.0)
    M = np.where(M < 0.01, 0.0, M)
    M /= M.sum(1, keepdims=True)
    return {k: M[:, i] for i, k in enumerate(keys) if M[:, i].any()}


# =========================================================================== garments, hair, shoes

def region_cut(*cuts):
    """Intersection of half-space / custom region functions (negative inside)."""
    def fn(P):
        r = np.full(len(P), -1.0)
        for c in cuts:
            r = np.maximum(r, c(P))
        return r
    return fn


def below(z0, tilt=0.0):
    """Inside below a plane through height z0; tilt > 0 lowers it at the front (-Y)."""
    return lambda P: (P[:, 2] - z0 - tilt * P[:, 1]) / math.sqrt(1 + tilt * tilt)


def above(z0, tilt=0.0):
    return lambda P: (z0 - P[:, 2] + tilt * P[:, 1]) / math.sqrt(1 + tilt * tilt)


def not_(fn):
    return lambda P: -fn(P)


def arm_beyond(body: Body, side: int, length: float, radius: float):
    """Region of one arm beyond `length` metres from the shoulder joint (negative inside)."""
    SJ, d = body.m(body.SJ, side), body.m(body.d, side)

    def fn(P):
        t = (P - SJ) @ d
        radial = np.linalg.norm((P - SJ) - np.outer(t, d), axis=1)
        return np.maximum(length - t, radial - radius)
    return fn


def arms_beyond(body: Body, length: float, radius: float):
    l_, r_ = arm_beyond(body, 1, length, radius), arm_beyond(body, -1, length, radius)
    return lambda P: np.minimum(l_(P), r_(P))


@dataclass
class Part:
    """One mesh of a character before it becomes a Blender object."""
    name: str
    fn: object                # SDF callable
    lo: np.ndarray
    hi: np.ndarray
    h: float                  # voxel size
    tris: int                 # decimation target
    material: str
    uv: str = "box"           # "box", "cyl", "sphere"
    rigid: str | None = None  # bone for rigid parts (hair, helmet)
    covers: object = None     # region fn: body skin inside it (by > 2 cm) is deleted
    split: tuple | None = None  # (z, material below) e.g. shoe soles


def garment(body: Body, t: float, region, hull: Field | None = None, hull_k: float = 0.03, hem_k: float = 0.004,
            ease: tuple[float, float] | None = None):
    """The body pushed out by t, smoothed over a looser hull, cut to region. ease = (hem height,
    extra) lets the fabric hang away from the hips over the last 10 cm above the hem."""
    s = body.s

    def fn(P):
        tt = t if ease is None else t + ease[1] * smoothstep((ease[0] + 0.1) * s, ease[0] * s, P[:, 2])
        d = body.field(P) - tt * s
        if hull is not None:
            d = smin(d, hull(P) - tt * s, hull_k * s)
        return smax(d, region(P), hem_k * s)
    return fn


def torso_hull(body: Body, z0: float, z1: float, r0: float, r1: float, depth: float = 0.7) -> Field:
    s, wb = body.s, body.wb
    h = Field()
    h.add(cone(np.array([0, 0.012, z0]) * s, np.array([0, 0.006, z1]) * s, r0 * s * wb, r1 * s * wb,
               flat=(1.0, depth + 0.5 * body.belly), hint=(1, 0, 0)))
    return h


def leg_hull(body: Body, r_top: float, r_hem: float) -> Field:
    s = body.s
    h = Field()
    for side in (1, -1):
        h.add(cone(body.m([0.092, 0.002, 0.86], side) * s, body.m([0.103, 0.018, 0.09], side) * s,
                   r_top * s * body.lb, r_hem * s, flat=(1.0, 0.95)), 0.0)
    return h


def sleeve_hull(body: Body, length: float, r0: float, r1: float, h: Field | None = None) -> Field:
    s = body.s
    h = h or Field()
    for side in (1, -1):
        SJ, d = body.m(body.SJ, side), body.m(body.d, side)
        h.add(cone(SJ + d * 0.03 * s, SJ + d * length * s, r0 * s * body.lb, r1 * s * body.lb), 0.0)
    return h


def neck_radius(body: Body, extra: float) -> float:
    """Radius (m) of a garment's neck opening: the neck plus `extra` metres of room."""
    return (0.056 * (0.86 if body.sp.sex == "f" else 1.0) + extra) * body.s


def neck_hole(body: Body, extra: float, flare: float = 0.0):
    """The neck opening: a cylinder round the neck above a neckline that dips at the front
    (negative inside). flare widens it upwards (a collar standing open)."""
    s = body.s
    r = neck_radius(body, extra)

    def fn(P):
        zc = 1.405 * s + 0.35 * P[:, 1]
        radial = np.hypot(P[:, 0], P[:, 1] - 0.018 * s)
        return np.maximum(radial - r - flare * np.maximum(P[:, 2] - zc, 0.0), zc - P[:, 2])
    return fn


def neckline_heights(body: Body, extra: float, t: float) -> tuple[np.ndarray, np.ndarray]:
    """Height of the garment's neck edge per azimuth (radians, 0 = front): where the
    neck-hole cylinder meets the neckline plane or the shoulders, whichever is higher."""
    s = body.s
    r = neck_radius(body, extra)
    az = np.linspace(-math.pi, math.pi, 73)
    zs = np.linspace(1.49 * s, 1.3 * s, 200)   # below the chin; 1.49 caps the garment
    out = []
    for a in az:
        P = np.stack([np.full_like(zs, r * math.sin(a)), np.full_like(zs, 0.018 * s - r * math.cos(a)), zs], 1)
        inside = np.nonzero(body.field(P) - t * s < 0)[0]
        z_surf = zs[inside[0]] if len(inside) else 0.0
        out.append(max(1.405 * s + 0.35 * P[0, 1], z_surf))
    return az, np.array(out)


def shirt_parts(body: Body, key: str, sleeve: float, hem: float, t: float) -> list[Part]:
    """A shirt or polo: torso and sleeves to `sleeve` metres from the shoulder, and a collar."""
    s = body.s
    lo, hi = body.bbox()
    # the top button is open: a narrow V below the neckline (a polo's placket is shorter)
    v_bottom = 1.36 if key == "polo" else 1.345
    placket = vee(body, v_bottom, 0.004, 0.32)
    region = region_cut(not_(neck_hole(body, 0.02)), below(1.49 * s), above(hem * s),
                        not_(arms_beyond(body, sleeve * s, 0.09 * s)), not_(placket))
    hull = torso_hull(body, hem - 0.04, 1.27, 0.15, 0.13)
    if sleeve > 0.35:
        sleeve_hull(body, sleeve - 0.02, 0.046, 0.036, hull)
    lo2 = np.array([lo[0], lo[1], (hem - 0.03) * s])
    parts = [Part(key, garment(body, t, region, hull, ease=(hem, 0.012) if hem < 0.9 else None), lo2, hi, 0.0045 * s, 2600 if sleeve > 0.35 else 2100,
                  key, covers=region)]
    parts.append(Part(key + "_collar", collar_fn(body, t, 0.02, 0.022 if key == "polo" else 0.026),
                      np.array([-0.15, -0.15, 1.3]) * s, np.array([0.15, 0.12, 1.56]) * s, 0.0018 * s, 700, key))
    return parts


def vee(body: Body, z_bottom: float, half: float, slope: float):
    """A V opening at the front (negative inside): `half` m wide at its bottom, widening by
    `slope` per metre up."""
    s = body.s
    return lambda P: np.maximum.reduce([np.abs(P[:, 0]) - half * s - (P[:, 2] - z_bottom * s) * slope,
                                        P[:, 1] + 0.02 * s, z_bottom * s - P[:, 2]])


def collar_fn(body: Body, t: float, extra: float, height: float):
    """A turned-down collar on the neckline: `height` m at the back, lower towards the front,
    leaning outwards, its two points spreading apart from the open top button."""
    s = body.s
    edge = neckline_heights(body, extra, t)
    inner, outer = neck_hole(body, extra + 0.0015, 0.32), neck_hole(body, extra + 0.0065, 0.32)

    def fn(P):
        az = np.arctan2(P[:, 0], -(P[:, 1] - 0.018 * s))
        z0 = np.interp(az, edge[0], edge[1])
        front = np.clip(np.cos(az), 0.0, 1.0) ** 2
        top = z0 + (height - 0.008 * front) * s
        rise = np.maximum(P[:, 2] - z0, 0.0)
        spread = 0.008 * s + rise * 0.8 - np.abs(P[:, 0])          # positive in the opening
        opening = np.minimum(spread, -P[:, 1] - 0.02 * s)
        return np.maximum.reduce([outer(P), -inner(P), z0 - 0.005 * s - P[:, 2], P[:, 2] - top, opening])
    return fn


def trouser_parts(body: Body, key: str, waist: float, r_hem: float, t: float = 0.007) -> list[Part]:
    s = body.s
    lo, hi = body.bbox()
    no_arms = not_(arms_beyond(body, 0.25 * s, 0.13 * s))
    region = region_cut(below(waist * s, tilt=0.15), above(0.072 * s), no_arms)
    fn = garment(body, t, region, leg_hull(body, 0.085, r_hem), hull_k=0.03)
    return [Part(key, fn, lo, np.array([hi[0], hi[1], (waist + 0.06) * s]), 0.0045 * s, 2200, key,
                 covers=region_cut(below(waist * s, tilt=0.15), above(0.11 * s), no_arms))]


def belt_part(body: Body, z: float) -> Part:
    s = body.s
    def fn(P):
        return np.maximum.reduce([body.field(P) - 0.0135 * s, np.abs(P[:, 2] - z * s) - 0.017 * s, np.abs(P[:, 0]) - 0.2 * s])
    return Part("belt", fn, np.array([-0.25, -0.2, z - 0.05]) * s, np.array([0.25, 0.2, z + 0.05]) * s, 0.0025 * s, 500, "belt")


def shoe_parts(body: Body, boot: bool) -> list[Part]:
    s = body.s
    f = Field()
    for side in (1, -1):
        m = lambda p: body.m(p, side) * s  # noqa: E731
        f.add(rbox(m([0.103, -0.045, 0.014]), np.array([0.042, 0.13, 0.009]) * s, 0.008 * s, z=(0, 0, 1), hint=(1, 0, 0)))
        f.add(cone(m([0.1, 0.06, 0.045]), m([0.105, -0.15, 0.035]), 0.042 * s, 0.034 * s, flat=(1.0, 0.82), hint=(1, 0, 0)), 0.02 * s)
        f.add(ball(m([0.104, -0.12, 0.04]), np.array([0.04, 0.06, 0.032]) * s), 0.025 * s)
        top = 0.17 if boot else 0.105
        f.add(cone(m([0.1, 0.035, 0.05]), m([0.1, 0.03, top]), 0.05 * s, 0.047 * s), 0.02 * s)
    return [Part("shoes", f, np.array([-0.2, -0.24, -0.01]) * s, np.array([0.2, 0.14, 0.2]) * s, 0.0025 * s, 1400,
                 "boot" if boot else "shoe", covers=lambda P: P[:, 2] - (0.12 if boot else 0.08) * s,
                 split=(0.026 * s, "sole"))]


HAIRLINES = {   # (degrees from the front, head-local height of the hairline) per style
    "short": [(0, 0.05), (30, 0.045), (55, 0.03), (80, 0.0), (100, -0.012), (125, -0.045), (180, -0.092)],
    "receding": [(0, 0.062), (22, 0.075), (40, 0.07), (70, 0.012), (95, -0.012), (125, -0.05), (180, -0.088)],
    "buzz": [(0, 0.052), (30, 0.046), (55, 0.03), (80, 0.0), (100, -0.014), (125, -0.05), (180, -0.095)],
    "bob": [(0, 0.052), (40, 0.05), (58, 0.03), (72, -0.115), (180, -0.118)],
    "ponytail": [(0, 0.056), (30, 0.05), (55, 0.034), (80, 0.0), (100, -0.02), (125, -0.06), (180, -0.1)],
}
HAIR_T = {"short": 0.012, "receding": 0.008, "buzz": 0.004, "bob": 0.018, "ponytail": 0.01}


def hair_part(body: Body) -> Part:
    sp, hs, c = body.sp, body.hs, body.head_c
    style = sp.hair_style
    base = Field()
    base.add(ball(body.H(0, 0.012, 0), np.array([0.074, 0.094, 0.093]) * hs))
    base.add(ball(body.H(0, -0.038, 0.03), np.array([0.066, 0.05, 0.055]) * hs), 0.02 * hs)
    base.add(ball(body.H(0, 0.03, -0.07), np.array([0.06, 0.06, 0.05]) * hs), 0.03 * hs)
    if style == "short":
        base.add(ball(body.H(0, -0.01, 0.035), np.array([0.07, 0.088, 0.065]) * hs), 0.03 * hs)
    if style == "bob":
        base.add(ball(body.H(0, 0.014, -0.025), np.array([0.09, 0.104, 0.112]) * hs), 0.04 * hs)
        base.add(ball(body.H(-0.018, -0.07, 0.058), np.array([0.058, 0.03, 0.03]) * hs, z=(0.25, 0, 1)), 0.03 * hs)
    line = np.array(HAIRLINES[style])
    t = HAIR_T[style]
    brows = brow_field(body)
    tail = Field()   # hair pulled back into a tie at the back of the head
    if style == "ponytail":
        tail.add(ball(body.H(0, 0.1, -0.015), np.array([0.03, 0.026, 0.03]) * hs))
        tail.add(cone(body.H(0, 0.11, -0.03), body.H(0, 0.15, -0.21), 0.026 * hs, 0.011 * hs, flat=(1.0, 0.8)), 0.02 * hs)

    def fn(P):
        q = (P - c) / hs
        az = np.degrees(np.abs(np.arctan2(q[:, 0], -q[:, 1])))
        zl = np.interp(az, line[:, 0], line[:, 1])
        if style == "bob":   # a side parting: the fringe sweeps lower on the right
            zl = zl - np.clip(-q[:, 0], 0, 0.05) * 0.5 * (az < 60)
        above_line = q[:, 2] - zl
        thick = (0.0025 + (t - 0.0025) * smoothstep(0.0, 0.03, above_line)) * hs
        d = base(P) - thick
        d = smax(d, -above_line * hs, 0.004 * hs)
        if style == "bob":
            d = smax(d, (-0.118 - q[:, 2]) * hs, 0.012 * hs)
        if tail.ops:
            d = smin(d, tail(P), 0.008 * hs)
        return np.minimum(d, brows(P))

    lo, hi = c + np.array([-0.13, -0.15, -0.25]) * hs, c + np.array([0.13, 0.2, 0.13]) * hs
    return Part("hair", fn, lo, hi, 0.0018 * hs, 2200 if style == "bob" else 1500, "hair", uv="sphere", rigid="Head",
                covers=lambda P: smax(base(P) - 0.002 * hs, -((P[:, 2] - c[2]) / hs - np.interp(
                    np.degrees(np.abs(np.arctan2(P[:, 0] - c[0], -(P[:, 1] - c[1])))), line[:, 0], line[:, 1])) * hs, 0) + 0.006 * hs)


def surface_point(body: Body, p) -> np.ndarray:
    """Move p along -Y onto the body surface (first point outside going forward)."""
    p = np.array(p, float)
    ys = np.linspace(p[1] + 0.05, p[1] - 0.06, 400)
    P = np.repeat(p[None], len(ys), 0)
    P[:, 1] = ys
    f = body.field(P)
    i = int(np.argmax(f > 0.0005 * body.s))
    return P[i]


def brow_field(body: Body) -> Field:
    f, hs = Field(), body.hs
    female = body.sp.sex == "f"
    for sd in (1, -1):
        arch = ((0.011, 0.0135), (0.03, 0.0175), (0.05, 0.0135)) if female else ((0.012, 0.011), (0.032, 0.0145), (0.051, 0.0115))
        pts = [surface_point(body, body.H(sd * x, -0.05, z)) for x, z in arch]
        r = (0.0026 if female else 0.0034) * hs
        f.add(cone(pts[0], pts[1], r, r * 1.05, flat=(1.0, 0.5), hint=(0, 0, 1)), 0.002 * hs)
        f.add(cone(pts[1], pts[2], r * 1.05, r * 0.6, flat=(1.0, 0.5), hint=(0, 0, 1)), 0.002 * hs)
    return f


def shoulder_cut(body: Body, inset: float, z_from: float):
    """Beyond the shoulder seam (negative inside): where a sleeveless garment or a set-in
    sleeve ends, so no garment caps the top of the arm like a wing."""
    s = body.s
    xs = body.SJ[0] - inset * s
    return lambda P: np.maximum(xs - np.abs(P[:, 0]), z_from * s - P[:, 2])


def vest_parts(body: Body) -> list[Part]:
    """EN ISO 20471 class 2 style vest: sleeveless, two 5 cm retroreflective bands."""
    s = body.s
    lo, hi = body.bbox()
    near_arm, far_arm = arms_beyond(body, -0.02 * s, 0.075 * s), arms_beyond(body, 0.2 * s, 0.13 * s)
    seam = shoulder_cut(body, 0.022, 1.2)
    holes = lambda P: np.minimum.reduce([near_arm(P), far_arm(P), seam(P)])  # noqa: E731
    region = region_cut(not_(neck_hole(body, 0.03)), below(1.5 * s), above(0.9 * s), not_(holes), not_(vee(body, 1.28, 0.03, 0.3)))
    hull = torso_hull(body, 0.9, 1.25, 0.156, 0.13, depth=0.74)
    return [Part("vest", garment(body, 0.013, region, hull, hull_k=0.03, hem_k=0.005, ease=(0.9, 0.006)),
                 np.array([lo[0], lo[1], 0.85 * s]), np.array([hi[0], hi[1], 1.56 * s]), 0.004 * s, 1800, "hivis", uv="cyl")]


def blazer_parts(body: Body) -> list[Part]:
    """A single-breasted jacket, open: fitted sleeves, the lapels a raised fold along the V."""
    s = body.s
    lo, hi = body.bbox()
    v_from = 1.08
    region = region_cut(not_(neck_hole(body, 0.026)), below(1.5 * s), above(0.83 * s),
                        not_(arms_beyond(body, 0.535 * s, 0.1 * s)), not_(vee(body, v_from, 0.004, 0.2)))
    hull = torso_hull(body, 0.86, 1.26, 0.156, 0.13, depth=0.72)
    sleeve_hull(body, 0.5, 0.047, 0.038, hull)
    jacket = garment(body, 0.013, region, hull, hull_k=0.035, hem_k=0.005, ease=(0.83, 0.008))

    def lapel(P):   # 1 on a strip along each edge of the V, widening towards the shoulders
        x, z = np.abs(P[:, 0]), P[:, 2]
        edge = 0.004 * s + (z - v_from * s) * 0.2
        width = 0.011 * s + np.clip(z - v_from * s, 0, None) * 0.11
        band = np.maximum.reduce([np.abs(x - edge - width) - width, (v_from + 0.01) * s - z, z - 1.43 * s])
        return smoothstep(0.002 * s, -0.002 * s, band) * (P[:, 1] < 0)

    fn = lambda P: jacket(P) - 0.007 * s * lapel(P)  # noqa: E731
    return [Part("blazer", fn, np.array([lo[0], lo[1], 0.78 * s]), hi, 0.004 * s, 3400, "blazer", covers=region)]


def helmet_part(body: Body) -> Part:
    hs = body.hs
    f = Field()
    f.add(ball(body.H(0, 0.006, 0.006), np.array([0.096, 0.118, 0.106]) * hs))
    f.add(ball(body.H(0, -0.02, 0.024), np.array([0.112, 0.142, 0.012]) * hs), 0.01 * hs)
    f.add(cone(body.H(0, -0.09, 0.07), body.H(0, 0.1, 0.07), 0.016 * hs, 0.016 * hs, hint=(1, 0, 0)), 0.03 * hs)
    cut = body.H(0, 0, 0.018)

    def fn(P):
        d = smax(f(P), cut[2] - 0.006 * hs - P[:, 2], 0.004 * hs)
        return smax(d, -(np.linalg.norm((P - body.H(0, 0.006, -0.01)) / (np.array([0.086, 0.106, 0.098]) * hs), axis=1) - 1) * 0.08 * hs, 0.002)
    return Part("helmet", fn, body.H(-0.15, -0.18, -0.02), body.H(0.15, 0.16, 0.13), 0.0025 * hs, 1100, "helmet", rigid="Head")


def outfit_parts(body: Body) -> list[Part]:
    o = body.sp.outfit
    if o == "business":
        return (shirt_parts(body, "polo", 0.16, 0.86, 0.011)
                + trouser_parts(body, "chinos", 0.95, 0.058) + shoe_parts(body, boot=False))
    if o == "shirt":
        return (shirt_parts(body, "shirt", 0.565, 0.95, 0.005)
                + trouser_parts(body, "trousers", 1.02, 0.062) + [belt_part(body, 1.0)] + shoe_parts(body, boot=False))
    if o == "manager":
        return (shirt_parts(body, "shirt", 0.565, 0.95, 0.005) + blazer_parts(body)
                + trouser_parts(body, "trousers", 1.02, 0.062) + [belt_part(body, 1.0)] + shoe_parts(body, boot=False))
    if o == "monteur":
        return (shirt_parts(body, "workshirt", 0.565, 0.95, 0.006) + vest_parts(body)
                + trouser_parts(body, "worktrousers", 1.02, 0.07, t=0.009) + [belt_part(body, 1.0)]
                + shoe_parts(body, boot=True) + ([helmet_part(body)] if body.sp.helmet else []))
    raise ValueError(f"unknown outfit {o!r}")


# =========================================================================== textures

TEX_SIZE = {"pique": 0.1, "denim": 0.18, "twill": 0.15, "oxford": 0.12, "wool": 0.2, "leather": 0.15, "hair": 0.12}


def _png(name: str, arr: np.ndarray) -> None:
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8)).save(TEX / f"{name}.png", optimize=True)


def _normal(name: str, height: np.ndarray, strength: float) -> None:
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5
    dy = (np.roll(height, 1, 0) - np.roll(height, -1, 0)) * 0.5
    n = np.stack([-dx * strength, -dy * strength, np.ones_like(height)], -1)
    _png(f"{name}_normal", n / np.linalg.norm(n, axis=-1, keepdims=True) * 0.5 + 0.5)


def make_textures() -> None:
    """Tileable fabric, hair and leather maps (greyscale: the material colour tints them),
    the hi-vis band layout and the Voltana logo patch."""
    TEX.mkdir(parents=True, exist_ok=True)
    n = TEX_PX
    k = n / 512   # weave frequencies were tuned at 512 px: keep 4+ pixels per thread
    y, x = np.mgrid[0:n, 0:n] / n
    mottle = noise(n, 3, beta=2.5, low=1.0, high=8)

    cells = round(52 * k)
    pq = (0.5 + 0.5 * np.cos(2 * np.pi * x * cells) * np.cos(2 * np.pi * y * cells * 1.3)) ** 2
    pq = 0.7 * pq + 0.3 * noise(n, 11, beta=0.5)
    _png("pique_albedo", np.repeat((0.86 + 0.08 * (pq - 0.5) + 0.1 * (mottle - 0.5))[..., None], 3, -1))
    _normal("pique", pq, 6.0)

    tw = 0.5 + 0.5 * np.sin(2 * np.pi * (x + y) * round(90 * k))
    thread = noise(n, 21, beta=1.0, stretch=(1, 14))
    h = 0.75 * tw + 0.25 * thread
    _png("twill_albedo", np.repeat((0.84 + 0.08 * (h - 0.5) + 0.12 * (mottle - 0.5))[..., None], 3, -1))
    _normal("twill", h, 4.0)

    fade = noise(n, 33, beta=2.2, stretch=(6, 1), low=1, high=20)
    weft = np.clip(tw * 0.6 + thread * 0.6 - 0.35, 0, 1)
    indigo, white = np.array([0.13, 0.2, 0.36]), np.array([0.62, 0.66, 0.74])
    t = np.clip(0.3 * weft + 0.35 * (fade - 0.5) + 0.06, 0, 1)
    _png("denim_albedo", indigo * (1 - t[..., None]) + white * t[..., None])
    _normal("denim", h, 5.0)

    ox = 0.5 + 0.25 * np.sin(2 * np.pi * x * round(120 * k)) + 0.25 * np.sin(2 * np.pi * y * round(120 * k))
    _png("oxford_albedo", np.repeat((0.9 + 0.05 * (ox - 0.5) + 0.06 * (mottle - 0.5))[..., None], 3, -1))
    _normal("oxford", ox, 2.0)

    wool = noise(n, 41, beta=1.2)
    herring = np.abs(((x * 40 * k) % 1.0) - 0.5) * 2
    hb = 0.5 + 0.5 * np.sin(2 * np.pi * (y * 140 * k + np.where((x * 40 * k) % 2 < 1, 1, -1) * x * 140 * k))
    _png("wool_albedo", np.repeat((0.86 + 0.07 * (wool - 0.5) + 0.05 * (hb - 0.5) + 0.06 * (mottle - 0.5))[..., None], 3, -1))
    _normal("wool", 0.6 * wool + 0.4 * hb * herring, 3.0)

    strands = noise(n, 51, beta=1.4, stretch=(1, 40))
    clump = noise(n, 52, beta=2.0, stretch=(1, 10), high=24)
    hh = 0.65 * strands + 0.35 * clump
    _png("hair_albedo", np.repeat((0.62 + 0.62 * (hh - 0.5) + 0.15 * (mottle - 0.5))[..., None], 3, -1))
    _normal("hair", hh, 5.0)

    grain = noise(n, 61, beta=1.6)
    crease = noise(n, 62, beta=2.0, stretch=(5, 1), high=40)
    lh = 0.6 * grain + 0.4 * crease
    _png("leather_albedo", np.repeat((0.86 + 0.14 * (lh - 0.5))[..., None], 3, -1))
    _normal("leather", lh, 3.0)

    # hi-vis: u wraps around the torso (0.25 m per tile), v spans the vest from hem (0) to top (1)
    knit = noise(n, 71, beta=0.6)
    orange = np.array([1.0, 0.36, 0.04]) * (0.93 + 0.07 * knit[..., None]) * (0.97 + 0.06 * (mottle[..., None] - 0.5))
    silver = np.array([0.74, 0.76, 0.78]) * (0.9 + 0.1 * noise(n, 72, beta=0.3)[..., None])
    vv = 1.0 - y   # image rows run top-down
    band = ((vv > 0.07) & (vv < 0.155)) | ((vv > 0.34) & (vv < 0.425))
    _png("hivis_albedo", np.where(band[..., None], silver, orange))
    _normal("hivis", knit * 0.5 + band * 0.6, 3.0)

    img = Image.new("RGB", (256, 128), (14, 78, 160))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([3, 3, 252, 124], 16, outline=(230, 236, 245), width=4)
    _logo(d, 52, 64, 36)
    d.text((98, 30), "Voltana", font=_font(40, bold=True), fill=(255, 255, 255))
    d.text((100, 78), "Netbeheer", font=_font(24), fill=(190, 222, 255))
    img.save(TEX / "logo_albedo.png", optimize=True)


# =========================================================================== materials

MATS: dict[str, bpy.types.Material] = {}


def material(name: str, color=(255, 255, 255), tex: str | None = None, rough: float = 0.75,
             metal: float = 0.0, vcol: bool = False) -> bpy.types.Material:
    """A Principled material the glTF exporter maps one to one: a plain colour
    (baseColorFactor), or the vertex colour as albedo (skin). A texture is not linked here (the
    exporter would embed it, or with images off drop the colour): its name goes in the
    material's extras, {"texture": tex}, and the game's import script lays the shared texture
    under the colour. So the Cycles previews show the colours without the weave."""
    mat = bpy.data.materials.new(name)
    mat.use_backface_culling = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if vcol:
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Col"
        nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = srgb(*color)
    if tex:
        mat["texture"] = tex
    MATS[name] = mat
    return mat


def make_materials(sp: Spec) -> dict[str, tuple[str, str | None]]:
    """Materials of one person, named per person (colours differ); returns key -> (material, texture)."""
    c = {**GARMENT_COLORS, **sp.colors}
    p = sp.name
    spec = {
        "skin": dict(vcol=True, rough=0.55),
        "hair": dict(color=sp.hair_color, tex="hair", rough=0.5),
        "polo": dict(color=c["polo"], tex="pique", rough=0.85),
        "chinos": dict(color=c["chinos"], tex="twill", rough=0.85),
        "shirt": dict(color=c["shirt"], tex="oxford", rough=0.8),
        "trousers": dict(color=c["trousers"], tex="wool", rough=0.8),
        "blazer": dict(color=c["blazer"], tex="wool", rough=0.8),
        "workshirt": dict(color=c["workshirt"], tex="twill", rough=0.85),
        "worktrousers": dict(color=c["worktrousers"], tex="twill", rough=0.85),
        "belt": dict(color=c["belt"], tex="leather", rough=0.45),
        "shoe": dict(color=c["shoe"], tex="leather", rough=0.4),
        "boot": dict(color=c["boot"], tex="leather", rough=0.55),
        "sole": dict(color=c["sole"], rough=0.8),
        "hivis": dict(tex="hivis", rough=0.7),
        "helmet": dict(color=c["helmet"], rough=0.3),
        "logo": dict(tex="logo", rough=0.7),
        "sclera": dict(color=(222, 214, 204), rough=0.15),
        "iris": dict(color=sp.eye_color, rough=0.1),
        "pupil": dict(color=(8, 8, 10), rough=0.1),
        "frame": dict(color=(40, 40, 46), rough=0.3, metal=0.5),
    }
    out = {}
    for key, kw in spec.items():
        out[key] = (material(f"{p}__{key}", **kw).name, kw.get("tex"))
    return out


# =========================================================================== mesh objects

def new_object(name: str, verts, faces, coll) -> bpy.types.Object:
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], [tuple(f) for f in faces])
    me.validate()
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    return ob


def decimate(ob: bpy.types.Object, tris: int, detail=None, share: float = 0.4) -> None:
    """Collapse-decimate towards `tris` triangles (X symmetry is off: it flips faces).
    detail(V) -> bool per vertex marks a region (the face) that gets `share` of the budget."""
    if detail is None:
        _collapse(ob, tris)
    else:   # a decimate vertex group is a mask: only its vertices collapse
        _collapse(ob, tris * (1 - share), lambda V: ~detail(V))
        _collapse(ob, tris * share, detail)
    bm = bmesh.new()   # collapsing can leave zero-area faces; the glTF exporter flags those
    bm.from_mesh(ob.data)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-6, edges=bm.edges)
    bm.to_mesh(ob.data)
    bm.free()
    ob.data.validate()
    ob.data.shade_smooth()


def _collapse(ob: bpy.types.Object, tris: float, mask=None) -> None:
    """Collapse until `tris` triangles remain (in `mask`'s faces, when given)."""
    for _ in range(4):
        n = len(ob.data.polygons)
        if mask is not None:
            m = mask(verts_of(ob))
            vg = ob.vertex_groups.get("mask") or ob.vertex_groups.new(name="mask")
            vg.add(np.nonzero(m)[0].tolist(), 1.0, "REPLACE")
            vg.remove(np.nonzero(~m)[0].tolist())
            starts = np.empty(n, int)
            ob.data.polygons.foreach_get("loop_start", starts)
            lv = np.empty(len(ob.data.loops), int)
            ob.data.loops.foreach_get("vertex_index", lv)
            inside = int(m[lv[starts]].sum())    # faces by their first corner
        else:
            inside = n
        if inside <= tris * 1.05:
            break
        mod = ob.modifiers.new("decimate", "DECIMATE")
        mod.ratio = (n - inside + tris) / n
        if mask is not None:
            mod.vertex_group = "mask"
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        ob.modifiers.clear()
        old = ob.data
        ob.data = me
        bpy.data.meshes.remove(old)
    if "mask" in ob.vertex_groups:
        ob.vertex_groups.remove(ob.vertex_groups["mask"])


def verts_of(ob) -> np.ndarray:
    v = np.empty(len(ob.data.vertices) * 3)
    ob.data.vertices.foreach_get("co", v)
    return v.reshape(-1, 3)


def normals_of(ob) -> np.ndarray:
    v = np.empty(len(ob.data.vertices) * 3)
    ob.data.vertices.foreach_get("normal", v)
    return v.reshape(-1, 3)


def delete_faces(ob, covered: np.ndarray) -> None:
    """Delete faces whose vertices are all covered."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    dead = [f for f in bm.faces if all(covered[v.index] for v in f.verts)]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(ob.data)
    bm.free()


def set_uvs(ob, mode: str, tile: float, center=(0, 0, 0), zspan=(0.0, 1.0)) -> None:
    """Per-loop UVs. box: per face along its dominant axis; cyl: around Z (u wraps,
    v = (z - zspan[0]) / span); sphere: azimuth / polar angle about center. tile = metres per repeat."""
    me = ob.data
    uv = me.uv_layers.new(name="UVMap")
    V = verts_of(ob)
    nl = len(me.loops)
    lv = np.empty(nl, int)
    me.loops.foreach_get("vertex_index", lv)
    starts = np.empty(len(me.polygons), int)
    me.polygons.foreach_get("loop_start", starts)
    counts = np.empty(len(me.polygons), int)
    me.polygons.foreach_get("loop_total", counts)
    face_of_loop = np.repeat(np.arange(len(me.polygons)), counts)
    P = V[lv]
    c = np.asarray(center, float)
    if mode == "box":
        fn = np.empty(len(me.polygons) * 3)
        me.polygons.foreach_get("normal", fn)
        ax = np.abs(fn.reshape(-1, 3)).argmax(1)[face_of_loop]
        u = np.where(ax == 0, P[:, 1], P[:, 0])
        v = np.where(ax == 2, P[:, 1], P[:, 2])
        UV = np.stack([u, v], 1) / tile
    else:
        q = P - c
        az = np.arctan2(q[:, 0], -q[:, 1])           # 0 at the front, wraps at the back
        if mode == "cyl":
            u = az * 0.16 / tile
            v = (P[:, 2] - zspan[0]) / (zspan[1] - zspan[0])
        else:
            pol = np.arccos(np.clip(q[:, 2] / np.linalg.norm(q, axis=1), -1, 1))
            u, v = az * 0.09 / tile, -pol * 0.09 / tile
        period = 2 * math.pi * (0.16 if mode == "cyl" else 0.09) / tile
        # faces across the wrap: lift their low side by one period (textures tile in u)
        lo_u = np.minimum.reduceat(u, starts)
        hi_u = np.maximum.reduceat(u, starts)
        wrap = (hi_u - lo_u)[face_of_loop] > period / 2
        u = np.where(wrap & (u < 0), u + period, u)
        UV = np.stack([u, v], 1)
    uv.data.foreach_set("uv", UV.ravel())


def assign_weights(ob, weights: dict) -> None:
    for name, w in weights.items():
        vg = ob.vertex_groups.new(name=name)
        for i in np.nonzero(w > 0)[0]:
            vg.add([int(i)], float(w[i]), "REPLACE")


def eye_mesh(name: str, r: float) -> bpy.types.Mesh:
    """An eyeball with its pole on -Y: rings at chosen latitudes so pupil (0-9 deg) and iris
    (9-30 deg) get their own faces; materials 0 sclera, 1 iris, 2 pupil."""
    lats = [0, 9, 16, 24, 30, 42, 60, 80, 105, 135, 160, 180]
    seg = 18
    bm = bmesh.new()
    rings = []
    for la in lats:
        a = math.radians(la)
        if la in (0, 180):
            rings.append([bm.verts.new((0, -r * math.cos(a), 0))])
            continue
        rings.append([bm.verts.new((r * math.sin(a) * math.cos(t), -r * math.cos(a), r * math.sin(a) * math.sin(t)))
                      for t in np.linspace(0, 2 * math.pi, seg, endpoint=False)])
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        mat = 2 if lats[k + 1] <= 9 else 1 if lats[k + 1] <= 30 else 0
        for i in range(seg):
            j = (i + 1) % seg
            if len(a) == 1:
                f = bm.faces.new((a[0], b[j], b[i]))
            elif len(b) == 1:
                f = bm.faces.new((a[i], a[j], b[0]))
            else:
                f = bm.faces.new((a[i], a[j], b[j], b[i]))
            f.material_index = mat
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    for f in me.polygons:
        f.use_smooth = True
    return me


def glasses_mesh(body: Body, name: str) -> bpy.types.Mesh:
    """Thin rectangular frames: rims, bridge and temples as beveled curves."""
    hs, H = body.hs, body.H
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = 0.0014 * hs
    cu.bevel_resolution = 0
    y_front = -0.096
    for sd in (1, -1):
        sp = cu.splines.new("POLY")
        cx, cz, w, h = 0.033 * sd, -0.021, 0.025, 0.0165
        pts = []
        for k in range(20):
            a = 2 * math.pi * k / 20
            ca, sa = math.cos(a), math.sin(a)
            x = cx + w * np.sign(ca) * abs(ca) ** 0.45
            z = cz + h * np.sign(sa) * abs(sa) ** 0.45
            pts.append(H(x, y_front + 0.004 * abs(x - cx) / w, z))
        sp.points.add(len(pts) - 1)
        for p, co in zip(sp.points, pts):
            p.co = (*co, 1.0)
        sp.use_cyclic_u = True
        t = cu.splines.new("POLY")
        tp = [H(sd * 0.058, y_front + 0.004, -0.014), H(sd * 0.07, -0.06, -0.013), H(sd * 0.071, 0.0, -0.017),
              H(sd * 0.066, 0.016, -0.03)]
        t.points.add(len(tp) - 1)
        for p, co in zip(t.points, tp):
            p.co = (*co, 1.0)
    b = cu.splines.new("POLY")
    bp = [H(-0.0085, y_front, -0.013), H(-0.004, y_front - 0.002, -0.0095), H(0.004, y_front - 0.002, -0.0095),
          H(0.0085, y_front, -0.013)]
    b.points.add(len(bp) - 1)
    for p, co in zip(b.points, bp):
        p.co = (*co, 1.0)
    ob = bpy.data.objects.new("tmp_glasses", cu)
    bpy.context.scene.collection.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    me.name = name
    return me


def patch_mesh(name: str, target, center, w: float, h: float, offset: float) -> bpy.types.Mesh:
    """A logo patch (UVs 0..1) w x h metres round `center` (x, z), facing -Y, laid onto
    target's front by ray casts so it follows a curved surface (a helmet, a chest)."""
    from mathutils.bvhtree import BVHTree
    bvh = BVHTree.FromObject(target, bpy.context.evaluated_depsgraph_get())
    nu, nv = 8, 4
    verts, uvs = [], []
    for j in range(nv + 1):
        for i in range(nu + 1):
            u, v = i / nu, j / nv
            hit, normal, _, _ = bvh.ray_cast(Vector((center[0] + (u - 0.5) * w, -0.6, center[1] + (v - 0.5) * h)), Vector((0, 1, 0)))
            if hit is None:
                raise RuntimeError(f"logo ray missed {target.name}")
            verts.append(hit + normal * offset)
            uvs.append((u, v))
    faces = [(j * (nu + 1) + i, j * (nu + 1) + i + 1, (j + 1) * (nu + 1) + i + 1, (j + 1) * (nu + 1) + i)
             for j in range(nv) for i in range(nu)]
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    uv = me.uv_layers.new(name="UVMap")
    lv = [lp.vertex_index for lp in me.loops]
    uv.data.foreach_set("uv", [c for k in lv for c in uvs[k]])
    me.shade_smooth()
    return me


# =========================================================================== skin colour

def skin_colors(body: Body, V: np.ndarray, N: np.ndarray) -> np.ndarray:
    """Linear RGBA per vertex: tone, lips, blush, stubble, baked ambient occlusion."""
    sp, hs, H = body.sp, body.hs, body.H
    base = np.array(srgb(*sp.skin)[:3])
    col = np.repeat(base[None], len(V), 0)

    def near(c, r):
        q = (V - c) / (np.asarray(r) * hs)
        return np.exp(-np.sum(q * q, 1))

    lips = np.clip(near(H(0, -0.086, -0.08), (0.022, 0.012, 0.007)) + near(H(0, -0.083, -0.093), (0.02, 0.012, 0.0085)), 0, 1)
    lip_col = base * np.array([0.82, 0.5, 0.5]) * (1.05 if sp.sex == "f" else 1.0)
    col = col * (1 - lips[:, None]) + lip_col * lips[:, None]
    mouth = near(H(0, -0.092, -0.0865), (0.024, 0.02, 0.0022))
    col *= 1 - 0.55 * mouth[:, None]
    lashes = sum(near(H(sd * 0.033, -0.077, -0.0153), (0.016, 0.012, 0.0022)) for sd in (1, -1))
    col *= 1 - 0.6 * np.clip(lashes, 0, 1)[:, None]   # the upper lash line: eyes read from afar
    blush = sum(near(H(sd * 0.045, -0.06, -0.045), (0.022, 0.03, 0.02)) for sd in (1, -1))
    blush += near(H(0, -0.105, -0.05), (0.012, 0.02, 0.012)) + sum(near(H(sd * 0.078, 0.015, -0.022), (0.02, 0.03, 0.035)) for sd in (1, -1))
    col *= 1 + np.clip(blush, 0, 1)[:, None] * np.array([0.04, -0.07, -0.06])
    if sp.stubble:   # beard shadow: jaw and chin below the mouth corners, and the upper lip
        q = (V - body.head_c) / hs
        jaw = smoothstep(-0.07, -0.095, q[:, 2]) * smoothstep(0.03, -0.01, q[:, 1]) * smoothstep(-0.13, -0.11, q[:, 2])
        moustache = near(H(0, -0.088, -0.071), (0.022, 0.02, 0.006))
        beard = np.clip(jaw + moustache, 0, 1) * (1 - lips)
        col *= 1 - beard[:, None] * sp.stubble * np.array([0.22, 0.2, 0.16])
    # ambient occlusion from the SDF (Quilez): sample along the normal, compare distances
    ao = np.zeros(len(V))
    for i in range(1, 6):
        dist = 0.004 * i * body.s
        ao += (dist - body.field(V + N * dist)) / (2 ** i)
    ao = np.clip(1 - 8.0 * ao / body.s, 0.68, 1.0)
    col *= ao[:, None]
    return np.concatenate([col, np.ones((len(V), 1))], 1)


# =========================================================================== the rig and its actions

def build_rig(body: Body, coll) -> bpy.types.Object:
    arm = bpy.data.armatures.new(f"{body.sp.name}_rig")
    ob = bpy.data.objects.new("Rig", arm)
    coll.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent) in body.bones.items():
        eb = arm.edit_bones.new(name)
        eb.head, eb.tail = head, tail
        eb.roll = 0.0
        if parent:
            eb.parent = arm.edit_bones[parent]
        eb.use_deform = name != "Root"
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in ob.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return ob


def rot_x(deg):
    return Quaternion((1, 0, 0), math.radians(deg))


def rot_z(deg):
    return Quaternion((0, 0, 1), math.radians(deg))


def fwd(deg):
    """Swing a hanging bone forward (its end towards -Y) by deg."""
    return rot_x(-deg)


def lean(deg):
    """Tip an upright bone (spine, neck, head) forward by deg: the opposite sense of fwd."""
    return rot_x(deg)


def periodic_bump(t, center, width):
    d = (t - center + 0.5) % 1.0 - 0.5
    return math.exp(-(d / width) ** 2)


def base_arms(body: Body) -> dict:
    """Arms down from the A-pose, elbows slightly bent, palms to the thighs."""
    out = {}
    for side in (1, -1):
        d = Vector(body.m(body.d, side))
        down = Vector((side * math.sin(math.radians(7)), 0.02, -math.cos(math.radians(7)))).normalized()
        out[side] = (d.rotation_difference(down), d.cross(Vector((0, -1, 0))).normalized())
    return out


STRIDE = 30.0   # thigh swing (degrees each way)
DUTY = 0.6      # share of a stride a foot is on the floor (human walking: ~0.6)


def stride_angle(t: float) -> float:
    """The thigh's swing (degrees, + forward) through one stride: linear from front to back
    while the foot is down (0..DUTY), then a smooth swing forward."""
    if t < DUTY:
        return STRIDE * (1 - 2 * t / DUTY)
    return STRIDE * (2 * float(smoothstep(0.0, 1.0, (t - DUTY) / (1 - DUTY))) - 1)


def pose_walk(body: Body, t: float) -> tuple[dict, Vector]:
    """A brisk walk (a long stride, 1.25 strides a second). The stance sweeps the thigh back
    at an even rate, so a planted foot moves at one speed the game can match (no slide)."""
    s = body.s
    q, arms = {}, base_arms(body)
    for side, phase in ((1, 0.0), (-1, 0.5)):
        tt = (t + phase) % 1.0
        name = lambda b: body.side_name(side, b)  # noqa: E731
        thigh = stride_angle(tt) + 3
        knee = 12 * periodic_bump(tt, 0.1, 0.08) + 58 * periodic_bump(tt, 0.78, 0.1) + 4
        toe_off = 18 * periodic_bump(tt, 0.58, 0.05)
        heel = -8 * periodic_bump(tt, 0.0, 0.05)
        q[name("UpperLeg")] = fwd(thigh)
        q[name("LowerLeg")] = rot_x(knee)
        q[name("Foot")] = rot_x(thigh - knee + toe_off + heel)
        down, elbow_axis = arms[side]
        swing = -16 * math.cos(2 * math.pi * tt) - 2
        q[name("UpperArm")] = fwd(swing) @ down
        q[name("LowerArm")] = Quaternion(elbow_axis, math.radians(11 + 8 * max(0.0, -math.cos(2 * math.pi * tt))))
        q[name("Hand")] = Quaternion()
    yaw = 6 * math.cos(2 * math.pi * t)
    q["Hips"] = rot_z(-yaw) @ fwd(-2)
    q["Spine"] = rot_z(yaw * 0.6) @ fwd(3)
    q["Chest"] = rot_z(yaw * 0.6)
    q["Neck"] = rot_z(-yaw * 0.3)
    q["Head"] = Quaternion()
    bob = (-0.032 + 0.016 * (1 - math.cos(4 * math.pi * t))) * s
    return q, Vector((0, 0, bob))


def pose_idle(body: Body, t: float) -> tuple[dict, Vector]:
    s = body.s
    q, arms = {}, base_arms(body)
    breath = math.sin(2 * math.pi * t * 1)       # one breath per loop of 4 s
    sway = math.sin(2 * math.pi * t)
    for side in (1, -1):
        name = lambda b: body.side_name(side, b)  # noqa: E731
        down, elbow_axis = arms[side]
        q[name("UpperArm")] = fwd(1.5 * breath + 2) @ down
        q[name("LowerArm")] = Quaternion(elbow_axis, math.radians(12 + 1.5 * breath))
        q[name("Hand")] = Quaternion()
        q[name("Shoulder")] = rot_x(0.6 * breath)
        q[name("UpperLeg")] = fwd(0.0)
        q[name("LowerLeg")] = rot_x(1.5)
        q[name("Foot")] = rot_x(-1.5)
    q["Hips"] = Quaternion((0, 1, 0), math.radians(1.2 * sway))
    q["Spine"] = fwd(1.0 * breath) @ Quaternion((0, 1, 0), math.radians(-0.8 * sway))
    q["Chest"] = fwd(0.8 * breath)
    q["Neck"] = Quaternion((0, 1, 0), math.radians(-0.6 * sway))
    q["Head"] = rot_z(4 * math.sin(2 * math.pi * t * 2 + 0.7)) @ fwd(2)
    return q, Vector((0.006 * sway * s, 0, -0.004 * s * (1 - abs(sway))))


SEAT_HIP = 0.6    # hip joint height (m) on an office chair (seat top 0.52 m)
SEAT_BACK = 0.05  # hip joint behind the chair's centre (m): the knees go under the desk


def pose_sit(body: Body, t: float) -> tuple[dict, Vector]:
    """Seated at a desk, typing, glancing between two screens (4 s). The person's origin is
    the chair's: shins vertical, feet flat on the floor whatever the height."""
    q, arms = {}, base_arms(body)
    thigh = math.degrees(math.acos(float(np.clip((SEAT_HIP - body.K[2]) / (body.HJ[2] - body.K[2]), 0.0, 1.0))))
    typing = smoothstep(0.0, 0.05, t) * smoothstep(0.75, 0.68, t)   # a burst, then a pause at the mouse
    for side in (1, -1):
        name = lambda b: body.side_name(side, b)  # noqa: E731
        q[name("UpperLeg")] = fwd(thigh) @ rot_z(side * 4)
        q[name("LowerLeg")] = rot_x(thigh)
        q[name("Foot")] = Quaternion()
        down, elbow_axis = arms[side]
        d = Vector(body.m(body.d, side))
        tap = math.sin(2 * math.pi * (t * 14 + (0.25 if side > 0 else 0.0)))
        q[name("UpperArm")] = fwd(36) @ down   # the chest's forward lean swings the arms back by 12
        # forearm forward over the keyboard, turned palm-down (half in the forearm, half the wrist)
        q[name("LowerArm")] = Quaternion(elbow_axis, math.radians(60 + 1.5 * tap * typing)) @ Quaternion(d, math.radians(side * 45))
        q[name("Hand")] = Quaternion(elbow_axis, math.radians(-8 + 5 * tap * typing)) @ Quaternion(d, math.radians(side * 40))
    look = 7 * math.sin(2 * math.pi * t)
    q["Hips"] = Quaternion()
    q["Spine"] = lean(8)
    q["Chest"] = lean(4 + 0.8 * math.sin(2 * math.pi * t))
    q["Neck"] = lean(-4)
    q["Head"] = rot_z(look) @ lean(-2)
    return q, Vector((0, SEAT_BACK, SEAT_HIP - body.HJ[2]))


def pose_talk(body: Body, t: float) -> tuple[dict, Vector]:
    """Standing and explaining (3 s): the right hand opens palm-up twice, then the left once;
    the head nods with the words, the weight shifts."""
    q, hip = pose_idle(body, t)
    arms = base_arms(body)
    for side, (start, end, beats) in ((-1, (0.0, 0.62, 2)), (1, (0.58, 1.0, 1))):
        name = lambda b: body.side_name(side, b)  # noqa: E731
        down, elbow_axis = arms[side]
        d = Vector(body.m(body.d, side))
        on = smoothstep(start, start + 0.12, t) * smoothstep(end, end - 0.12, t)
        beat = 0.5 - 0.5 * math.cos(2 * math.pi * beats * (t - start) / (end - start))
        q[name("UpperArm")] = fwd(4 + on * (14 + 6 * beat)) @ down
        q[name("LowerArm")] = Quaternion(elbow_axis, math.radians(12 + on * (52 + 14 * beat))) @ Quaternion(d, math.radians(-side * 50 * on))
        q[name("Hand")] = Quaternion(elbow_axis, math.radians(-12 * on * beat))
    q["Head"] = fwd(2 + 4 * max(0.0, math.sin(2 * math.pi * t * 3))) @ rot_z(5 * math.sin(2 * math.pi * t))
    q["Chest"] = rot_z(3 * math.sin(2 * math.pi * t)) @ q["Chest"]
    return q, hip


def with_stoop(q: dict, stoop: float) -> dict:
    """Age in the posture: the back rounds and the head comes forward, the eyes level."""
    if stoop:
        for bone, deg in (("Spine", 5), ("Chest", 9), ("Neck", 8), ("Head", -15)):
            q[bone] = lean(deg * stoop) @ q.get(bone, Quaternion())
    return q


def walk_pace(rig, action: bpy.types.Action, frames: int) -> float:
    """The walk's ground speed (m/s): the ankle's travel front to back over the time a foot
    is down (DUTY of the cycle). Moving the person at this speed keeps the feet on the floor.
    (The game measures it the same way from the imported animation; this is the build's report.)"""
    left = rig.pose.bones["LeftFoot"]
    ys = []
    show_pose(rig, action.name, 1)
    for f in range(1, frames + 1):
        bpy.context.scene.frame_set(f)
        ys.append(left.head.y)
    rig.animation_data.action = None
    for tr in rig.animation_data.nla_tracks:
        tr.mute = False
    return (max(ys) - min(ys)) / (DUTY * frames / bpy.context.scene.render.fps)


def bake_action(rig, body: Body, name: str, pose_fn, frames: int) -> bpy.types.Action:
    rest = {b.name: b.matrix_local.to_quaternion() for b in rig.data.bones}
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    for f in range(frames + 1):
        q, hip = pose_fn(body, (f % frames) / frames)
        q = with_stoop(q, body.sp.stoop)
        for pb in rig.pose.bones:
            r = rest[pb.name]
            pb.rotation_quaternion = r.inverted() @ q.get(pb.name, Quaternion()) @ r
            pb.keyframe_insert("rotation_quaternion", frame=f + 1)
        hb = rig.pose.bones["Hips"]
        hb.location = rest["Hips"].inverted() @ hip
        hb.keyframe_insert("location", frame=f + 1)
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, act)
    rig.animation_data.action = None
    return act


def show_pose(rig, action_name: str, frame: int) -> None:
    """Put the rig in a frame of an action (for the preview renders)."""
    for tr in rig.animation_data.nla_tracks:
        tr.mute = True
    rig.animation_data.action = bpy.data.actions[action_name]
    if hasattr(rig.animation_data, "action_suitable_slots") and rig.animation_data.action_suitable_slots:
        rig.animation_data.action_slot = rig.animation_data.action_suitable_slots[0]
    bpy.context.scene.frame_set(frame)


# =========================================================================== one person

def build_person(sp: Spec) -> tuple[bpy.types.Collection, bpy.types.Object, int]:
    t0 = time.time()
    coll = bpy.data.collections.new(sp.name)
    bpy.context.scene.collection.children.link(coll)
    body = Body(sp)
    mats = make_materials(sp)
    rig = build_rig(body, coll)
    parts = outfit_parts(body) + [hair_part(body)]
    objs = []

    def finish(ob, mat_key, weights, uv=None, uv_args=None):
        ob.data.materials.append(bpy.data.materials[mats[mat_key][0]])
        if uv:
            set_uvs(ob, uv, **(uv_args or {}))
        assign_weights(ob, weights)
        ob.parent = rig
        mod = ob.modifiers.new("Armature", "ARMATURE")
        mod.object = rig
        objs.append(ob)

    # skin
    lo, hi = body.bbox()
    V, Fc = polygonize(body.field, lo, hi, 0.0028 * body.s)
    ob = new_object(f"{sp.name}_body", V, Fc, coll)
    V = verts_of(ob)
    covered = np.zeros(len(V), bool)
    for p in parts:
        if p.covers is not None:
            covered |= p.covers(V) < -0.02 * body.s
    covered[V[:, 2] < 0.085 * body.s] = True   # feet always sit in shoes
    delete_faces(ob, covered)   # first, so the budget goes to skin that is seen
    head_z = body.head_c[2] - 0.13 * body.hs
    decimate(ob, 6000, detail=lambda V: V[:, 2] > head_z, share=0.6)
    V, N = verts_of(ob), normals_of(ob)
    ca = ob.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", skin_colors(body, V, N).ravel())
    finish(ob, "skin", skin_weights(body, V))

    for p in parts:
        V, Fc = polygonize(p.fn, p.lo, p.hi, p.h)
        ob = new_object(f"{sp.name}_{p.name}", V, Fc, coll)
        decimate(ob, p.tris)
        V = verts_of(ob)
        tex = mats[p.material][1]
        uv_args = {"tile": TEX_SIZE.get(tex, 0.15)}
        if p.uv == "cyl":
            uv_args.update(center=(0, 0, 0), zspan=(0.9 * body.s, 1.47 * body.s), tile=0.25)
        elif p.uv == "sphere":
            uv_args.update(center=tuple(body.head_c))
        if p.split:
            ob.data.materials.append(bpy.data.materials[mats[p.material][0]])
            ob.data.materials.append(bpy.data.materials[mats[p.split[1]][0]])
            set_uvs(ob, "box", **uv_args)
            for poly in ob.data.polygons:
                poly.material_index = 1 if poly.center.z < p.split[0] else 0
            assign_weights(ob, skin_weights(body, V, rigid=p.rigid))
            ob.parent = rig
            ob.modifiers.new("Armature", "ARMATURE").object = rig
            objs.append(ob)
            continue
        finish(ob, p.material, skin_weights(body, V, rigid=p.rigid), p.uv if tex else None, uv_args)

    # eyes
    for sd in (1, -1):
        me = eye_mesh(f"{sp.name}_eye", 0.0122 * body.hs)
        ob = bpy.data.objects.new(f"{sp.name}_eye_{'L' if sd > 0 else 'R'}", me)
        coll.objects.link(ob)
        me.transform(Matrix.Translation(body.H(0.032 * sd, -0.0635, -0.0195)))
        for k in ("sclera", "iris", "pupil"):
            me.materials.append(bpy.data.materials[mats[k][0]])
        assign_weights(ob, {"Head": np.ones(len(me.vertices))})
        ob.parent = rig
        ob.modifiers.new("Armature", "ARMATURE").object = rig
        objs.append(ob)
    if sp.glasses:
        me = glasses_mesh(body, f"{sp.name}_glasses")
        ob = bpy.data.objects.new(f"{sp.name}_glasses", me)
        coll.objects.link(ob)
        finish(ob, "frame", {"Head": np.ones(len(me.vertices))})

    # logo patch on the chest (polo, blazer lapel pin) or the vest, and on the helmet
    host = {"business": "polo", "manager": "blazer", "monteur": "vest"}.get(sp.outfit)   # a plain shirt has none
    if host:
        x, z, w = (0.105, 1.36, 0.026) if sp.outfit == "manager" else (0.085, 1.33, 0.07)
        me = patch_mesh(f"{sp.name}_logo", bpy.data.objects[f"{sp.name}_{host}"], (x * body.s, z * body.s), w * body.s, w * 0.5 * body.s, 0.0015)
        ob = bpy.data.objects.new(f"{sp.name}_logo", me)
        coll.objects.link(ob)
        finish(ob, "logo", skin_weights(body, verts_of(ob)))
    if sp.outfit == "monteur" and sp.helmet:
        me = patch_mesh(f"{sp.name}_helmet_logo", bpy.data.objects[f"{sp.name}_helmet"], body.H(0, 0, 0.05)[[0, 2]],
                        0.05 * body.hs, 0.025 * body.hs, 0.0012)
        ob = bpy.data.objects.new(f"{sp.name}_helmet_logo", me)
        coll.objects.link(ob)
        finish(ob, "logo", {"Head": np.ones(len(me.vertices))})

    bake_action(rig, body, "idle_loop", pose_idle, 120)
    walk = bake_action(rig, body, "walk_loop", pose_walk, WALK_FRAMES)
    bake_action(rig, body, "sit_loop", pose_sit, 120)
    bake_action(rig, body, "talk_loop", pose_talk, 90)
    print(f"{sp.name}: walk pace {walk_pace(rig, walk, WALK_FRAMES):.2f} m/s")
    per ={o.name.removeprefix(sp.name + "_"): sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs}
    tris = sum(per.values())
    print("  ", " ".join(f"{k}={v}" for k, v in per.items()))
    print(f"{sp.name}: {tris} triangles, {len(objs)} meshes, {time.time() - t0:.0f} s")
    return coll, rig, tris


def export(coll, path: Path) -> None:
    layer = bpy.context.view_layer.layer_collection.children[coll.name]
    bpy.context.view_layer.active_layer_collection = layer
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_active_collection=True, export_keep_originals=False,
        export_image_format="NONE", export_extras=True,   # textures are shared: see material()
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE", export_cameras=False, export_lights=False,
        export_skins=True, export_animations=True, export_animation_mode="NLA_TRACKS", export_force_sampling=True,
        export_optimize_animation_size=False, export_anim_slide_to_zero=True)
    print(f"wrote {path} ({path.stat().st_size / 1e6:.2f} MB)")


# =========================================================================== preview renders

def studio(samples: int) -> None:
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Base Contrast" if "AgX - Base Contrast" in [
        i.identifier for i in sc.view_settings.bl_rna.properties["look"].enum_items] else "None"
    world = bpy.data.worlds.new("studio")
    sc.world = world
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.62, 0.64, 0.68, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
    # a seamless backdrop: floor curving up into a wall behind the people
    bm = bmesh.new()
    prof = [(-6.0, 0.0)] + [(1.5 + 2.5 * math.sin(a), 2.5 - 2.5 * math.cos(a)) for a in np.linspace(0, math.pi / 2, 12)] + [(4.0, 8.0)]
    rows = [[bm.verts.new((x, y, z)) for (y, z) in prof] for x in (-12.0, 12.0)]
    for i in range(len(prof) - 1):
        bm.faces.new((rows[0][i], rows[1][i], rows[1][i + 1], rows[0][i + 1]))
    me = bpy.data.meshes.new("backdrop")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    bd = bpy.data.objects.new("backdrop", me)
    sc.collection.objects.link(bd)
    m = bpy.data.materials.new("backdrop")
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.43, 0.45, 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    me.materials.append(m)

    def area(name, loc, target, power, size, color=(1, 1, 1)):
        li = bpy.data.lights.new(name, "AREA")
        li.energy, li.size, li.color = power, size, color
        ob = bpy.data.objects.new(name, li)
        ob.location = loc
        ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(ob)
    area("key", (-3.2, -4.0, 4.2), (0, 0, 1.1), 650, 3.0, (1.0, 0.96, 0.9))
    area("fill", (4.0, -3.5, 2.2), (0, 0, 1.0), 220, 4.0, (0.9, 0.95, 1.0))
    area("rim", (1.5, 3.5, 3.5), (0, 0, 1.4), 450, 2.0)


def camera(name: str, loc, target, lens: float) -> bpy.types.Object:
    cam = bpy.data.cameras.new(name)
    cam.lens = lens
    ob = bpy.data.objects.new(name, cam)
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(ob)
    return ob


def render(path: Path, cam) -> None:
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.filepath = str(path)
    t0 = time.time()
    bpy.ops.render.render(write_still=True)
    print(f"rendered {path} in {time.time() - t0:.0f} s")


def render_previews(rigs: dict, samples: int) -> None:
    studio(samples)
    order = [k for k in ("ruud", "player", "ahmed") if k in rigs]
    for i, k in enumerate(order):
        rigs[k].location = ((i - (len(order) - 1) / 2) * 0.95, 0, 0)
        rigs[k].rotation_euler = (0, 0, 0)
        show_pose(rigs[k], "idle_loop", 1)
    render(SHOTS / "characters_lineup.png", camera("cam_lineup", (0, -6.4, 1.55), (0, 0, 0.93), 52))
    # Sims view: a little group, the player walking in, seen 3/4 from above at ~45 degrees
    spots = {"ruud": ((-0.55, 0.35, 0), -60), "ahmed": ((0.55, 0.45, 0), 55), "player": ((0.05, -0.75, 0), 175)}
    for k in order:
        loc, rot = spots[k]
        rigs[k].location = loc
        rigs[k].rotation_euler = (0, 0, math.radians(rot))
    for k in order:   # one scene frame poses them all; the walker mid-swing, arms near vertical
        show_pose(rigs[k], "walk_loop" if k == "player" else "idle_loop", 9)   # (a forward arm seen from above lands by the head)
    render(SHOTS / "characters_sims_view.png", camera("cam_sims", (-3.2, -3.9, 4.6), (0, 0, 0.75), 46))


# =========================================================================== main

def pose_sheet(rig, path: Path) -> None:
    """A quick, noisy render of one person in each action (a seat box under the sitter):
    for checking poses without the full previews or the game. (Workbench needs a GPU.)"""
    studio(12)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = 1400, 600
    for i, action in enumerate(("idle_loop", "walk_loop", "sit_loop", "talk_loop")):
        dup = rig.copy()
        sc.collection.objects.link(dup)
        for child in rig.children:
            c = child.copy()
            c.parent = dup
            c.modifiers["Armature"].object = dup
            sc.collection.objects.link(c)
        dup.location = ((i - 1.5) * 1.1, 0, 0)
        dup.rotation_euler = (0, 0, math.radians(-75 if action == "sit_loop" else -35))   # the sitter in profile
        show_pose(dup, action, 30)
        if action == "sit_loop":
            bpy.ops.mesh.primitive_cube_add(size=1, location=(dup.location.x, 0.0, 0.26))
            bpy.context.object.scale = (0.48, 0.47, 0.52)
    rig.hide_render = True
    for child in rig.children:
        child.hide_render = True
    render(path, camera("cam_sheet", (0.4, -6.8, 2.2), (0, 0, 0.8), 40))


def write_import(glb: Path) -> None:
    """A new glb's Godot import settings (once): the character import script, 30 fps, loops."""
    target = glb.with_name(glb.name + ".import")
    if target.exists():
        return
    target.write_text(IMPORT_TEMPLATE.format(name=glb.name))


IMPORT_TEMPLATE = """[remap]

importer="scene"
importer_version=1
type="PackedScene"

[deps]

source_file="res://assets/characters/{name}"

[params]

nodes/root_type=""
nodes/root_name=""
nodes/apply_root_scale=true
nodes/root_scale=1.0
nodes/import_as_skeleton_bones=false
nodes/use_name_suffixes=true
nodes/use_node_type_suffixes=true
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
meshes/force_disable_compression=false
skins/use_named_skins=true
animation/import=true
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
animation/import_rest_as_RESET=false
import_script/path="res://assets/characters/character_import.gd"
materials/extract=0
_subresources={{}}
gltf/naming_version=2
gltf/embedded_image_handling=2
"""


def main(argv: list[str]) -> None:
    global VOXEL
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--only", choices=sorted(CAST_SPECS), action="append", help="build only this person (repeatable)")
    ap.add_argument("--no-render", action="store_true", help="skip the Cycles preview renders")
    ap.add_argument("--samples", type=int, default=96, help="Cycles samples for the previews")
    ap.add_argument("--blend", type=Path, help="also save the .blend here (for inspection)")
    ap.add_argument("--draft", action="store_true", help="coarse voxels, no export: for --pose-sheet")
    ap.add_argument("--pose-sheet", type=Path, help="render the first person in every action (Workbench) here")
    args = ap.parse_args(argv)

    VOXEL = 2.0 if args.draft else 1.0
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 30   # the actions are keyed per frame at 30 fps (Blender's default is 24)
    make_textures()
    rigs = {}
    for key in args.only or CAST_SPECS:
        coll, rig, tris = build_person(CAST_SPECS[key])
        if tris > 20000:
            print(f"WARNING: {key} has {tris} triangles (budget 20000)")
        if not args.draft:
            export(coll, OUT / f"{key}.glb")
            write_import(OUT / f"{key}.glb")
        rigs[key] = rig
    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(args.blend))
    if args.pose_sheet:
        pose_sheet(next(iter(rigs.values())), args.pose_sheet)
    elif not args.no_render:
        render_previews(rigs, args.samples)


if __name__ == "__main__":
    main(sys.argv[1:])
