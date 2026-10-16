"""The people of Spanning from the CC0 Quaternius pack (PLAN 1.3a), re-dressed for Voltana.

Called by build_character.py (the default method; `--method script` keeps the scripted
mannequins as Merijn's fallback). The pack is downloaded by fetch_pack.py into .pack/ and not
committed; only the built glbs and the shared textures are.

How a person is made from cast.json (`look`):
- Body: Universal Base Characters, `Superhero_Male` or `_Female` (one rig for both). The rig's
  bones are renamed to Godot's SkeletonProfileHumanoid names (Hips, Spine, ..., LeftFoot), so
  the game's contract (CharacterModel) holds; the finger-tip leaf bones are folded into their
  parents. Height scales the body but not the head (heads vary little between people, and the
  creator's hair and glasses then fit everyone); build widens the waist, hips and limbs.
- Skin, hair, eyes: shared textures made from the pack's (textures/skin_m, skin_f, hairpack_1/2,
  eye), tinted by the material colour, so the cast list's colours (and later the creator's)
  are material parameters. The eye's iris is its own material, tinted by eye_color.
- Clothes: the body's own surface in a region (a T-pose rest makes regions simple: arms run
  along x, legs along z), copied, smoothed so fabric bridges the muscles' hollows, and kept at a
  fabric's thickness off the skin; skin under clothes is deleted. Polo with the Voltana logo
  (business), shirt and belt (shirt), blazer over a shirt (manager), work shirt, hi-vis vest and
  boots (monteur), optional helmet; trousers and shoes for everyone. Fabric textures are the
  scripted builder's shared greyscale ones.
- Animation: the Universal Animation Libraries, retargeted onto the rig in world space (each
  bone's rotation from its rest, the hips' travel scaled by leg length): idle, walk (the cycle
  quickened for the office's brisk pace), talk, jog (timed to JOG_PACE m/s) and sit (the
  library's seated torso, the legs set on the office chair and the arms typing at the keyboard
  by two-bone IK). The library's heroic stance is relaxed (fingers, arms, feet). Age adds a
  stoop to every action.
- The character creator's bodies, outfits, hair, beards, glasses and face layers (`--creator`):
  creator_build.py, from the same pieces.

Coordinates are Blender's: metres, Z up, the person faces -Y (Godot +Z). Rest is a T-pose.
"""
from __future__ import annotations

import math
import time
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree
from PIL import Image

import build_character as bc

PARTS = bc.OUT / "parts"
FPS = 30
JOG_PACE = 4.5          # m/s: the run key's speed (the jog is timed to it, so it plays at 1x)
WALK_FRAMES = 26        # one walk cycle: the library's 40 frames quickened to a brisk office pace
SEAT_HIP = bc.SEAT_HIP  # hip joint height on the office chair (m)
SEAT_BACK = bc.SEAT_BACK
KEYBOARD = (0.0, -0.40, 0.785)   # the wrists' centre at the keyboard, from the chair (build_office)

# ----------------------------------------------------------------------------- the pack's names

UE_TO_GODOT = {
    "root": "Root", "pelvis": "Hips", "spine_01": "Spine", "spine_02": "Chest", "spine_03": "UpperChest",
    "neck_01": "Neck", "Head": "Head",
}
for _s, _S in (("l", "Left"), ("r", "Right")):
    UE_TO_GODOT.update({
        f"clavicle_{_s}": f"{_S}Shoulder", f"upperarm_{_s}": f"{_S}UpperArm", f"lowerarm_{_s}": f"{_S}LowerArm",
        f"hand_{_s}": f"{_S}Hand", f"thigh_{_s}": f"{_S}UpperLeg", f"calf_{_s}": f"{_S}LowerLeg",
        f"foot_{_s}": f"{_S}Foot", f"ball_{_s}": f"{_S}Toes",
        f"thumb_01_{_s}": f"{_S}ThumbMetacarpal", f"thumb_02_{_s}": f"{_S}ThumbProximal",
        f"thumb_03_{_s}": f"{_S}ThumbDistal",
    })
    for _f, _F in (("index", "Index"), ("middle", "Middle"), ("ring", "Ring"), ("pinky", "Little")):
        UE_TO_GODOT.update({f"{_f}_01_{_s}": f"{_S}{_F}Proximal", f"{_f}_02_{_s}": f"{_S}{_F}Intermediate",
                            f"{_f}_03_{_s}": f"{_S}{_F}Distal"})

# Animation Library 1 names its (Rigify) bones DEF-*; Library 2 uses the base characters' names.
UAL1_TO_UE = {"DEF-hips": "pelvis", "DEF-spine.001": "spine_01", "DEF-spine.002": "spine_02",
              "DEF-spine.003": "spine_03", "DEF-neck": "neck_01", "DEF-head": "Head"}
for _s, _S in (("l", "L"), ("r", "R")):
    UAL1_TO_UE.update({
        f"DEF-shoulder.{_S}": f"clavicle_{_s}", f"DEF-upper_arm.{_S}": f"upperarm_{_s}",
        f"DEF-forearm.{_S}": f"lowerarm_{_s}", f"DEF-hand.{_S}": f"hand_{_s}", f"DEF-thigh.{_S}": f"thigh_{_s}",
        f"DEF-shin.{_S}": f"calf_{_s}", f"DEF-foot.{_S}": f"foot_{_s}", f"DEF-toe.{_S}": f"ball_{_s}",
    })
    for _k in ("01", "02", "03"):
        UAL1_TO_UE[f"DEF-thumb.{_k}.{_S}"] = f"thumb_{_k}_{_s}"
        for _f in ("index", "middle", "ring", "pinky"):
            UAL1_TO_UE[f"DEF-f_{_f}.{_k}.{_S}"] = f"{_f}_{_k}_{_s}"

# (library, clip) per game animation; the walk is the formal one in office clothes.
CLIPS = {
    "idle": ("ual1", "Idle_Loop"),
    "talk": ("ual1", "Idle_Talking_Loop"),
    "sit": ("ual1", "Sitting_Idle_Loop"),
    "jog": ("ual1", "Jog_Fwd_Loop"),
    "walk": ("ual1", "Walk_Formal_Loop"),
    "walk_monteur": ("ual1", "Walk_Loop"),
}

HAIR = {   # cast hair_style -> (pack hairstyle per sex, trim)
    "bob": ({"m": "Hair_Long", "f": "Hair_Long"}, None),
    "short": ({"m": "Hair_SimpleParted", "f": "Hair_BuzzedFemale"}, None),
    "buzz": ({"m": "Hair_Buzzed", "f": "Hair_BuzzedFemale"}, None),
    "receding": ({"m": "Hair_SimpleParted", "f": "Hair_BuzzedFemale"}, "receding"),
    "ponytail": ({"m": "Hair_BuzzedFemale", "f": "Hair_BuzzedFemale"}, "ponytail"),
    "buns": ({"m": "Hair_Buns", "f": "Hair_Buns"}, None),
}


def pack_paths(pack: Path) -> dict[str, Path]:
    ubc = pack / "ubc"
    paths = {
        "body_m": ubc / "Base Characters/Godot - UE/Superhero_Male_FullBody.gltf",
        "body_f": ubc / "Base Characters/Godot - UE/Superhero_Female_FullBody.gltf",
        "hair": ubc / "Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)",
        "textures": ubc / "Base Characters/Textures",
        "ual1": pack / "ual1/Godot/AnimationLibrary_Godot_Standard.glb",
        "ual2": pack / "ual2/Unreal-Godot/UAL2_Standard.glb",
    }
    missing = [str(p) for p in paths.values() if not p.exists()]
    if missing:
        raise SystemExit("the character pack is not in %s (run tools/blender/fetch_pack.py): %s" % (pack, missing[0]))
    for licence in (ubc / "License_Standard.txt", pack / "ual1/License.txt", pack / "ual2/License.txt"):
        if "CC0" not in licence.read_text(errors="replace"):
            raise SystemExit(f"{licence} does not say CC0: not using it")
    return paths


# ============================================================================= shared textures

def _save(img: np.ndarray, name: str, px: int) -> None:
    im = Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8))
    im.resize((px, px), Image.LANCZOS).save(bc.TEX / f"{name}.png", optimize=True)


def _load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), np.float32) / 255.0


def _flatter(normal: np.ndarray, keep: float) -> np.ndarray:
    """A tangent-space normal map with its relief scaled by `keep` (the base bodies are athletes)."""
    n = normal * 2 - 1
    n[..., :2] *= keep
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def make_pack_textures(paths: dict) -> None:
    """Skin, hair and eye maps from the pack, as tints: the material colour (cast skin, hair
    and eye colours; later the creator's) multiplies them. Skin keeps its relative colour
    (lips, cheeks, the face's shading) around 0.92 of the skin's mean, so colour / 0.92 is
    the skin tone. Normal maps use Godot's convention (the pack's "Unity - Godot" ones)."""
    t = paths["textures"]
    bc.TEX.mkdir(parents=True, exist_ok=True)
    for sex, albedo in (("m", "T_Superhero_Male_Ligh.png"), ("f", "T_Superhero_Female_Light_BaseColor.png")):
        img = _load(t / albedo)
        sat = img.max(-1) - img.min(-1)
        skin = img[sat > 0.12]   # the grey underwear is not skin
        _save(img * (SKIN_HEADROOM / skin.mean(0)), f"skin_{sex}_albedo", 1024)
        normal = _load(t / f"Normals Unity - Godot/T_Superhero_{'Male' if sex == 'm' else 'Female'}_Normal.png")
        _save(_flatter(normal, 0.55), f"skin_{sex}_normal", 512)
    for k in ("1", "2"):
        img = _load(t / f"T_Hair_{k}_BaseColor.png")
        grey = img.mean(-1, keepdims=True).repeat(3, -1)
        _save(grey / grey.mean() * 0.62, f"hairpack_{k}_albedo", 512)
        _save(_load(t / f"Normals Unity - Godot/T_Hair_{k}_Normal.png"), f"hairpack_{k}_normal", 512)
    eye = _load(t / "T_Eye_Brown.png")
    h, w, _ = eye.shape
    y, x = np.mgrid[0:h, 0:w]
    r = np.hypot(x / w - IRIS_UV[0], (1 - y / h) - IRIS_UV[1])
    iris = (r < IRIS_R + 0.012)[..., None]
    grey = eye.mean(-1, keepdims=True).repeat(3, -1)
    _save(np.where(iris, np.clip(grey * 2.3, 0, 1), eye), "eye_albedo", 256)


