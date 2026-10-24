class_name KpiBoard
extends RefCounted
## The KPI board, unlocked by a countermeasure (Obeya with end-to-end KPIs).
## At each quarterly review every department on the menu follows two of its
## KPIs; they become the work rules of effect source `board:kpis`, saved with
## the network. The reward is a forecast (Merijn, 2026-10-13): the coming
## quarter is run twice from the review on copies of the network, with the
## habit (no board rules) and with the chosen KPIs. Both runs continue the
## same random sequences, so they differ only in the work rules, and only
## the measured gain of the chosen KPIs over the habit pays, never the
## labels chosen. A good choice pays again every quarter it is kept.

const SOURCE := "board:kpis"
## What a countermeasure's `unlocks` names to open this board.
const UNLOCK := "kpi_board"
## A quarter of 13 weeks: the OKR cycle.
const REVIEW_DAYS := 91
## ESTIMATE: the reward per 100 % forecast gain beyond DEAD_BAND. On the
## real network (probe 2026-10-13, 5 seeds) the best realistic choice, lead
## time + complete handover, gains 0.76 % over the habit on average; it should
## earn about a small side mission each quarter it is kept: about 140 XP and
## €1,400 after the band.
const REVIEW_XP := 30000
const REVIEW_BUDGET := 300000
## ESTIMATE: the forecast runs share their random sequences per purpose, but a
## different order or start rule changes which order draws next, so the
## pairing is not perfect: the same choice's gain varies by about ±0.5 %
## between seeds, and Obeya's lead time + oldest averages +0.06 % (noise).
## Only the gain beyond this band pays.
const DEAD_BAND := 0.003
## The end-to-end KPIs a review compares per stream (which way is better:
## Pdca.direction, the throughput as its stream says).
const MEASURES: Array[String] = ["lead_days_p50", "on_time", "first_time_right", "throughput_per_week", "wip_age"]
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


func _init(kpi_menu: KpiMenu) -> void:
	menu = kpi_menu


## Open the board; the first review is due at once. False
## when it was already open or has no menu to choose from (it stays shut).
func unlock(now: int) -> bool:
	if unlocked or menu.menus.is_empty():
		return false
	unlocked = true
	next_review_at = now
	return true


func review_due(now: int) -> bool:
	return unlocked and now >= next_review_at


## The quarterly review: `choices` maps every department on the menu to two
## distinct KPI ids from its menu. Returns {error, improvement (the forecast
## gain of the chosen KPIs over the habit), paid (the part beyond DEAD_BAND),
## xp, budget, question, habit and chosen (each stream's measures in the two
## forecast runs)}. Error is "" or a code (locked | not_due |
## unknown_department | choose_two | not_on_menu, or a message from the
## network), and on an error nothing changes: the forecast runs first, on
## copies, and only then is the choice put in force. The caller grants the reward.
func review(net: Network, choices: Dictionary) -> Dictionary:
	var error := _choice_error(net.time, choices)
	if not error.is_empty():
		return {"error": error}
	var effects := []
	for pool: String in menu.menus:
		effects.append_array(menu.effects_for(pool, _ids(choices[pool])))
	var runs := forecast(net, effects)
	if not runs["error"].is_empty():
		return {"error": runs["error"]}
	net.set_effects(SOURCE, effects)  # accepted on the copy, so accepted here
	for pool: String in menu.menus:
		chosen[pool] = _ids(choices[pool])
	next_review_at = net.time + SimCalendar.days(REVIEW_DAYS)
	var gain := improvement(runs["habit"], runs["chosen"], menu.streams(), net)
	var pay := maxf(0.0, gain - DEAD_BAND)
	return {
		"error": "", "improvement": gain, "paid": pay, "xp": roundi(pay * REVIEW_XP),
		"budget": roundi(pay * REVIEW_BUDGET), "question": menu.review_question,
		"habit": runs["habit"], "chosen": runs["chosen"],
	}


## The coming quarter run twice on copies of `net`: {error, habit: without
## the board's rules, chosen: with `effects` as the board's rules}, each as
## every stream's MEASURES and `completed` at the end. `net` is only read.
## Only the network runs on: fixes fading and problems recurring are the
## Region's, so the forecast holds today's problems and fixes for the quarter.
static func forecast(net: Network, effects: Array) -> Dictionary:
	var habit := NetworkState.copy(net)
	var chosen_run := NetworkState.copy(net)
	var error := habit.error if not habit.error.is_empty() else chosen_run.error
	if error.is_empty():
		error = chosen_run.set_effects(SOURCE, effects)
	if not error.is_empty():
		return {"error": error}
	habit.clear_effects(SOURCE)
	var out := {"error": ""}
	for run: String in ["habit", "chosen"]:
		var twin: Network = habit if run == "habit" else chosen_run
		twin.advance_days(REVIEW_DAYS)
		out[run] = _measured_now(twin)
	return out


