# Slice 3.2 — *De straat* Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One real 120 m street in Nova-Oost, the Zonnestraat, that the player reaches by van from the yard: twelve houses, a shut corner shop, a trafohuisje, Gert's trench, three residents, the street's tells, and the missions that so far only *told* the player about the field (Sandra's doors, Gert at the hole, El Amrani's front door, the trafohuisje explainer).

**Architecture:** The street is one more "floor" of the world (`content/world.yaml`, `reached_by: van`), built by a Blender script from a small street graph (`content/town.yaml` → `game/data/town.json` → `tools/blender/build_street.py` → `game/assets/office/street.glb`) and loaded by the existing `Office.load_floor()`. A new `OfficeStreet` node (like `OfficeYard`) owns what only the street has: the van back, the bells and doors, the lit windows, the trench, the heat pump. The van ride gains a street branch: a ride with `floor: street` ends at the kerb and you ride back by E at the van. Field steps stay where they are on the yard (spec: the yard's stand-ins are left as they are); the street gets **field markers** (`field:<step>`) that open the same place panel. The El Amrani door reads the winter's outcome through one function, `ElAmraniDoor.state(s)`. Out of scope here: spec §4's Act III moments on the street (the heatwave at the trafohuisje, the storm night) are slice 3.3's tasks; this slice only names the `trafo_vent` node they will use.

**Tech Stack:** Godot 4.7 / GDScript (`game/`, Compatibility renderer), Python 3 content pipeline (`tools/build_content.py`), Blender `bpy` 5.2 scripts (`tools/blender/`, run with `.bvenv/bin/python`), pytest (`tests/`), the Spanning test runner (`python tools/run_godot_tests.py`; one file: `godot --headless --path game --script res://tests/run_tests.gd -- /test_x.gd`).

**Spec:** `docs/superpowers/specs/2026-10-26-phase3-design.md` §4 *De straat* (binding), with §1 (Merijn's decisions: decision 3, "one real street") and §6 (the gate: "frame time on the street ≥ 30 fps on the reference machine"). The parent plan is `docs/superpowers/plans/2026-10-26-phase3-voelbaar.md`; its Global Constraints are copied below verbatim.

**Who builds it:** spec §4 "One agent owns it for the whole phase; a plain look lands before a late one." One implementer takes Tasks 1–14 in order; each task lands alone through the gate (`scratchpad/gate`, `g.sh`, `land.sh`). Task 13 waits for Merijn.

## Global Constraints

(Copied verbatim from the Phase 3 plan.)

- Dutch game text, English code and docs; every UI string through `tr()`; every spoken or on-screen line follows `docs/superpowers/specs/2026-10-19-dutch-style-guide.md` and passes `BANNED_SPOKEN` in `tools/build_content.py`.
- Nothing is handed over: no tell, briefing, codex text or mission name names a problem's cause; the spoiler checks in `build_content.py` (`check_clue_spoilers`, the company check) stay on and are extended to new text.
- Problems arrive only through missions; one main, at most three sides (a routine takes no slot); the coach helps only the main quest.
- Evidence first: every number in content has a `source:` on an approved domain or `estimate:` with its reasoning.
- Network rule (CLAUDE.md §3, verbatim in every agent brief): only the approved domains; agents stop and report instead of fetching anything else.
- Designer features are never in the player's build: gated by `Designer.enabled()` (Task 1) and nothing else; `game/tools/*` and `game/tests/*` stay excluded by `game/export_presets.cfg`.
- Save compatibility: old saves load (`JsonFile.int_or`, `dict_or_empty`, clamps); the splits in Tasks 7–8 change no save key.
- Behaviour-neutral refactors keep every touched test file's pass count identical before and after.
- TDD: a failing test first for every behaviour change; `simplify` on each diff before its final commit; one Godot process at a time (`godot --headless --path game --script res://tests/run_tests.gd -- /test_x.gd`).
- Commits by explicit paths; agents never push; the footer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_018C759XCCMetfCHDHUbymvT`; no model id anywhere else.

Slice 3.2 adds:

- **The network rule, verbatim, in every brief for this slice:** "The environment has full network access, but **never access a domain Merijn has not approved**. Approved: assets `quaternius.com`, `opengameart.org`, `itch.io` incl. `quaternius.itch.io` and its file-storage host `itchio-mirror.cb031a832f44726753d6267436f3b414.r2.cloudflarestorage.com` for downloads; sources `rijksoverheid.nl`, `officielebekendmakingen.nl`, `wetten.overheid.nl`, `acm.nl`, `netbeheernederland.nl` (incl. subdomains), `cbs.nl`, `knmi.nl`, `nen.nl`, `tennet.eu`; tooling `docs.godotengine.org`, `github.com`, and the package managers the project already uses. Web search is allowed; opening a result is only allowed on this list. Any other domain (a mirror, a CDN a download redirects to, a source page): ask Merijn first, naming the domain and why. Agents stop and report instead of fetching. Every brief to an agent repeats this rule."
- **Assets: procedural first, CC0 from approved hosts only** (table below). No new download is planned. A downloaded CC0 model or sound may later replace a procedural one only from an approved host, with its licence file read, its SHA-256 pinned in `tools/blender/fetch_pack.py` (or the audio table) and a row in the licences file; if it is not on an approved host, the procedural one stays.
- **No dynamic lights on the street.** The Compatibility renderer draws each extra omni light as another pass over every object it touches; night is a runtime dim (the office's 2026-10-21 spike) plus emissive lamp heads, emissive windows and additive light-pool quads. A test pins zero `OmniLight3D`/`SpotLight3D` on the street.
- **Street dimensions are estimates** (by eye of a 1980s Dutch woonerf-style street: klinker carriageway about 5 m, pavements about 1.8 m, front gardens about 4 m, semi-detached houses about 9 m wide); `content/town.yaml` says so in an `estimate:` comment with that reasoning.
- **Respect the player's time:** the ride stays real-time-only (no game time passes, Spatie skips); walking the street costs no game time, as on the yard.

### Assets and their sources

| What | Source | Licence |
|---|---|---|
| Road, klinkers, pavements, kerbs, twelve houses, roofs, the corner shop, the trafohuisje, the trench and its barrier, the KLIC board, hedges, the canal, lamp posts, parked vans | built in `tools/blender/build_street.py` (vans: `build_yard.van()`'s kit) | the project's own |
| Textures `klinkers`, `roof_tiles`, `hedge`, `water`, `brick_red`, `brick_buff`, and the `street_signs` atlas (house numbers 1–14, the "Zonnestraat" sign, the KLIC printout, the "helaas niet thuis" card, the "WANNEER?" notes, the "Grondwerk Peeters" van livery, the papered shop window) | generated in `tools/blender/textures.py` (numpy/PIL, no internet) | the project's own |
| Fatima El Amrani and Kees de Jong (`el_amrani.glb`, `de_jong.glb`) | Quaternius *Universal Base Characters [Standard]*, https://quaternius.com/packs/universalbasecharacters.html downloaded from https://quaternius.itch.io/universal-base-characters; *Universal Animation Library [Standard]* https://opengameart.org/content/universal-animation-library; *Universal Animation Library 2 [Standard]* https://opengameart.org/content/universal-animation-library-2 (already adopted, SHA-256 in `game/assets/characters/LICENSES.md`, fetched by `tools/blender/fetch_pack.py`) | CC0 1.0 |
| `street_day.ogg` (the street's bed) | re-cut from https://opengameart.org/content/high-traffic-road-sounds (IgnasD), already in `game/assets/audio/SOURCES.md` for `street_evening.ogg` | CC0 1.0 |
| `doorbell.ogg`, `heat_pump.ogg`, `trafo_hum.ogg` | synthesised with ffmpeg (`aevalsrc`, `anoisesrc`), recipes in `SOURCES.md` | the project's own |

## Rulings on the spec (Claude's calls; Task 14 records them in PLAN §10)

1. **The corner bakery (spec §4 "Samira's; shut until Act IV") vs. the arc (`2026-10-16-drie-winters-arc.md` §9.2: her bakery is in Havenzij, the old harbour).** Built as a **shut corner shop with papered windows and no name**: it serves both until Phase 4 decides; nothing on the street names Samira.
2. **Night: runtime dim, not a second lightmap set** (spec allows either). The day bake is sky light plus contact AO on the ground and the façades, as the office's; night uses the office's runtime dim, emissive lamps and windows, and light-pool quads, no dynamic lights (Global Constraints).
3. **The model lives at `game/assets/office/street.glb`**, not `game/assets/town/` (the Phase 3 plan's task line): the floors' validator and `OfficeBuilding.MODEL_DIR` take a file name in `game/assets/office/`, and the street shares `game/assets/office/textures/`. Phase 4's town script may move it.
4. **Field steps stay on the yard; the street gets field markers.** A place lies in exactly one room (`check_world`), and spec §4 leaves the yard's stand-ins as they are. A `field:<step>` marker on the street opens the same place panel. Only `meters.visit` (Sandra's doors, house 7) and `outages.locate` (the trench) get one.
5. **The street is the Zonnestraat**, where Wim Kortekaas already lives (`dialogs.yaml`: "Kortekaas, Zonnestraat veertien"). The three residents are Fatima El Amrani (9), Kees de Jong (4, the angry customer in `fix_not_at_home`'s briefing) and Wim (14).
6. **`walk_meters` rides to the street as well** ("Tel hoe vaak de deur opengaat" is a street walk). `fix_wrong_joint` (the Lindelaan) and `save_henks_knowledge` (Nova-Oud) stay on the yard: no streets beyond this one.
7. **Gert moves from the ontvangst to the trench** for `fix_digging_damage`, which gets a ride with Ahmed. His KLIC printout is a sheet in his right hand.
8. **The letter becomes the doorstep.** `winter_el_amrani`'s `by: letter` payoff entry is removed; its words, rewritten as speech, are her doorstep beats. Her phone call stays. Every player passes the street again in Act II (`fix_digging_damage` is a main), so nobody loses the thanks.
9. **The trafohuisje explainer's ring moves to the street**; the mock-up on the opleidingsterrein keeps its geometry for Henk and loses its ring.
10. **Residents are not talked to with E**; you ring their bell. Their phone talks (El Amrani's calls) stay calls and never point the minimap at the street.
11. **The missed winter's door is Task 13, waiting for Merijn** (decision-day pack row M2). Until then a missed winter leaves house 9 like its neighbours with no bell offered: no claim either way.

## Review Focus

1. **A game saved on the street.** The player quits by the trench and continues next week: the game must resume on the street with the van at the kerb that takes them back, with no ride object alive. Pinned by Task 5's `test_a_game_resumed_on_the_street_rides_back_without_a_ride`.
2. **The mission ends while you stand on the street.** You stop `fix_not_at_home` from the phone (or it completes in a talk) by door 7: Sandra's street spot goes, and the van must still take you back. Pinned by Task 5's `test_stopping_the_mission_on_the_street_still_lets_you_ride_back`.
3. **The lift and the stairs.** With the street in `world.yaml`'s floors, the lift's floor list and the stairs must never offer it. Pinned by Task 3's `test_the_lift_never_goes_to_the_street` and `test_the_stairs_skip_the_street`.
4. **Where a mission points when its person is on the street.** Gert's talk step while you are on the 1e, or El Amrani's calls (she now has a body on the street): the minimap must point Gert to the van, and point nowhere for a call. Pinned by Task 7's `test_a_target_on_the_street_points_to_the_van_from_the_yard` and Task 6's `test_el_amrani_calls_point_nowhere`.
5. **The winter's outcome changes between visits.** The door is visited before day 70, the winter is then kept or missed, and the next visit must show the new state (never a cached one). Pinned by Task 12's `test_the_state_is_read_fresh_on_each_visit`.

---

### Task 1 (3.2-A1): The street's content, `content/town.yaml`, and its validator

**Files:**
- Create: `content/town.yaml`
- Modify: `tools/build_content.py` (register `"town": validate_town` in `VALIDATORS`, add `"town"` to `OPTIONAL`, add `check_town` to `CROSS_CHECKS`)
- Create: `tests/test_town_content.py`
- Generated: `game/data/town.json` (by `python tools/build_content.py`)

**Interfaces:**
- Produces: `game/data/town.json` with the shape below (read by Task 2's Blender script and Task 3's `Town` loader); `build_content.validate_town(doc, source) -> None`, `build_content.check_town(docs) -> None`; constants `TOWN_KEYS = {"segments", "lots", "props", "fields"}`, `TOWN_LOT_KINDS = ("house", "shop", "trafohuisje")`, `TOWN_PROP_KINDS = ("trench", "van", "hedge", "canal", "lamp")`, `TOWN_HOUSES = 12`. Later tasks add keys (`doors`, `arrivals`) and their checks.

`content/town.yaml` is the spec's "tiny street graph" (segments, lots, props) and the seed of Phase 4's town: today one segment; a lot or prop names its `segment` only when there are several. The values are decisions; dimensions in metres, `at` along the segment from its `from` end, `side: even` is north, `odd` south; an `estimate:` comment at the top gives the reasoning in Global Constraints:

```yaml
segments:
  - {id: zonnestraat, name: Zonnestraat, district: Nova-Oost, from: [0, 0], to: [120, 0],
     carriageway: 5.0, pavement: 1.8, front_garden: 4.0, house_depth: 9.0}
lots:   # width 9 unless given
  - {id: shop, kind: shop, side: odd, at: 0, width: 12, n: 1}          # the shut corner shop
  - {id: house_2,  kind: house, side: even, at: 6,  n: 2}
  - {id: house_4,  kind: house, side: even, at: 18, n: 4, resident: de_jong}
  - {id: house_6,  kind: house, side: even, at: 30, n: 6}
  - {id: house_8,  kind: house, side: even, at: 42, n: 8}
  - {id: house_10, kind: house, side: even, at: 54, n: 10}
  - {id: house_12, kind: house, side: even, at: 66, n: 12}
  - {id: house_14, kind: house, side: even, at: 78, n: 14, resident: wim}
  - {id: house_3,  kind: house, side: odd, at: 18, n: 3}
  - {id: house_5,  kind: house, side: odd, at: 30, n: 5}
  - {id: house_7,  kind: house, side: odd, at: 42, n: 7}
  - {id: house_9,  kind: house, side: odd, at: 54, n: 9, resident: el_amrani, story: el_amrani}
  - {id: house_11, kind: house, side: odd, at: 66, n: 11}
  - {id: trafohuisje, kind: trafohuisje, side: odd, at: 100, width: 3}
props:
  - {id: trench, kind: trench, side: even, at: 32, length: 26}          # in the north pavement, 6..10
  - {id: van_kerb, kind: van, side: odd, at: 82, kerb: true, livery: voltana, yard_van: 5}
  - {id: van_peeters, kind: van, side: even, at: 61, livery: peeters}
  - {id: hedge_west, kind: hedge, across: true, at: -3}
  - {id: hedge_green, kind: hedge, side: even, at: 90, length: 20}
  - {id: canal, kind: canal, across: true, at: 112, length: 12}
  - {id: lamp_1, kind: lamp, side: even, at: 10}
  # lamp_2..lamp_6 at 30, 50, 70, 90, 108, alternating sides
fields:
  - {step: meters.visit, at: house_7}
  - {step: outages.locate, at: trench}
```

- [ ] **Step 1: Write the failing tests** in `tests/test_town_content.py` (same `_check(mutate)` pattern as `tests/test_world_content.py`):

```python
def test_the_real_street_is_valid_with_twelve_houses_a_shop_and_a_trafohuisje():
    town = bc.load_content()["town"]
    kinds = [l["kind"] for l in town["lots"]]
    assert kinds.count("house") == 12 and kinds.count("shop") == 1 and kinds.count("trafohuisje") == 1
    seg = town["segments"][0]
    assert len(town["segments"]) == 1 and seg["to"] == [120, 0] and seg["name"] == "Zonnestraat"

def test_el_amrani_lives_at_nine_and_carries_the_story():
    lot = next(l for l in bc.load_content()["town"]["lots"] if l.get("story") == "el_amrani")
    assert (lot["n"], lot["resident"]) == (9, "el_amrani")

def test_house_numbers_follow_the_side():            # even north, odd south, each number once
def test_lots_on_one_side_must_not_overlap():         # house_6 at 20 -> ContentError "overlaps"
def test_a_lot_must_lie_inside_the_street():          # house_11 at 115 -> "outside the street"
def test_the_shop_stands_on_a_corner_and_the_trafohuisje_at_the_far_end():
def test_a_resident_lives_in_one_house_only():
def test_exactly_one_kerb_van_with_its_yard_van():
def test_a_field_names_a_real_step_and_a_lot_or_prop():   # step "meters.nowhere" -> "unknown step"
def test_unknown_keys_are_refused():
```

Each mutation test asserts `pytest.raises(bc.ContentError, match=...)` with the message the validator gives.

- [ ] **Step 2: Run them, expect FAIL** (`python -m pytest tests/test_town_content.py -v`: "no validator registered" for `town.yaml`, or `KeyError: 'town'`).

- [ ] **Step 3: Implement `validate_town(doc, source)` and `check_town(docs)`**, then write `content/town.yaml`. `validate_town` checks the shape and the geometry: known keys (`_known_keys`), exactly one segment for now (Phase 4 lifts this), its length (`from` to `to`) 100–140, exactly `TOWN_HOUSES` houses with unique `n` (even on `side: even`, odd on `odd`), one `shop` within 15 m of an end, one `trafohuisje` within 25 m of the other end, no overlap per side, every lot within `[0, length]` and every prop within `[−5, length + 15]` (the hedge and the canal close the ends), `resident` an id at most once, exactly one `story: el_amrani` lot whose resident is `el_amrani`, one trench, ≥ 2 hedges, one canal, 4–8 lamps, exactly one van with `kerb: true` and an int `yard_van`. `check_town` checks `fields[].step` against the value streams' steps (`_network_index`) and `fields[].at` against lot and prop ids, each step once. Run `python tools/build_content.py` to write `game/data/town.json`.

- [ ] **Step 4: Run them, expect PASS;** then `python tools/build_content.py --check` and `python -m pytest tests/ -v`.

- [ ] **Step 5: `simplify`, then commit**

```bash
git add content/town.yaml tools/build_content.py tests/test_town_content.py game/data/town.json
git commit -m "3.2-A1: the Zonnestraat as content (town.yaml) and its validator"
```

---

### Task 2 (3.2-A2): The street model, `tools/blender/build_street.py`

**Files:**
- Create: `tools/blender/build_street.py`
- Modify: `tools/blender/build_office.py` (`bake_lightmaps(spots, samples, floor_id, maps=LIGHTMAPS)` and `attach_lightmaps(floor_id, maps=LIGHTMAPS)`: the shell maps become a parameter; the office's output stays byte-identical)
- Modify: `tools/blender/textures.py` (the new textures and `street_sign_rects()`)
- Modify: `tools/blender/README.md` (the build line and what is in `street.glb`)
- Create: `game/assets/office/street.glb`, `game/assets/office/street.glb.import` (a copy of `office_yard.glb.import` without its uid, import script `office_import.gd`), `game/assets/office/textures/` new PNGs incl. `lightmap_floor_street.png`, `lightmap_walls_street.png`
- Create: `tests/test_street_glb.py`

**Interfaces:**
- Consumes: `game/data/town.json` (Task 1).
- Produces (node names in `street.glb`, Blender metres, Z up; the street runs +X from its west end at x = 0, road centre y = 0, even side +Y; Godot sees (x, z = −y)):
  - `shell_floor` (the walkable ground only: road, pavements, garden paths; lightmap UV), `shell_walls` (house fronts and sides; lightmap UV), `outside` (gardens, grass beyond, the canal's water, hedges), `roofs`, `glass_windows` (casts no shadow), `windows_lit` (emissive panes), `light_pools` (additive quads under the lamps), `lamp_heads` (emissive), `collision-colonly` (houses, hedges, the canal bank, vans, the trench barrier, both street ends).
  - Markers (empties with glTF extras `{"interaction": <kind>, "id": <id>}` as on the floors): `arrive:van` and `ride:street` (beside and at the passenger door of `van_kerb`), `room:zonnestraat` (extras `rect` = `shell_floor`'s bounds in Godot x, z), `lot:<lot id>` (extras add `n`), `bell:<n>` and `doorstep:<n>` for houses 4, 7, 9, 14, `home:<resident>` inside the front doors of 4, 9, 14, `field:meters.visit` (house 7's path), `field:outages.locate` (the trench's edge), `explain:transformator` (the trafohuisje's doors), `spot:<id>` for people (`gert_trench`, `ahmed_trench`, `sandra_door7`, `de_jong_garden`, `el_amrani_garden`, `wim_garden`).
  - Nodes the game switches: `kerb_van`, `heat_pump_9` with child `fan`, `card_7` (the card in door 7), `trench_marks` (spray line and pegs), `klic_board`, `trafo_vent` (for 3.3's heatwave), `tell_street_lamp` (house 14's porch lamp), `tell_dug_pavement` (the odd pavement at x 36), `tell_window_note` (windows of 3, 5, 11), each with `_low`, `_mid`, `_high` variants; each `tell_street_lamp_*` holds a `bulb` mesh.

- [ ] **Step 1: Write the failing tests** in `tests/test_street_glb.py`. They read the GLB's JSON chunk with `struct` (no Blender, no Godot) and compare it with `town.json`:

```python
def _gltf(path=ASSETS / "street.glb") -> dict:      # header 12 bytes, then chunk 0 = JSON
def _names(g) -> set[str]: return {n.get("name", "") for n in g["nodes"]}

def test_every_lot_has_its_marker_with_its_number():
def test_residents_have_a_bell_a_doorstep_and_a_home():
def test_fields_explainer_and_ride_markers_are_there():
def test_three_street_tells_with_three_heights_and_a_bulb_on_the_lamp():
def test_no_lights_are_exported():
    assert "KHR_lights_punctual" not in _gltf().get("extensionsUsed", [])
def test_the_static_street_stays_within_the_draw_budget():
    g = _gltf(); assert sum(len(m["primitives"]) for m in g["meshes"]) <= 160
def test_the_shell_carries_a_lightmap_on_uv2():     # shell_floor/shell_walls materials have occlusionTexture texCoord 1
```

- [ ] **Step 2: Run them, expect FAIL** (`street.glb` missing).

- [ ] **Step 3: Implement `tools/blender/build_street.py`** (`main()` with `--samples N` default 64, `--no-bake`, `--blend PATH`), importing `build_office as bo` and `build_yard` for `van()`, as `build_yard.py` does. Static geometry is merged per material (`bo.MeshBuilder`, one mesh per material group) so the draw budget holds; tells, the van, the fan, the card, the marks and the lit windows stay separate nodes. Bake with `bo.bake_lightmaps([], samples, "street", maps=STREET_LIGHTMAPS)` where `STREET_LIGHTMAPS = {"shell_floor": ("lightmap_floor", (4096, 1024)), "shell_walls": ("lightmap_walls", (2048, 2048))}` (sky only, no panels, plus contact AO), then `bo.attach_lightmaps("street", maps=STREET_LIGHTMAPS)`; export as `build_yard._export` does (`export_lights=False`). In `textures.py` add `klinkers` (red-brown herringbone, 1.2 m), `roof_tiles` (dark anthracite, 2.0 m), `hedge`, `water`, `brick_red`, `brick_buff` (2.0 m each) and the `street_signs` atlas (1024 × 1024) with `street_sign_rects() -> dict[str, tuple]` for `n1`…`n14`, `zonnestraat`, `klic`, `card`, `wanneer`, `peeters`, `papered`; add their sizes to `build_office.TEX_SIZE`. A plain look is the goal (spec §4).

- [ ] **Step 4: Build and run the tests, expect PASS**

```bash
python tools/build_content.py && python3 tools/blender/textures.py klinkers roof_tiles hedge water brick_red brick_buff street_signs
.bvenv/bin/python tools/blender/build_street.py --samples 64
.bvenv/bin/python tools/blender/build_office.py --floors first --no-bake
git diff --stat game/assets/office/office.glb   # empty: the bake refactor leaves the office as it was
                                                # (if the exporter is not byte-stable, compare the glTF JSON chunks instead)
godot --headless --path game --import
python -m pytest tests/test_street_glb.py -v
```

- [ ] **Step 5: `simplify`, then commit** (the glb, its import file, the new textures and the lightmaps by explicit path).

---

### Task 3 (3.2-A3): The street in Godot: a floor reached by van, its walk grid, day and night

**Files:**
- Modify: `content/world.yaml` (floor `- {id: street, reached_by: van, name: Zonnestraat, model: street.glb}`; room `- {id: zonnestraat, floor: street, name: Zonnestraat, places: [], opens_with: [start]}`; the header comment explains `reached_by`)
- Modify: `tools/build_content.py` (`WORLD_FLOOR_KEYS` gains `reached_by`; a floor has exactly one of `level`, `outside_of`, `reached_by`; `reached_by` must be `van`; a room on a `reached_by` floor has no places)
- Modify: `tests/test_world_content.py` (the real building now has the street; the new rules)
- Create: `game/src/world/office/town.gd` (`class_name Town`)
- Create: `game/src/world/office/office_street.gd` (`class_name OfficeStreet`)
- Modify: `game/src/world/office/office_building.gd`, `office_floors.gd`, `office.gd` (`load_floor`, `enter_saved_floor`), `game/src/ui/office_map.gd` (lift mode skips van floors), `game/src/audio/soundscape.gd` (`street_day` in `SOUNDS`)
- Create: `game/assets/audio/street_day.ogg` (+ `SOURCES.md` row)
- Modify: `game/tools/play_shot.gd` (states `street_day`, `street_evening`, `street_night`)
- Create: `game/tests/test_street_floor.gd`

**Interfaces:**
- Consumes: `street.glb` and its markers (Task 2), `town.json` (Task 1).
- Produces:
  - `Town.load_from(data_dir: String) -> Town` (fields `segments: Array[Dictionary]`, `lots: Array[Dictionary]`, `props: Array[Dictionary]`, `fields: Array[Dictionary]`, `error: String`; a missing or bad `town.json` gives an empty town and a warning, never a crash); `Town.street() -> Dictionary` (the one segment); `Town.lot(id: String) -> Dictionary`; `Town.kerb_van() -> Dictionary`.
  - `OfficeBuilding.floors[i]["reached_by"]` (`""` or `"van"`); `OfficeBuilding.by_van(floor_id: String) -> bool`; `next_floor()` never returns a van floor.
  - `OfficeFloors.go_to(id, how, force := false)`: a van floor only with `how == "van"`; the yard with `"exit"` or `"van"`; `const NO_LIFT_STREET := "De lift gaat niet naar de %s: daar rijd je heen met een bus van de werf."`; `map_floors()` entries gain `"van": bool`.
  - `OfficeStreet.create(of_office: Office) -> OfficeStreet` (null when the loaded floor has no `kerb_van`); `Office.street: OfficeStreet`; `OfficeStreet.town: Town`; `OfficeStreet.apply_light(minute: int) -> void` (`windows_lit`, `light_pools` and the lamp heads' emission on from `LIT_FROM := 17 * 60 + 30` and before `LIT_UNTIL := 7 * 60`); the street bed (`Soundscape.loop_under(street, "street_day")`) with the office's beds silent.
  - `Office.enter_saved_floor("street")` goes there by van (`force`), standing at `arrive:van`.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_street_floor.gd` (an `_office()` helper as in `test_van_ride.gd`; `_on_street(office)` = `office.floors.go_to("street", "van", true)`):

```gdscript
func test_the_street_loads_as_a_floor_with_its_room() -> void:
	# floor_id == "street", find_marker("kerb_van") != null, office.street != null, "zonnestraat" in floors.open
func test_the_lift_never_goes_to_the_street() -> void:
	# go_to("street", "lift") == false and the toast names the van; OfficeMap in lift mode lists no van floor
func test_the_stairs_skip_the_street() -> void:
	# for every floor f: building.next_floor(f, ±1) != "street"
func test_the_street_is_walkable_from_the_kerb_to_the_trafohuisje() -> void:
	# office.nav().path(arrive:van, explain:transformator) is not empty and its length < 110 m
func test_houses_hedges_and_the_canal_are_not_walkable() -> void:
	# nav().walkable() false inside lot house_9's footprint, in hedge_west, in the canal
func test_the_walk_grid_bakes_in_under_three_seconds() -> void:
	# Time.get_ticks_msec() around office.nav() < 3000
func test_lit_windows_and_light_pools_only_after_dark() -> void:
	# apply_light(9 * 60): windows_lit and light_pools hidden; apply_light(21 * 60 + 30): shown
func test_the_street_has_no_dynamic_lights() -> void:
	# geometry and street hold no OmniLight3D or SpotLight3D
func test_a_game_left_on_the_street_resumes_there() -> void:
	# enter_saved_floor("street") -> floor_id == "street", player within 1 m of arrive:van
```

Python, in `tests/test_world_content.py`: `test_a_floor_needs_exactly_one_of_level_outside_of_or_reached_by`, `test_a_van_floor_has_no_places`, and the real-building test's floor list updated to `[0, 1, 2, None, None]` with `"street": ["Zonnestraat"]`.

- [ ] **Step 2: Run them, expect FAIL** (`go_to` refuses an unknown floor; the validator refuses `reached_by`).

- [ ] **Step 3: Implement.** `OfficeBuilding._fill` reads `reached_by` (a van floor sorts last, level 0); `OfficeFloors.go_to` applies the rules above; `OfficeMap._fill_floor_bar` skips `"van"` floors in lift mode (the Nova page itself is Task 7); `Office.load_floor` creates `OfficeStreet` when `find_marker("kerb_van")` exists (next to the yard's `OfficeYard`) and frees it with the floor; `OfficeStreet._process` polls the clock every `POLL_SECONDS := 1.0` and calls `apply_light`. Make `street_day.ogg` from the CC0 source in the table (a 20 s loop, low-pass 2 kHz, −8 dB under `street_evening`). play_shot's three states load the office, go to the street, place the player at `arrive:van` facing east and use `--at` (09:00, 17:30, 21:30).

- [ ] **Step 4: Run, expect PASS:** the file above, `test_office_floors.gd`, `test_office_map.gd`, `test_van_ride.gd` (unchanged counts), `python tools/build_content.py --check`, `python -m pytest tests/ -v`. Then look at the three shots:

```bash
for s in street_day street_evening street_night; do xvfb-run -a godot --path game --rendering-driver opengl3 \
  --resolution 1600x900 --script res://tools/play_shot.gd -- $s docs/screenshots/$s.png; done
```

- [ ] **Step 5: `simplify`, then commit** (code, tests, `world.yaml`, `game/data/world.json`, the sound, the three screenshots).

---

### Task 4 (3.2-A4): Frame time on the street

**Files:**
- Create: `game/tools/frame_stats.gd` (`class_name FrameStats`, pure)
- Create: `game/tools/frame_time.gd` (a `SceneTree` script, needs a display)
- Create: `game/tests/test_frame_stats.gd`

**Interfaces:**
- Produces: `FrameStats.summary(frame_usec: PackedInt64Array) -> Dictionary` (`{frames, median_ms, p95_ms, fps}`; fps = 1000 / median_ms); `FrameStats.verdict(street: Dictionary, baseline: Dictionary, max_ratio: float, max_draw_calls: int) -> String` ("" when within budget, else the reason in English); constants `MAX_RATIO := 1.3`, `TARGET_FPS := 30.0`.
- The tool: `xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 1600x900 --script res://tools/frame_time.gd -- [--baseline first] [--floor street] [--at HH:MM] [--frames 600]`. It turns vsync off (`DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)`) and `Engine.max_fps = 0`, loads the office, warms up 120 frames, then records each frame's `Time.get_ticks_usec()` delta and the per-frame maximum of `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` and `..._PRIMITIVES_IN_FRAME` while the player walks the floor's long axis at walking speed (the street: `arrive:van` → `explain:transformator` and back; the baseline floor: its own `floor_rect()` diagonal). It prints one JSON line `{baseline: {...}, street: {...}, verdict: "..."}` and exits 1 when the verdict is not "".

**How the ≥ 30 fps target is measured.** Headless Godot uses the dummy renderer, so it cannot measure frame time. In the container the tool runs under Xvfb with `opengl3` (the Compatibility renderer the game ships with, also the web export's), on a software rasteriser whose absolute numbers mean nothing; so the container gate is **relative**: the street (09:00 and 21:30, the night with its pools and lit windows) costs at most `MAX_RATIO` × the 1e floor's median frame time, which plays fine today, and at most the 1e's peak draw calls. The **absolute** ≥ 30 fps is measured on the reference machine (spec §6) by Merijn at the playtest: the Windows playtest build started as `Spanning.exe --print-fps` (Godot's own command-line flag, it prints the frames per second each second) while he walks the street at 17:30; the checklist (Task 14) asks for the lowest number he sees.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_frame_stats.gd`:

```gdscript
func test_summary_takes_the_median_and_the_95th_percentile() -> void:
	var s := FrameStats.summary(PackedInt64Array([10000, 20000, 30000, 40000, 100000]))
	assert_eq(s["median_ms"], 30.0); assert_eq(s["p95_ms"], 100.0); assert_near(s["fps"], 33.3, 0.1)
func test_the_verdict_names_a_street_too_slow_for_its_baseline() -> void:
	# street median 14 ms vs baseline 10 ms, ratio 1.3 -> verdict contains "1.40"
func test_the_verdict_names_too_many_draw_calls() -> void:
func test_within_budget_the_verdict_is_empty() -> void:
```

- [ ] **Step 2: Run, expect FAIL** (`FrameStats` unknown).
- [ ] **Step 3: Implement `FrameStats` and `frame_time.gd`.**
- [ ] **Step 4: Run the tests, expect PASS;** then run the tool for 09:00 and 21:30 and expect an empty verdict. If it fails, cut cost in `build_street.py` (merge more, shorten the light-pool quads' overdraw, drop far detail) until it passes; never raise `MAX_RATIO`. Put both JSON lines in the commit message.
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 5 (3.2-B1): The van to the kerb and back

**Files:**
- Modify: `content/world.yaml` (rides: `{mission: walk_meters, with: sandra, to: meters.visit, floor: street}`, `{mission: fix_not_at_home, with: sandra, to: meters.visit, floor: street}`; the rides comment explains `floor`)
- Modify: `tools/build_content.py` (`WORLD_RIDE_KEYS` gains optional `floor`; `_check_rides`: `floor` is `yard` (the default) or a `reached_by: van` floor; a street ride's `to` must be a `fields` step in `town.yaml`, and its room on the yard still opens with the mission)
- Modify: `tests/test_world_content.py`
- Modify: `game/src/world/office/office_building.gd` (rides carry `floor`, default `"yard"`), `van_ride.gd`, `office_street.gd`, `office.gd` (`interact` chain asks `street.use`; `designer_to_street()`), `game/src/ui/game_ui.gd` (F7, designer only)
- Create: `game/tests/test_street_travel.gd`

**Interfaces:**
- Consumes: `OfficeFloors.go_to(.., "van", true)`, `OfficeStreet`, `Town.kerb_van()` (Task 3).
- Produces:
  - `VanRide.van_index: int` (the monteur's van, kept from `begin`, so nothing reads a freed `OfficePerson` after the floor changes); `VanRide.go_back() -> void` (on the street: fade, then back); `static func VanRide.back_from_street(of_office: Office, van: int) -> VanRide` (a return-only ride: fade, the yard, standing at `ride:van<van>`); internal `_arrive_on_street()` and `_back_from_street()`.
  - `OfficeStreet.use(target: Interactable) -> bool`, `prompt(target) -> String`, `label(target) -> String` for kind `ride` (`"E — Terug naar de werf"`, `"Bus naar de werf"`): `office.ride.go_back()` when a ride is `THERE`, else `VanRide.back_from_street(office, town.kerb_van()["yard_van"])`.
  - `Office.designer_to_street() -> bool` (false unless `Designer.enabled()`; F7 in `GameUI` calls it): straight to the street at `arrive:van`, no cab.
- Street-ride flow: the cab and the talk as today; on arrival a fade, `go_to(ride.floor, "van", true)`, the player at `arrive:van`, the `rode:` fact as today, **no place panel opens** (you walk to the field marker yourself, Task 8); `panels_closed()` on the street does not start the ride back; E at `ride:street` does.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_street_travel.gd`:

```gdscript
func test_sandras_ride_ends_at_the_kerb_on_the_street() -> void:
	# take fix_not_at_home on the yard, VanRide.begin with Sandra, drive to arrived():
	# floors.floor_id == "street", player within 1 m of arrive:van, facts has rode:fix_not_at_home
func test_no_place_opens_by_itself_on_the_street() -> void:
	# after arrival: not office.ui.is_busy()
func test_the_van_at_the_kerb_takes_you_back_to_sandras_van() -> void:
	# interact(ride:street), step until over(): floor_id == "yard", player within 1 m of ride:van5
func test_the_monteur_is_never_a_freed_object_after_the_floor_changes() -> void:
	# through arrival and return: ride.monteur == null or is_instance_valid(ride.monteur)
func test_a_game_resumed_on_the_street_rides_back_without_a_ride() -> void:   # Review Focus 1
	# enter_saved_floor("street"); office.ride == null; interact(ride:street) -> back on the yard
func test_stopping_the_mission_on_the_street_still_lets_you_ride_back() -> void:   # Review Focus 2
	# arrive, session.missions.stop("fix_not_at_home"), interact(ride:street) -> yard
func test_rides_to_the_yard_are_unchanged() -> void:
	# fix_wrong_joint: arrives at place:outages.repair on the yard with its place open (as before)
func test_f7_goes_to_the_street_only_for_the_designer() -> void:
	# Designer.force(false): designer_to_street() false; Designer.force(true): true and on the street
```

Python: `test_a_street_ride_needs_a_field_for_its_place`, `test_a_ride_floor_must_be_a_van_floor_or_the_yard`.

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** the flow above; `test_van_ride.gd`'s `test_walking_the_meters_stream_rides_with_sandra` now expects the street.
- [ ] **Step 4: Run, expect PASS:** this file, `test_van_ride.gd`, `test_office_floors.gd`, `test_save_menus.gd`, the content check, pytest. Add play_shot state `street_arrive` (the fade's end at the kerb with Sandra's van).
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 6 (3.2-D): People on the street

**Files:**
- Modify: `game/assets/characters/cast.json` (new `el_amrani` and `de_jong`; `wim`, `gert`, `ahmed`, `sandra` change; the `_about` text explains `resident`, `holds` and a `during` spot's `floor`)
- Create: `game/assets/characters/el_amrani.glb`, `de_jong.glb` (+ `.import`) via `build_character.py --only <id>`
- Modify: `content/company.yaml` (`{id: de_jong, title: "klant, Nova-Oost", organisation: klant}`)
- Modify: `tools/build_content.py` (`check_town`: each lot `resident` is in the cast with `office.floor: street` and `resident: true`)
- Modify: `game/src/world/office/office_people.gd`, `office_person.gd`, `office_yard.gd` (`where`), `minimap_targets.gd` (`_spot` per mission; residents are never a person target)
- Modify: `game/tools/play_shot.gd` (state `street_people`)
- Create: `game/tests/test_street_people.gd`

**Interfaces:**
- Consumes: the `spot:` and `home:` markers (Task 2), the street floor (Task 3).
- Produces:
  - Cast entries (spots in Godot (x, z) taken from the `spot:` markers):
    - `el_amrani`: `{"name": "Fatima El Amrani", "role": "klant, Nova-Oost", "office": {"floor": "street", "at": <spot:el_amrani_garden>, "pose": "idle", "resident": true}, "day": {"arrive": "15:40", "leave": "17:05"}}`
    - `de_jong`: `{"name": "Kees de Jong", "role": "klant, Nova-Oost", "office": {"floor": "street", "at": <spot:de_jong_garden>, "pose": "idle", "resident": true}, "day": {"arrive": "09:20", "leave": "11:40"}}`
    - `wim`: `office` → `{"floor": "street", "at": <spot:wim_garden>, "pose": "idle", "resident": true, "during": {"fix_inverters_tripping": {"floor": "ground", "at": [-2.2, -3.4], "face": [-4.6, -4.7], "pose": "idle"}}}`, `"day": {"arrive": "12:50", "leave": "15:30"}` (his `missions` key goes: he lives there)
    - `gert`: `office` → `{"floor": "street", "at": <spot:gert_trench>, "pose": "idle", "holds": "klic", "missions": ["fix_digging_damage"]}`
    - `ahmed`: `during` gains `"fix_digging_damage": {"floor": "street", "at": <spot:ahmed_trench>, "pose": "idle"}`; `sandra`: `during` `{"walk_meters": {...door 7}, "fix_not_at_home": {...door 7}}` with `"floor": "street"`
  - Rules in `OfficePeople`: a person is on this floor when their active `during` spot is here, or their base spot is here and no active `during` spot names another floor; a `resident` takes no coffee and no lunch, `arrive`/`leave` are stepping out of and back into `home:<id>`, and E on a resident gives their greeting line, never a talk (ruling 10).
  - `OfficePerson.hold_prop(atlas_rect: String) -> void`: a 0.21 × 0.297 m sheet (QuadMesh, `street_signs` atlas rect) under a `BoneAttachment3D` on bone `"RightHand"`, node name `"held_" + atlas_rect`.
  - `MinimapTargets._spot(cast, id, mission_id := "") -> Dictionary` (the active mission's `during` spot when it has one); a `resident` is a person target only through a `during` spot.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_street_people.gd`:

```gdscript
func test_residents_are_in_their_gardens_by_their_day() -> void:
	# 10:00: de_jong visible, el_amrani not; 16:00: el_amrani visible
func test_a_resident_walks_out_of_their_front_door() -> void:
	# at 09:21 de_jong is walking and was within 1 m of home:de_jong at 09:20
func test_residents_take_no_coffee_or_lunch() -> void:
	# place_for(de_jong, 10 * 60 + 2) != OfficeDay.COFFEE; 12:10 is not LUNCH
func test_e_on_a_resident_never_opens_a_talk() -> void:
func test_wim_is_at_the_ontvangst_during_his_mission_and_not_in_his_garden() -> void:
func test_gert_stands_at_the_trench_with_the_klic_in_his_hand_only_during_digging_damage() -> void:
	# visible iff fix_digging_damage active; find_child("held_klic") under a BoneAttachment3D, bone "RightHand"
func test_sandra_is_at_door_7_on_the_street_and_at_her_van_on_the_yard() -> void:
func test_street_spots_lie_on_their_markers() -> void:
	# each street cast spot within 0.5 m of its spot:<id> marker
func test_el_amrani_calls_point_nowhere() -> void:          # Review Focus 4
	# with winter_el_amrani active (her call step): MinimapTargets.of(...) == {}
func test_wims_talk_points_to_the_ontvangst() -> void:
	# fix_inverters_tripping's talk step: target floor "ground"
```

Python: `test_every_resident_is_in_the_cast_on_the_street` in `tests/test_town_content.py`.

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Build the two characters** (the pack comes only from the approved hosts in the asset table, through `fetch_pack.py`, which refuses any other host):

```bash
python3 tools/blender/fetch_pack.py          # only if .pack/ is missing
.bvenv/bin/python tools/blender/build_character.py --only el_amrani
.bvenv/bin/python tools/blender/build_character.py --only de_jong
godot --headless --path game --import
```

Then implement the people rules, `hold_prop`, the `_spot` change and the `check_town` cast check.

- [ ] **Step 4: Run, expect PASS** with `test_office_people.gd`, `test_characters.gd`, `test_minimap.gd`, `test_van_ride.gd`, the content check (`check_company`: both new people placed, titles equal), pytest. Look at `street_people` at 16:00.
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 7 (3.2-B2): The Nova page and the street minimap

**Files:**
- Modify: `game/src/world/office/office_floors.gd` (`map_plan("street")` adds `lots`), `office.gd` (`map_lots() -> Array[Dictionary]`), `game/src/ui/office_map.gd` (the Nova page), `game/src/world/office/office_minimap.gd` and `game/src/ui/minimap.gd` (street mode), `game/src/world/office/minimap_targets.gd` (van floors)
- Create: `game/tests/test_street_map.gd`

**Interfaces:**
- Consumes: `map_floors()` `"van"` flag (Task 3), rides with `floor` (Task 5), Gert's street spot and `MinimapTargets._spot` (Task 6).
- Produces:
  - A map plan's `lots: Array[Dictionary]` = `[{n: int, at: Vector2}]` from the `lot:` markers (houses only).
  - `OfficeMap`: the floor bar shows a van floor as `NOVA := "Nova: %s"` (after the office floors, never at the lift); choosing it shows its plan with house numbers; the title reads `"Kaart: Zonnestraat (Nova-Oost)"` from `Town.street()`'s `name` and `district`; `●` when a target is there (existing `_floor_marked`).
  - `Minimap`: on the street the plan's `lots` draw their numbers; the road is the floor outline as today.
  - `OfficeMinimap._seam`: a target on a van floor, seen from elsewhere, points at the ride's van door `ride:van<k>` when the player is on the yard (k = the mission's ride monteur's van), else at the seam toward the yard (the way a yard target does); the label is the street's name.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_street_map.gd`:

```gdscript
func test_the_map_has_a_nova_page_with_the_house_numbers() -> void:
	# on the 1e: map_floors() has {id: "street", van: true}; map_plan("street")["lots"].size() == 12
func test_the_nova_page_is_marked_when_a_mission_waits_there() -> void:
func test_on_the_street_the_minimap_draws_the_house_numbers() -> void:
func test_a_target_on_the_street_points_to_the_van_from_the_yard() -> void:   # Review Focus 4
	# fix_digging_damage active (its talk step: Gert, on the street since Task 6), player on the yard:
	# the target's at == ride:van0's (x, z) (Ahmed's van) and its text names "Zonnestraat"
func test_a_target_on_the_street_points_to_the_yard_from_the_1e() -> void:
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect PASS** with `test_minimap.gd` and `test_office_map.gd` unchanged; play_shot state `phone_map_nova`.
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 8 (3.2-C1): Field places, Sandra's doors and the bells

**Files:**
- Modify: `content/town.yaml` (new `doors:` and `arrivals:`)
- Modify: `tools/build_content.py` (`validate_town`/`check_town` for the new keys; `check_spoken` and the spoiler check cover their lines)
- Modify: `tests/test_town_content.py`
- Create: `game/src/world/office/street_doors.gd` (`class_name StreetDoors`, pure)
- Modify: `game/src/world/office/office_street.gd`, `office.gd` (`_add_interactables` on the street), `van_ride.gd` (`_arrive_on_street` asks the street for the arrival)
- Create: `game/assets/audio/doorbell.ogg` (+ `SOURCES.md` row)
- Create: `game/tests/test_street_missions.gd`

**Interfaces:**
- Consumes: field markers (Task 2), street rides (Task 5), Sandra's street spot (Task 6).
- Produces:
  - `town.yaml` `doors: [{lot, lines: [{line, needs?}]}]` (a plain door: the first line whose `needs` holds, facts grammar as in `scenes.yaml`; the speaker is the lot's resident, or none for an empty house) and `arrivals: [{mission, beats: [{speaker, line, needs?}]}]` (≤ 4 beats; `mission` must have a street ride). Doors for houses 4 (De Jong: a line while `fix_not_at_home` is active, one after `done:fix_not_at_home`, one otherwise), 7 ("Er doet niemand open." as narration, no speaker) and 14 (Wim). House 9 is Task 12's.
  - `StreetDoors.lines_for(door: Dictionary, knows: Callable) -> Array[Dictionary]` (`[{speaker, line}]`, `knows` = `session.missions.knows`).
  - `OfficeStreet.arrive(mission_id: String) -> void` (plays that mission's arrival beats once per ride via `SceneLines`, Sandra staged at `doorstep:7`, `doorbell` played), `bell:<n>` interactables (`"E — Aanbellen"`, label `"Voordeur nummer %d"`), `field:<step>` markers become `Interactable.create("place:" + step, …)` while the step's room is in `floors.open`.
  - `card_7` visible while problem `not_at_home` is open in the region (`region.state["not_at_home"].is_open()`), read on `poll()`.
- Copy: the beats and door lines are written by the implementer to the style guide and are checked by `BANNED_SPOKEN` and `_never_names` against every problem: Sandra's arrival describes (the bell, the wait, the card through the letterbox), it never says why nobody is home (no "herinnering", "tijdvak", "bevestiging").

- [ ] **Step 1: Write the failing tests:**

```gdscript
func test_the_field_marker_opens_the_place_panel_for_meters_visit() -> void:
	# on the street with fix_not_at_home active: interactable("place:meters.visit") at field:meters.visit; interact -> the place panel is open
func test_the_field_is_offered_only_while_its_room_is_open() -> void:
func test_sandra_rings_at_seven_on_arrival_and_the_card_stays_while_not_at_home_is_open() -> void:
func test_the_arrival_beats_play_once_per_ride() -> void:
func test_ringing_de_jong_gives_his_line_by_the_facts() -> void:
func test_ringing_seven_gets_no_answer() -> void:
```

Python: `test_door_and_arrival_lines_pass_the_spoken_words_and_spoiler_checks` (a line naming not_at_home's cause → `ContentError`), `test_an_arrival_names_a_mission_with_a_street_ride`, `test_a_door_names_a_house`.

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement**; synthesise `doorbell.ogg` (two tones, 660 and 550 Hz, 0.35 s each, soft decay).
- [ ] **Step 4: Run, expect PASS**, content check, pytest; play_shot `street_sandra_door`.
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 9 (3.2-C2): *Graafschade* at the trench

**Files:**
- Modify: `content/world.yaml` (ride `{mission: fix_digging_damage, with: ahmed, to: outages.locate, floor: street}`; `van_park` opens with `fix_digging_damage`)
- Modify: `content/missions.yaml` (`fix_digging_damage.steps.talk: "Rijd met Ahmed mee naar de sleuf in de Zonnestraat en praat met Gert"`)
- Modify: `game/src/world/office/office_street.gd` (the trench)
- Modify: `game/tests/test_street_missions.gd`

**Interfaces:**
- Consumes: Gert's and Ahmed's street spots and `held_klic` (Task 6), the `outages.locate` field (Task 8).
- Produces: `OfficeStreet.contained_now(mission_id: String) -> bool` (`missions.contained.has(id)` and `region.net.time < missions.contained[id]`); `trench_marks` visible iff `contained_now("fix_digging_damage")`, read on `poll()`.

- [ ] **Step 1: Write the failing tests:**

```gdscript
func test_digging_damage_rides_with_ahmed_to_the_trench() -> void:
func test_gert_is_talked_to_at_the_trench() -> void:
	# on the street, fix_digging_damage active: office.talk_to(gert) opens gert_klic standing
func test_the_trench_shows_the_marks_only_while_contained() -> void:
	# missions.contain("fix_digging_damage") == "" -> marks visible; time past its days -> hidden
func test_the_trench_field_opens_outages_locate() -> void:
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect PASS** with `test_mission_talks.gd`, `test_act1_fixes.gd` (unchanged counts), content check (the step text through the spoiler check), pytest; play_shot `street_gert` (Gert at the trench with the KLIC sheet, 10:00).
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 10 (3.2-C3): The street's tells

**Files:**
- Modify: `content/world.yaml` (tells `street_lamp`, `dug_pavement`, `window_note`, each `room: zonnestraat` with `low`/`mid`/`high`)
- Modify: `content/problems_tier1.yaml` (`tells:` entries: `inverters_tripping` → `street_lamp`; `digging_damage` → `dug_pavement`; `not_at_home`, `double_visits` → `window_note`, each with its own mid-and-up line)
- Modify: `tools/build_content.py` (`TELLS` gains the three with room `zonnestraat`; `check_tells`: every street tell is listed by ≥ 1 problem, and every problem whose step has a `town.yaml` field lists ≥ 1 street tell)
- Modify: `tests/test_tells_content.py`
- Modify: `game/src/world/office/office_tells.gd` (`THRESHOLDS`, `readings()`), `office_street.gd` (the flicker)
- Modify: `game/tools/yard_tell_probe.gd` (`STREET := ["dug_pavement"]` alongside `YARD`)
- Modify: `game/tests/test_office_tells.gd`

**Interfaces:**
- Produces:
  - Readings: `street_lamp` = the `measurement_tray` reading (thresholds `[10, 18]`, already probed); `window_note` = the `van_returns` reading (`[18, 28]`, already probed); `dug_pavement` = `_counted(net, "outages.report", WEEK_DAYS, "entered")`, thresholds from the probe (`godot --headless --path game --script res://tools/yard_tell_probe.gd -- 11,12 60`), with min/median/max for the base and for `digging_damage` in the `THRESHOLDS` comment, marked ESTIMATES like the yard's.
  - `static func OfficeStreet.flicker(band: int, t: float) -> float` (the bulb's emission factor at time `t` s: `LOW` always 1.0; `MID` drops below 0.5 for about 0.2 s a few times a minute; `HIGH` drops several times a second; deterministic in `t`).
- Copy (drafts; the style guide decides the final words): `street_lamp` low "Bij nummer 14 brandt de lamp naast de voordeur gewoon.", mid "De lamp naast de voordeur van nummer 14 knippert af en toe.", high "De lamp naast de voordeur van nummer 14 knippert de hele tijd."; `dug_pavement` low "In de stoep zit een plek met nieuwe klinkers.", mid "In de stoep zitten twee plekken met nieuwe klinkers, nog lichter dan de rest.", high "Bij nummer 5 ligt de stoep open, met rood-witte hekken eromheen, naast een plek die net is dichtgelegd."; `window_note` low "Achter de ramen hangen gordijnen en een paar kindertekeningen.", mid "Achter één raam hangt een A4'tje met in grote letters: WANNEER?", high "Achter drie ramen in de straat hangt een A4'tje met WANNEER? erop. Onder één staat een datum, doorgestreept."

- [ ] **Step 1: Write the failing tests:**

```gdscript
func test_the_street_tells_read_the_same_numbers_as_their_yard_twins() -> void:
	var r := OfficeTells.readings(net)
	assert_eq(r["street_lamp"], r["measurement_tray"]); assert_eq(r["window_note"], r["van_returns"])
func test_dug_pavement_reads_this_weeks_outages() -> void:
func test_the_porch_lamp_flickers_by_band() -> void:
	# flicker(LOW, t) == 1.0 for t in 0..60; MID has a value < 0.5 within 60 s; HIGH within 1 s
func test_looking_at_a_street_tell_notes_it_under_the_zonnestraat() -> void:
```

Python: `test_every_street_tell_is_listed_by_a_problem`, `test_a_field_problem_lists_a_street_tell`.

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Run the probe, set `dug_pavement`'s thresholds, implement.**
- [ ] **Step 4: Run, expect PASS** with `test_office_tells.gd`, content check (`_never_names` on every new line), pytest; play_shot `play_tell_street_high` (the three at their highest, dusk).
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 11 (3.2-C4): The trafohuisje explainer moves to the street

**Files:**
- Modify: `game/src/world/office/office_trafohuisje.gd` (the place is the street's `explain:transformator` marker; `ROOM := "zonnestraat"`; `LABEL := "Trafohuisje (Zonnestraat)"`; the yard-node constants `NODE`, `DOORS`, `OUTWARD` go)
- Modify: `game/src/world/office/office_street.gd` (`trafo_hum` loops at the trafohuisje)
- Create: `game/assets/audio/trafo_hum.ogg` (+ `SOURCES.md` row: 100 Hz with harmonics at 200 and 300 Hz, low)
- Modify: `game/tests/test_explainer_trafo_world.gd`, `game/tools/play_shot.gd` (`play_trafohuisje` and `play_explainer_trafo_*` stage on the street)

**Interfaces:**
- Produces: `OfficeTrafohuisje.place(office) -> Interactable` (null off the street), `stand(office) -> Transform3D`, `look_point(office) -> Vector3`, all from the marker; `Office.open_trafohuisje()` unchanged.

- [ ] **Step 1: Write the failing tests:**

```gdscript
func test_the_trafohuisje_explainer_opens_at_the_street() -> void:
func test_the_mock_up_on_the_opleidingsterrein_has_no_ring() -> void:
	# yard with save_henks_knowledge active: no interactable of kind "trafohuisje"; the opleidingsterrein node still there
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement**; update the existing world tests that expected the mock-up's ring.
- [ ] **Step 4: Run, expect PASS** with `test_explainer_trafo*.gd`, `test_explainer_view.gd`; the four play_shot states.
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 12 (3.2-C5): El Amrani's door: the one reader, *before* and *kept*

**Files:**
- Create: `game/src/rules/el_amrani_door.gd` (`class_name ElAmraniDoor`)
- Modify: `content/town.yaml` (`doors:` entry for `house_9` with `story: el_amrani`, `before`, `kept_first`, `kept`)
- Modify: `content/missions.yaml` (`winter_el_amrani.payoff`: the `by: letter` entry goes; the comment "Kept: her call on your phone and her letter on your desk (Phase 4: her front door)" becomes "Kept: her call on your phone, and her thanks at her front door (town.yaml, house_9)")
- Modify: `tools/build_content.py` (`validate_town`: a story door needs `before`, `kept_first`, `kept`; it may not yet carry `missed`), `tests/test_town_content.py`
- Modify: `game/src/world/office/street_doors.gd`, `office_street.gd` (house 9: the bell, the heat pump), `game/tests/test_player_desk.gd` (line 109's test is rewritten: the letter no longer comes; the call stays)
- Create: `game/assets/audio/heat_pump.ogg` (+ `SOURCES.md` row)
- Create: `game/tests/test_el_amrani_door.gd`
- Modify: `game/tools/play_shot.gd` (`street_door_before`, `street_door_kept`)

**Interfaces:**
- Produces:
  - `ElAmraniDoor`: `const MISSION := "winter_el_amrani"`, `const BEFORE := "before"`, `const KEPT := "kept"`, `const MISSED := "missed"`, `const THANKED := "flag:el_amrani_thanked"`; `static func state(s: GameSession) -> String`: `KEPT` when `s.missions.done_once.has(MISSION)`, `MISSED` when `s.missions.failed(MISSION)`, else `BEFORE`. **The only code that reads the winter's outcome for the street**; Task 13 changes only this function and the door's content.
  - `StreetDoors.story_lines(door: Dictionary, state: String, knows: Callable) -> Array[Dictionary]`: `BEFORE` → `before`; `KEPT` → `kept_first` until `THANKED` is known, then `kept`; `MISSED` → `[]` (Task 13).
  - `OfficeStreet`: `bell:9` offered for `BEFORE` and `KEPT` only; after `kept_first` plays, `THANKED` is added to the facts; Fatima staged at `doorstep:9` while her lines play; `heat_pump_9/fan` turns and `heat_pump` loops under it only in `KEPT`; the state is read again on every `poll()` and every street load, never cached across loads.
  - Interim for `MISSED` (until Task 13): no bell on 9; windows and lights as the neighbours'; no hum.
- Copy: `kept_first` is her letter's content said on her doorstep (her mother warm in the room, "iemand die terugbelde", "deze keer schrijf ik iets anders op: dank u wel"), two to four beats, her voice from the dialogs; `before` is one or two worried lines that never name a cause; `kept` is one short line for later rings.

- [ ] **Step 1: Write the failing tests** in `game/tests/test_el_amrani_door.gd`:

```gdscript
func test_state_is_before_until_the_winter_is_decided() -> void:
func test_state_is_kept_when_the_winter_was_kept() -> void:
	# missions.done_once["winter_el_amrani"] = true -> ElAmraniDoor.state(s) == ElAmraniDoor.KEPT
func test_state_is_missed_when_it_failed() -> void:
	# missions.failed_once["winter_el_amrani"] = true -> MISSED
func test_the_doorstep_thanks_plays_once_then_the_short_line() -> void:
func test_the_heat_pump_hums_only_when_kept() -> void:
func test_the_state_is_read_fresh_on_each_visit() -> void:      # Review Focus 5
	# visit at BEFORE (no hum), leave, set done_once, visit again: hum and kept_first
func test_missed_is_neutral_until_m2() -> void:                 # replaced by Task 13
	# MISSED: no interactable "bell:9", fan still, house_9's windows follow the clock like house_7's
```

`test_player_desk.gd`: `test_her_thanks_is_no_longer_a_letter_but_her_call_stays` (no payoff letter on the desk; Berichten holds `payoff:winter_el_amrani:0` only). Python: `test_only_el_amrani_door_reads_the_winter_outcome` (no `.gd` file under `game/src/world/` names `winter_el_amrani`; `game/src/rules/el_amrani_door.gd` does), `test_a_story_door_needs_before_kept_first_and_kept`.

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement**; synthesise `heat_pump.ogg` (an 8 s loop: a 48 Hz fan drone with a slow beat and pink noise, low-pass 1.2 kHz).
- [ ] **Step 4: Run, expect PASS** with `test_player_desk.gd`, `test_phone.gd`, `test_milestones_content.py`, content check, pytest; the two play_shot states (16:00).
- [ ] **Step 5: `simplify`, then commit.**

---

### Task 13 (3.2-C6): El Amrani's door when the winter was missed — **WAITS FOR MERIJN (decision-day pack row M2)**

**Do not start until Merijn has answered M2** ("Does a missed El Amrani winter close her door for good?", `docs/qa/decision-day-2026-10.md`). The controller fills in the chosen shape and dispatches this task; the rest of the slice does not depend on it.

**Files:**
- Modify: `game/src/rules/el_amrani_door.gd` (only for shape B), `content/town.yaml` (house 9's door), `tools/build_content.py` (`validate_town` allows the new key), `game/src/world/office/street_doors.gd`, `office_street.gd`, `tests/test_town_content.py`, `game/tests/test_el_amrani_door.gd` (`test_missed_is_neutral_until_m2` is deleted and replaced)
- Record the answer in PLAN §9 (Decisions Made) with the date.

**What spec §4 already fixes for a missed winter:** "the house is dark and she does not open." M2 decides only whether that is for good.

**Shape A, "for good":** `state()` is unchanged. Door key `missed: []`. In `MISSED` house 9's `windows_lit` part stays dark at every hour, the curtains are drawn (a `curtains_9` node from `build_street.py`), `bell:9` is offered and rings with no answer and no line; nothing on the street ever changes it; Act IV's daughter thread reads the existing `flag:el_amrani_cold_winter` (no new fact). Tests: `test_missed_house_is_dark_and_nobody_opens`, `test_a_late_connection_does_not_open_the_door`.

**Shape B, "a later door":** `state()` gains `const LATE := "late"`: `MISSED` becomes `LATE` once the followed order is delivered after the deadline (`delivered:el_amrani` known and `failed(MISSION)`). Door keys `missed: []` (dark and closed, as A, until then) and `late: [beats]` (cooler and short: her mother came home, no thanks to the player); the heat pump hums from `LATE`. The story order must still deliver after day 70 (`game/src/rules/followed_order.gd`; check that it does, add the path if not). Tests: `test_missed_house_is_dark_until_a_late_connection`, `test_a_late_connection_opens_the_door_with_the_late_lines`.

- [ ] **Step 1:** Write the failing tests of the chosen shape.
- [ ] **Step 2:** Run, expect FAIL.
- [ ] **Step 3:** Implement the chosen shape (A: content, the dark house, the silent bell; B: as A plus `LATE`), copy to the style guide.
- [ ] **Step 4:** Run, expect PASS; content check; pytest; play_shot `street_door_missed` (and `street_door_late` for B).
- [ ] **Step 5:** `simplify`, then commit with message `3.2-C6: El Amrani's door when the winter was missed (M2: <answer>)`.

---

### Task 14 (3.2-E): Slice exit

**Files:**
- Create: `docs/qa/playtest-checklist-street.md`
- Create: `docs/screenshots/street_0900.png`, `street_1730.png`, `street_night.png` (from Task 3's states, retaken with the people and the tells)
- Modify: `PLAN.md` (§1 status line; the 3.2 tasks ticked; §5 the street and its frame-time numbers; §10 the rulings above as "Claude's calls, pending Merijn (2026-10-27, slice 3.2)")

- [ ] **Step 1: The whole suite and the machine checks.** `python tools/run_godot_tests.py`, `python tools/build_content.py --check`, `python -m pytest tests/ -v`; autoplay on Acts 0–II with the five personas (`game/tools/autoplay.gd`) shows no change in mission completion against the last report (the street changes the world, not the rules); the route check unchanged.
- [ ] **Step 2: Frame time again with people and sound**: Task 4's tool at 09:00, 17:30 and 21:30; empty verdict; numbers into PLAN §5.
- [ ] **Step 3: The playtest checklist** for Merijn, in Dutch where it quotes the game: from `designer_day045` take `walk_meters` or `fix_not_at_home` if offered (else F7, the designer jump), ride with Sandra, watch door 7, ring 4 and 9 (*before*), walk to the trafohuisje and open the explainer, ride back by the van; from `designer_act2` take `fix_digging_damage`, ride with Ahmed, talk to Gert at the trench; from `designer_day095` see door 9 *kept* or *missed* as the save has it; the frame rate: start the playtest build as `Spanning.exe --print-fps`, stand on the street at 17:30 and at night, note the lowest frames per second (target ≥ 30, spec §6); the slice question, verbatim: "voelde de buitenwereld als onderdeel van het bedrijf?"
- [ ] **Step 4: Code review of the slice** (superpowers:requesting-code-review over the slice's commits); fix wave; `simplify`.
- [ ] **Step 5: Commit** the checklist, the screenshots and `PLAN.md`.

**Slice 3.2 exit (spec §4):** Merijn drives to the street from the day-45 save, meets Gert at the trench, rings the El Amrani bell, and answers "voelde de buitenwereld als onderdeel van het bedrijf?"; a screenshot set at 09:00, 17:30 and night; frame time ≥ 30 fps on the reference machine (spec §6); Task 13 landed once M2 is answered.
