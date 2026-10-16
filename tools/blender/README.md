# Office art pipeline (Blender, scripted)

The connections office (`game/assets/office/office.glb`) is built entirely by script:
no hand-made .blend, no downloaded assets.

## Setup (once)
Blender's Python module from PyPI needs the Python version it was built for
(bpy 5.2 = Python 3.13):

    python3.13 -m venv .bvenv
    .bvenv/bin/pip install bpy numpy pillow      # ~400 MB download

## Build
    python3 tools/blender/textures.py                       # textures -> game/assets/office/textures/
    .bvenv/bin/python tools/blender/build_office.py          # model + lightmap bake (~6 min on 4 cores, 48 samples)
    .bvenv/bin/python tools/blender/build_office.py --no-bake  # seconds: reuses lightmap_*.png on disk
    godot --headless --path game --import

`--samples N` sets the Cycles bake quality, `--blend out.blend` also saves the scene.
Rebake after moving furniture or walls; the lightmaps hold the shell's AO and soft light.

## Preview
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/screenshot.gd -- res://assets/office/preview.tscn out.png 30 <view 0-5>

## What is in the glb
- Coordinates: Blender metres, Z up; Godot sees (x, z, -y). Floor 24 x 16 m, ceiling 2.8 m.
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
    .bvenv/bin/python tools/blender/build_character.py --only joost --parts   # + the creator's parts
    .bvenv/bin/python tools/blender/build_character.py --only henk --pose-sheet /tmp/sheet.png  # Cycles check
    .bvenv/bin/python tools/blender/build_character.py --method script --no-render   # the scripted fallback
    godot --headless --path game --import
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/characters_shot.gd -- $PWD/docs/screenshots/characters_pack_lineup.png 30 lineup

- `game/assets/characters/<id>.glb`, ~1 MB each: the pack's humanoid rig renamed to Godot's
  `SkeletonProfileHumanoid` bone names; actions `idle_loop`, `walk_loop`, `sit_loop` (typing at
  a desk, the origin on the chair), `talk_loop` and `jog_loop` (the run), imported as looping
  `idle`, `walk`, `sit`, `talk`, `jog`. Looks: sex (two base bodies), height (the head keeps its
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
- Creator parts (PLAN 2.7b): `game/assets/characters/parts/` hair_bob, hair_parted, hair_buzzed,
  hair_pixie, hair_buns, hair_ponytail, beard_full, beard_short, glasses_round, glasses_rect;
  each a full skeleton with the part skinned to `Head`. `CharacterModel.attach(model, part)` moves
  the part's mesh onto a person's skeleton (it binds by bone name, so it sits on any head).
- Screenshots: `docs/screenshots/characters_pack_*.png`.