SKIN_HEADROOM = 0.92
IRIS_UV = (0.5, 0.51)   # the iris' centre and radius in the pack's eye texture (uv, v up)
IRIS_R = 0.1


# ============================================================================= scene helpers

def import_gltf(path: Path) -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new = [o for o in bpy.data.objects if o not in before]
    for o in [o for o in new if o.name.startswith("Icosphere")]:   # the pack's preview sphere
        new.remove(o)
        bpy.data.objects.remove(o)
    return new


def armature_of(objs) -> bpy.types.Object:
    return next(o for o in objs if o.type == "ARMATURE")


def solo(rig, action: str | None) -> None:
    """Play `action` alone on `rig` (its NLA tracks muted), or None: back to the tracks."""
    ad = rig.animation_data or rig.animation_data_create()
    for tr in ad.nla_tracks:
        tr.mute = action is not None
    ad.action = bpy.data.actions[action] if action else None
    if action and getattr(ad, "action_suitable_slots", None):
        ad.action_slot = ad.action_suitable_slots[0]


def set_mode(ob, mode: str) -> None:
    bpy.context.view_layer.objects.active = ob
    if bpy.context.object.mode != mode:
        bpy.ops.object.mode_set(mode=mode)


def rename_rig(rig, meshes) -> None:
    """Godot humanoid bone names; fold the finger-tip leaf bones into their parents."""
    set_mode(rig, "EDIT")
    eb = rig.data.edit_bones
    leaves = {b.name: b.parent.name for b in eb if "leaf" in b.name}
    for name in leaves:
        eb.remove(eb[name])
    set_mode(rig, "OBJECT")
    for ob in meshes:
        for leaf, parent in leaves.items():
            g = ob.vertex_groups.get(leaf)
            if g is None:
                continue
            dst = ob.vertex_groups.get(parent) or ob.vertex_groups.new(name=parent)
            for v in ob.data.vertices:
                for ge in v.groups:
                    if ge.group == g.index and ge.weight > 0:
                        dst.add([v.index], ge.weight, "ADD")
            ob.vertex_groups.remove(g)
    for b in rig.data.bones:
        new = UE_TO_GODOT.get(b.name)
        if new:
            b.name = new
    for ob in meshes:
        for g in ob.vertex_groups:
            if g.name in UE_TO_GODOT:
                g.name = UE_TO_GODOT[g.name]


def bind(ob, rig) -> None:
    """Parent a mesh to the rig (both at the origin, the mesh's transform applied to its data)
    with an armature modifier (weights by bone name)."""
    ob.data.transform(ob.matrix_world)
    ob.parent = rig
    ob.matrix_parent_inverse = Matrix()
    ob.matrix_world = Matrix()
    for m in list(ob.modifiers):
        if m.type == "ARMATURE":
            ob.modifiers.remove(m)
    ob.modifiers.new("Armature", "ARMATURE").object = rig


def verts(ob) -> np.ndarray:
    a = np.empty(len(ob.data.vertices) * 3)
    ob.data.vertices.foreach_get("co", a)
    return a.reshape(-1, 3)


def set_verts(ob, V: np.ndarray) -> None:
    ob.data.vertices.foreach_set("co", V.ravel())
    ob.data.update()


def weights(ob) -> dict[str, np.ndarray]:
    """Bone name -> weight per vertex."""
    n = len(ob.data.vertices)
    out = {g.name: np.zeros(n) for g in ob.vertex_groups}
    names = [g.name for g in ob.vertex_groups]
    for v in ob.data.vertices:
        for ge in v.groups:
            out[names[ge.group]][v.index] = ge.weight
    return out


def head_of(rig, bone: str) -> Vector:
    return rig.data.bones[bone].head_local.copy()


def transplant(ob, src_rig, dst_rig, bone: str = "Head") -> None:
    """Move a part made for src_rig's `bone` onto dst_rig's (rests may differ)."""
    m = dst_rig.data.bones[bone].matrix_local @ src_rig.data.bones[bone].matrix_local.inverted()
    ob.data.transform(m @ ob.matrix_world)
    ob.matrix_world = Matrix()


# ============================================================================= body shape

def reshape(rig, meshes, height: float, girth: dict[str, tuple[float, float]]) -> None:
    """Scale to `height` (crown to sole) keeping the head's size, then widen bones' flesh.

    Height: every point scales by s about the floor, except what the Head bone carries, which
    only moves with the neck (blended by its weight). Girth: each bone's flesh moves away from
    the bone (torso bones: x and y separately, about a line in the torso's middle; limbs: around
    their axis), blended by the vertex weights."""
    body = meshes[0]
    s = height / float(verts(body)[:, 2].max())
    head = head_of(rig, "Head")
    set_mode(rig, "EDIT")
    for eb in rig.data.edit_bones:
        if eb.name == "Head":
            d = eb.tail - eb.head
            eb.head = eb.head * s
            eb.tail = eb.head + d
        else:
            eb.head, eb.tail = eb.head * s, eb.tail * s
    set_mode(rig, "OBJECT")
    bones = {b.name: (np.array(b.head_local), np.array(b.tail_local)) for b in rig.data.bones}
    H0, H1 = np.array(head), np.array(head) * s
    for ob in meshes:
        V, W = verts(ob), weights(ob)
        wh = W.get("Head", np.zeros(len(V)))[:, None]
        V = (1 - wh) * V * s + wh * (H1 + (V - H0))
        delta = np.zeros_like(V)
        for name, (gx, gy) in girth.items():
            w = W.get(name)
            if w is None or not w.any() or (gx == 1 and gy == 1):
                continue
            a, b = bones[name]
            axis = b - a
            t = np.clip((V - a) @ axis / (axis @ axis), 0, 1)
            c = a + t[:, None] * axis
            r = V - c
            if abs(axis[2]) > abs(axis[0]):    # torso or leg: x and y apart, about the torso's middle
                c = c + np.array([0, TORSO_FRONT * (name in TORSO), 0])
                r = V - c
                scaled = r * np.array([gx, gy, 1.0])
            else:                               # arm (along x in the T-pose)
                scaled = r * np.array([1.0, gx, gx])
            delta += w[:, None] * (scaled - r)
        set_verts(ob, V + delta)


TORSO = ("Hips", "Spine", "Chest", "UpperChest")
NECK_R = 0.085        # what the neckline cuts: the neck's radius and a margin (m)
TORSO_FRONT = -0.05   # the torso's middle is in front of the spine bones (m)


def girth_for(sp) -> dict[str, tuple[float, float]]:
    """Per bone (lateral, depth) scale from build 0 slim .. 1 heavy. The pack's bodies are
    athletes (PLAN 1.3c): everyone gets a softer waist and belly, the men a much narrower chest
    (no lats), slimmer upper arms and thighs, the women slightly slimmer limbs."""
    b = sp.build - 0.4
    man = sp.sex == "m"
    waist = (1.0 + 0.30 * b + (0.12 if man else 0.04), 1.0 + 0.6 * b + (0.14 if man else 0.1))
    shoulder = (1.0 - (0.2 if man else 0.06), 1.0 - (0.2 if man else 0.06))
    upper_arm = 1.0 + 0.06 * b - (0.22 if man else 0.06)   # weight goes to the belly, not the arms
    lower_arm = 1.0 + 0.04 * b - (0.14 if man else 0.03)
    thigh = 1.0 + 0.15 * b - (0.1 if man else 0.05)
    calf = 1.0 + 0.06 * b - (0.1 if man else 0.06)
    return {
        "Hips": (1.0 + 0.22 * b + (0.0 if man else 0.02), 1.0 + 0.3 * b + 0.03),
        "Spine": waist,
        "Chest": (1.0 + 0.12 * b - (0.02 if man else 0.0), 1.0 + 0.4 * b + (0.04 if man else 0.06)),
        "UpperChest": (1.0 + 0.04 * b - (0.15 if man else 0.02), 1.0 + 0.1 * b - (0.08 if man else 0.0)),
        "LeftShoulder": shoulder, "RightShoulder": shoulder,
        "LeftUpperArm": (upper_arm, 1.0), "RightUpperArm": (upper_arm, 1.0),
        "LeftLowerArm": (lower_arm, 1.0), "RightLowerArm": (lower_arm, 1.0),
        "LeftUpperLeg": (thigh, thigh), "RightUpperLeg": (thigh, thigh),
        "LeftLowerLeg": (calf, calf), "RightLowerLeg": (calf, calf),
    }


SHOULDER_IN = {"m": 0.024, "f": 0.006}   # how far the arms move in (m): an office build, not a swimmer's
ARM_CHAIN = ("UpperArm", "LowerArm", "Hand", "Thumb", "Index", "Middle", "Ring", "Little")


def narrow_shoulders(rig, meshes, dx: float) -> None:
    """Move both arms `dx` towards the body (bones and the flesh they carry; the clavicle's
    flesh half as far), so the shoulders are an average office worker's, not an athlete's."""
    if not dx:
        return
    set_mode(rig, "EDIT")
    for eb in rig.data.edit_bones:
        side = 1 if eb.name.startswith("Left") else -1 if eb.name.startswith("Right") else 0
        if side and any(k in eb.name for k in ARM_CHAIN):
            eb.head.x -= side * dx
            eb.tail.x -= side * dx
        elif side and eb.name.endswith("Shoulder"):
            eb.tail.x -= side * dx
    set_mode(rig, "OBJECT")
    for ob in meshes:
        V, W = verts(ob), weights(ob)
        move = np.zeros(len(V))
        for name, w in W.items():
            if any(k in name for k in ARM_CHAIN):
                move += w
            elif name.endswith("Shoulder") and name != "Shoulder":
                move += 0.5 * w
        V[:, 0] -= np.sign(V[:, 0]) * dx * np.clip(move, 0, 1)
        set_verts(ob, V)


