class_name SimCalendar
## Simulation time: integer minutes since Monday 00:00 of week 1.
## Working days are Monday–Friday.

const MINUTES_PER_DAY := 1440
## Simulation step. Touch times are in hours, so 10 minutes is precise enough.
const TICK := 10


@warning_ignore("integer_division")
static func day_of(t: int) -> int:
	return t / MINUTES_PER_DAY


static func weekday(t: int) -> int:
	return day_of(t) % 7


static func is_workday(t: int) -> bool:
	return weekday(t) < 5


static func minute_of_day(t: int) -> int:
	return t % MINUTES_PER_DAY


## "07:30" → 450. Returns -1 for anything else.
static func parse_hhmm(text: String) -> int:
	var parts := text.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	return int(parts[0]) * 60 + int(parts[1])


static func days(n: float) -> int:
	return roundi(n * MINUTES_PER_DAY)
