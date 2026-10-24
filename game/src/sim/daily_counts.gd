class_name DailyCounts
extends RefCounted
## Integer counters per simulated day (a fixed number of slots), for time
## windows: "since day N" comparisons, Check before/after, saves. Old days are
## dropped by the network (HISTORY_DAYS), so memory and saves stay bounded.

var _slots: int
var _days: Dictionary[int, PackedInt64Array] = {}
var _last_day := 0


func _init(slots: int) -> void:
	_slots = slots


func add(day: int, slot: int, amount: int = 1) -> void:
	var counts: PackedInt64Array = _days.get(day, PackedInt64Array())
	if counts.is_empty():
		counts.resize(_slots)
		_last_day = maxi(_last_day, day)
	counts[slot] += amount
	_days[day] = counts


## Totals per slot from `day` on.
func since(day: int) -> PackedInt64Array:
	var totals := PackedInt64Array()
	totals.resize(_slots)
	for d in range(maxi(0, day), _last_day + 1):
		if _days.has(d):
			for i in _slots:
				totals[i] += _days[d][i]
	return totals


func forget_day(day: int) -> void:
	_days.erase(day)


## For a save file: {day: counts}.
func export_days() -> Dictionary:
	return _days.duplicate(true)


## Restore export_days() output; malformed days are skipped. Days saved before a slot was
## added (fewer slots) load with the new ones at 0.
func import_days(saved: Dictionary) -> void:
	_days.clear()
	_last_day = 0
	for day: Variant in saved:
		if day is int and saved[day] is PackedInt64Array and saved[day].size() <= _slots:
			var counts: PackedInt64Array = saved[day].duplicate()
			counts.resize(_slots)
			_days[day] = counts
			_last_day = maxi(_last_day, day)
