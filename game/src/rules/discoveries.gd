class_name Discoveries
extends RefCounted
## Hidden rewards ("Ontdekkingen", audit §4): unannounced recognition for
## deep thinking (the extra why, the patient fix, developing people, measuring
## before choosing, learning from a failed Check). Each fires once, as a quiet
## {type: discovery, id} event; the codex shows found ones with their story and
## the rest as silhouettes, with a hint once their act is over (Merijn,
## 2026-10-15).
##
## Rules (audit §4.1, CLAUDE.md §2): a reward never pays the short-term or the
## disrespectful choice more; anything about speed also needs quality; small
## in power (reputation at most +3, no XP); no streaks and no loss for
## stopping (respect the player's time): counts add up, they never reset.
##
## GameSession feeds it what the player does (note_*) and calls update after
## every action. Nothing depends on it.

## Trigger types and the parameters each takes (mirrored in build_content.py).
const TRIGGERS := {
	"check_recovery": [], "fork_measured": ["window_days"], "fork_learned": [], "held": ["days"],
	"tool_at": ["place", "tool", "hours", "months", "problem_active", "no_problem_at"],
	"predictions": ["count"], "deepest_why": ["count"], "durable_held": ["count", "days"],
	"blame_repair_clue": [], "no_blame_act": [], "no_overload_act": ["experiments"],
	"missions_scored": ["missions", "score"], "recovered_after_fail": ["score"], "coach_cycle": [],
	"tool_in_missions": ["place", "tool", "missions", "problem", "countermeasure"],
	"farewell": ["mission", "place", "days", "countermeasures"],
	"followed_order": ["days"], "contain_then_fix": ["days"],
}
## A fix holds when its health is at least this (Reputation.HELD_HEALTH).
const HELD_HEALTH := Reputation.HELD_HEALTH
## A countermeasure that fades within this many days is the quick option.
const QUICK_DAYS := 45
## Gemba uses remembered for the windowed triggers (days).
const LOG_DAYS := 30

## id → {id, name, line, hint, act, trigger, reward}
var defs: Dictionary[String, Dictionary] = {}
## Found discoveries: id → the minute it was found.
var found: Dictionary[String, int] = {}
var events: Array[Dictionary] = []

# Signals, saved with the state.
var _uses: Array[Dictionary] = []  # {t, place, tool, mission}
var _accepted := {}  # mission → when it was last taken on
var _counts := {}  # predictions, deepest_why, durable_held
var _after_fail := {}  # problem → "failed" | "new_clue"
var _durable := {}  # problem → when its durable choice was acted on
var _blame := {}  # "mission|team" → "blamed" | "repaired"
var _coach := {}  # main mission → {stage: true}
var _act_blamed := {}
var _act_experiments := {}
var _act_overload := {}
var _missions_heard := {}  # discovery id → {mission: true}
var _not_constraint := {}  # problems whose Check said not the constraint
var _first_pass := {}  # problems whose first Check passed with the right cause and KPI
var _contained := {}  # missions contained within contain_then_fix's days of being taken on


func _init(content: Array) -> void:
	for d: Variant in content:
		if d is Dictionary and d.has("id"):
			defs[str(d["id"])] = d


# ── Signals ─────────────────────────────────────────────────────────────────