def soften(body, iters: int = 24) -> None:
    """Fade the pack's muscle relief (pecs, abs, deltoids, quads) on the torso and limbs by
    Taubin smoothing, which keeps the volume; the head, neck, hands and feet keep their detail."""
    W = weights(body)
    n = len(body.data.vertices)
    keep = np.zeros(n)
    for name, w in W.items():
        if name in ("Head", "Neck") or name.endswith(("Hand", "Foot", "Toes")) or \
                any(f in name for f in ("Thumb", "Index", "Middle", "Ring", "Little")):
            keep += w
    m = np.clip(1.0 - 1.5 * keep, 0, 1)[:, None]
    E = np.empty(len(body.data.edges) * 2, int)
    body.data.edges.foreach_get("vertices", E)
    E = E.reshape(-1, 2)
    deg = np.maximum(np.bincount(E.ravel(), minlength=n), 1).astype(float)[:, None]
    V = verts(body)

    def step(V, k):
        acc = np.zeros_like(V)
        np.add.at(acc, E[:, 0], V[E[:, 1]])
        np.add.at(acc, E[:, 1], V[E[:, 0]])
        return V + m * k * (acc / deg - V)

    for _ in range(iters):
        V = step(step(V, 0.5), -0.53)
    set_verts(body, V)


# ============================================================================= landmarks

class Marks:
    """Heights and reaches of a shaped rest body (T-pose): where garments start and end."""

    def __init__(self, rig, body):
        h = lambda n: head_of(rig, n)  # noqa: E731
        V = verts(body)
        self.shoulder_x = h("LeftUpperArm").x
        self.elbow_x = h("LeftLowerArm").x
        self.wrist_x = h("LeftHand").x
        self.waist = h("Spine").z
        self.hip = h("LeftUpperLeg").z
        self.knee = h("LeftLowerLeg").z
        self.ankle = h("LeftFoot").z
        self.neck = h("Neck").z
        self.head = h("Head")
        self.chest = h("UpperChest").z
        self.top = float(V[:, 2].max())


# ============================================================================= garments

def smooth_inflate(ob, body_bvh: BVHTree, t: float, iters: int, lam: float = 0.5, taubin: bool = True) -> None:
    """Fabric over skin: smoothing (the muscles' bumps fade, Taubin's way so the cloth does not
    shrink onto the skin) alternating with a push to at least `t` off the skin along its normal."""
    me = ob.data
    V = verts(ob)
    E = np.empty(len(me.edges) * 2, int)
    me.edges.foreach_get("vertices", E)
    E = E.reshape(-1, 2)
    # a hem or a cuff (an open edge) smooths along itself only, so it stays where it was cut
    faces_per_edge = np.zeros(len(me.edges), int)
    for poly in me.polygons:
        faces_per_edge[[me.loops[li].edge_index for li in poly.loop_indices]] += 1
    open_edge = faces_per_edge == 1
    on_hem = np.zeros(len(V), bool)
    on_hem[E[open_edge].ravel()] = True
    use = open_edge | ~(on_hem[E[:, 0]] | on_hem[E[:, 1]])
    E = E[use]
    deg = np.bincount(E.ravel(), minlength=len(V)).astype(float)[:, None]

    def towards_neighbours(V, k):
        acc = np.zeros_like(V)
        np.add.at(acc, E[:, 0], V[E[:, 1]])
        np.add.at(acc, E[:, 1], V[E[:, 0]])
        return V + k * (np.where(deg > 0, acc / np.maximum(deg, 1), V) - V)

    for it in range(iters + 1):
        if it:   # Taubin's two steps: smooth without shrinking (a drape keeps its width)
            V = towards_neighbours(V, lam)
            if taubin:
                V = towards_neighbours(V, -lam - 0.03)
        for i, p in enumerate(V):
            loc, nrm, _, _ = body_bvh.find_nearest(Vector(p))
            if loc is None:
                continue
            d = (Vector(p) - loc).dot(nrm)
            if d < t:
                V[i] = p + np.array(nrm) * (t - d)
    set_verts(ob, V)


def drape(ob, mk: "Marks", kind: str, amount: float = 0.9) -> None:
    """Cloth hangs over the body's hollows: each thin slice of the garment (across the legs and
    torso, along the arms) is pushed `amount` of the way out to its convex outline, from the
    slice's middle. kind "legs" (trousers: one slice above the crotch, a leg each below),
    "upper" (shirt: the torso in z slices, each arm in x slices), "feet" (shoes)."""
    from scipy.spatial import ConvexHull
    V = verts(ob)
    x, z = V[:, 0], V[:, 2]
    if kind == "upper":
        arm = np.abs(x) > mk.shoulder_x - 0.02
        axis = np.where(arm, 0, 2)
        comp = np.where(arm, np.sign(x), 0)
    else:
        axis = np.full(len(V), 2)
        comp = np.where((kind == "feet") | (z < mk.hip - 0.09), np.sign(x), 0)
    out = V.copy()
    step = 0.012
    for c in np.unique(comp):
        for ax in np.unique(axis[comp == c]):
            sel = np.nonzero((comp == c) & (axis == ax))[0]
            other = [i for i in range(3) if i != ax]
            bins = np.floor(V[sel, ax] / step).astype(int)
            for b in np.unique(bins):
                idx = sel[np.abs(bins - b) <= 0]
                ring = sel[np.abs(bins - b) <= 1]    # the hull from a slice and its neighbours
                if len(ring) < 6:
                    continue
                P = V[ring][:, other]
                try:
                    hull = P[ConvexHull(P).vertices]
                except Exception:   # a flat or degenerate slice: leave it
                    continue
                centre = hull.mean(0)
                Q = V[idx][:, other] - centre
                edges = np.stack([hull - centre, np.roll(hull, -1, 0) - centre], 1)   # (E, 2, 2)
                for k, q in zip(idx, Q):
                    n = np.hypot(*q)
                    if n < 1e-6:
                        continue
                    d = q / n
                    best = n
                    for a0, a1 in edges:
                        e = a1 - a0
                        den = d[0] * e[1] - d[1] * e[0]
                        if abs(den) < 1e-12:
                            continue
                        t = (a0[0] * e[1] - a0[1] * e[0]) / den
                        u = (a0[0] * d[1] - a0[1] * d[0]) / den
                        if t > 0 and -1e-6 <= u <= 1 + 1e-6:
                            best = max(best, t)
                            break
                    r = n + (best - n) * amount
                    out[k, other] = centre + d * r
    if kind == "legs":
        out = straight_legs(out, comp, mk, limb_share(ob, ("UpperLeg", "LowerLeg", "Foot")))
    elif kind == "upper":
        out = loose_sleeves(out, mk, limb_share(ob, ("UpperArm", "LowerArm", "Hand")))
    set_verts(ob, out)


def limb_share(ob, bones: tuple[str, ...]) -> np.ndarray:
    """How much each vertex belongs to a limb (0 torso .. 1 limb), from its bone weights: the
    sleeve and trouser shaping fades out where cloth meets the torso (armpit, crotch), so a
    slice that also cuts the torso does not pull it into a spike."""
    W = weights(ob)
    w = sum((v for k, v in W.items() if k.endswith(bones)), np.zeros(len(ob.data.vertices)))
    return np.clip((w - 0.3) / 0.5, 0, 1)


def loose_sleeves(V: np.ndarray, mk: "Marks", limb: np.ndarray, ease: float = 1.14, step: float = 0.012) -> np.ndarray:
    """Sleeves hang loose around the arm instead of showing its muscles (PLAN 1.3c): each slice
    across an arm (in the T-pose, along x) widens about its middle, by `ease` from 10 cm past
    the shoulder joint (blending in from the joint), narrowing again towards a long sleeve's cuff."""
    out = V.copy()
    ax = np.abs(V[:, 0])
    for side in (-1, 1):
        sel = np.nonzero((np.sign(V[:, 0]) == side) & (ax > mk.shoulder_x - 0.02) & (limb > 0))[0]
        if not len(sel):
            continue
        end = float(ax[sel].max())
        bins = np.floor(ax[sel] / step).astype(int)
        for b in np.unique(bins):
            idx = sel[bins == b]
            x = (b + 0.5) * step
            grow = np.clip((x - mk.shoulder_x + 0.02) / 0.1, 0, 1)
            cuff = 0.45 + 0.55 * np.clip((end - x) / 0.08, 0, 1) if end > mk.wrist_x - 0.06 else 1.0
            k = 1 + (ease - 1) * grow * cuff
            c = V[idx][:, 1:].mean(0)
            out[idx, 1:] = c + rounder(V[idx, 1:] - c, ROUND) * k
    return V + limb[:, None] * (out - V)


ROUND = 0.5   # how much of a slice's own outline (a muscle's bulge) a sleeve or trouser leg loses


def rounder(D: np.ndarray, amount: float) -> np.ndarray:
    """Offsets `D` from a slice's middle pulled `amount` of the way to their mean length: a
    fabric tube is rounder than the limb inside it."""
    r = np.linalg.norm(D, axis=1, keepdims=True)
    mean = float(r.mean())
    return D / np.maximum(r, 1e-6) * (r + (mean - r) * amount)


def straight_legs(V: np.ndarray, comp: np.ndarray, mk: "Marks", limb: np.ndarray, ease: float = 1.1, fall: float = 0.95) -> np.ndarray:
    """Trousers fall from the thigh instead of hugging the knee and calf: below the crotch each
    leg's slice is widened to at least `fall` of the widest slice in the 25 cm above it, and
    every leg slice gets `ease` (room to move)."""
    out = V.copy()
    step = 0.012
    for c in (-1, 1):
        sel = np.nonzero(comp == c)[0]
        if not len(sel):
            continue
        bins = np.floor(V[sel, 2] / step).astype(int)
        centre, radius = {}, {}
        for b in np.unique(bins):
            P = V[sel[bins == b]][:, :2]
            centre[b] = P.mean(0)
            radius[b] = float(np.linalg.norm(P - centre[b], axis=1).mean())
        span = int(0.25 / step)
        for b in centre:
            above = [radius[k] for k in range(b + 1, b + span + 1) if k in radius]
            want = max([radius[b]] + [fall * r for r in above]) * ease
            idx = sel[bins == b]
            out[idx, :2] = centre[b] + rounder(V[idx, :2] - centre[b], ROUND) * (want / max(radius[b], 1e-6))
    return V + limb[:, None] * (out - V)


def region_copy(body, name: str, keep: np.ndarray, coll) -> bpy.types.Object:
    """A copy of the body with only the `keep` vertices (and the faces between them)."""
    me = body.data.copy()
    me.name = name
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    for g in body.vertex_groups:
        ob.vertex_groups.new(name=g.name)
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep[v.index]], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    me.materials.clear()
    return ob


