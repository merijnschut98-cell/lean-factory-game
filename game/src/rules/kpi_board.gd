class_name KpiBoard
extends RefCounted
## The KPI board, unlocked by a countermeasure (Obeya with end-to-end KPIs).
## At each quarterly review every department on the menu follows two of its
## KPIs; they become the work rules of effect source `board:kpis`, saved with
## the network. The reward follows only the measured end-to-end change since
## the last review (or the unlock), never the labels chosen.

const SOURCE := "board:kpis"
## A quarter of 13 weeks: the OKR cycle.
const REVIEW_DAYS := 91
## The reward for a 100 % average improvement (an estimate, the size of a
## late main mission's reward): a 10 % better quarter earns 100 XP and €1,000.
const REVIEW_XP := 1000
const REVIEW_BUDGET := 10000
## The end-to-end KPIs a review compares per stream: +1 when higher is
## better, −1 when lower is.
const MEASURES := {"lead_days_p50": -1, "on_time": 1, "first_time_right": 1, "throughput_per_week": 1, "wip_age": -1}
## ESTIMATE: one KPI's relative change counts for at most ±50 %. Small
## denominators make relative changes explode (on time from 5 % to 50 % is
## +900 %), and the reward must follow only a real gain.
const MAX_CHANGE := 0.5
## ESTIMATE: a stream counts only with at least this many finished orders in
## both quarters; below it, chance moves the KPIs more than the work rules do.
const MIN_COMPLETED := 10

var menu: KpiMenu
var unlocked := false
## Department (pool id) → the two KPI ids it follows.
var chosen: Dictionary[String, PackedStringArray] = {}
## When the next review is due (minutes).
var next_review_at := 0
## Stream id → its MEASURES and `completed` over the quarter before the last
## review (or the unlock).
var snapshot: Dictionary = {}


func _init(kpi_menu: KpiMenu) -> void:
	menu = kpi_menu


## Open the board; the first review is due a quarter from now. Idempotent.
func unlock(net: Network) -> void:
	if unlocked:
		return
	unlocked = true
	_start_quarter(net)


func review_due(now: int) -> bool:
	return unlocked and now >= next_review_at


## The quarterly review: `choices` maps every department on the menu to two
## distinct KPI ids from its menu. Returns {error, improvement, xp, budget,
## question, before, after}; error is "" or a code (locked | not_due |
## unknown_department | choose_two | not_on_menu, or the network's message
## for a menu effect it refuses), and on an error nothing changes. The caller
## grants the reward.
func review(net: Network, choices: Dictionary) -> Dictionary:
	var error := _choice_error(net.time, choices)
	if not error.is_empty():
		return {"error": error}
	var effects := []
	for pool: String in menu.menus:
		effects.append_array(menu.effects_for(pool, _ids(choices[pool])))
	error = net.set_effects(SOURCE, effects)
	if not error.is_empty():
		return {"error": error}
	for pool: String in menu.menus:
		chosen[pool] = _ids(choices[pool])
	var before := snapshot
	_start_quarter(net)
	var gain := improvement(before, snapshot)
	return {
		"error": "", "improvement": gain, "xp": roundi(gain * REVIEW_XP), "budget": roundi(gain * REVIEW_BUDGET),
		"question": menu.review_question, "before": before, "after": snapshot,
	}


func _choice_error(now: int, choices: Dictionary) -> String:
	if not unlocked:
		return "locked"
	if not review_due(now):
		return "not_due"
	for pool: Variant in choices:
		if not _on_menu(pool):
			return "unknown_department"
	for pool: String in menu.menus:
		var ids := _ids(choices.get(pool))
		if ids.size() != 2 or ids[0] == ids[1]:
			return "choose_two"
		if _known(pool, ids).size() != 2:
			return "not_on_menu"
	return ""


func _on_menu(pool: Variant) -> bool:
	return pool is String and menu.menus.has(pool)


## A list of ids as text; empty when `v` is no list.
static func _ids(v: Variant) -> PackedStringArray:
	return PackedStringArray(v) if v is Array or v is PackedStringArray else PackedStringArray()


## The ids of `ids` on `pool`'s menu.
func _known(pool: String, ids: PackedStringArray) -> PackedStringArray:
	var menu_ids: Array = menu.menus[pool].map(func(k: KpiDef) -> String: return k.id)
	return PackedStringArray(Array(ids).filter(func(id: String) -> bool: return menu_ids.has(id)))


## Measure every stream over the last quarter; the next review is due a quarter from now.
func _start_quarter(net: Network) -> void:
	snapshot = {}
	for s in net.streams:
		var k := s.kpis(net.time, REVIEW_DAYS)
		k["wip_age"] = net.open_age_days(s)
		var measured := {"completed": k["completed"]}
		for m: String in MEASURES:
			measured[m] = k[m]
		snapshot[s.id] = measured
	next_review_at = net.time + SimCalendar.days(REVIEW_DAYS)


## The mean relative change of the MEASURES (better is positive, each
## within ±MAX_CHANGE), averaged over the streams that finished at least
## MIN_COMPLETED orders in both quarters; at least 0. A KPI that was 0 before
## counts as no change, as does a quiet or thin stream.
static func improvement(before: Dictionary, after: Dictionary) -> float:
	var total := 0.0
	var streams := 0
	for id: String in before:
		var b: Dictionary = before[id]
		var a: Dictionary = after.get(id, {})
		if b.get("completed", 0) < MIN_COMPLETED or a.get("completed", 0) < MIN_COMPLETED:
			continue
		var change := 0.0
		for m: String in MEASURES:
			if b[m] != 0.0:
				change += clampf(MEASURES[m] * (a[m] - b[m]) / b[m], -MAX_CHANGE, MAX_CHANGE)
		total += change / MEASURES.size()
		streams += 1
	return maxf(0.0, total / streams) if streams > 0 else 0.0


func to_dict() -> Dictionary:
	return {"unlocked": unlocked, "chosen": chosen.duplicate(), "next_review_at": next_review_at,
		"snapshot": snapshot.duplicate(true)}


## Restore to_dict() output, untrusted: departments and KPI ids the menu
## does not have are dropped, and damaged values fall back to "nothing measured".
func load_dict(d: Dictionary) -> void:
	unlocked = d.get("unlocked") is bool and d["unlocked"]
	next_review_at = d["next_review_at"] if d.get("next_review_at") is int else 0
	chosen.clear()
	var saved_chosen := JsonFile.dict_or_empty(d.get("chosen"))
	for pool: Variant in saved_chosen:
		var known := _known(pool, _ids(saved_chosen[pool])) if _on_menu(pool) else PackedStringArray()
		if not known.is_empty():
			chosen[pool] = known
	snapshot = {}
	var saved_snapshot := JsonFile.dict_or_empty(d.get("snapshot"))
	for id: Variant in saved_snapshot:
		var saved: Variant = saved_snapshot[id]
		if saved is Dictionary:
			var measured := {"completed": int(_number(saved.get("completed")))}
			for m: String in MEASURES:
				measured[m] = _number(saved.get(m))
			snapshot[str(id)] = measured


## A finite number from a save; 0 for anything else.
static func _number(v: Variant) -> float:
	return float(v) if (v is int or v is float) and is_finite(v) else 0.0
