"""
Authoritative world layout — tile coordinates, objects, rooms, and NPCs.
Translated directly from Lean Factory Topology v3.html (the design reference).

Tile size: 24 px.  World: 100 × 60 tiles = 2 400 × 1 440 px.
"""

# ── Tile-type codes ────────────────────────────────────────────────────────────
TILE = {
    "void":       0,
    "concrete":   1,   # factory floor
    "wall":       2,
    "carpet_gray":3,   # corridor
    "carpet_blue":4,   # operations
    "carpet_green":5,  # quality
    "carpet_purple":6, # IT
    "carpet_teal": 7,  # finance
    "carpet_orange":8, # HR
    "carpet_brown":9,  # break room
    "locker":    10,
    "maintenance":11,
    "asphalt":   12,
    "zone_recv": 13,   # zone paint colours
    "zone_prep": 14,
    "zone_sub":  15,
    "zone_final":16,
    "zone_test": 17,
    "zone_pack": 18,
    "door":      19,
    "grass":     20,
    "hazard":    21,
}

TILE_COLORS = {
    0:  (10,  9,   8),    # void — near black
    1:  (207, 198, 178),  # concrete
    2:  (58,  56,  48),   # wall
    3:  (189, 180, 158),  # carpet gray
    4:  (182, 200, 218),  # carpet blue
    5:  (191, 213, 191),  # carpet green
    6:  (201, 188, 220),  # carpet purple
    7:  (188, 214, 208),  # carpet teal
    8:  (228, 200, 179),  # carpet orange
    9:  (201, 181, 154),  # carpet brown
    10: (227, 220, 203),  # locker white-tile
    11: (216, 195, 122),  # maintenance yellow-shop
    12: (92,  86,  75),   # asphalt
    13: (229, 207, 154),  # recv amber
    14: (201, 214, 163),  # prep olive
    15: (169, 212, 184),  # sub mint
    16: (169, 195, 214),  # final steel-blue
    17: (195, 181, 214),  # test lavender
    18: (214, 169, 169),  # pack blush
    19: (202, 162, 74),   # door gold
    20: (93,  122, 60),   # grass
    21: (240, 198, 70),   # hazard yellow
}

SOLID_TILES = {0, 2, 20}   # everything else is walkable

# ── Player spawn (tile 72, 17 → pixel centre) ─────────────────────────────────
PLAYER_SPAWN_TILE = (72, 17)   # (tx, ty)

# ── Rooms ─────────────────────────────────────────────────────────────────────
ROOMS = [
    {"id": "yard",    "name": "Exterior Yard",  "x1":  0, "y1":  0, "x2": 69, "y2":  3},
    {"id": "factory", "name": "Factory Floor",  "x1":  0, "y1":  4, "x2": 69, "y2": 30},
    {"id": "corr",    "name": "Main Corridor",  "x1": 70, "y1":  4, "x2": 77, "y2": 59},
    {"id": "ops",     "name": "Operations",     "x1": 78, "y1":  4, "x2": 99, "y2": 12},
    {"id": "qua",     "name": "Quality",        "x1": 78, "y1": 13, "x2": 99, "y2": 21},
    {"id": "it",      "name": "IT",             "x1": 78, "y1": 22, "x2": 99, "y2": 30},
    {"id": "fin",     "name": "Finance",        "x1": 78, "y1": 31, "x2": 99, "y2": 39},
    {"id": "hr",      "name": "HR",             "x1": 78, "y1": 40, "x2": 99, "y2": 48},
    {"id": "brk",     "name": "Break Room",     "x1": 78, "y1": 49, "x2": 99, "y2": 59},
    {"id": "mnt",     "name": "Maintenance",    "x1":  0, "y1": 31, "x2": 29, "y2": 59},
    {"id": "lkr",     "name": "Locker Room",    "x1": 30, "y1": 48, "x2": 69, "y2": 59},
]