def scale_uvs(ob, tile: float) -> None:
    """The body's UVs (1.74 m of body per UV unit) scaled so a fabric texture repeats every `tile` m."""
    uv = ob.data.uv_layers.active.data
    a = np.empty(len(uv) * 2)
    uv.foreach_get("uv", a)
    uv.foreach_set("uv", a * (BODY_M_PER_UV / tile))


BODY_M_PER_UV = 1.74


def cylinder_uvs(ob, center_y: float, z0: float, z1: float, tile: float = 0.25) -> None:
    """u around the torso (`tile` m per repeat), v from z0 (0) to z1 (1): the hi-vis layout."""
    me = ob.data
    uv = me.uv_layers.active.data
    for poly in me.polygons:
        us = []
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            us.append((math.atan2(co.x, co.y - center_y) + math.pi) / (2 * math.pi))
        if max(us) - min(us) > 0.5:   # the seam at the front: keep a face on one side
            us = [u + 1.0 if u < 0.5 else u for u in us]
        for li, u in zip(poly.loop_indices, us):
            co = me.vertices[me.loops[li].vertex_index].co
            uv[li].uv = (u * 1.05 / tile, (co.z - z0) / (z1 - z0))


def boundary_ring(body, keep: np.ndarray, rings: int) -> np.ndarray:
    """`keep` without its outermost `rings` vertex rings (the skin there stays, under the hem)."""
    E = np.empty(len(body.data.edges) * 2, int)
    body.data.edges.foreach_get("vertices", E)
    E = E.reshape(-1, 2)
    inner = keep.copy()
    for _ in range(rings):
        out = ~inner
        touch = np.zeros(len(inner), bool)
        touch[E[out[E[:, 0]], 1]] = True
        touch[E[out[E[:, 1]], 0]] = True
        inner &= ~touch
    return inner


def delete_covered(body, covered: np.ndarray) -> None:
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    dead = [f for f in bm.faces if all(covered[v.index] for v in f.verts)]
    bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(body.data)
    bm.free()


def extrude_collar(ob, mk: Marks, up: float, out: float, back_only: bool = False) -> None:
    """A stand collar: the neckline's open edge raised `up` and leaned `out` from the neck
    (`back_only`: round the back and sides of the neck only, for a garment open in front)."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    edges = [e for e in bm.edges if e.is_boundary and all(
        abs(v.co.x) < 0.11 and v.co.z > mk.neck - 0.12 and (not back_only or v.co.y > mk.head.y - 0.035) for v in e.verts)]
    ret = bmesh.ops.extrude_edge_only(bm, edges=edges)
    for v in [g for g in ret["geom"] if isinstance(g, bmesh.types.BMVert)]:
        r = Vector((v.co.x, v.co.y - mk.head.y - 0.005, 0))
        v.co += Vector((0, 0, up)) + (r.normalized() * out if r.length > 1e-6 else Vector())
    bm.to_mesh(ob.data)
    bm.free()


# Per outfit (cast.json `outfit`, or the creator's kleding): the trousers, the shoes, and
# whether the top is tucked in (a belt line) or worn over the trousers.
TROUSERS = {"business": "chinos", "monteur": "worktrousers", "overshirt": "chinos", "sweater": "chinos",
            "blazer": "jeans", "quarterzip": "chinos"}
SHOES = {"monteur": "boot", "overshirt": "sneaker", "blazer": "sneaker", "quarterzip": "sneaker"}
TUCKED = ("shirt", "manager", "monteur")
SOLE = 0.022   # a sneaker's sole: the faces below this height (m)


class Wardrobe:
    """Builds one person's garments from their shaped body."""

    def __init__(self, sp, rig, body, coll, mats):
        self.sp, self.rig, self.body, self.coll, self.mats = sp, rig, body, coll, mats
        self.mk = Marks(rig, body)
        self.V = verts(body)
        self.bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get(), deform=False)
        self.covered = np.zeros(len(self.V), bool)
        self.objs: list[bpy.types.Object] = []

    def upper(self, hem: float, sleeve_x: float, neck_drop: float, vee: float = 0.0) -> np.ndarray:
        """Upper-body cloth: from `hem` up to the neckline, arms out to `sleeve_x`."""
        V, mk = self.V, self.mk
        x, y, z = V[:, 0], V[:, 1], V[:, 2]
        ax = np.abs(x)
        front = y < mk.head.y
        neckline = mk.neck - neck_drop - np.where(front, 0.025 + vee * np.clip(1 - ax / 0.05, 0, 1), 0.0)
        under_neck = ~((z > neckline) & ((np.hypot(x, y - mk.head.y) < NECK_R) | (z > mk.neck + 0.05)))
        return (z >= hem) & (ax <= sleeve_x) & under_neck & (z < mk.top - 0.15)

    def lower(self, top: float, bottom: float) -> np.ndarray:
        V = self.V
        return (V[:, 2] <= top) & (V[:, 2] >= bottom) & (np.abs(V[:, 0]) < 0.35)

    def add(self, name: str, keep: np.ndarray, mat: str, t: float, iters: int = 6, hide: bool = True,
            tile: float | None = None, kind: str | None = None) -> bpy.types.Object:
        ob = region_copy(self.body, f"{self.sp.name}_{name}", keep, self.coll)
        ob.data.materials.append(bpy.data.materials[self.mats[mat][0]])
        tex = self.mats[mat][1]
        if tex and tile is not False:
            scale_uvs(ob, tile or bc.TEX_SIZE.get(tex, 0.15))
        if kind:
            drape(ob, self.mk, kind)
        smooth_inflate(ob, self.bvh, t, iters, taubin=kind != "feet")   # a shoe loses the toes
        if hide:
            self.covered |= boundary_ring(self.body, keep, 2)
        bind(ob, self.rig)
        self.objs.append(ob)
        return ob

    def shoes(self, kind: str) -> None:
        """`kind`: shoe (leather), boot (the monteur's, over the ankle) or sneaker (white, on a
        thicker sole of its own colour)."""
        mk = self.mk
        top = mk.ankle + {"boot": 0.06, "sneaker": 0.03}.get(kind, 0.025)
        sneaker = kind == "sneaker"
        ob = self.add("shoes", self.V[:, 2] < top, kind, 0.015 if sneaker else 0.011, iters=24, kind="feet")
        V = verts(ob)
        V[:, 2] = np.maximum(V[:, 2], 0.0)             # a flat sole on the floor
        toe = V[:, 1] < -0.06
        V[toe, 1] -= (0.016 if sneaker else 0.012) * np.clip((top - V[toe, 2]) / top, 0, 1)   # a toe box
        set_verts(ob, V)
        if sneaker:
            ob.data.materials.append(bpy.data.materials[self.mats["sneaker_sole"][0]])
            for poly in ob.data.polygons:
                if max(ob.data.vertices[i].co.z for i in poly.vertices) < SOLE:
                    poly.material_index = 1

    def build(self) -> list[bpy.types.Object]:
        """The person's outfit, and the skin under it deleted."""
        objs = self.dress(self.sp.outfit)
        delete_covered(self.body, self.covered)
        return objs

    def dress(self, outfit: str) -> list[bpy.types.Object]:
        """Cut `outfit` from the body; the skin it covers is only marked (`covered`), so several
        outfits can be cut from one body (the creator's)."""
        mk = self.mk
        top = mk.waist + 0.012 if outfit in TUCKED else mk.waist - 0.02
        thick = 0.014 if outfit == "monteur" else 0.012
        self.add("trousers", self.lower(top, mk.ankle + 0.012), TROUSERS.get(outfit, "trousers"), thick, iters=12, kind="legs")
        getattr(self, "top_" + outfit)()
        self.shoes(SHOES.get(outfit, "shoe"))
        return self.objs

    # --- the tops, one per outfit (outer layers sit further off the skin than what they cover)
    def top_business(self) -> None:
        """The Voltana polo: short sleeves, a stand collar, the logo on the chest."""
        mk = self.mk
        polo = self.add("polo", self.upper(mk.hip - 0.035, self.short_sleeve(), 0.005, vee=0.05), "polo", 0.02, iters=10, kind="upper")
        extrude_collar(polo, mk, 0.022, 0.006)
        self.logo(polo, (0.085, mk.chest + 0.03), 0.07)

    def top_shirt(self) -> None:
        mk = self.mk
        self.shirt()
        self.add("belt", self.lower(mk.waist + 0.016, mk.waist - 0.02), "belt", 0.018, iters=10, hide=False, kind="legs")

    def top_manager(self) -> None:
        mk = self.mk
        self.shirt()
        self.add("blazer", self.upper(mk.hip + 0.01, mk.wrist_x - 0.03, -0.01) & ~self.front_open(0.055, mk.chest - 0.12),
                 "blazer", 0.016, iters=12, kind="upper")
        self.logo(self.objs[-1], (0.105, mk.chest + 0.04), 0.026)

    def top_monteur(self) -> None:
        mk = self.mk
        self.add("workshirt", self.upper(mk.waist - 0.03, mk.wrist_x - 0.02, 0.0, vee=0.02), "workshirt", 0.008, iters=10, kind="upper")
        vest = self.upper(mk.hip - 0.04, mk.shoulder_x - 0.025, -0.012, vee=0.08)
        ob = self.add("vest", vest, "hivis", 0.02, iters=12, tile=False, kind="upper")
        cylinder_uvs(ob, mk.head.y - 0.03, mk.hip - 0.04, mk.neck)
        self.logo(ob, (0.09, mk.chest + 0.02), 0.07)

    def top_overshirt(self) -> None:
        """An overshirt worn open over a T-shirt, its collar standing round the back of the neck."""
        mk = self.mk
        self.tee()
        ob = self.add("overshirt", self.upper(mk.hip - 0.06, mk.wrist_x - 0.035, -0.004) & ~self.front_open(0.042, mk.hip - 0.1),
                      "overshirt", 0.017, iters=12, kind="upper")
        extrude_collar(ob, mk, 0.026, 0.016, back_only=True)

    def top_sweater(self) -> None:
        """A crew-neck knit over a shirt: the shirt's collar and cuffs show."""
        mk = self.mk
        self.shirt()
        self.add("sweater", self.upper(mk.hip - 0.03, mk.wrist_x - 0.022, 0.016), "sweater", 0.017, iters=12, kind="upper")

    def top_blazer(self) -> None:
        """An unstructured blazer, open over a T-shirt (with jeans and sneakers)."""
        mk = self.mk
        self.tee()
        self.add("blazer", self.upper(mk.hip, mk.wrist_x - 0.03, -0.01) & ~self.front_open(0.06, mk.chest - 0.16),
                 "blazer", 0.016, iters=12, kind="upper")

    def top_quarterzip(self) -> None:
        """A knit with a tall zipped collar, the zip open a hand's width."""
        mk = self.mk
        ob = self.add("quarterzip", self.upper(mk.hip - 0.035, mk.wrist_x - 0.022, -0.008, vee=0.045), "quarterzip", 0.016,
                      iters=12, kind="upper")
        extrude_collar(ob, mk, 0.04, 0.004)
        self.zip(ob, mk.neck + 0.03, mk.chest + 0.03)

    # --- pieces
    def short_sleeve(self) -> float:
        return self.mk.shoulder_x + 0.42 * (self.mk.elbow_x - self.mk.shoulder_x)

    def shirt(self) -> None:
        mk = self.mk
        shirt = self.add("shirt", self.upper(mk.waist - 0.03, mk.wrist_x - 0.012, 0.0, vee=0.03), "shirt", 0.007, iters=10, kind="upper")
        extrude_collar(shirt, mk, 0.028, 0.005)

    def tee(self) -> None:
        mk = self.mk
        self.add("tee", self.upper(mk.hip - 0.025, self.short_sleeve() - 0.02, 0.008), "tee", 0.007, iters=10, kind="upper")

    def front_open(self, half: float, bottom: float) -> np.ndarray:
        """The front left open (a jacket's V, an open shirt): `half` m each side of the middle at
        the top, closing to nothing at `bottom`."""
        V, mk = self.V, self.mk
        return (V[:, 1] < mk.head.y - 0.02) & (V[:, 2] > bottom) & \
            (np.abs(V[:, 0]) < half * np.clip((V[:, 2] - bottom) / 0.2, 0, 1))

    def zip(self, host, z_top: float, z_bottom: float, w: float = 0.007) -> None:
        """A zip down the middle of `host`'s front: a strip of quads following the cloth."""
        bvh = BVHTree.FromObject(host, bpy.context.evaluated_depsgraph_get(), deform=False)
        pts = []
        for z in np.linspace(z_bottom, z_top, 9):
            hit, nrm, _, _ = bvh.ray_cast(Vector((0.0, -1.0, float(z))), Vector((0, 1, 0)))
            if hit is not None:
                pts.append((hit + nrm * 0.002, nrm))
        if len(pts) < 2:
            print(f"  no zip on {host.name}")
            return
        V, F = [], []
        for i, (c, nrm) in enumerate(pts):
            side = nrm.cross(Vector((0, 0, 1))).normalized() * (w / 2)
            V += [tuple(c - side), tuple(c + side)]
            if i:
                F.append((2 * i - 2, 2 * i - 1, 2 * i + 1, 2 * i))
        me = bpy.data.meshes.new(f"{self.sp.name}_zip")
        me.from_pydata(V, [], F)
        me.uv_layers.new()
        ob = bpy.data.objects.new(f"{self.sp.name}_zip", me)
        self.coll.objects.link(ob)
        me.materials.append(bpy.data.materials[self.mats["zip"][0]])
        copy_weights_nearest(host, ob)
        bind(ob, self.rig)
        self.objs.append(ob)

    def logo(self, host, at: tuple[float, float], w: float) -> None:
        """The Voltana patch on the chest's left: a quad on the garment, its weights copied."""
        x, z = at
        bvh = BVHTree.FromObject(host, bpy.context.evaluated_depsgraph_get(), deform=False)
        hit, nrm, _, _ = bvh.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)))
        if hit is None:
            print(f"  no logo: nothing on {host.name} at x={x:.2f} z={z:.2f}")
            return
        h = w / 2
        side = nrm.cross(Vector((0, 0, 1))).normalized() * -1
        up = side.cross(nrm).normalized() * -1
        c = hit + nrm * 0.0015
        pts = [c - side * w / 2 - up * h / 2, c + side * w / 2 - up * h / 2, c + side * w / 2 + up * h / 2, c - side * w / 2 + up * h / 2]
        me = bpy.data.meshes.new(f"{self.sp.name}_logo")
        me.from_pydata([tuple(p) for p in pts], [], [(0, 1, 2, 3)])
        uv = me.uv_layers.new().data
        for i, u in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
            uv[i].uv = u
        ob = bpy.data.objects.new(f"{self.sp.name}_logo", me)
        self.coll.objects.link(ob)
        me.materials.append(bpy.data.materials[self.mats["logo"][0]])
        copy_weights_nearest(host, ob)
        bind(ob, self.rig)
        self.objs.append(ob)


