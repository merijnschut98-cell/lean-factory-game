class_name SimCalendar
## Simulation time: integer minutes since Monday 00:00 of week 1.
## Which days and hours count (working days, shifts) is up to a WeekSchedule.

const MINUTES_PER_DAY := 1440
const WEEK := 7 * MINUTES_PER_DAY
const DAY_NAMES: Array[String] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
## Simulation step. Touch times are in hours, so 10 minutes is precise enough.
const TICK := 10


@warning_ignore("integer_division")
static func day_of(t: int) -> int:
	return t / MINUTES_PER_DAY


static func weekday(t: int) -> int:
	return day_of(t) % 7


## "07:30" → 450 ("24:00" → 1440, for the end of a day). Returns -1 for anything else.
static func parse_hhmm(text: String) -> int:
	var parts := text.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	return int(parts[0]) * 60 + int(parts[1])


static func days(n: float) -> int:
	return roundi(n * MINUTES_PER_DAY)


static func hours(n: float) -> int:
	return roundi(n * 60.0)


## "mon-fri" → [0, 1, 2, 3, 4]; "sat" → [5]. Ranges do not wrap. Empty on error.
static func parse_days(text: String) -> PackedInt32Array:
	var ends := text.split("-")
	var first := DAY_NAMES.find(ends[0])
	var last := DAY_NAMES.find(ends[-1])
	if ends.size() > 2 or first < 0 or last < first:
		return PackedInt32Array()
	return PackedInt32Array(range(first, last + 1))