# ── Objects (stations, desks, boards, NPCs, etc.) ─────────────────────────────
# Each dict: tx, ty (top-left tile), w, h (tile dimensions), kind, id, label
# Stations also carry: z (zone label), ct (cycle time), ops, status, station_id
OBJECTS = [
    # ── Zone 1 — Receiving ────────────────────────────────────────────────────
    {"tx":  4, "ty":  6, "w": 3, "h": 5, "kind": "dock",    "id": "R-01",    "label": "Dock",            "zone": "Z1 Receiving", "station_id": "dock",          "ct": 120, "ops": 1, "status": "run"},
    {"tx":  9, "ty":  7, "w": 3, "h": 2, "kind": "bench",   "id": "R-02",    "label": "Incoming QA",     "zone": "Z1 Receiving", "station_id": "incoming_qa",   "ct":  90, "ops": 1, "status": "run"},
    {"tx":  9, "ty": 11, "w": 6, "h": 3, "kind": "rack",    "id": "R-03",    "label": "Staging",         "zone": "Z1 Receiving", "station_id": "staging",       "ct":  60, "ops": 1, "status": "wait"},
    # ── Zone 2 — Component Prep ───────────────────────────────────────────────
    {"tx": 19, "ty":  7, "w": 3, "h": 4, "kind": "machine", "id": "P-01",    "label": "Coil Winding",    "zone": "Z2 Prep",      "station_id": "coil_winding",  "ct": 180, "ops": 1, "status": "run"},
    {"tx": 24, "ty":  7, "w": 3, "h": 4, "kind": "machine", "id": "P-02",    "label": "PCB Prep",        "zone": "Z2 Prep",      "station_id": "pcb_prep",      "ct": 150, "ops": 1, "status": "run"},
    {"tx": 29, "ty":  7, "w": 3, "h": 5, "kind": "cnc",     "id": "P-03",    "label": "Deck Cutting",    "zone": "Z2 Prep",      "station_id": "deck_cutting",  "ct": 200, "ops": 1, "status": "run"},
    # ── Zone 3 — Subassembly ──────────────────────────────────────────────────
    {"tx": 36, "ty":  7, "w": 6, "h": 5, "kind": "cell",    "id": "S-01",    "label": "Propulsion Build","zone": "Z3 Subassy",   "station_id": "propulsion_build","ct":240, "ops": 1, "status": "run"},
    {"tx": 44, "ty":  7, "w": 6, "h": 5, "kind": "cell",    "id": "S-02",    "label": "Battery Assembly","zone": "Z3 Subassy",   "station_id": "battery_assembly","ct":220, "ops": 1, "status": "run"},
    {"tx": 52, "ty":  7, "w": 7, "h": 5, "kind": "cell",    "id": "S-03",    "label": "Deck Assembly",   "zone": "Z3 Subassy",   "station_id": "deck_assembly", "ct": 260, "ops": 1, "status": "wait"},
    # ── Zone 4 — Final Assembly ───────────────────────────────────────────────
    {"tx": 55, "ty": 23, "w": 8, "h": 3, "kind": "line",    "id": "FA-01",   "label": "Integration 1",   "zone": "Z4 Final",     "station_id": "integration_1", "ct": 300, "ops": 1, "status": "run"},
    {"tx": 46, "ty": 23, "w": 8, "h": 3, "kind": "line",    "id": "FA-02",   "label": "Integration 2",   "zone": "Z4 Final",     "station_id": "integration_2", "ct": 320, "ops": 1, "status": "run"},
    {"tx": 37, "ty": 23, "w": 8, "h": 3, "kind": "line",    "id": "FA-03",   "label": "Integration 3",   "zone": "Z4 Final",     "station_id": "integration_3", "ct": 360, "ops": 2, "status": "block"},
    {"tx": 28, "ty": 23, "w": 8, "h": 3, "kind": "line",    "id": "FA-04",   "label": "Integration 4",   "zone": "Z4 Final",     "station_id": "integration_4", "ct": 340, "ops": 2, "status": "wait"},
    {"tx": 19, "ty": 23, "w": 8, "h": 3, "kind": "line",    "id": "FA-05",   "label": "Integration 5",   "zone": "Z4 Final",     "station_id": "integration_5", "ct": 280, "ops": 1, "status": "run"},
    # ── Zone 5 — Testing ──────────────────────────────────────────────────────
    {"tx": 13, "ty": 28, "w": 5, "h": 2, "kind": "rig",     "id": "T-01",    "label": "Burn-in",         "zone": "Z5 Testing",   "station_id": "burn_in",       "ct": 600, "ops": 1, "status": "run"},
    {"tx": 20, "ty": 28, "w": 7, "h": 2, "kind": "pad",     "id": "T-02",    "label": "Flight Test",     "zone": "Z5 Testing",   "station_id": "flight_test",   "ct": 420, "ops": 1, "status": "run"},
    {"tx": 29, "ty": 28, "w": 8, "h": 2, "kind": "bench",   "id": "T-03",    "label": "Final QA",        "zone": "Z5 Testing",   "station_id": "final_qa",      "ct": 300, "ops": 2, "status": "run"},
    # ── Zone 6 — Packaging & Shipping ────────────────────────────────────────
    {"tx": 45, "ty": 28, "w":10, "h": 2, "kind": "packline","id": "PK-01",   "label": "Packaging",       "zone": "Z6 Pack",      "station_id": "packaging",     "ct": 180, "ops": 1, "status": "run"},
    {"tx": 58, "ty": 28, "w": 6, "h": 2, "kind": "dock",    "id": "PK-02",   "label": "Dispatch Staging","zone": "Z6 Pack",      "station_id": "dock_out",      "ct": 120, "ops": 1, "status": "wait"},
    # ── Team leader desks ─────────────────────────────────────────────────────
    {"tx":  4, "ty": 17, "w": 3, "h": 1, "kind": "desk",      "id": "TL-Z1",  "label": "TL Desk — Receiving", "role": "Team Leader"},
    {"tx": 20, "ty": 17, "w": 3, "h": 1, "kind": "desk",      "id": "TL-Z2",  "label": "TL Desk — Prep",      "role": "Team Leader"},
    {"tx": 40, "ty": 17, "w": 3, "h": 1, "kind": "desk",      "id": "TL-Z3",  "label": "TL Desk — Subassy",   "role": "Team Leader"},
    {"tx": 60, "ty": 17, "w": 3, "h": 1, "kind": "desk",      "id": "TL-Z4",  "label": "TL Desk — Final",     "role": "Team Leader"},
    # ── Office wing ───────────────────────────────────────────────────────────
    {"tx": 82, "ty":  7, "w": 3, "h": 1, "kind": "desk-exec", "id": "OPS-MGR","label": "Plant Manager Desk",  "role": "Plant Manager (you)"},
    {"tx": 90, "ty":  7, "w": 3, "h": 1, "kind": "desk",      "id": "OPS-SCH","label": "Scheduler Desk",       "role": "Scheduler"},
    {"tx": 94, "ty":  7, "w": 3, "h": 1, "kind": "desk",      "id": "OPS-COACH","label": "Lean Coach Desk",    "role": "Lean Coach"},
    {"tx": 86, "ty": 10, "w": 4, "h": 1, "kind": "board",     "id": "OPS-BRD","label": "Ops Daily Board"},
    {"tx": 82, "ty": 16, "w": 3, "h": 1, "kind": "desk",      "id": "QA-LEAD","label": "QA Lead Desk",         "role": "Quality Lead"},
    {"tx": 90, "ty": 16, "w": 4, "h": 2, "kind": "metro",     "id": "METRO",  "label": "Metrology Bench"},
    {"tx": 82, "ty": 25, "w": 3, "h": 1, "kind": "desk",      "id": "IT-ENG", "label": "IT Engineer Desk",     "role": "IT Engineer"},
    {"tx": 92, "ty": 25, "w": 3, "h": 3, "kind": "server",    "id": "SRV",    "label": "Server Rack — MES"},
    {"tx": 82, "ty": 34, "w": 3, "h": 1, "kind": "desk",      "id": "FIN-CTRL","label": "Controller Desk",     "role": "Controller"},
    {"tx": 91, "ty": 34, "w": 4, "h": 2, "kind": "shelf",     "id": "FIN-SHELF","label": "Records Shelf"},
    {"tx": 82, "ty": 43, "w": 3, "h": 1, "kind": "desk",      "id": "HR-MGR", "label": "HR Manager Desk",      "role": "HR Manager"},
    {"tx": 91, "ty": 43, "w": 4, "h": 2, "kind": "sofa",      "id": "HR-SOFA","label": "Interview Area"},
    {"tx": 82, "ty": 52, "w": 4, "h": 2, "kind": "table",     "id": "BR-TABLE","label": "Lunch Table"},
    {"tx": 90, "ty": 52, "w": 3, "h": 1, "kind": "vend",      "id": "BR-VEND","label": "Vending Machine"},
    {"tx": 90, "ty": 56, "w": 4, "h": 1, "kind": "board",     "id": "BR-BRD", "label": "Info Board — Takt Rhythm"},
    # ── Maintenance ───────────────────────────────────────────────────────────
    {"tx":  4, "ty": 36, "w": 6, "h": 2, "kind": "tools",     "id": "MNT-CRIB","label": "Tool Crib"},
    {"tx": 14, "ty": 36, "w": 4, "h": 2, "kind": "desk",      "id": "MNT-LEAD","label": "Maintenance Lead Desk", "role": "Maintenance Lead"},
    {"tx":  4, "ty": 42, "w":10, "h": 4, "kind": "mill",      "id": "MNT-MILL","label": "Repair Bay — Mill/Lathe"},
    {"tx": 18, "ty": 42, "w": 8, "h": 4, "kind": "parts",     "id": "MNT-PARTS","label": "Spare Parts Shelves"},
    {"tx":  4, "ty": 50, "w": 6, "h": 2, "kind": "board",     "id": "MNT-BRD","label": "TPM Daily Board"},
    # ── Locker room ───────────────────────────────────────────────────────────
    {"tx": 35, "ty": 51, "w":18, "h": 2, "kind": "lockers",   "id": "LKR-ROW1","label": "Lockers A–M"},
    {"tx": 35, "ty": 55, "w":18, "h": 2, "kind": "lockers",   "id": "LKR-ROW2","label": "Lockers N–Z"},
    {"tx": 58, "ty": 53, "w": 4, "h": 2, "kind": "clock",     "id": "CLOCK",   "label": "Clock-in Terminal"},
    # ── Exterior yard ─────────────────────────────────────────────────────────
    {"tx":  2, "ty":  1, "w": 6, "h": 2, "kind": "truck",     "id": "YARD-TRK","label": "Inbound Truck", "zone": "Yard"},
]

