class_name Progression
## Belts from XP. What each belt unlocks is content (Phase B).
## Thresholds (Merijn, 2026-10-15) pace the whole campaign: yellow after the
## first fork, green in Act II, black in the middle of tier 2's Act III,
## master black in tier 4 (mission-system spec §2.13). Tier 1 pays at most
## ~20,000 XP, so its expert ends green.

const BELTS := [
	{"id": "white", "xp": 0},
	{"id": "yellow", "xp": 2000},
	{"id": "green", "xp": 6000},
	{"id": "black", "xp": 30000},
	{"id": "master_black", "xp": 110000},
]


static func belt_index(xp: int) -> int:
	var index := 0
	for i in BELTS.size():
		if xp >= BELTS[i]["xp"]:
			index = i
	return index


## 0..1 towards the next belt (1 at the top belt).
static func belt_progress(xp: int) -> float:
	var i := belt_index(xp)
	if i == BELTS.size() - 1:
		return 1.0
	return (xp - BELTS[i]["xp"]) / float(BELTS[i + 1]["xp"] - BELTS[i]["xp"])
