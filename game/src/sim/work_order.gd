class_name WorkOrder
extends RefCounted
## One unit of work (a connection request, later an outage or a meter job)
## travelling through the steps of its value stream.

enum State { QUEUED, WORKING, WAITING, STOCK, DONE }

var id: int
var stream: ValueStream
var born: int
var due: int
var state := State.QUEUED
var step_index := 0
## Minutes of touch time left at the current work step.
var remaining := 0
## When the order joined the current queue (for queue-time statistics).
var queued_at := 0
## For WAITING orders: when the wait ends and which step comes next.
var wait_until := 0
var pending_step := 0
var reworks := 0


func _init(order_id: int, of_stream: ValueStream, now: int) -> void:
	id = order_id
	stream = of_stream
	born = now
	due = now + of_stream.norm_minutes


func current_step() -> SimStep:
	return stream.steps[step_index]