## A gemba tool or a question ("conversation") at a place. `reply`: the
## question's reply code (blame, repair, clue, ...); `key_clue`: a key clue was
## found.
func note_use(s: GameSession, place: String, tool: String, reply: String = "", key_clue: bool = false) -> void:
	var main := _main(s)
	_uses.append({"t": s.region.net.time, "place": place, "tool": tool, "mission": main})
	while not _uses.is_empty() and s.region.net.time - int(_uses[0]["t"]) > SimCalendar.days(LOG_DAYS):
		_uses.pop_front()
	var team := s.region.team_at(place)
	var key := main + "|" + team
	match reply:
		"blame":
			_blame[key] = "blamed"
			_act_blamed[str(_act(s))] = true
		"repair", "welcome":
			if _blame.get(key) == "blamed":
				_blame[key] = "repaired"
		"clue":
			if key_clue and _blame.get(key) == "repaired":
				_reward(s, "blame_repair_clue")
	if key_clue:
		for problem_id: String in _after_fail:
			if _after_fail[problem_id] == "failed" and s.region.problems[problem_id].clues.any(
					func(c: Clue) -> bool: return c.at == place and s.region.found.has(c.id)):
				_after_fail[problem_id] = "new_clue"
	for d: Dictionary in _of_type("tool_at"):
		if _tool_at(s, d["trigger"], place, tool):
			_award(s, d)
	for d: Dictionary in _of_type("tool_in_missions"):
		var t: Dictionary = d["trigger"]
		if place == t["place"] and tool == t["tool"] and not main.is_empty():
			_missions_heard.get_or_add(d["id"], {})[main] = true


## An A3 was submitted (it passed the form): the deepest why, and whether a
## lasting fix was chosen over a quick one.
func note_a3(s: GameSession, problem_id: String) -> void:
	var r := s.region
	var p: ProblemDef = r.problems[problem_id]
	var st: ProblemState = r.state[problem_id]
	_act_experiments[str(_act(s))] = int(_act_experiments.get(str(_act(s)), 0)) + 1
	var deepest := 0
	for c in p.clues:
		if c.key:
			deepest = maxi(deepest, c.depth)
	var linked: Array = st.a3["evidence"]
	if st.cause_correct and p.clues.any(func(c: Clue) -> bool: return c.key and c.depth == deepest and c.id in linked):
		_count("deepest_why")


## A Check's result.
func note_check(s: GameSession, problem_id: String, result: Dictionary) -> void:
	var st: ProblemState = s.region.state[problem_id]
	if result.get("not_constraint", false):
		_not_constraint[problem_id] = true
	if not result.get("passed", false):
		_after_fail[problem_id] = "failed"
		return
	var right: bool = st.cause_correct and st.a3.get("prediction") == s.region.problems[problem_id].kpi
	if right and st.failed_checks == 0:
		_first_pass[problem_id] = true
		_count("predictions")
	if _after_fail.get(problem_id) == "new_clue" and st.cause_correct:
		_reward(s, "check_recovery")
	_after_fail.erase(problem_id)


## An Act: a lasting fix chosen over a quick one starts its clock.
func note_act(s: GameSession, problem_id: String) -> void:
	var r := s.region
	var p: ProblemDef = r.problems[problem_id]
	var st: ProblemState = r.state[problem_id]
	var cm: CountermeasureDef = r.countermeasures.get(st.a3.get("cm", ""))
	if cm == null:
		return
	var lasting := cm.decay_days < 0 or st.standardised
	var quick_fitted := p.countermeasures.keys().any(func(id: String) -> bool:
		var other: CountermeasureDef = r.countermeasures.get(id)
		return other != null and other.id != cm.id and other.decay_days > 0 and other.decay_days <= QUICK_DAYS \
			and p.countermeasures[id] >= 0.6)
	if lasting and quick_fitted:
		_durable[problem_id] = r.net.time


## A mission was taken on.
func note_accept(s: GameSession, mission_id: String) -> void:
	_accepted[mission_id] = s.region.net.time


## A safety mission was contained (Missions.contain): in time when within
## contain_then_fix's days of taking it on.
func note_contain(s: GameSession, mission_id: String) -> void:
	var accepted: Variant = _accepted.get(mission_id)
	if accepted != null and s.region.net.time - int(accepted) <= SimCalendar.days(_param("contain_then_fix", "days", 2)):
		_contained[mission_id] = true


## The coach answered about a main mission at a stage.
func note_coach(mission_id: String, stage: String) -> void:
	_coach.get_or_add(mission_id, {})[stage] = true


