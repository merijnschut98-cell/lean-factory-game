class_name SimStep
extends RefCounted
## One stage of a value stream: work by a pool, an external wait, or taking
## material from stock, plus running statistics. Definition only: pools and
## stock are referenced by id and queues live in the Network, so no object
## graph loops back to its owner (RefCounted cannot free cycles).

enum Kind { WORK, WAIT, MATERIAL }
## What the daily statistics count (see record / stats_since).
enum Stat { ENTERED, DONE, REWORKED, STARTED, QUEUE_MINUTES, STALE }

var id: String
var name: String
var kind: Kind
## Share of orders that need this step (the rest skip it).
var applies := 1.0
# WORK
## Pools that can do this work (e.g. the monteurs by day, the on-call crew at night).
var pool_ids := PackedStringArray()
var touch_minutes := 0
var ftr := 1.0
var rework_index := 0
var rework_wait_minutes := 0
## Where an order goes when urgent work interrupts it (e.g. back to planning
## for a new appointment), and after how long; -1 = it simply resumes.
var interrupt_index := -1
var interrupt_wait_minutes := 0
## A dossier that waited longer than this in the queue is out of date when
## work starts: it goes back to `stale_index` (after `stale_wait_minutes`,
## e.g. for the customer to confirm their details again). 0 = never.
var stale_after_minutes := 0
var stale_index := -1
var stale_wait_minutes := 0
# WAIT
var wait_minutes := 0
var spread := 0.0
## Requests go out in batches: the wait starts at the next multiple of this (0 = at once).
var batch_minutes := 0
## Id of an earlier step at which this wait already starts (in parallel); "" = in sequence.
var starts_with := ""
# MATERIAL
var item_id := ""
var quantity := 1

## Per simulated day: counts by Stat, for before/after comparisons and the
## value stream map.
var _daily: Dictionary[int, PackedInt64Array] = {}
var _last_day := 0


func record(day: int, stat: Stat, amount: int = 1) -> void:
	var counts: PackedInt64Array = _daily.get(day, PackedInt64Array())
	if counts.is_empty():
		counts.resize(Stat.size())
		_last_day = maxi(_last_day, day)
	counts[stat] += amount
	_daily[day] = counts


## The daily statistics for a save file: {day: counts by Stat}.
func export_daily() -> Dictionary:
	return _daily.duplicate(true)


## Restore export_daily() output; malformed days are skipped.
func import_daily(saved: Dictionary) -> void:
	_daily.clear()
	_last_day = 0
	for day: Variant in saved:
		if day is int and saved[day] is PackedInt64Array and saved[day].size() == Stat.size():
			_daily[day] = saved[day]
			_last_day = maxi(_last_day, day)


func forget_day(day: int) -> void:
	_daily.erase(day)


## Totals from `day` on: {entered, done, reworked, queue_hours (mean wait
## before the first start, for work steps)}.
func stats_since(day: int) -> Dictionary:
	var totals := PackedInt64Array()
	totals.resize(Stat.size())
	for d in range(maxi(0, day), _last_day + 1):
		if _daily.has(d):
			for i in Stat.size():
				totals[i] += _daily[d][i]
	var started := totals[Stat.STARTED]
	return {
		"entered": totals[Stat.ENTERED],
		"done": totals[Stat.DONE],
		"reworked": totals[Stat.REWORKED],
		"queue_hours": totals[Stat.QUEUE_MINUTES] / 60.0 / started if started > 0 else 0.0,
		"stale": totals[Stat.STALE],
	}