def copy_weights_nearest(src, dst) -> None:
    """Each of dst's vertices takes the weights of src's nearest vertex."""
    from mathutils.kdtree import KDTree
    kd = KDTree(len(src.data.vertices))
    for v in src.data.vertices:
        kd.insert(v.co, v.index)
    kd.balance()
    names = [g.name for g in src.vertex_groups]
    groups = {}
    for v in dst.data.vertices:
        _, i, _ = kd.find(v.co)
        for ge in src.data.vertices[i].groups:
            g = groups.get(names[ge.group]) or dst.vertex_groups.new(name=names[ge.group])
            groups[g.name] = g
            g.add([v.index], ge.weight, "REPLACE")


# ============================================================================= hair, eyes, extras

def tube(name: str, path: list, radii: list, sides: int = 10, close: bool = False) -> bpy.types.Mesh:
    """A tube along a polyline (closed: a ring), radius per point."""
    P = [Vector(p) for p in path]
    n = len(P)
    bm = bmesh.new()
    rings = []
    prev_side = None
    for i, p in enumerate(P):
        a = P[(i - 1) % n] if (close or i > 0) else P[i]
        b = P[(i + 1) % n] if (close or i < n - 1) else P[i]
        d = (b - a).normalized()
        side = (prev_side - d * prev_side.dot(d)).normalized() if prev_side else d.orthogonal().normalized()
        prev_side = side
        up = d.cross(side)
        rings.append([bm.verts.new(p + (side * math.cos(2 * math.pi * k / sides) + up * math.sin(2 * math.pi * k / sides)) * radii[i])
                      for k in range(sides)])
    for i in range(n if close else n - 1):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(sides):
            bm.faces.new((r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]))
    if not close:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    return me


def rigid(ob, bone: str = "Head") -> None:
    g = ob.vertex_groups.new(name=bone)
    g.add(list(range(len(ob.data.vertices))), 1.0, "REPLACE")


def trim_receding(hair, head: Vector) -> None:
    """A receding hairline: the hair over the forehead and temples goes, the crown stays thinner."""
    bm = bmesh.new()
    bm.from_mesh(hair.data)
    dead = []
    for f in bm.faces:
        c = f.calc_center_median()
        fwd = head.y - c.y          # towards the face
        up = c.z - head.z
        if fwd > 0.03 and up > 0.085 - 0.6 * max(0.0, abs(c.x) - 0.02):
            dead.append(f)
        elif fwd > 0.055:
            dead.append(f)
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(hair.data)
    bm.free()


def ponytail(name: str, head: Vector, coll) -> bpy.types.Object:
    """A tied ponytail falling from the back of the head (rigid on the Head bone)."""
    c = head
    path = [(0, c.y + 0.085, c.z + 0.14), (0, c.y + 0.115, c.z + 0.11), (0, c.y + 0.13, c.z + 0.05),
            (0, c.y + 0.125, c.z - 0.02), (0, c.y + 0.11, c.z - 0.09), (0, c.y + 0.1, c.z - 0.14)]
    me = tube(name, path, [0.02, 0.03, 0.032, 0.027, 0.018, 0.006], sides=12)
    uv = me.uv_layers.new().data
    for poly in me.polygons:
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            uv[li].uv = ((math.atan2(co.x, co.y - c.y - 0.11) + math.pi) * 0.3, (co.z - c.z) * 5)
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    rigid(ob)
    return ob


GLASSES = {   # style -> (half width, half height of a rim, superellipse exponent (2: an ellipse), rim radius) (m)
    "round": (0.021, 0.02, 2.0, 0.0016),     # thin metal
    "rect": (0.026, 0.0165, 4.0, 0.0024),    # black acetate, rectangular
    "clear": (0.025, 0.019, 3.0, 0.0028),    # a thick see-through frame
    "large": (0.027, 0.026, 2.2, 0.0024),    # big and round
}


def glasses(name: str, style: str, body, eyes, coll) -> bpy.types.Object:
    """Frames only (no lenses: clear glass only shows as a sheen at this distance): two rims in
    front of the eyes, a bridge, temples back to the ears. `style`: a key of GLASSES."""
    half_rx, half_rz, k, thick = GLASSES[style]
    E = verts(eyes)
    left, right = E[E[:, 0] > 0].mean(0), E[E[:, 0] < 0].mean(0)
    front = float(E[:, 1].min()) - 0.012 - (thick - 0.0016)
    V = verts(body)
    band = V[np.abs(V[:, 2] - left[2]) < 0.012]
    half_w = float(np.abs(band[:, 0]).max()) + 0.002
    ear_y = float(band[np.argmax(np.abs(band[:, 0])), 1]) + 0.01
    parts = []
    for c in (left, right):
        cx, cz = float(c[0]), float(c[2]) - 0.002
        ring = []
        for a in np.linspace(0, 2 * math.pi, 28, endpoint=False):
            ca, sa = math.cos(a), math.sin(a)
            rx = half_rx * math.copysign(abs(ca) ** (2 / k), ca)
            rz = half_rz * math.copysign(abs(sa) ** (2 / k), sa)
            ring.append((cx + rx, front + 0.002 * (1 - abs(ca)), cz + rz))
        parts.append(tube("rim", ring, [thick] * len(ring), sides=6, close=True))
        sign = 1 if cx > 0 else -1
        outer = (cx + sign * half_rx, front, cz + 0.004)
        parts.append(tube("temple", [outer, (sign * half_w, front + 0.02, cz + 0.006), (sign * half_w, ear_y, cz + 0.004),
                                     (sign * (half_w - 0.004), ear_y + 0.02, cz - 0.02)], [max(0.0016, thick * 0.8)] * 4, sides=6))
    parts.append(tube("bridge", [(left[0] - half_rx, front, left[2] + 0.004), (0, front - 0.003, left[2] + 0.009),
                                 (right[0] + half_rx, front, right[2] + 0.004)], [max(0.0016, thick * 0.8)] * 3, sides=6))
    bm = bmesh.new()
    for me in parts:
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    rigid(ob)
    return ob