# ── Time and progress ───────────────────────────────────────────────────────

## After every action: discoveries that follow from time passing and from
## missions done.
func update(s: GameSession) -> void:
	var r := s.region
	for e: Dictionary in s.missions.events:
		if e["type"] == "overload":
			_act_overload[str(_act(s))] = true
	for problem_id: String in _durable.keys():
		if r.state[problem_id].phase != ProblemState.Phase.RESOLVED:
			_durable.erase(problem_id)
		elif r.net.time - _durable[problem_id] >= SimCalendar.days(_param("durable_held", "days", 180)):
			_durable.erase(problem_id)
			if r.health(problem_id) >= HELD_HEALTH:
				_count("durable_held")
	for d: Dictionary in defs.values():
		if not found.has(d["id"]) and _met(s, d):
			_award(s, d)


func _met(s: GameSession, d: Dictionary) -> bool:
	var t: Dictionary = d["trigger"]
	var m := s.missions
	match str(t["type"]):
		"held":
			var days := SimCalendar.days(int(t.get("days", 365)))
			for problem_id: String in m.stewardship.act_at:
				if s.region.net.time - m.stewardship.act_at[problem_id] >= days and s.region.health(problem_id) >= HELD_HEALTH:
					return true
		"fork_measured", "fork_learned":
			return _fork(s, t)
		"no_blame_act":
			return _ended_acts(s).any(func(act: int) -> bool:
				return not _act_blamed.has(str(act)) and s.region.trust.values().all(func(v: int) -> bool: return v >= 0))
		"no_overload_act":
			return _ended_acts(s).any(func(act: int) -> bool:
				return int(_act_experiments.get(str(act), 0)) >= int(t.get("experiments", 3)) and not _act_overload.has(str(act)))
		"missions_scored":
			return (t["missions"] as Array).all(func(id: Variant) -> bool:
				var def: MissionDef = m.defs.get(str(id))
				return def != null and m.done_once.has(def.id) \
					and int(s.region.state[def.goal_problem].score.get("total", 0)) >= int(t.get("score", 20)))
		"recovered_after_fail":
			return m.failed_once.keys().any(func(id: String) -> bool:
				var def: MissionDef = m.defs[id]
				var st: ProblemState = s.region.state.get(def.goal_problem)
				return st != null and st.phase == ProblemState.Phase.RESOLVED and int(st.score.get("total", 0)) >= int(t.get("score", 20)))
		"coach_cycle":
			return _coach.keys().any(func(id: String) -> bool:
				var def: MissionDef = m.defs.get(id)
				return def != null and _coach[id].size() == Missions.STAGES.size() and _first_pass.has(def.goal_problem))
		"tool_in_missions":
			var cm := "chose:%s:%s" % [t["problem"], t["countermeasure"]]
			return _missions_heard.get(d["id"], {}).size() >= int(t.get("missions", 3)) and m.knows(cm)
		"farewell":
			return _farewell(s, t)
		"followed_order":
			var delivered: float = s.followed_order()["delivered_days"]
			return delivered >= 0.0 and delivered <= float(t.get("days", 126))
		"contain_then_fix":
			return _contained.keys().any(func(id: String) -> bool:
				var def: MissionDef = m.defs.get(id)
				var st: ProblemState = s.region.state.get(def.goal_problem) if def != null else null
				return st != null and st.phase == ProblemState.Phase.RESOLVED and st.cause_correct)
		"predictions", "deepest_why", "durable_held":
			return int(_counts.get(str(t["type"]), 0)) >= int(t.get("count", 1))
	return false


