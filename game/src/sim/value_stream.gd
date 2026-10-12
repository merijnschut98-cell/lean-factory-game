class_name ValueStream
extends RefCounted
## An end-to-end flow of work orders (e.g. new connections) and its KPIs.

var id: String
var name: String
var arrivals: Array[Arrivals] = []
var norm_minutes: int
## Higher goes first when streams compete for the same people.
var priority: int
## Urgent work (outages) interrupts lower-priority work in progress.
var preempts := false
## At most this many started orders at once (CONWIP); new orders beyond it
## wait, not yet started. 0 = no limit.
var wip_limit := 0
## Failure demand: an open order older than `call_after_minutes` makes its
## customer call stream `calls_to` (the contact centre) `call_rate` times a
## week, asking where it stands. 0 = nobody calls.
var calls_to := ""
var call_after_minutes := 0
var call_rate := 0.0
## When this stream's late customers call (see Rng: one sequence per purpose).
var calls_rng: Rng
var steps: Array[SimStep] = []
## Orders in the stream right now (the backlog / WIP), held ones included.
var active := 0
## One record per finished order: {done_at, lead_minutes, on_time, reworks, failure_demand}.
var finished: Array[Dictionary] = []


## A source of new orders: `per_week` on average, spread evenly over the
## moments of `when` (e.g. working days 08:00–17:00, or around the clock).
class Arrivals:
	## Optional, for effects on one source ("outages.daytime").
	var id := ""
	var per_week: float
	var when: WeekSchedule
	var rng: Rng

	func _init(rate: float, schedule: WeekSchedule) -> void:
		per_week = rate
		when = schedule


func per_week() -> float:
	var total := 0.0
	for a in arrivals:
		total += a.per_week
	return total


func step(step_id: String) -> SimStep:
	var at := step_index(step_id)
	return steps[at] if at >= 0 else null


## Position of a step in the stream; -1 if there is none.
func step_index(step_id: String) -> int:
	for i in steps.size():
		if steps[i].id == step_id:
			return i
	return -1


## Drop finished records from before `t` (keeps history and saves bounded).
func forget_before(t: int) -> void:
	var first := finished.bsearch_custom({"done_at": t},
		func(a: Dictionary, b: Dictionary) -> bool: return a["done_at"] < b["done_at"])
	if first > 0:
		finished = finished.slice(first)


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
		"lead_days_p50": percentile(leads, 0.5),
		"lead_days_p85": percentile(leads, 0.85),
		# All finished orders' lead time per week: for outages, the hours
		# customers are without power (count × duration).
		"lead_hours_per_week": leads.reduce(func(sum: float, d: float) -> float: return sum + d, 0.0) * 24.0 * 7.0 / window_days,
		"on_time": on_time / float(n) if n > 0 else 0.0,
		"first_time_right": first_time_right / float(n) if n > 0 else 0.0,
	}


static func percentile(sorted_values: Array[float], q: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	return sorted_values[mini(sorted_values.size() - 1, floori(q * sorted_values.size()))]
