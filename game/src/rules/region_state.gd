class_name RegionState
## Captures and restores the rules state of a Region (the player's progress,
## what they found and whom they upset, every problem's place in the PDCA
## loop). The Network is saved separately (NetworkState). Problems the
## content no longer has are dropped and reported.

const PROBLEM_INTS := ["failed_checks", "check_at", "recur_at"]


static func capture(r: Region) -> Dictionary:
	var problems := {}
	for st: ProblemState in r.state.values():
		problems[st.id] = {
			"phase": ProblemState.Phase.keys()[st.phase], "blamed": st.blamed, "a3": st.a3,
			"cause_correct": st.cause_correct, "waste_right": st.waste_right, "eff": st.eff, "level": st.level,
			"failed_checks": st.failed_checks, "check_at": st.check_at, "baseline": st.baseline,
			"recur_at": st.recur_at, "score": st.score,
		}
	return {
		"profile": {"budget": r.profile.budget, "xp": r.profile.xp, "concepts": Array(r.profile.concepts)},
		"observed": r.observed.keys(), "found": r.found.keys(), "trust": r.trust, "problems": problems,
	}


## Returns {error, dropped}.
static func restore(r: Region, d: Dictionary) -> Dictionary:
	for key in ["profile", "trust", "problems"]:
		if not d.get(key) is Dictionary:
			return {"error": "'%s' must be an object" % key, "dropped": []}
	for key in ["observed", "found"]:
		if not d.get(key) is Array:
			return {"error": "'%s' must be a list" % key, "dropped": []}
	var dropped: Array[String] = []
	r.profile.budget = int(d["profile"].get("budget", r.profile.budget))
	r.profile.xp = int(d["profile"].get("xp", 0))
	r.profile.concepts = PackedStringArray(d["profile"].get("concepts", []))
	for place: String in d["observed"]:
		r.observed[place] = true
	for clue_id: String in d["found"]:
		r.found[clue_id] = true
	for team: String in d["trust"]:
		r.trust[team] = int(d["trust"][team])
	for id: String in d["problems"]:
		var saved: Dictionary = d["problems"][id]
		var phase := ProblemState.Phase.keys().find(saved.get("phase", ""))
		if not r.state.has(id) or phase < 0:
			dropped.append(id)
			continue
		var st: ProblemState = r.state[id]
		st.phase = phase
		st.blamed = bool(saved.get("blamed", false))
		st.a3 = _a3(saved.get("a3", {}))
		st.cause_correct = bool(saved.get("cause_correct", false))
		st.waste_right = bool(saved.get("waste_right", false))
		st.eff = float(saved.get("eff", 0.0))
		st.level = saved.get("level", "")
		for key in PROBLEM_INTS:
			st.set(key, int(saved.get(key, st.get(key))))
		st.baseline = saved.get("baseline", {})
		st.score = saved.get("score", {})
	return {"error": "", "dropped": dropped}


static func _a3(saved: Dictionary) -> Dictionary:
	var a3 := saved.duplicate(true)
	if a3.has("cause"):
		a3["cause"] = int(a3["cause"])
	return a3