## Fork rewards. measured: before accepting the branch done first, the
## player counted (queue_count or time_study) at both branches' places in the
## window, and the bottleneck was done first. learned: the non-bottleneck
## came first, its Check said "not the constraint", and the bottleneck then
## passed its first Check with the right cause and KPI.
func _fork(s: GameSession, t: Dictionary) -> bool:
	var m := s.missions
	for fact in m.facts.with_prefix("fork_first:"):
		var first: MissionDef = m.defs.get(fact.get_slice(":", 2))
		if first == null:
			continue
		var branches := m.defs.values().filter(func(b: MissionDef) -> bool: return b.fork_group == first.fork_group)
		var bottleneck: Array = branches.filter(func(b: MissionDef) -> bool: return b.fork_role == "bottleneck")
		if bottleneck.is_empty():
			continue
		var b: MissionDef = bottleneck[0]
		if t["type"] == "fork_learned":
			if first.fork_role == "non_bottleneck" and _not_constraint.has(first.goal_problem) and _first_pass.has(b.goal_problem):
				return true
			continue
		if first.fork_role != "bottleneck" or not _accepted.has(first.id):
			continue
		var accepted: int = _accepted[first.id]
		var window := SimCalendar.days(int(t.get("window_days", 7)))
		if branches.all(func(br: MissionDef) -> bool:
				var place: String = s.region.problems[br.goal_problem].step if s.region.problems.has(br.goal_problem) else ""
				return _uses.any(func(u: Dictionary) -> bool:
					return u["place"] == place and u["tool"] in ["queue_count", "time_study"] \
						and int(u["t"]) <= accepted and accepted - int(u["t"]) <= window)):
			return true
	return false


## Henk's farewell: his mission done with a countermeasure that develops
## people, and an open conversation at his place in its last days.
func _farewell(s: GameSession, t: Dictionary) -> bool:
	var m := s.missions
	var id := str(t["mission"])
	if not m.done_once.has(id) or not m.defs.has(id) or not m.opened_at.has(id):
		return false
	var def: MissionDef = m.defs[id]
	if not (t["countermeasures"] as Array).any(func(cm: Variant) -> bool: return m.knows("chose:%s:%s" % [def.goal_problem, cm])):
		return false
	var deadline: int = m.opened_at[id] + SimCalendar.days(def.deadline_days)
	var window := SimCalendar.days(int(t.get("days", 7)))
	return _uses.any(func(u: Dictionary) -> bool:
		return u["place"] == t["place"] and u["tool"] == "conversation" and int(u["t"]) <= deadline and deadline - int(u["t"]) <= window)


func _tool_at(s: GameSession, t: Dictionary, place: String, tool: String) -> bool:
	var at := str(t["place"])
	if not (place == at or at.ends_with(".") and place.begins_with(at)):
		return false
	if t.has("tool") and str(t["tool"]) != tool:
		return false
	var minute := s.region.net.time % SimCalendar.MINUTES_PER_DAY
	if t.has("hours"):
		var from := int(t["hours"][0]) * 60
		var to := int(t["hours"][1]) * 60
		if not (minute >= from and minute < to if from < to else minute >= from or minute < to):
			return false
	if t.has("months") and not s.month() in t["months"]:
		return false
	if t.has("problem_active") and not s.region.state[str(t["problem_active"])].is_open():
		return false
	if t.get("no_problem_at", false) and s.region.problem_list().any(func(p: ProblemDef) -> bool:
			return p.step == place and s.region.state[p.id].is_open()):
		return false
	return true


# ── Helpers ─────────────────────────────────────────────────────────────────

func _of_type(type: String) -> Array:
	return defs.values().filter(func(d: Dictionary) -> bool: return d["trigger"]["type"] == type and not found.has(d["id"]))


func _param(type: String, key: String, fallback: int) -> int:
	for d: Dictionary in defs.values():
		if d["trigger"]["type"] == type:
			return int(d["trigger"].get(key, fallback))
	return fallback


func _count(type: String) -> void:
	_counts[type] = int(_counts.get(type, 0)) + 1


func _reward(s: GameSession, type: String) -> void:
	for d: Dictionary in _of_type(type):
		_award(s, d)


