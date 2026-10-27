"""The street model (tools/blender/build_street.py, slice 3.2): game/assets/office/street.glb.

Reads the GLB's JSON chunk with struct (no Blender, no Godot) and compares it with
game/data/town.json. Blender is Z up; the glTF is Y up: a Blender (x, y, z) is the glTF
node translation (x, z, -y), so the even (north, +y) side has a negative glTF z.
"""
from __future__ import annotations

import json
import struct
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "game" / "assets" / "office"
TOWN = json.loads((ROOT / "game" / "data" / "town.json").read_text(encoding="utf-8"))
LOTS = {lot["id"]: lot for lot in TOWN["lots"]}
PROPS = {prop["id"]: prop for prop in TOWN["props"]}
DOORS = (4, 7, 9, 14)   # the houses with a bell: the three residents and Sandra's door 7
BANDS = ("low", "mid", "high")


def _gltf(path: Path = ASSETS / "street.glb") -> dict:
    data = path.read_bytes()
    magic, version, _length = struct.unpack_from("<4sII", data, 0)
    assert (magic, version) == (b"glTF", 2)
    chunk_length, chunk_type = struct.unpack_from("<I4s", data, 12)
    assert chunk_type == b"JSON"
    return json.loads(data[20:20 + chunk_length])


G = _gltf() if (ASSETS / "street.glb").exists() else {"nodes": []}


def _names(g: dict = G) -> set[str]:
    return {n.get("name", "") for n in g["nodes"]}


def _node(name: str, g: dict = G) -> dict:
    return next(n for n in g["nodes"] if n.get("name") == name)


def _extras(name: str) -> dict:
    return _node(name).get("extras", {})


def _blender_xy(name: str) -> tuple[float, float]:
    x, _z, gz = _node(name)["translation"]
    return x, -gz


def _lot_span(lot: dict) -> tuple[float, float]:
    return lot["at"], lot["at"] + lot.get("width", 9)


def test_the_street_model_exists():
    assert (ASSETS / "street.glb").exists() and (ASSETS / "street.glb.import").exists()


def test_every_lot_has_its_marker_with_its_number():
    for lot_id, lot in LOTS.items():
        name = f"lot:{lot_id}"
        assert name in _names(), name
        extras = _extras(name)
        assert extras.get("id") == lot_id and extras.get("n") == lot.get("n"), (name, extras)
        x, y = _blender_xy(name)
        low, high = _lot_span(lot)
        assert low <= x <= high, f"{name} stands at x {x}, its lot spans {low}..{high}"
        assert (y > 0) == (lot["side"] == "even"), f"{name}: even is north (+y), odd is south"


def test_residents_have_a_bell_a_doorstep_and_a_home():
    for n in DOORS:
        for kind in ("bell", "doorstep"):
            assert f"{kind}:{n}" in _names(), f"{kind}:{n}"
            assert _extras(f"{kind}:{n}").get("id") == str(n) or _extras(f"{kind}:{n}").get("id") == n
    residents = {lot["resident"]: lot["n"] for lot in LOTS.values() if "resident" in lot}
    assert set(residents.values()) <= set(DOORS)
    for resident in residents:
        assert f"home:{resident}" in _names()
        assert _extras(f"home:{resident}").get("id") == resident
    for n in DOORS:   # a bell and a doorstep stand on the house's own side of the street, by its door
        lot = next(lot for lot in LOTS.values() if lot.get("n") == n)
        low, high = _lot_span(lot)
        for kind in ("bell", "doorstep"):
            x, y = _blender_xy(f"{kind}:{n}")
            assert low <= x <= high and (y > 0) == (lot["side"] == "even"), (kind, n, x, y)


def test_fields_explainer_and_ride_markers_are_there():
    for field in TOWN["fields"]:
        name = f"field:{field['step']}"
        assert name in _names(), name
        assert _extras(name) == {"interaction": "field", "id": field["step"]}
    assert _extras("explain:transformator").get("interaction") == "explain"
    assert _extras("ride:street").get("interaction") == "ride"
    assert _extras("arrive:van").get("interaction") == "arrive"
    for spot in ("gert_trench", "ahmed_trench", "sandra_door7", "de_jong_garden", "el_amrani_garden", "wim_garden"):
        assert _extras(f"spot:{spot}") == {"interaction": "spot", "id": spot}


