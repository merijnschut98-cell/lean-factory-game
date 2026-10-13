# Office task 1 report: art pipeline and the office model

## Built
- `tools/blender/textures.py`: numpy/PIL generators, tileable with normal and ORM maps: carpet tiles
  (0.5 m, quarter-turn), mineral ceiling tiles with T-bar grid, oak laminate, plaster, concrete, paving,
  grass, powder-coated metal, fabric, glass roughness; drawn atlases: obeya boards (KPI board with
  VKLKM run charts, value stream with inventory triangles, action list), mission cork board, signage
  (Voltana logo, zone signs, coach door sign, NOODUITGANG), six Dutch monitor screens, dossiers/binders,
  devices (keyboard, phone, coffee machine), leaves, trees, posters (Zuidmark grid map, safety poster).
- `tools/blender/build_office.py`: bpy build of the 24 x 16 m floor: ribbon windows with RAL 7016
  mullions, sills, convector radiators, roller blinds; suspended ceiling with 600 x 600 LED panels and
  diffusers; concrete columns; blue accent entrance wall with door and exit sign; intake (2 desks,
  trays, phone), werkvoorbereiding (4 desks, dual monitors, dossier backlog on a sideboard and the
  floor, rolls, plotter), planning and klantcontact benches, obeya wall with sticky notes, glass coach
  room with manifestation bands, mission board, pantry with coffee machine, meeting table, lockers,
  huddle table, lounge, plants, posters, outside paving/street/trees/neighbour buildings.
  Cycles bakes the shell lightmaps (sky + panels, no sun). Exports with external textures and
  strips the exporter's placeholder bufferViews (Godot warned about them).
- `game/assets/office/`: `office.glb`, `textures/`, `office_import.gd` (lightmap -> UV2 multiply detail,
  glass casts no shadow), `office_environment.tres`, `preview.tscn` + `preview.gd` (6 camera views).
- Empties: `place:connections.intake` (3.2, 4.75), `place:connections.design` (9.0, 5.4), `obeya`
  (22.6, 3.4), `coach` (22.4, 13.0, inside the glass room), `mission_board` (1.3, 9.9), `spawn`
  (1.6, 7.95) — Blender x, y; floor level; facing the object. In Godot they are named
  `place_connections_intake` etc.; the real id is in `get_meta("extras")["id"]`.

## Numbers
- 70,280 triangles (budget 150k), 223 objects, 61 shared meshes.
- office.glb 1.7 MB; textures/ 17 MB (37 PNGs, max 1024²). Total ~19 MB.

## Screenshots
docs/screenshots/office_1.png (spawn, down the aisle), office_2.png (from the obeya side towards
intake/werkvoorbereiding and the entrance), office_3.png (werkvoorbereiding desks close up).

## Rebuild
See tools/blender/README.md (bpy 5.2.2 in a Python 3.13 venv; full build ~6 min with the bake).

## Concerns
- The lightmaps on disk were baked before the last props (lockers, huddle table, lounge, blinds)
  were added: those items have no baked contact AO on the floor until the next full build
  (`build_office.py` without `--no-bake`).
- Furniture itself has no baked AO (only sun shadows); the compatibility renderer has no SSAO, so
  furniture can look a bit clean/flat. Vertex-colour AO would be the next step.
- Walls lightmap UV packing wastes space (smart project); fine at this distance, blurry up close.
- The sun is in preview.tscn only; Task 3's office.tscn needs the same row-major sun transform
  (light travelling north, 35° down) or the sun shines upward (that bug cost me a round).
- Procedural textures read well at a distance; close up the carpet/wood are plainly synthetic.
  The names allow a 1:1 swap for CC0 photo textures when internet is available.
- Remaining art-director notes: the middle aisle is still roomy, chairs are blocky, no cables or
  personal clutter, the exterior is a backdrop only.