def short_beard(beard, body, keep: float = 0.35) -> None:
    """A trimmed beard: the pack's full beard pulled to `keep` of its depth off the skin."""
    bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get(), deform=False)
    V = verts(beard)
    for i, p in enumerate(V):
        loc, nrm, _, _ = bvh.find_nearest(Vector(p))
        if loc is not None:
            V[i] = np.array(loc) + (p - np.array(loc)) * keep + np.array(nrm) * 0.0015
    set_verts(beard, V)


def split_iris(eyes, iris_index: int) -> None:
    """Faces of the eye mesh inside the iris (in the eye texture) take the iris material."""
    me = eyes.data
    uv = me.uv_layers.active.data
    for poly in me.polygons:
        u = np.mean([uv[li].uv[:] for li in poly.loop_indices], 0)
        if math.hypot(u[0] - IRIS_UV[0], u[1] - IRIS_UV[1]) < IRIS_R:
            poly.material_index = iris_index


# ============================================================================= materials

def lean_mesh(ob) -> None:
    """Only what the game uses: one UV map, no colour layers (the pack carries spares), smooth
    shading, and the mesh named after its object."""
    me = ob.data
    me.name = ob.name
    keep = me.uv_layers.active or (me.uv_layers[0] if me.uv_layers else None)
    for uv in [u for u in me.uv_layers if u != keep]:
        me.uv_layers.remove(uv)
    for ca in list(me.color_attributes):
        me.color_attributes.remove(ca)
    for poly in me.polygons:
        poly.use_smooth = True


def make_materials(sp) -> dict[str, tuple[str, str | None]]:
    """The scripted builder's garment materials plus the pack's skin, hair, brow and eye ones.
    Clothes are double-sided (a hem shows its inside)."""
    out = bc.make_materials(sp)
    p = sp.name
    skin = tuple(min(255, c / SKIN_HEADROOM) for c in sp.skin)
    brow = sp.brow_color or tuple(c * 0.8 for c in sp.hair_color)
    for key, kw in {
        "skin": dict(color=skin, tex=f"skin_{sp.sex}", rough=0.6),
        "hair": dict(color=sp.hair_color, tex="hairpack_2", rough=0.55),
        "hair1": dict(color=sp.hair_color, tex="hairpack_1", rough=0.55),
        "brow": dict(color=brow, tex="hairpack_1", rough=0.6),
        "eye": dict(color=(255, 255, 255), tex="eye", rough=0.15),
        "iris": dict(color=sp.eye_color, tex="eye", rough=0.1),
    }.items():
        name = f"{p}__{key}"
        if name in bpy.data.materials:
            bpy.data.materials.remove(bpy.data.materials[name])
        out[key] = (bc.material(name, **kw).name, kw.get("tex"))
    for key, (color, tex, rough, metal) in MORE_GARMENTS.items():
        out[key] = (bc.material(f"{p}__{key}", sp.colors.get(key, color), tex=tex, rough=rough, metal=metal).name, tex)
    for key in ("polo", "chinos", "shirt", "trousers", "blazer", "workshirt", "worktrousers", "belt", "shoe", "boot", "hivis",
                *MORE_GARMENTS):
        bpy.data.materials[out[key][0]].use_backface_culling = False
    return out


# The creator's garments (PLAN 2.7b): key -> (colour sRGB, shared texture, roughness, metal);
# cast.json `colors` (or the creator's outfit colours) override the colour.
MORE_GARMENTS = {
    "tee": ((238, 238, 234), "oxford", 0.85, 0.0),
    "overshirt": ((92, 100, 70), "twill", 0.85, 0.0),
    "sweater": ((38, 58, 72), "knit", 0.9, 0.0),
    "quarterzip": ((128, 130, 136), "knit", 0.9, 0.0),
    "jeans": ((46, 60, 94), "twill", 0.85, 0.0),       # dark denim: a twill weave (the denim map reads as a print)
    "sneaker": ((238, 238, 234), "leather", 0.5, 0.0),
    "sneaker_sole": ((216, 212, 202), None, 0.75, 0.0),
    "zip": ((58, 60, 64), None, 0.35, 0.6),
}


def set_material(ob, mat_name: str) -> None:
    ob.data.materials.clear()
    ob.data.materials.append(bpy.data.materials[mat_name])
    for poly in ob.data.polygons:
        poly.material_index = 0


# ============================================================================= retargeting

class Source:
    """An animation library loaded once: its rig, clips and bone map to Godot names."""

    def __init__(self, path: Path, ue_names: dict[str, str] | None):
        objs = import_gltf(path)
        self.rig = armature_of(objs)
        for o in objs:
            if o.type == "MESH":
                bpy.data.objects.remove(o)
        self.rig.name = f"src_{path.stem}"
        self.map = {}
        for b in self.rig.data.bones:
            ue = ue_names.get(b.name) if ue_names is not None else b.name
            if ue in UE_TO_GODOT:
                self.map[b.name] = UE_TO_GODOT[ue]
        self.hips = next(k for k, v in self.map.items() if v == "Hips")
        self.thigh = next(k for k, v in self.map.items() if v == "LeftUpperLeg")
        self.foot = next(k for k, v in self.map.items() if v == "LeftFoot")
        self.rest = {b.name: b.matrix_local.to_quaternion() for b in self.rig.data.bones}
        self.hips_rest = self.rig.data.bones[self.hips].head_local.copy()

    def length(self, clip: str) -> float:
        lo, hi = bpy.data.actions[clip].frame_range
        return float(hi - lo)

    def leg(self) -> float:
        """Hip joint to ankle height in rest (the hips' travel scales by the ratio of legs)."""
        b = self.rig.data.bones
        return b[self.thigh].head_local.z - b[self.foot].head_local.z

    def clip(self, name: str) -> tuple[float, float]:
        solo(self.rig, name)
        lo, hi = bpy.data.actions[name].frame_range
        return float(lo), float(hi)

    def sample(self, frame: float) -> tuple[dict[str, Quaternion], Vector]:
        """World (armature space) rotation of each mapped bone relative to its rest, and the hips' travel."""
        f = math.floor(frame)
        bpy.context.scene.frame_set(int(f), subframe=frame - f)
        deltas = {}
        for src, dst in self.map.items():
            q = self.rig.pose.bones[src].matrix.to_quaternion()
            deltas[dst] = q @ self.rest[src].inverted()
        hips = self.rig.pose.bones[self.hips].matrix.translation - self.hips_rest
        return deltas, hips


class Target:
    """The person's rig: rest rotations, the bone order, keyframing world rotations."""

    def __init__(self, rig):
        self.rig = rig
        self.rest = {b.name: b.matrix_local.to_quaternion() for b in rig.data.bones}
        self.order = [b.name for b in rig.data.bones]   # parents before children
        self.parent = {b.name: (b.parent.name if b.parent else None) for b in rig.data.bones}
        self.rest_head = {b.name: b.head_local.copy() for b in rig.data.bones}

    def world(self, deltas: dict[str, Quaternion]) -> dict[str, Quaternion]:
        out = {}
        for b in self.order:
            if b in deltas:
                out[b] = deltas[b] @ self.rest[b]
            else:
                p = self.parent[b]
                out[b] = out[p] @ self.rest[p].inverted() @ self.rest[b] if p else self.rest[b]
        return out

    def basis(self, world: dict[str, Quaternion]) -> dict[str, Quaternion]:
        out = {}
        for b in self.order:
            p = self.parent[b]
            if p is None:
                out[b] = self.rest[b].inverted() @ world[b]
            else:
                rest_rel = self.rest[p].inverted() @ self.rest[b]
                out[b] = rest_rel.inverted() @ world[p].inverted() @ world[b]
            out[b].normalize()
        return out

    def key(self, frame: int, world: dict[str, Quaternion], hips: Vector) -> None:
        basis = self.basis(world)
        for b in self.order:
            pb = self.rig.pose.bones[b]
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = basis[b]
            pb.keyframe_insert("rotation_quaternion", frame=frame)
        hb = self.rig.pose.bones["Hips"]
        hb.location = self.rest["Hips"].inverted() @ (hips - self.rest_head["Hips"])
        hb.keyframe_insert("location", frame=frame)

    def compose(self, world: dict[str, Quaternion], absolute: dict | None = None, local: dict | None = None) -> dict[str, Quaternion]:
        """A pose changed at some bones (`absolute`: new world rotations; `local`: new rotations
        relative to the parent), their children following with their own local rotations."""
        absolute, local = absolute or {}, local or {}
        out = {}
        for b in self.order:
            p = self.parent[b]
            if b in absolute:
                out[b] = absolute[b]
            elif p is None:
                out[b] = world[b]
            else:
                out[b] = out[p] @ local.get(b, world[p].inverted() @ world[b])
        return out

    def local(self, world: dict[str, Quaternion], b: str) -> Quaternion:
        return world[self.parent[b]].inverted() @ world[b]

    def rest_local(self, b: str) -> Quaternion:
        p = self.parent[b]
        return self.rest[p].inverted() @ self.rest[b]

    def posed_heads(self, world: dict[str, Quaternion], hips: Vector) -> dict[str, Vector]:
        """Each bone's head in armature space for these world rotations (forward kinematics)."""
        out = {}
        for b in self.order:
            p = self.parent[b]
            if b == "Hips":
                out[b] = hips.copy()
            elif p is None:
                out[b] = self.rest_head[b].copy()
            else:
                off = self.rest[p].inverted() @ (self.rest_head[b] - self.rest_head[p])
                out[b] = out[p] + world[p] @ off
        return out


def scaled(q: Quaternion, amount: float) -> Quaternion:
    """The same rotation axis, `amount` times the angle."""
    axis, angle = q.to_axis_angle()
    if angle > math.pi:
        angle -= 2 * math.pi
    return Quaternion(axis, angle * amount)


def lean(deg: float) -> Quaternion:
    """Forward lean (the person faces -Y): about +X."""
    return Quaternion((1, 0, 0), math.radians(-deg))


