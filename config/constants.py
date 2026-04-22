"""
Game-wide constants. Tune STATION_DEFINITIONS to calibrate Day-1 metrics.

Day-1 targets (spec §3.4):
  output = 14 hoverboards/day
  OEE    = 41% plant-wide weighted average
  WIP    = 62 units in-system
  FTR    = 91.8% plant-wide
"""

# ── Rendering ──────────────────────────────────────────────────────────────────
TILE_SIZE        = 48          # px per grid tile
SCREEN_W         = 1280
SCREEN_H         = 720
FPS              = 60

# ── Simulation time ────────────────────────────────────────────────────────────
SHIFT_DURATION   = 8 * 3600   # simulated seconds per shift
SHIFTS_PER_DAY   = 3
DAY_DURATION     = SHIFT_DURATION * SHIFTS_PER_DAY  # 86 400 s

# Real-time ratio at 1× speed: 1 simulated day ≈ 20 real minutes
# → 1 real second = 86400 / (20×60) = 72 simulated seconds
SIM_SECONDS_PER_REAL_SECOND = 72.0
SPEED_MULTIPLIERS = [0, 1, 2, 4, 8]   # index 0 = pause

# ── Operator model ─────────────────────────────────────────────────────────────
FATIGUE_RATE          = 0.0001   # fatigue units per simulated second
FATIGUE_RESET_BREAK   = 0.4      # fatigue removed per break
FATIGUE_PERF_PENALTY  = 0.25     # max performance penalty at full fatigue
BREAK_DURATION        = 1800     # simulated seconds per break

# ── Credits ────────────────────────────────────────────────────────────────────
CREDIT_BASE = {"low": 75, "medium": 150, "high": 200, "critical": 300}

# ── AI cost (§10.4) ────────────────────────────────────────────────────────────
COACH_COST_PER_EXCHANGE    = 75   # credits
POST_SCORE_REFLECTION_COST = 50
PROBLEM_GENERATION_COST    = 500

# ── Save/load ──────────────────────────────────────────────────────────────────
SAVE_ROLLING_BACKUPS = 5
DB_FILENAME          = "novoglide_save.db"
SCHEMA_VERSION       = 1

# ──────────────────────────────────────────────────────────────────────────────
# Station definitions — 19 stations, 6 zones
#
# Each entry: (id, name, zone_id, zone_name, station_type,
#              target_cycle_time,  ← seconds/unit at full performance
#              base_availability, base_performance, base_quality,
#              operator_count, starting_wip_in)
#
# OEE = availability × performance × quality.
# Targets chosen so plant average ≈ 41%.
# ──────────────────────────────────────────────────────────────────────────────
STATION_DEFINITIONS = [
    # id                  name                          zone  zone_name          type              ct      avail  perf   qual   ops  wip_in
    ("dock",              "Dock & Staging",             "z1", "Receiving",       "receiving",      600,    0.80,  0.78,  0.98,  2,   0),
    ("incoming_qa",       "Incoming QA",                "z1", "Receiving",       "inspection",     900,    0.70,  0.65,  0.90,  2,   3),
    ("coil_winding",      "Coil Winding",               "z2", "Component Prep",  "component_prep", 1800,   0.65,  0.70,  0.88,  2,   5),
    ("pcb_prep",          "PCB Prep",                   "z2", "Component Prep",  "component_prep", 2400,   0.55,  0.65,  0.85,  2,   6),
    ("deck_cutting",      "Deck Cutting",               "z2", "Component Prep",  "component_prep", 1200,   0.70,  0.75,  0.90,  1,   4),
    ("battery_prep",      "Battery Prep",               "z2", "Component Prep",  "component_prep", 1500,   0.68,  0.72,  0.89,  1,   3),
    ("deck_assembly",     "Deck Assembly",              "z3", "Subassembly",     "subassembly",    2100,   0.60,  0.68,  0.87,  2,   5),
    ("battery_assembly",  "Battery Assembly",           "z3", "Subassembly",     "subassembly",    2400,   0.65,  0.72,  0.85,  2,   4),
    ("propulsion_build",  "Propulsion Build",           "z3", "Subassembly",     "subassembly",    2700,   0.60,  0.65,  0.83,  2,   6),
    ("shell_assembly",    "Shell Assembly",             "z3", "Subassembly",     "subassembly",    1800,   0.70,  0.75,  0.91,  1,   3),
    ("integration_1",     "Integration Line — Stn 1",  "z4", "Final Assembly",  "final_assembly", 1800,   0.68,  0.70,  0.90,  1,   4),
    ("integration_2",     "Integration Line — Stn 2",  "z4", "Final Assembly",  "final_assembly", 1800,   0.70,  0.72,  0.89,  1,   3),
    ("integration_3",     "Integration Line — Stn 3",  "z4", "Final Assembly",  "final_assembly", 2000,   0.62,  0.68,  0.82,  1,   5),
    ("integration_4",     "Integration Line — Stn 4",  "z4", "Final Assembly",  "final_assembly", 2000,   0.60,  0.65,  0.80,  1,   4),
    ("integration_5",     "Integration Line — Stn 5",  "z4", "Final Assembly",  "final_assembly", 1800,   0.72,  0.78,  0.90,  1,   2),
    ("burn_in",           "Burn-In",                   "z5", "Testing",         "testing",        3600,   0.70,  0.72,  0.96,  1,   3),
    ("flight_test",       "Flight Test",               "z5", "Testing",         "testing",        1800,   0.55,  0.58,  0.88,  2,   4),
    ("final_qa",          "Final QA",                  "z5", "Testing",         "inspection",     1200,   0.68,  0.71,  0.93,  2,   3),
    ("packaging",         "Packaging & Shipping",       "z6", "Packaging",       "packaging",      600,    0.88,  0.92,  0.98,  2,   3),
]

