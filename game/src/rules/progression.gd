class_name Progression
## Belts from XP. What each belt unlocks is content (Phase B).

const BELTS := [
	{"id": "white", "xp": 0},
	{"id": "yellow", "xp": 1200},
	{"id": "green", "xp": 3500},
	{"id": "black", "xp": 7000},
	{"id": "master_black", "xp": 12000},
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