# ── NPCs ──────────────────────────────────────────────────────────────────────
NPCS = [
    {"tx":  5, "ty": 18, "w": 1, "h": 1, "color": (74,  144, 216), "name": "TL — Receiving",  "role": "Team Leader",   "label": "Team Leader",   "dir": "down"},
    {"tx": 21, "ty": 18, "w": 1, "h": 1, "color": (74,  144, 216), "name": "TL — Prep",       "role": "Team Leader",   "label": "Team Leader",   "dir": "down"},
    {"tx": 41, "ty": 18, "w": 1, "h": 1, "color": (74,  144, 216), "name": "TL — Subassy",    "role": "Team Leader",   "label": "Team Leader",   "dir": "down"},
    {"tx": 61, "ty": 18, "w": 1, "h": 1, "color": (74,  144, 216), "name": "TL — Final",      "role": "Team Leader",   "label": "Team Leader",   "dir": "left"},
    {"tx": 83, "ty":  8, "w": 1, "h": 1, "color": (216, 161, 74),  "name": "Maya — Scheduler","role": "Scheduler",     "label": "Scheduler",     "dir": "down"},
    {"tx": 95, "ty":  8, "w": 1, "h": 1, "color": (200, 100, 100), "name": "Alex — Lean Coach","role": "Lean Coach",   "label": "Lean Coach",    "dir": "down"},
    {"tx": 83, "ty": 17, "w": 1, "h": 1, "color": (106, 178, 106), "name": "Sven — QA Lead",  "role": "Quality Lead",  "label": "Quality Lead",  "dir": "down"},
    {"tx": 83, "ty": 26, "w": 1, "h": 1, "color": (154, 106, 219), "name": "Priya — IT",      "role": "IT Engineer",   "label": "IT Engineer",   "dir": "right"},
    {"tx": 83, "ty": 35, "w": 1, "h": 1, "color": (74,  179, 166), "name": "Jon — Finance",   "role": "Controller",    "label": "Controller",    "dir": "down"},
]

# Station IDs that appear in production flow
STATION_IDS = [obj["id"] for obj in OBJECTS if "station_id" in obj]