def test_the_ride_marker_stands_at_the_kerb_vans_passenger_door():
    van = PROPS["van_kerb"]
    x, y = _blender_xy("ride:street")
    assert abs(x - van["at"]) <= 6, "within the van's length"
    assert y < 0 if van["side"] == "odd" else y > 0, "on the pavement side of the van"
    ax, ay = _blender_xy("arrive:van")
    assert abs(ax - van["at"]) <= 6 and (ay < 0) == (y < 0)
    assert "kerb_van" in _names()


def test_the_zonnestraat_room_marks_the_walkable_ground():
    extras = _extras("room:zonnestraat")
    assert extras["interaction"] == "room" and extras["id"] == "zonnestraat"
    x, z, w, d = extras["rect"]
    assert x <= 0 and x + w >= PROPS["canal"]["at"] - 1 and w <= 130, "the street, hedge to canal"
    assert d >= 16 and z < 0 < z + d, "road centre inside, both sides"


def test_three_street_tells_with_three_heights_and_a_bulb_on_the_lamp():
    for tell in ("street_lamp", "dug_pavement", "window_note"):
        assert f"tell_{tell}" in _names(), tell
        for band in BANDS:
            assert f"tell_{tell}_{band}" in _names(), f"tell_{tell}_{band}"
    for band in BANDS:
        assert f"tell_street_lamp_{band}_bulb" in _names()


def test_the_dug_pavement_lies_at_x_36_and_the_lamp_at_house_14():
    x, _y = _blender_xy("tell_dug_pavement")
    assert abs(x - 36) <= 4
    lamp_x, lamp_y = _blender_xy("tell_street_lamp")
    low, high = _lot_span(LOTS["house_14"])
    assert low - 1 <= lamp_x <= high + 1 and lamp_y > 0


def test_the_nodes_the_game_switches_are_there():
    names = _names()
    for name in ("kerb_van", "heat_pump_9", "fan", "card_7", "trench_marks", "klic_board", "trafo_vent",
                 "shell_floor", "shell_walls", "outside", "roofs", "glass_windows", "windows_lit", "light_pools",
                 "lamp_heads", "collision-colonly"):
        assert name in names, name
    fan = _node("fan")
    parent = next(n for n in G["nodes"] if fan in [G["nodes"][c] for c in n.get("children", [])])
    assert parent["name"] == "heat_pump_9"


def test_no_lights_are_exported():
    assert "KHR_lights_punctual" not in G.get("extensionsUsed", [])
    assert not any("light" in n and "KHR" in str(n.get("extensions", {})) for n in G["nodes"])


def test_the_static_street_stays_within_the_draw_budget():
    assert sum(len(m["primitives"]) for m in G["meshes"]) <= 160


def _material_of(mesh_node_name: str) -> list[dict]:
    mesh = G["meshes"][_node(mesh_node_name)["mesh"]]
    return [G["materials"][p["material"]] for p in mesh["primitives"]]


def test_the_shell_carries_a_lightmap_on_uv2():
    for name in ("shell_floor", "shell_walls"):
        mesh = G["meshes"][_node(name)["mesh"]]
        for prim in mesh["primitives"]:
            assert "TEXCOORD_1" in prim["attributes"], f"{name} has no second UV set"
        for material in _material_of(name):
            assert material["occlusionTexture"]["texCoord"] == 1, (name, material.get("name"))


def test_every_texture_is_an_external_file_that_exists():
    for image in G.get("images", []):
        assert (ASSETS / image["uri"]).exists(), image["uri"]


def test_street_dimensions_follow_the_town():
    seg = TOWN["segments"][0]
    x0, z0, w, d = _extras("room:zonnestraat")["rect"]
    half = seg["carriageway"] / 2 + seg["pavement"] + seg["front_garden"]
    assert d == pytest.approx(2 * half, abs=0.5), "ground from the north garden line to the south one"
