class_name WorkOrder
extends RefCounted
## One unit of work (a connection request, later an outage or a meter job)
## travelling through the steps of its value stream.

var id: int
var stream: ValueStream
var born: int
var due: int
var step_index := 0
## Where an order is follows from the container holding it (a step queue,
## a pool's busy list, the network's waiting list or a stock's waiting list).
## Minutes of touch time left at the current work step.
var remaining := 0
## When the order joined the current queue (for queue-time statistics).
var queued_at := 0
## For WAITING orders: when the wait ends and which step comes next.
var wait_until := 0
var pending_step := 0
var reworks := 0
## Waits started in parallel: wait step index → when it is over.
var early: Dictionary[int, int] = {}


func _init(order_id: int, of_stream: ValueStream, now: int) -> void:
	id = order_id
	stream = of_stream
	born = now
	due = now + of_stream.norm_minutes


func current_step() -> SimStep:
	return stream.steps[step_index]