func _choice_error(now: int, choices: Dictionary) -> String:
	if not unlocked:
		return "locked"
	if not review_due(now):
		return "not_due"
	if menu.menus.is_empty():
		return "choose_two"  # nothing to choose: a board without a menu grants nothing
	for pool: Variant in choices:
		if not _on_menu(pool):
			return "unknown_department"
	for pool: String in menu.menus:
		var error := _pair_error(pool, _ids(choices.get(pool)))
		if not error.is_empty():
			return error
	return ""


## Why `ids` is not two distinct KPIs from `pool`'s menu; "" when it is.
func _pair_error(pool: String, ids: PackedStringArray) -> String:
	if ids.size() != 2 or ids[0] == ids[1]:
		return "choose_two"
	return "" if _known(pool, ids).size() == 2 else "not_on_menu"


func _on_menu(pool: Variant) -> bool:
	return pool is String and menu.menus.has(pool)


## A list of ids as text; empty when `v` is no list.
static func _ids(v: Variant) -> PackedStringArray:
	return PackedStringArray(v) if v is Array or v is PackedStringArray else PackedStringArray()


## The ids of `ids` on `pool`'s menu, in the order given.
func _known(pool: String, ids: PackedStringArray) -> PackedStringArray:
	var known: Array = menu.defs_for(pool, ids).map(func(k: KpiDef) -> String: return k.id)
	return PackedStringArray(Array(ids).filter(func(id: String) -> bool: return known.has(id)))


## Every stream's MEASURES and `completed` over the last quarter.
static func _measured_now(net: Network) -> Dictionary:
	var out := {}
	for s in net.streams:
		var k := s.kpis(net.time, REVIEW_DAYS)
		k["wip_age"] = net.open_age_days(s)
		var measured := {"completed": k["completed"]}
		for m: String in MEASURES:
			measured[m] = k[m]
		out[s.id] = measured
	return out


## The mean relative change from `before` to `after` of the MEASURES (better
## is positive, each within ±MAX_CHANGE), averaged over `streams` that
## finished at least MIN_COMPLETED orders in both; negative when worse. A
## KPI that was 0 counts as no change, as does a quiet or thin stream. `net`
## says which streams count fewer finished a week as better (outages); without
## it every throughput is better higher.
static func improvement(before: Dictionary, after: Dictionary, streams: PackedStringArray,
		net: Network = null) -> float:
	var total := 0.0
	var counted := 0
	for id in streams:
		var b: Dictionary = before.get(id, {})
		var a: Dictionary = after.get(id, {})
		if b.get("completed", 0) < MIN_COMPLETED or a.get("completed", 0) < MIN_COMPLETED:
			continue
		var change := 0.0
		var throughput := throughput_direction(net, id)
		for m: String in MEASURES:
			if b[m] != 0.0:
				change += clampf(Pdca.direction(m, throughput) * (a[m] - b[m]) / b[m], -MAX_CHANGE, MAX_CHANGE)
		total += change / MEASURES.size()
		counted += 1
	return total / counted if counted > 0 else 0.0


## `stream_id`'s ValueStream.throughput_direction on `net`; 1 without either.
static func throughput_direction(net: Network, stream_id: String) -> int:
	var stream := net.stream(stream_id) if net != null else null
	return stream.throughput_direction if stream != null else 1


func to_dict() -> Dictionary:
	return {"unlocked": unlocked, "chosen": chosen.duplicate(), "next_review_at": next_review_at}


## Restore to_dict() output, untrusted: departments and KPI ids the menu
## does not have are dropped (and a department left without two of them).
## Keys this board no longer keeps are ignored.
func load_dict(d: Dictionary) -> void:
	unlocked = d.get("unlocked") is bool and d["unlocked"]
	# A JSON round trip makes ints floats.
	var at: Variant = d.get("next_review_at")
	next_review_at = int(at) if (at is int or at is float) and is_finite(at) else 0
	chosen.clear()
	var saved_chosen := JsonFile.dict_or_empty(d.get("chosen"))
	for pool: Variant in saved_chosen:
		if not _on_menu(pool):
			continue
		var known := _known(pool, _ids(saved_chosen[pool]))
		if _pair_error(pool, known).is_empty():
			chosen[pool] = known
