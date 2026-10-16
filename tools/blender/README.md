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

## Characters (a trial: Blender script vs AI generator vs asset packs)
Who the people are and how they look is one list, `game/assets/characters/cast.json`: the
builder reads each `look`, the office reads each `office` (seat, pose, the missions that
bring someone in). Another character method replaces the builder and keeps the ids.

    .bvenv/bin/python tools/blender/build_character.py --no-render        # every glb (~4 min each)
    .bvenv/bin/python tools/blender/build_character.py --only joost --no-render
    .bvenv/bin/python tools/blender/build_character.py --only henk --draft --pose-sheet /tmp/henk.png  # poses, ~1 min
    .bvenv/bin/python tools/blender/build_character.py --only ruud --only player --only ahmed --samples 32  # + Cycles previews
    godot --headless --path game --import
    xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 \
      --script res://tools/play_shot.gd -- people_desks $PWD/docs/screenshots/play_people_desks.png

- `game/assets/characters/<id>.glb`, ~1 MB each: humanoid rig with Godot `SkeletonProfileHumanoid`
  bone names; actions `idle_loop`, `walk_loop`, `sit_loop` (typing at a desk, the origin on the
  chair) and `talk_loop`, imported as looping `idle`, `walk`, `sit`, `talk`. Variations: sex,
  height, build, skin, hair (bob, short, receding, buzz, ponytail), outfit (polo, shirt, blazer,
  monteur PPE with or without helmet), glasses, stubble, stoop (age).
- The walk sweeps the planted foot back at an even rate; its pace (printed, ~1.7–1.9 m/s) is
  measured again in the game (`CharacterModel.walk_pace`), which plays the walk at
  speed / pace so the feet do not slide.
- Textures are shared, not embedded: `game/assets/characters/textures/` (256 px, greyscale,
  tinted by the material colour). A glb's materials carry the colour and `{"texture": name}` in
  their extras; `character_import.gd` (the import script each `.glb.import` names, written by
  the builder for a new person) lays the texture under the colour. Its import also turns the
  skin's vertex colours into albedo.
- Previews: `docs/screenshots/characters_lineup.png`, `characters_sims_view.png` (Cycles shows the
  colours, not the weave).