def with_stoop(world: dict[str, Quaternion], stoop: float, order: list[str], parent: dict) -> dict[str, Quaternion]:
    """Age in the posture: the back rounds and the head comes forward, the eyes level. Each lean
    is relative to the bone's parent, so they add up along the spine."""
    if not stoop:
        return world
    extra = {"Spine": 5, "Chest": 9, "UpperChest": 4, "Neck": 8, "Head": -20}
    out = dict(world)
    acc = {}
    for b in order:
        p = parent[b]
        up = acc.get(p, Quaternion())
        mine = lean(extra.get(b, 0) * stoop)
        acc[b] = up @ mine
        if acc[b] != Quaternion():
            # rotate this bone's world rotation about its own head by everything above it
            out[b] = acc[b] @ world[b]
    return out


def two_bone(shoulder: Vector, target: Vector, l1: float, l2: float, pole: Vector) -> Vector:
    """The elbow for a shoulder, a wrist target and a pole direction."""
    d = target - shoulder
    dist = min(d.length, (l1 + l2) * 0.999)
    u = d.normalized()
    a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
    h = math.sqrt(max(l1 * l1 - a * a, 0.0))
    p = (pole - u * pole.dot(u)).normalized()
    return shoulder + u * a + p * h


def frame_rot(d0: Vector, n0: Vector, d1: Vector, n1: Vector) -> Quaternion:
    """The rotation taking direction d0 (with a second direction n0) to d1 (with n1)."""
    def basis(d, n):
        d = d.normalized()
        n = (n - d * n.dot(d)).normalized()
        return Matrix((d, n, d.cross(n))).transposed()
    return (basis(d1, n1) @ basis(d0, n0).inverted()).to_quaternion()


class Animator:
    """Retargets the library clips onto one person and adds the office's own touches."""

    def __init__(self, target: Target, sources: dict[str, Source], sp):
        self.t, self.sources, self.sp = target, sources, sp
        self.rig = target.rig
        self.rig.animation_data_create()

    def retarget(self, name: str, clip: tuple[str, str], frames: int | None = None, loops: int = 1, edit=None) -> bpy.types.Action:
        src = self.sources[clip[0]]
        lo, hi = src.clip(clip[1])
        length = hi - lo
        n = frames or int(round(length * loops))
        leg = (self.t.rest_head["LeftUpperLeg"].z - self.t.rest_head["LeftFoot"].z) / src.leg()
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        self.rig.animation_data.action = act
        for f in range(n + 1):
            phase = (f % n) / n
            deltas, travel = src.sample(lo + (phase * loops % 1.0) * length)
            hips = self.t.rest_head["Hips"] + travel * leg
            world = with_stoop(self.t.world(deltas), self.sp.stoop, self.t.order, self.t.parent)
            if edit:
                world, hips = edit(f, phase, world, hips)
            self.t.key(f + 1, world, hips)
        track = self.rig.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, 1, act)
        self.rig.animation_data.action = None
        return act

    def relax(self, world, fingers: float = 0.45, arms_in: float = 9.0, legs: float = 0.0) -> dict[str, Quaternion]:
        """The library's men stand like heroes: fists, arms out, feet wide. Office people: finger
        curls scaled by `fingers`, the upper arms turned `arms_in` degrees towards the body, the
        thighs' spread blended `legs` of the way to rest."""
        local, absolute = {}, {}
        for side in ("Left", "Right"):
            for finger in ("Index", "Middle", "Ring", "Little", "Thumb"):
                for joint in (("Metacarpal", "Proximal", "Distal") if finger == "Thumb" else ("Proximal", "Intermediate", "Distal")):
                    b = side + finger + joint
                    ref = self.t.rest_local(b)
                    local[b] = ref @ scaled(ref.inverted() @ self.t.local(world, b), fingers)
            if legs:
                b = side + "UpperLeg"
                local[b] = self.t.local(world, b).slerp(self.t.rest_local(b), legs)
        world = self.t.compose(world, local=local)
        for side, sx in (("Left", 1), ("Right", -1)):
            absolute[side + "UpperArm"] = Quaternion((0, 1, 0), math.radians(sx * arms_in)) @ world[side + "UpperArm"]
        return self.t.compose(world, absolute=absolute)

    def standing(self, legs: float):
        def edit(f, phase, world, hips):
            return self.relax(world, legs=legs), hips
        return edit

    def ground(self, act_name: str, frames: int) -> None:
        """Lower (or raise) the hips per frame so the lower foot touches the floor as in rest."""
        rig = self.rig
        solo(rig, act_name)
        rest_foot = self.t.rest_head["LeftFoot"].z
        hb = rig.pose.bones["Hips"]
        rest_rot = self.t.rest["Hips"]
        for f in range(1, frames + 2):
            bpy.context.scene.frame_set(f)
            low = min((rig.matrix_world @ rig.pose.bones[s + "Foot"].head).z for s in ("Left", "Right"))
            toe = min((rig.matrix_world @ rig.pose.bones[s + "Toes"].head).z for s in ("Left", "Right"))
            lift = min(low - rest_foot, toe - self.t.rest_head["LeftToes"].z)
            world_loc = rest_rot @ hb.location
            world_loc.z -= lift
            hb.location = rest_rot.inverted() @ world_loc
            hb.keyframe_insert("location", frame=f)
        solo(rig, None)

    # --- seated at the desk, typing
    def sit_edit(self):
        t = self.t
        rh = t.rest_head
        thigh_len = (rh["LeftLowerLeg"] - rh["LeftUpperLeg"]).length
        shin_len = (rh["LeftFoot"] - rh["LeftLowerLeg"]).length
        ankle = rh["LeftFoot"].z
        upper_len = (rh["LeftLowerArm"] - rh["LeftUpperArm"]).length
        fore_len = (rh["LeftHand"] - rh["LeftLowerArm"]).length

        def palm(side):
            h = rh[f"{side}Hand"]
            f = rh[f"{side}MiddleProximal"] - h
            a = rh[f"{side}IndexProximal"] - rh[f"{side}LittleProximal"]
            n = f.cross(a).normalized()
            return -n if n.z > 0 else n          # the T-pose's palms face down
        palms = {s: palm(s) for s in ("Left", "Right")}

        mid = (rh["LeftUpperLeg"] + rh["RightUpperLeg"]) / 2 - rh["Hips"]   # hip joints from the Hips bone

        def edit(f, phase, world, hips):
            # the hip joints on the chair, whatever the library's seat height
            hips = Vector((0, SEAT_BACK, SEAT_HIP)) - (world["Hips"] @ t.rest["Hips"].inverted()) @ mid
            heads = t.posed_heads(world, hips)
            legs = {}
            for side, sx in (("Left", 1), ("Right", -1)):
                hip = heads[f"{side}UpperLeg"]
                drop = hip.z - (ankle + shin_len)
                fwd = math.sqrt(max(thigh_len ** 2 - drop ** 2, 0.0))
                knee = hip + Vector((sx * 0.05, -fwd, -drop)).normalized() * thigh_len
                foot = knee + Vector((0, -0.02, -shin_len)).normalized() * shin_len
                swing = lambda b, a, c: (rh[c] - rh[a]).rotation_difference(b)  # noqa: E731
                legs[f"{side}UpperLeg"] = swing(knee - hip, f"{side}UpperLeg", f"{side}LowerLeg") @ t.rest[f"{side}UpperLeg"]
                legs[f"{side}LowerLeg"] = swing(foot - knee, f"{side}LowerLeg", f"{side}Foot") @ t.rest[f"{side}LowerLeg"]
                legs[f"{side}Foot"] = t.rest[f"{side}Foot"]
            world = t.compose(world, absolute=legs)
            # arms: wrists at the keyboard, elbows down and a little out; a typing tap
            world = t.compose(world, absolute=self.type_arms(world, hips, phase, upper_len, fore_len, palms))
            return self.relax(world, arms_in=0.0, fingers=0.7), hips
        return edit

    def type_arms(self, world, hips, phase, l1, l2, palms) -> dict[str, Quaternion]:
        t = self.t
        rh = t.rest_head
        heads = t.posed_heads(world, hips)
        out = {}
        typing = bc.smoothstep(0.0, 0.05, phase) * bc.smoothstep(0.75, 0.68, phase)
        for side, sx in (("Left", 1), ("Right", -1)):
            tap = math.sin(2 * math.pi * (phase * 14 + (0.25 if sx > 0 else 0.0)))
            shoulder = heads[f"{side}UpperArm"]
            wrist = Vector((KEYBOARD[0] + sx * 0.12, KEYBOARD[1], KEYBOARD[2] + 0.006 * tap * typing))
            elbow = two_bone(shoulder, wrist, l1, l2, Vector((sx * 0.45, 0.35, -1)))
            d0 = rh[f"{side}LowerArm"] - rh[f"{side}UpperArm"]
            f0 = rh[f"{side}Hand"] - rh[f"{side}LowerArm"]
            hinge0 = d0.cross(Vector((0, -1, 0)))
            d1, f1 = elbow - shoulder, wrist - elbow
            hinge1 = d1.cross(f1)
            out[f"{side}UpperArm"] = frame_rot(d0, hinge0, d1, hinge1) @ t.rest[f"{side}UpperArm"]
            down = Vector((-sx * 0.25, 0, -1))
            out[f"{side}LowerArm"] = frame_rot(f0, palms[side], f1, down) @ t.rest[f"{side}LowerArm"]
            hand_dir = Vector((-sx * 0.12, -1, -0.12 - 0.08 * tap * typing))
            h0 = rh[f"{side}MiddleProximal"] - rh[f"{side}Hand"]
            out[f"{side}Hand"] = frame_rot(h0, palms[side], hand_dir, down) @ t.rest[f"{side}Hand"]
        return out


def pace_of(rig, action_name: str, frames: int) -> float:
    """Ground speed (m/s) of an in-place cycle: the planted foot's backward speed while it is on
    the floor (the ankle or the ball of the foot within CONTACT of its standing height),
    sampled finely. The game measures it the same way."""
    solo(rig, action_name)
    n = 240
    pts = []
    for k in range(n + 1):
        x = 1 + frames * k / n
        f = math.floor(x)
        bpy.context.scene.frame_set(int(f), subframe=x - f)
        pts.append([(rig.matrix_world @ rig.pose.bones[b].head).copy() for b in ("LeftFoot", "LeftToes")])
    solo(rig, None)
    rest = [rig.data.bones[b].head_local.z for b in ("LeftFoot", "LeftToes")]
    dt = frames / FPS / n
    v = []
    for i in range(n):
        for j in (0, 1):   # the ankle or the ball of the foot, whichever is on the floor
            if pts[i][j].z < rest[j] + CONTACT and pts[i + 1][j].z < rest[j] + CONTACT:
                v.append((pts[i + 1][j].y - pts[i][j].y) / dt)
                break
    return float(np.median(v)) if v else 0.0


