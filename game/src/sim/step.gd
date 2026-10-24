class_name SimStep
extends RefCounted
## One stage of a value stream: work by a pool, an external wait, or taking
## material from stock, plus running statistics. Definition only: pools and
## stock are referenced by id and queues live in the Network, so no object
## graph loops back to its owner (RefCounted cannot free cycles).

enum Kind { WORK, WAIT, MATERIAL }
## What the daily statistics count (see record / stats_since).
enum Stat { ENTERED, DONE, REWORKED, STARTED, QUEUE_MINUTES, STALE, WAIT_MINUTES, INTERRUPTED, TRIPS }

var id: String
var name: String
var kind: Kind
## Share of orders that need this step (the rest skip it).
var applies := 1.0
## This step's draws: whether it applies, wait durations, first time right.
var rng: Rng
# WORK
## Pools that can do this work (e.g. the monteurs by day, the on-call crew at night).
var pool_ids := PackedStringArray()
var touch_minutes := 0
var ftr := 1.0
## What a failed attempt costs (the trip to an address where nobody is home);
## 0: the full touch time (work done, then found wrong).
var fail_minutes := 0
## A share of the attempts needs a trip first (`trip_share`, 0 in a healthy process: a
## problem switches it on), each costing `trip_minutes` more of the same person: the
## monteur who drives back to the magazijn for the right joint.
var trip_share := 0.0
var trip_minutes := 0
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
var daily := DailyCounts.new(Stat.size())


func record(day: int, stat: Stat, amount: int = 1) -> void:
	daily.add(day, stat, amount)


## What one failed attempt takes.
func failed_minutes() -> int:
	return mini(fail_minutes, touch_minutes) if fail_minutes > 0 else touch_minutes


## Expected minutes of work per visit, failed attempts included.
func minutes_per_visit() -> float:
	return ftr * touch_minutes + (1.0 - ftr) * failed_minutes() + trip_share * trip_minutes


## Totals from `day` on: {entered, done, reworked, stale, interrupted, trips, queue_hours (mean
## wait before the first start, for work steps), wait_hours (mean external
## wait per order, for wait steps; the stock-out wait, for material steps)}.
func stats_since(day: int) -> Dictionary:
	var totals := daily.since(day)
	var started := totals[Stat.STARTED]
	return {
		"entered": totals[Stat.ENTERED],
		"done": totals[Stat.DONE],
		"reworked": totals[Stat.REWORKED],
		"queue_hours": totals[Stat.QUEUE_MINUTES] / 60.0 / started if started > 0 else 0.0,
		"stale": totals[Stat.STALE],
		"interrupted": totals[Stat.INTERRUPTED],
		"trips": totals[Stat.TRIPS],
		"wait_hours": totals[Stat.WAIT_MINUTES] / 60.0 / totals[Stat.ENTERED] if totals[Stat.ENTERED] > 0 else 0.0,
	}
