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
## Work steps (in any stream) served by this pool. Steps do not point back.
var steps: Array[SimStep] = []


func is_on_shift(t: int) -> bool:
	return schedule.contains(t)


func free_people() -> int:
	return present - busy.size()


func roll_presence(rng: Rng) -> void:
	present = 0
	for i in headcount:
		if rng.chance(availability):
			present += 1


## Productive people-hours per week on average.
func hours_per_week() -> float:
	return headcount * availability * schedule.hours()