CONTACT = 0.02   # a foot is on the floor within this of its standing height (m)


# ============================================================================= one person

def base_body(paths: dict, sex: str, coll) -> tuple[bpy.types.Object, dict[str, bpy.types.Object]]:
    objs = import_gltf(paths[f"body_{sex}"])
    rig = armature_of(objs)
    parts = {}
    for o in objs:
        for c in o.users_collection:
            c.objects.unlink(o)
        coll.objects.link(o)
        if o.type == "MESH":
            key = "eyes" if o.name.startswith("Eyes") else "brows" if o.name.startswith("Eyebrows") else "body"
            parts[key] = o
    weld(parts["body"])
    rig.name = f"{coll.name}_rig"
    return rig, parts


def weld(ob) -> None:
    """Merge the vertices glTF split along UV seams (UVs live on the corners, so they stay):
    a garment copied from the body must not open along them."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(ob.data)
    bm.free()


def import_part(paths: dict, style: str, rig, coll) -> bpy.types.Object:
    """A pack hairstyle (or the beard) moved onto `rig`'s Head and bound to it."""
    objs = import_gltf(paths["hair"] / f"{style}.gltf")
    src = armature_of(objs)
    mesh = next(o for o in objs if o.type == "MESH")
    for c in mesh.users_collection:
        c.objects.unlink(mesh)
    coll.objects.link(mesh)
    rename_rig(src, [mesh])
    transplant(mesh, src, rig)
    for o in objs:
        if o is not mesh:
            bpy.data.objects.remove(o)
    bind(mesh, rig)
    return mesh


def head_parts(sp, paths, rig, parts, coll, mats) -> list[bpy.types.Object]:
    """Hair (pack style, trimmed or with a ponytail), beard and glasses as the cast says."""
    styles, trim = HAIR.get(sp.hair_style, HAIR["short"])
    out = []
    hair = import_part(paths, styles[sp.sex], rig, coll)
    hair.name = f"{sp.name}_hair"
    tex_key = "hair1" if any(m and m.name.startswith("MI_Hair_1") for m in hair.data.materials) else "hair"
    set_material(hair, mats[tex_key][0])
    head = head_of(rig, "Head")
    if trim == "receding":
        trim_receding(hair, head)
    out.append(hair)
    if trim == "ponytail":
        tail = ponytail(f"{sp.name}_ponytail", head, coll)
        set_material(tail, mats["hair"][0])
        bind(tail, rig)
        out.append(tail)
    if sp.beard:
        beard = import_part(paths, "Hair_Beard", rig, coll)
        beard.name = f"{sp.name}_beard"
        set_material(beard, mats["hair1"][0])
        if sp.beard == "short":
            short_beard(beard, parts["body"])
        out.append(beard)
    if sp.glasses:
        g = glasses(f"{sp.name}_glasses", "rect", parts["body"], parts["eyes"], coll)
        set_material(g, mats["frame"][0])
        bind(g, rig)
        out.append(g)
    return out


def build_person(sp, paths: dict, sources: dict[str, Source]) -> tuple[bpy.types.Collection, bpy.types.Object]:
    t0 = time.time()
    coll = bpy.data.collections.new(sp.name)
    bpy.context.scene.collection.children.link(coll)
    mats = make_materials(sp)
    rig, parts = base_body(paths, sp.sex, coll)
    meshes = [parts["body"], parts["eyes"], parts["brows"]]
    rename_rig(rig, meshes)
    for o in meshes:
        bind(o, rig)
    extras = head_parts(sp, paths, rig, parts, coll, mats)
    soften(parts["body"])
    narrow_shoulders(rig, [parts["body"]], SHOULDER_IN[sp.sex])
    reshape(rig, meshes + extras, sp.height, girth_for(sp))
    set_material(parts["body"], mats["skin"][0])
    set_material(parts["brows"], mats["brow"][0])
    eyes = parts["eyes"]
    set_material(eyes, mats["eye"][0])
    eyes.data.materials.append(bpy.data.materials[mats["iris"][0]])
    split_iris(eyes, 1)
    garments = Wardrobe(sp, rig, parts["body"], coll, mats).build()
    for key, ob in (("body", parts["body"]), ("eyes", eyes), ("brows", parts["brows"])):
        ob.name = f"{sp.name}_{key}"
    for ob in meshes + extras + garments:
        ob.name = ob.name if ob.name.startswith(sp.name) else f"{sp.name}_{ob.name}"
        lean_mesh(ob)

    animate(sp, rig, sources)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes + extras + garments)
    print(f"{sp.name}: {tris} triangles, {len(meshes + extras + garments)} meshes, {time.time() - t0:.0f} s")
    return coll, rig


def animate(sp, rig, sources: dict[str, Source]) -> dict[str, float]:
    target = Target(rig)
    an = Animator(target, sources, sp)
    an.retarget("idle_loop", CLIPS["idle"], edit=an.standing(0.45))
    an.ground("idle_loop", int(round(sources["ual1"].length(CLIPS["idle"][1]))))
    an.retarget("talk_loop", CLIPS["talk"], edit=an.standing(0.35))
    an.ground("talk_loop", int(round(sources["ual1"].length(CLIPS["talk"][1]))))
    an.retarget("sit_loop", CLIPS["sit"], frames=120, loops=3, edit=an.sit_edit())
    walk_clip = CLIPS["walk_monteur" if sp.outfit == "monteur" else "walk"]
    an.retarget("walk_loop", walk_clip, frames=WALK_FRAMES, edit=an.standing(0.0))
    # the jog, timed so it runs at JOG_PACE at speed 1: measure it once, then rebuild at the right length
    probe = an.retarget("jog_probe", CLIPS["jog"])
    lo, hi = sources[CLIPS["jog"][0]].clip(CLIPS["jog"][1])
    native = int(round(hi - lo))
    pace = pace_of(rig, "jog_probe", native)
    rig.animation_data.nla_tracks.remove(rig.animation_data.nla_tracks["jog_probe"])
    bpy.data.actions.remove(probe)
    frames = max(12, int(round(native * pace / JOG_PACE)))
    for attempt in range(3):   # the measure is not quite linear in the timing: settle it
        an.retarget("jog_loop", CLIPS["jog"], frames=frames)
        better = max(12, int(round(frames * pace_of(rig, "jog_loop", frames) / JOG_PACE)))
        if better == frames or attempt == 2:
            break
        rig.animation_data.nla_tracks.remove(rig.animation_data.nla_tracks["jog_loop"])
        bpy.data.actions.remove(bpy.data.actions["jog_loop"])
        frames = better
    paces = {"walk": pace_of(rig, "walk_loop", WALK_FRAMES), "jog": pace_of(rig, "jog_loop", frames)}
    print(f"{sp.name}: walk pace {paces['walk']:.2f} m/s, jog pace {paces['jog']:.2f} m/s ({frames} frames)")
    return paces


# ============================================================================= export

def only_head(ob) -> None:
    """A creator part follows the head alone (the pack's are already; this makes sure)."""
    for g in list(ob.vertex_groups):
        ob.vertex_groups.remove(g)
    rigid(ob)


def export(coll, path: Path, animations: bool = True) -> None:
    """A glb of the collection: meshes, skin and (a person's) NLA tracks' keys as they are
    (linear, one per frame; constant channels dropped); no images (the shared textures are
    named in the materials' extras)."""
    layer = bpy.context.view_layer.layer_collection.children[coll.name]
    bpy.context.view_layer.active_layer_collection = layer
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_active_collection=True, export_image_format="NONE",
        export_extras=True, export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=False, export_materials="EXPORT", export_vertex_color="NONE", export_cameras=False,
        export_lights=False, export_skins=True, export_animations=animations, export_animation_mode="NLA_TRACKS",
        export_force_sampling=False, export_optimize_animation_size=True, export_anim_slide_to_zero=True)
    print(f"wrote {path} ({path.stat().st_size / 1e6:.2f} MB)")


# ============================================================================= entry

def run(keys: list[str], pack: Path, blend: Path | None, sheet: Path | None) -> None:
    paths = pack_paths(pack)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bc.make_textures()
    make_pack_textures(paths)
    for key in keys:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.scene.render.fps = FPS
        bpy.context.preferences.edit.keyframe_new_interpolation_type = "LINEAR"
        sources = {"ual1": Source(paths["ual1"], UAL1_TO_UE)}
        sp = bc.CAST_SPECS[key]
        coll, rig = build_person(sp, paths, sources)
        for src in sources.values():
            bpy.data.objects.remove(src.rig)
        if sheet:
            pose_sheet(rig, sheet.with_name(f"{sheet.stem}_{key}{sheet.suffix}"))
        else:
            export(coll, bc.OUT / f"{key}.glb")
            bc.write_import(bc.OUT / f"{key}.glb")
        if blend:
            bpy.ops.wm.save_as_mainfile(filepath=str(blend.with_name(f"{blend.stem}_{key}.blend")))


def pose_sheet(rig, path: Path) -> None:
    """A quick Cycles render of one person in every action (and a chair box under the sitter)."""
    bc.studio(10)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = 1600, 600
    actions = ("idle_loop", "walk_loop", "sit_loop", "talk_loop", "jog_loop")
    for i, action in enumerate(actions):
        dup = rig.copy()
        dup.animation_data_clear()
        dup.animation_data_create()
        sc.collection.objects.link(dup)
        for child in rig.children:
            c = child.copy()
            c.parent = dup
            c.modifiers["Armature"].object = dup
            sc.collection.objects.link(c)
        dup.location = ((i - 2) * 1.0, 0, 0)
        dup.rotation_euler = (0, 0, math.radians(-70 if action in ("sit_loop", "walk_loop", "jog_loop") else -25))
        solo(dup, action)
        if action == "sit_loop":
            bpy.ops.mesh.primitive_cube_add(size=1, location=(dup.location.x, 0.0, 0.26))
            bpy.context.object.scale = (0.48, 0.47, 0.52)
    rig.hide_render = True
    for child in rig.children:
        child.hide_render = True
    sc.frame_set(8)
    bc.render(path, bc.camera("cam_sheet", (0.3, -7.2, 1.5), (0, 0, 0.85), 38))
