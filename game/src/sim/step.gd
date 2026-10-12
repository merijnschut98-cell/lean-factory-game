class_name SimStep
extends RefCounted
## One stage of a value stream: work by a pool, an external wait, or taking
## material from stock, plus running statistics. Definition only: pools and
## stock are referenced by id and queues live in the Network, so no object
## graph loops back to its owner (RefCounted cannot free cycles).

enum Kind { WORK, WAIT, MATERIAL }

var id: String
var name: String
var kind: Kind
## Share of orders that need this step (the rest skip it).
var applies := 1.0
# WORK
var pool_id := ""
var touch_minutes := 0
var ftr := 1.0
var rework_index := 0
var rework_wait_minutes := 0
# WAIT
var wait_minutes := 0
var spread := 0.0
# MATERIAL
var item_id := ""
var quantity := 1

# Statistics since the start of the run.
var entered := 0
var completed := 0
var reworked := 0
var queue_minutes := 0
var started := 0


func average_queue_hours() -> float:
	return queue_minutes / 60.0 / started if started > 0 else 0.0
