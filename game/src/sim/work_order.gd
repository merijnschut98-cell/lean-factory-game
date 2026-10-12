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
## When the order joined the current queue (for queue-time statistics), and
## whether work on it has started there (a resume after an interruption is
## no new start).
var queued_at := 0
var started := false
## For WAITING orders: when the wait ends and which step comes next.
var wait_until := 0
var pending_step := 0
var reworks := 0
## This attempt at the current work step will fail (drawn when work starts).
var failing := false
## Caused by a failure elsewhere (a customer asking where their order
## stands), not new value demand.
var failure_demand := false
## Waits started in parallel: wait step index → when it is over.
var early: Dictionary[int, int] = {}


func _init(order_id: int, of_stream: ValueStream, now: int) -> void:
	id = order_id
	stream = of_stream
	born = now
	due = now + of_stream.norm_minutes


func current_step() -> SimStep:
	return stream.steps[step_index]


## For save files: steps by id, never by index.
func to_dict() -> Dictionary:
	var steps := stream.steps
	var early_ids := {}
	for index in early:
		early_ids[steps[index].id] = early[index]
	return {
		"id": id, "stream": stream.id, "step": steps[step_index].id, "born": born, "due": due,
		"remaining": remaining, "queued_at": queued_at, "started": started, "wait_until": wait_until,
		"pending": steps[pending_step].id if pending_step < steps.size() else "", "reworks": reworks,
		"early": early_ids, "failure_demand": failure_demand, "failing": failing,
	}


## Rebuild a saved order in stream `s`; null if its steps no longer exist.
static func from_dict(d: Dictionary, s: ValueStream) -> WorkOrder:
	var at := s.step_index(str(d.get("step", "")))
	var pending := str(d.get("pending", ""))
	var pending_at := s.steps.size() if pending.is_empty() else s.step_index(pending)
	if at < 0 or pending_at < 0:
		return null
	var o := WorkOrder.new(int(d.get("id", 0)), s, int(d.get("born", 0)))
	o.due = int(d.get("due", o.due))
	o.step_index = at
	o.pending_step = pending_at
	o.remaining = int(d.get("remaining", 0))
	o.queued_at = int(d.get("queued_at", 0))
	o.started = bool(d.get("started", false))
	o.wait_until = int(d.get("wait_until", 0))
	o.reworks = int(d.get("reworks", 0))
	o.failure_demand = bool(d.get("failure_demand", false))
	o.failing = bool(d.get("failing", false))
	var early: Variant = d.get("early", {})
	if early is Dictionary:
		for step_id: Variant in early:
			var index := s.step_index(str(step_id))
			if index >= 0:
				o.early[index] = int(early[step_id])
	return o