func _award(s: GameSession, d: Dictionary) -> void:
	if found.has(d["id"]):
		return
	found[d["id"]] = s.region.net.time
	var reward: Dictionary = d.get("reward", {})
	if reward.has("reputation"):
		s.region.earn_reputation(int(reward["reputation"]), "discovery")
	var trust: Dictionary = reward.get("trust", {})
	for team: Variant in trust:
		s.region.change_trust(str(team), int(trust[team]))
	events.append({"type": "discovery", "id": d["id"]})


## The main mission now (the act the player is in), "" without one.
func _main(s: GameSession) -> String:
	var mains := s.missions.active("main")
	return mains[0].id if not mains.is_empty() else ""


## The act the player is in (Missions.current_act).
func _act(s: GameSession) -> int:
	return s.missions.current_act()


## Acts whose main missions are all done.
func _ended_acts(s: GameSession) -> Array[int]:
	var mains_by_act := {}
	for m: MissionDef in s.missions.defs.values():
		if m.kind == "main" and m.act >= 0:
			mains_by_act.get_or_add(m.act, []).append(m.id)
	var out: Array[int] = []
	for act: int in mains_by_act:
		if (mains_by_act[act] as Array).all(func(id: String) -> bool: return s.missions.done_once.has(id)):
			out.append(act)
	return out


# ── Views and saves ─────────────────────────────────────────────────────────

## The codex view: every discovery, found ones with their name, line and
## reward, the rest as silhouettes ({id, found: false}) with their hint once
## their act is over (Merijn, 2026-10-15).
func view(s: GameSession) -> Array[Dictionary]:
	var ended := _ended_acts(s)
	var out: Array[Dictionary] = []
	for d: Dictionary in defs.values():
		if found.has(d["id"]):
			out.append({"id": d["id"], "found": true, "name": d["name"], "line": d["line"], "reward": d.get("reward", {})})
		else:
			var hint: String = d["hint"] if int(d.get("act", -1)) in ended else ""
			out.append({"id": d["id"], "found": false, "hint": hint})
	return out


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func to_dict() -> Dictionary:
	return {"found": found.duplicate(), "uses": _uses.duplicate(true), "counts": _counts.duplicate(),
		"after_fail": _after_fail.duplicate(), "durable": _durable.duplicate(), "blame": _blame.duplicate(),
		"coach": _coach.duplicate(true), "act_blamed": _act_blamed.duplicate(), "act_experiments": _act_experiments.duplicate(),
		"act_overload": _act_overload.duplicate(), "missions_heard": _missions_heard.duplicate(true), "accepted": _accepted.duplicate(),
		"not_constraint": _not_constraint.duplicate(), "first_pass": _first_pass.duplicate(), "contained": _contained.duplicate()}


## Restore to_dict() output; discoveries the content no longer has are dropped.
func load_dict(d: Dictionary) -> void:
	var saved_found := JsonFile.dict_or_empty(d.get("found"))
	found.clear()
	for id: Variant in saved_found:
		if defs.has(str(id)):
			found[str(id)] = int(saved_found[id])
	_uses.assign((d.get("uses", []) as Array).filter(func(u: Variant) -> bool: return u is Dictionary) if d.get("uses") is Array else [])
	for pair in [[_counts, "counts"], [_after_fail, "after_fail"], [_durable, "durable"], [_blame, "blame"],
			[_act_blamed, "act_blamed"], [_act_experiments, "act_experiments"], [_act_overload, "act_overload"],
			[_not_constraint, "not_constraint"], [_first_pass, "first_pass"], [_coach, "coach"], [_missions_heard, "missions_heard"],
			[_accepted, "accepted"]]:
		var into: Dictionary = pair[0]
		into.clear()
		var saved := JsonFile.dict_or_empty(d.get(pair[1]))
		for key: Variant in saved:
			into[str(key)] = saved[key]
