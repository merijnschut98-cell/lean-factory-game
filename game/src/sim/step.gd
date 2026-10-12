class_name SimStep
extends RefCounted
## One stage of a value stream: work by a pool, an external wait, or taking
## material from stock, plus running statistics. Definition only: pools and
## stock are referenced by id and queues live in the Network, so no object
## graph loops back to its owner (RefCounted cannot free cycles).

enum Kind { WORK, WAIT, MATERIAL }
## What the daily statistics count (see record / stats_since).
enum Stat { ENTERED, DONE, REWORKED, STARTED, QUEUE_MINUTES }

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

# Counters since the start of the run.
var entered := 0
var reworked := 0
## Per simulated day: counts by Stat, for before/after comparisons and the
## value stream map.
var _daily: Dictionary[int, PackedInt64Array] = {}


func record(day: int, stat: Stat, amount: int = 1) -> void:
	if not _daily.has(day):
		var counts := PackedInt64Array()
		counts.resize(Stat.size())
		_daily[day] = counts
	_daily[day][stat] += amount


## Totals from `day` on: {entered, done, reworked, queue_hours (mean wait
## before the first start, for work steps)}.
func stats_since(day: int) -> Dictionary:
	var totals := PackedInt64Array()
	totals.resize(Stat.size())
	for d in _daily:
		if d >= day:
			for i in Stat.size():
				totals[i] += _daily[d][i]
	var started := totals[Stat.STARTED]
	return {
		"entered": totals[Stat.ENTERED],
		"done": totals[Stat.DONE],
		"reworked": totals[Stat.REWORKED],
		"queue_hours": totals[Stat.QUEUE_MINUTES] / 60.0 / started if started > 0 else 0.0,
	}
