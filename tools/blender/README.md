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
