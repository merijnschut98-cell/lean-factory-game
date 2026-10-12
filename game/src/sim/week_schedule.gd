class_name WeekSchedule
extends RefCounted
## Which moments of a week are "on" (a pool's working hours, a stream's
## arrival hours), as one flag per 10-minute tick: Monday 00:00 is slot 0.
## Built from blocks like {days: "mon-fri", from: "07:00", to: "15:00"};
## several blocks together can run through midnight.

const SLOTS := SimCalendar.WEEK / SimCalendar.TICK
const SLOTS_PER_DAY := SimCalendar.MINUTES_PER_DAY / SimCalendar.TICK

var _on := PackedByteArray()
var _count := 0


## Null when a block is malformed (validated by build_content.py already).
static func from_blocks(blocks: Array) -> WeekSchedule:
	var w := WeekSchedule.new()
	w._on.resize(SLOTS)
	for b: Dictionary in blocks:
		var days := SimCalendar.parse_days(b.get("days", ""))
		var start := SimCalendar.parse_hhmm(b.get("from", ""))
		var end := SimCalendar.parse_hhmm(b.get("to", ""))
		if days.is_empty() or start < 0 or end <= start or end > SimCalendar.MINUTES_PER_DAY:
			return null
		for d in days:
			for slot in range(d * SLOTS_PER_DAY + start / SimCalendar.TICK, d * SLOTS_PER_DAY + ceili(end / float(SimCalendar.TICK))):
				w._on[slot] = 1
	w._count = w._on.count(1)
	return w


func contains(t: int) -> bool:
	return _on[_slot(t)] == 1


## On-hours per week.
func hours() -> float:
	return _count * SimCalendar.TICK / 60.0


## The first moment at or after `t` that is on; `t + WEEK` if never.
func next_start(t: int) -> int:
	if contains(t):
		return t
	var slot := _slot(t)
	var base := t - posmod(t, SimCalendar.TICK)
	for i in range(1, SLOTS):
		if _on[(slot + i) % SLOTS] == 1:
			return base + i * SimCalendar.TICK
	return t + SimCalendar.WEEK


func overlap_hours(other: WeekSchedule) -> float:
	var n := 0
	for slot in SLOTS:
		n += _on[slot] & other._on[slot]
	return n * SimCalendar.TICK / 60.0


## Minutes after midnight of each on-slot on `weekday` (0 = Monday).
func slots_on_day(weekday: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in SLOTS_PER_DAY:
		if _on[weekday * SLOTS_PER_DAY + i] == 1:
			out.append(i * SimCalendar.TICK)
	return out


@warning_ignore("integer_division")
static func _slot(t: int) -> int:
	return posmod(t, SimCalendar.WEEK) / SimCalendar.TICK
