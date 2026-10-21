# Office art pipeline (Blender, scripted)

The head office (PLAN 2.1) is built entirely by script: no hand-made .blend, no downloaded
assets. Three floors, one glb each, from `game/data/world.json` (the floors and rooms in
`content/world.yaml`): `office_ground.glb` (begane grond), `office.glb` (1e verdieping, the
connections office) and `office_second.glb` (2e verdieping). The game loads one floor at a time.

## Setup (once)
Blender's Python module from PyPI needs the Python version it was built for
(bpy 5.2 = Python 3.13):

    python3.13 -m venv .bvenv
    .bvenv/bin/pip install bpy numpy pillow      # ~400 MB download

## Build
    python tools/build_content.py                            # game/data/world.json (names, floors)
    python3 tools/blender/textures.py                        # textures -> game/assets/office/textures/
    .bvenv/bin/python tools/blender/build_office.py --samples 64   # every floor + lightmap bake (~12 min a floor on 4 cores)
    .bvenv/bin/python tools/blender/build_office.py --floors ground  # one floor
    .bvenv/bin/python tools/blender/build_office.py --no-bake  # seconds: reuses lightmap_*_<floor>.png on disk
    .bvenv/bin/python tools/blender/build_yard.py          # the yard (PLAN 2.2): office_yard.glb, no lightmaps
    godot --headless --path game --import

`--samples N` sets the Cycles bake quality, `--blend out.blend` also saves each floor's scene.
A new floor's glb needs its `.glb.import` beside it naming `office_import.gd` as import script
(copy `office.glb.import` without its uid).
Rebake after moving furniture or walls; the lightmaps hold the shell's AO and soft light.

## Preview
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/floor_shot.gd -- <model:<floor>|play:<floor>|map:<floor>|lift|door> out.png
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/screenshot.gd -- res://assets/office/preview.tscn out.png 30 <view 0-5>

