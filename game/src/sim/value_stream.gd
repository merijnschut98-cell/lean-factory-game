class_name ValueStream
extends RefCounted
## An end-to-end flow of work orders (e.g. new connections) and its KPIs.

var id: String
var name: String
var arrivals_per_day: float
var norm_minutes: int
## Higher goes first when streams compete for the same people.
var priority: int
var steps: Array[SimStep] = []
## Orders in the stream right now (the backlog / WIP).
var active := 0
## One record per finished order: {done_at, lead_minutes, on_time, reworks}.
var finished: Array[Dictionary] = []


## KPIs over the last `window_days` calendar days.
func kpis(now: int, window_days: int = 28) -> Dictionary:
	var since := now - SimCalendar.days(window_days)
	var leads: Array[float] = []
	var on_time := 0
	var first_time_right := 0
	# `finished` is in completion order: binary-search the window start.
	var first := finished.bsearch_custom({"done_at": since},
		func(a: Dictionary, b: Dictionary) -> bool: return a["done_at"] < b["done_at"])
	for f in finished.slice(first):
		leads.append(f["lead_minutes"] / float(SimCalendar.MINUTES_PER_DAY))
		on_time += 1 if f["on_time"] else 0
		first_time_right += 1 if f["reworks"] == 0 else 0
	leads.sort()
	var n := leads.size()
	return {
		"completed": n,
		"throughput_per_week": n * 7.0 / window_days,
		"backlog": active,
		"lead_days_p50": _percentile(leads, 0.5),
		"lead_days_p85": _percentile(leads, 0.85),
		"on_time": on_time / float(n) if n > 0 else 0.0,
		"first_time_right": first_time_right / float(n) if n > 0 else 0.0,
	}


static func _percentile(sorted_values: Array[float], q: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	return sorted_values[mini(sorted_values.size() - 1, floori(q * sorted_values.size()))]