# Ordered flow: unit enters dock, exits packaging
STATION_FLOW_ORDER = [
    "dock", "incoming_qa",
    "coil_winding", "pcb_prep", "deck_cutting", "battery_prep",
    "deck_assembly", "battery_assembly", "propulsion_build", "shell_assembly",
    "integration_1", "integration_2", "integration_3", "integration_4", "integration_5",
    "burn_in", "flight_test", "final_qa",
    "packaging",
]

# ── Operator roster (24 operators) ────────────────────────────────────────────
# (id, name, home_station, shift, skill_levels_dict)
OPERATOR_DEFINITIONS = [
    ("op01", "Maya Chen",      "dock",             1, {"receiving": 4, "inspection": 3}),
    ("op02", "Darius Osei",    "incoming_qa",      1, {"inspection": 3, "receiving": 2}),
    ("op03", "Priya Nair",     "incoming_qa",      2, {"inspection": 2}),
    ("op04", "Tomasz Wiśnik",  "coil_winding",     1, {"component_prep": 4}),
    ("op05", "Fatima Diallo",  "coil_winding",     2, {"component_prep": 3}),
    ("op06", "Rafael Souza",   "pcb_prep",         1, {"component_prep": 5}),
    ("op07", "Ingrid Holm",    "pcb_prep",         2, {"component_prep": 3}),
    ("op08", "Kwame Asante",   "deck_cutting",     1, {"component_prep": 3}),
    ("op09", "Lena Bauer",     "battery_prep",     1, {"component_prep": 2}),
    ("op10", "Jin-Ho Park",    "deck_assembly",    1, {"subassembly": 3}),
    ("op11", "Sofia Rossi",    "deck_assembly",    2, {"subassembly": 2}),
    ("op12", "Amir Khalil",    "battery_assembly", 1, {"subassembly": 4}),
    ("op13", "Claudia Mende",  "battery_assembly", 2, {"subassembly": 2}),
    ("op14", "Yusuf Şahin",    "propulsion_build", 1, {"subassembly": 3}),
    ("op15", "Nkechi Obi",     "propulsion_build", 2, {"subassembly": 2}),
    ("op16", "Lars Eriksen",   "shell_assembly",   1, {"subassembly": 3}),
    ("op17", "Mei-Lin Wu",     "integration_1",    1, {"final_assembly": 2}),
    ("op18", "Carlos Vargas",  "integration_3",    1, {"final_assembly": 3}),
    ("op19", "Amara Diop",     "integration_4",    1, {"final_assembly": 3}),
    ("op20", "Viktor Novak",   "integration_5",    1, {"final_assembly": 5, "subassembly": 4}),  # hero operator
    ("op21", "Hana Tanaka",    "burn_in",          1, {"testing": 3}),
    ("op22", "Elan Brightman", "flight_test",      1, {"testing": 2}),
    ("op23", "Sera Quinn",     "flight_test",      2, {"testing": 2}),
    ("op24", "Bao Nguyen",     "packaging",        1, {"packaging": 5, "final_assembly": 4}),  # overqualified packager
]

# ── Zone colours (for rendering) ──────────────────────────────────────────────
ZONE_COLOURS = {
    "z1": (200, 220, 240),   # pale blue
    "z2": (220, 240, 200),   # pale green
    "z3": (240, 230, 200),   # pale amber
    "z4": (235, 210, 235),   # pale purple
    "z5": (240, 200, 200),   # pale red
    "z6": (200, 240, 240),   # pale teal
}
