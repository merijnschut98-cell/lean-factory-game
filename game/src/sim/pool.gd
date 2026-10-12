class_name SimPool
extends RefCounted
## A team of interchangeable people (e.g. the monteurs) with a weekly
## schedule, daily attendance and the orders they are working on right now.

var id: String
var name: String
var headcount: int
var availability: float
var schedule: WeekSchedule
## People present today (re-rolled each morning from `availability`).
var present := 0
var busy: Array[WorkOrder] = []
## People held for one stream (an outage reserve): while idle they take no other work.
var reserve := 0
var reserve_for := ""
## Work steps (in any stream) served by this pool. Steps do not point back.
var steps: Array[SimStep] = []


func is_on_shift(t: int) -> bool:
	return schedule.contains(t)


func free_people() -> int:
	return present - busy.size()


## People free to start work of `stream` now: idle reserved people only count
## for the stream they are held for.
func free_for(stream: ValueStream) -> int:
	if reserve == 0 or stream.id == reserve_for:
		return free_people()
	var reserved_busy := 0
	for order in busy:
		if order.stream.id == reserve_for:
			reserved_busy += 1
	return free_people() - maxi(0, mini(reserve, present) - reserved_busy)


func roll_presence(rng: Rng) -> void:
	present = 0
	for i in headcount:
		if rng.chance(availability):
			present += 1


## Productive people-hours per week on average.
func hours_per_week() -> float:
	return headcount * availability * schedule.hours()
