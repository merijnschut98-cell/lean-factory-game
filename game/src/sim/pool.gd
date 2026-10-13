class_name SimPool
extends RefCounted
## A team of interchangeable people (e.g. the monteurs) with a weekly
## schedule, daily attendance and the orders they are working on right now.

## Slots of `daily`.
const PRESENT := 0
const BUSY := 1
## Work rules a team can follow (see `start_rule` and `order_rule`).
const START_RULES := ["push", "pull"]
const ORDER_RULES := ["first_come", "oldest", "shortest", "due"]

var id: String
var name: String
var headcount: int
var availability: float
var schedule: WeekSchedule
## People present today (re-rolled each morning from `availability`).
var present := 0
var busy: Array[WorkOrder] = []
## Minutes left in this tick by people who just finished a job; the next job
## each of them starts uses them (short jobs are not rounded up to ticks).
var spare: Array[int] = []
## People held for one stream (an outage reserve), {stream, people}; while
## idle they take no other work. Empty: no reserve.
var reserve: Dictionary = {}
## How the team starts work (levers, see SimModifiers): "push" starts whatever
## is queued; "pull" holds a job back while the next work step downstream has
## `pull_limit_days` or more of work queued. And which queued job it takes
## first: "first_come" (longest in this queue), "oldest" (earliest born),
## "shortest" (least touch time left) or "due" (earliest due date).
var start_rule := "push"
var order_rule := "first_come"
var pull_limit_days := 3.0
## Work steps (in any stream) served by this pool. Steps do not point back.
var steps: Array[SimStep] = []
## Daily attendance draws.
var rng: Rng
## Per simulated day: people-minutes present and busy (actual load).
var daily := DailyCounts.new(2)


func is_on_shift(t: int) -> bool:
	return schedule.contains(t)


func free_people() -> int:
	return present - busy.size()


## People free to start work of `stream` now: idle reserved people only count
## for the stream they are held for.
func free_for(stream: ValueStream) -> int:
	var held := int(reserve.get("people", 0))
	if held == 0 or stream.id == reserve["stream"]:
		return free_people()
	var reserved_busy := 0
	for order in busy:
		if order.stream.id == reserve["stream"]:
			reserved_busy += 1
	return free_people() - maxi(0, mini(held, present) - reserved_busy)


func roll_presence() -> void:
	present = 0
	for i in headcount:
		if rng.chance(availability):
			present += 1


## Busy people-hours over present people-hours from `day` on (0 when nobody
## was present). Planned load is Capacity.analyse; this is what happened.
func load_since(day: int) -> float:
	var totals := daily.since(day)
	return totals[BUSY] / float(totals[PRESENT]) if totals[PRESENT] > 0 else 0.0


## Productive people-minutes per working day on average.
func minutes_per_day() -> float:
	return hours_per_week() * 60.0 / schedule.days_on()


## Productive people-hours per week on average.
func hours_per_week() -> float:
	return headcount * availability * schedule.hours()