## What is in the glb
- Coordinates: Blender metres, Z up; Godot sees (x, z, -y). The building is x -18..24, y 0..16:
  the east wing x 0..24 (the 1e's connections office, as it always was), the core x -6..0
  (stairs in the north-west, toilets north-east, lift south-east, the hall; the floors' seams)
  and the west wing x -18..-6. Ceiling 2.8 m, storey 3.4 m.
- The seams: `stairs_up`, `stairs_down`, `lift`, and the arrival points `arrive:lift`,
  `arrive:stairs_up`, `arrive:stairs_down`, `arrive:entrance`. Rooms: `room:<id>` (extras `rect`,
  its floor area in Godot x, z) and, for a room that can be shut, `door:<id>` before its door with
  `openleaf_<id>`, `lockleaf_<id>` and `lockcol_<id>-colonly` (the game opens it,
  `office_floors.gd`).
- Signs (`wayfinding_albedo.png`): door signs, floor directories by the lift and three status
  boards, names from world.json; `textures.py wayfinding_rects()` is the shared layout.
- Shell (`shell_floor`, `shell_walls`, `shell_ceiling`): baked lightmap on UV2, exported as the
  glTF occlusion texture. `game/assets/office/office_import.gd` (the import script) turns it into
  a multiply detail layer on UV2 and switches glass shadows off.
- `collision-colonly`: boxes Godot turns into one StaticBody3D (`collision`).
- Interaction empties at floor level, forward (-Z in Godot) facing the object. Godot renames
  `place:connections.intake` to `place_connections_intake` (':' and '.' are invalid in node
  names); the original id is in the node's `extras` metadata: `{"interaction": "place", "id": "connections.intake"}`.
- Textures are external PNGs (`textures/`), referenced by URI, named like CC0 library materials
  (carpet, plaster, concrete, ...) so photo textures can replace them file for file.

## Characters (the CC0 Quaternius pack, re-dressed: PLAN 1.3a)
Who the people are and how they look is one list, `game/assets/characters/cast.json`: the
builder reads each `look`, the office reads each `office` (seat, pose, the missions that
bring someone in). Bodies, hair, eyes and animations come from three free CC0 packs by
Quaternius (sources, versions and checksums: `game/assets/characters/LICENSES.md`); the
clothes, glasses, ponytail and Voltana logo are made here. The packs are fetched, not
committed:

    python3 tools/blender/fetch_pack.py                                   # -> .pack/ (~150 MB, CC0 checked)
    .bvenv/bin/python tools/blender/build_character.py                     # every glb (~10 s each)
    .bvenv/bin/python tools/blender/build_character.py --creator           # the creator's bodies, parts, masks (~1 min)
    .bvenv/bin/python tools/blender/build_character.py --only henk --pose-sheet /tmp/sheet.png  # Cycles check
    .bvenv/bin/python tools/blender/build_character.py --method script --no-render   # the scripted fallback
    godot --headless --path game --import
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/characters_shot.gd -- $PWD/docs/screenshots/characters_pack_lineup.png 30 lineup

- `game/assets/characters/<id>.glb`, ~1 MB each: the pack's humanoid rig renamed to Godot's
  `SkeletonProfileHumanoid` bone names; actions `idle_loop`, `walk_loop`, `sit_loop` (typing at
  a desk, the origin on the chair), `talk_loop` and `jog_loop` (the run), imported as looping
  `idle`, `walk`, `sit`, `talk`, `jog`; and the reaction clips (`react()` in `pack_character.py`, Phase 2
  §1.4): `arms_folded_loop`, `phone_loop`, `lean_loop`, `tired_loop`, `carry_loop`, `sit_talk_loop`,
  `sit_tired_loop`, and the one-shots `nod` and `look_away`. `--pose-sheet` renders every clip in a row. Looks: sex (two base bodies), height (the head keeps its
  size), build (waist, hips, limbs), skin/hair/eye colours, hair (bob, short, buzz, receding,
  ponytail, buns), beard (full, short), glasses, outfit (polo with logo, shirt and belt,
  blazer, monteur: work shirt, hi-vis vest, boots, optional helmet), stoop (age).
- Paces: the walk's and the jog's ground speed are measured from the planted foot (printed by the
  builder, measured again in the game: `CharacterModel.walk_pace`, `jog_pace`); the jog is timed
  so it runs at 4.5 m/s at speed 1. `test_characters.gd` checks that a foot on the floor slides
  less than 4 cm while the person moves at that pace.
- Textures are shared, not embedded: `game/assets/characters/textures/` (fabric 256 px greyscale;
  skin 1024 px, hair 512 px and eyes 256 px from the pack, all tints). A glb's materials carry the
  colour and `{"texture": name}` in their extras; `character_import.gd` (the import script each
  `.glb.import` names, written by the builder for a new file) lays the texture under the colour.
  So colours are material parameters (`CharacterModel.tint`).
- The character creator (PLAN 2.7b): `game/assets/characters/creator_options.json` lists every
  trait and option (its `_about` documents the fields); `--creator` (`creator_build.py`) reads it
  and builds what it names, per body (m, f): `player_<body>.glb` (body, eyes, a separate iris,
  brows, the animations; no hair, no clothes), `parts/outfit_<outfit>_<body>.glb` (cut from that
  body, skinned to its whole skeleton), `parts/<hair|beard|glasses>_<body>.glb` (on `Head`; built
  per body because the heads differ) and `textures/face_<layer>_<body>.png` (stubble and make-up
  masks the game lays over the skin). `CharacterModel.attach(model, part)` moves a part's meshes
  onto the body's skeleton (by bone name); `CreatorLook.build(look)` assembles and tints a look.
  Contact sheets: `creator_shot.gd` with `trait:<trait>`, `outfits`, `poses:<m|f>`.
- Bodies (PLAN 1.3c): the pack's athletes are softened into office bodies (arms moved in,
  muscle relief smoothed, slimmer limbs), and sleeves and trouser legs hang as loose, round
  tubes instead of tracing the muscles.
- Screenshots: `docs/screenshots/characters_pack_*.png`; studio contact sheets (no office) by
      xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
        --script res://tools/creator_shot.gd -- out.png cast        # or poses, parts:<id> (see the script)
