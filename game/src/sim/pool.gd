class_name SimPool
extends RefCounted
## A team of interchangeable people (e.g. the monteurs) with working hours,
## daily attendance and the orders they are working on right now.

var id: String
var name: String
var headcount: int
var availability: float
var shift_start: int
var shift_end: int
## People present today (re-rolled each morning from `availability`).
var present := 0
var busy: Array[WorkOrder] = []
## Work steps (in any stream) served by this pool. Steps do not point back.
var steps: Array[SimStep] = []


func is_on_shift(t: int) -> bool:
	var m := SimCalendar.minute_of_day(t)
	return SimCalendar.is_workday(t) and m >= shift_start and m < shift_end


func free_people() -> int:
	return present - busy.size()


func roll_presence(rng: Rng) -> void:
	present = 0
	for i in headcount:
		if rng.chance(availability):
			present += 1


## Productive hours per working day on average.
func available_hours() -> float:
	return headcount * availability * (shift_end - shift_start) / 60.0
