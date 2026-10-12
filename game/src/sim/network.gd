class_name Network
extends RefCounted
## The work-order simulation: value streams of steps, pools of people,
## external waits and stock, advanced in fixed ticks on a working-day calendar.
##
## Pure logic: no nodes, no rendering, all randomness from `rng`, so a run
## replays exactly from its seed. The world and UI read the state and drain
## `events`; they never change it directly.

const DEFAULT_PATH := "res://data/value_streams.json"
## Customer requests arrive between 08:00 and 17:00 on working days.
const ARRIVAL_WINDOW := [480, 1020]
const MAX_EVENTS := 2000

var time := 0
var rng: Rng
var pools: Dictionary[String, SimPool] = {}
var stock: Dictionary[String, SimStock] = {}
var streams: Array[ValueStream] = []
## Something wrong in the configuration; the network is unusable when set.
var error := ""
## Recent happenings for the world/UI to animate: {t, type, ...}.
var events: Array[Dictionary] = []

var _waiting: Array[WorkOrder] = []
## Queue per work step (kept here, not on the step, to avoid reference cycles).
var _queues: Dictionary[SimStep, Array] = {}
## Today's scheduled arrivals: [{at: int, stream: ValueStream}], sorted by time.
var _arrivals: Array[Dictionary] = []
var _day := -1
var _next_id := 1


static func load_file(path: String = DEFAULT_PATH, seed_value: int = 1) -> Network:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not parsed is Dictionary:
		var net := Network.new()
		net.error = "cannot read %s as a JSON object" % path
		return net
	return Network.create(parsed, seed_value)


## Build from the value_streams.json structure (validated by build_content.py;
## rechecked here only as far as needed to fail loudly instead of misbehaving).
static func create(config: Dictionary, seed_value: int = 1) -> Network:
	var net := Network.new()
	net.rng = Rng.new(seed_value)
	for p: Dictionary in config.get("pools", []):
		var pool := SimPool.new()
		pool.id = p["id"]
		pool.name = p["name"]
		pool.headcount = int(p["headcount"])
		pool.availability = float(p["availability"])
		pool.shift_start = SimCalendar.parse_hhmm(p["shift"][0])
		pool.shift_end = SimCalendar.parse_hhmm(p["shift"][1])
		net.pools[pool.id] = pool
	for s: Dictionary in config.get("stock", []):
		var item := SimStock.new()
		item.id = s["id"]
		item.name = s["name"]
		item.level = int(s["level"])
		item.reorder_point = int(s["reorder_point"])
		item.order_quantity = int(s["order_quantity"])
		item.lead_minutes = SimCalendar.days(float(s["lead_days"]))
		net.stock[item.id] = item
	for v: Dictionary in config.get("streams", []):
		var stream := net._build_stream(v)
		if stream == null:
			return net
		net.streams.append(stream)
	if net.streams.is_empty():
		net.error = "no value streams in configuration"
	return net


func _build_stream(v: Dictionary) -> ValueStream:
	var stream := ValueStream.new()
	stream.id = v["id"]
	stream.name = v["name"]
	stream.arrivals_per_day = float(v["arrivals_per_day"])
	stream.norm_minutes = SimCalendar.days(float(v["norm_days"]))
	stream.priority = int(v["priority"])
	var ids: Array = v["steps"].map(func(s: Dictionary) -> String: return s["id"])
	for s: Dictionary in v["steps"]:
		var step := SimStep.new()
		step.id = s["id"]
		step.name = s["name"]
		step.applies = float(s.get("applies", 1.0))
		match s["kind"]:
			"work":
				step.kind = SimStep.Kind.WORK
				step.pool_id = s["pool"]
				step.touch_minutes = roundi(float(s["touch_hours"]) * 60.0)
				step.ftr = float(s["ftr"])
				step.rework_index = ids.find(s.get("rework_to", step.id))
				step.rework_wait_minutes = SimCalendar.days(float(s.get("rework_wait_days", 0.0)))
				if not pools.has(step.pool_id):
					error = "step %s: unknown pool %s" % [step.id, step.pool_id]
					return null
				pools[step.pool_id].steps.append(step)
				_queues[step] = [] as Array[WorkOrder]
			"wait":
				step.kind = SimStep.Kind.WAIT
				step.wait_minutes = SimCalendar.days(float(s["days"]))
				step.spread = float(s.get("spread", 0.0))
			"material":
				step.kind = SimStep.Kind.MATERIAL
				step.item_id = s["item"]
				step.quantity = int(s["quantity"])
				if not stock.has(step.item_id):
					error = "step %s: unknown stock item %s" % [step.id, step.item_id]
					return null
			_:
				error = "step %s: unknown kind %s" % [step.id, s["kind"]]
				return null
		stream.steps.append(step)
	return stream


## Orders waiting at a work step (empty for other kinds).
func queue_of(step: SimStep) -> Array[WorkOrder]:
	return _queues.get(step, [] as Array[WorkOrder])


func stream(stream_id: String) -> ValueStream:
	for s in streams:
		if s.id == stream_id:
			return s
	return null


# ── Time ────────────────────────────────────────────────────────────────────

func advance(minutes: int) -> void:
	var end := time + minutes
	while time < end:
		time += SimCalendar.TICK
		_tick()


func advance_days(n: float) -> void:
	advance(SimCalendar.days(n))


func _tick() -> void:
	var day := SimCalendar.day_of(time)
	if day != _day:
		_day = day
		_start_day()
	_release_arrivals()
	_finish_waits()
	_deliver_stock()
	_progress_work()
	_assign_work()


func _start_day() -> void:
	for pool: SimPool in pools.values():
		pool.roll_presence(rng)
	if not SimCalendar.is_workday(time):
		return
	var day_start := SimCalendar.day_of(time) * SimCalendar.MINUTES_PER_DAY
	for s in streams:
		for i in _poisson(s.arrivals_per_day):
			var at := day_start + ARRIVAL_WINDOW[0] + int(rng.next() * (ARRIVAL_WINDOW[1] - ARRIVAL_WINDOW[0]))
			_arrivals.append({"at": at, "stream": s})
	_arrivals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])


func _poisson(mean: float) -> int:
	var limit := exp(-mean)
	var k := 0
	var p := rng.next()
	while p > limit:
		k += 1
		p *= rng.next()
	return k


# ── Flow ────────────────────────────────────────────────────────────────────

func _release_arrivals() -> void:
	while not _arrivals.is_empty() and _arrivals[0]["at"] <= time:
		var s: ValueStream = _arrivals.pop_front()["stream"]
		var order := WorkOrder.new(_next_id, s, time)
		_next_id += 1
		s.active += 1
		_emit("arrived", order)
		_enter(order, 0)


## Put an order into step `index`, skipping steps it does not need.
func _enter(order: WorkOrder, index: int) -> void:
	var steps := order.stream.steps
	while index < steps.size() and steps[index].applies < 1.0 and not rng.chance(steps[index].applies):
		index += 1
	if index >= steps.size():
		_finish_order(order)
		return
	order.step_index = index
	var step := steps[index]
	step.entered += 1
	match step.kind:
		SimStep.Kind.WORK:
			order.state = WorkOrder.State.QUEUED
			order.remaining = step.touch_minutes
			order.queued_at = time
			queue_of(step).append(order)
		SimStep.Kind.WAIT:
			_wait(order, int(rng.around(step.wait_minutes, step.spread)), index + 1)
		SimStep.Kind.MATERIAL:
			_take_material(order, step)


func _wait(order: WorkOrder, minutes: int, then_step: int) -> void:
	order.state = WorkOrder.State.WAITING
	order.wait_until = time + minutes
	order.pending_step = then_step
	_waiting.append(order)


func _finish_waits() -> void:
	if _waiting.is_empty():
		return
	var still: Array[WorkOrder] = []
	var done: Array[WorkOrder] = []
	for order in _waiting:
		(done if order.wait_until <= time else still).append(order)
	_waiting = still
	for order in done:
		_enter(order, order.pending_step)


func _take_material(order: WorkOrder, step: SimStep) -> void:
	var item := stock[step.item_id]
	if item.level >= step.quantity:
		item.level -= step.quantity
		_reorder_if_needed(item)
		_enter(order, order.step_index + 1)
		return
	order.state = WorkOrder.State.STOCK
	item.waiting.append(order)
	_emit("stockout", order, {"item": item.id})
	_reorder_if_needed(item)


func _reorder_if_needed(item: SimStock) -> void:
	if item.needs_reorder():
		item.deliveries.append({"at": time + item.lead_minutes, "quantity": item.order_quantity})
		events.append({"t": time, "type": "reordered", "item": item.id})


func _deliver_stock() -> void:
	for item: SimStock in stock.values():
		var arrived := item.deliveries.filter(func(d: Dictionary) -> bool: return d["at"] <= time)
		if arrived.is_empty():
			continue
		item.deliveries = item.deliveries.filter(func(d: Dictionary) -> bool: return d["at"] > time)
		for d: Dictionary in arrived:
			item.level += d["quantity"]
		while not item.waiting.is_empty():
			var order := item.waiting[0]
			var need := order.current_step().quantity
			if item.level < need:
				break
			item.waiting.pop_front()
			item.level -= need
			_enter(order, order.step_index + 1)
		_reorder_if_needed(item)


func _progress_work() -> void:
	for pool: SimPool in pools.values():
		if pool.busy.is_empty() or not pool.is_on_shift(time):
			continue
		for order: WorkOrder in pool.busy.duplicate():
			order.remaining -= SimCalendar.TICK
			if order.remaining <= 0:
				pool.busy.erase(order)
				_complete_work(order)


func _complete_work(order: WorkOrder) -> void:
	var step := order.current_step()
	step.completed += 1
	if step.ftr < 1.0 and not rng.chance(step.ftr):
		order.reworks += 1
		step.reworked += 1
		_emit("rework", order)
		if step.rework_wait_minutes > 0:
			_wait(order, step.rework_wait_minutes, step.rework_index)
		else:
			_enter(order, step.rework_index)
		return
	_enter(order, order.step_index + 1)


## Give free people the most urgent waiting work: highest stream priority
## first, then the order that has queued longest. When nobody is free, an
## urgent order pre-empts the least urgent order in progress.
func _assign_work() -> void:
	for pool: SimPool in pools.values():
		if not pool.is_on_shift(time):
			continue
		while true:
			var step := _most_urgent_step(pool)
			if step == null:
				break
			var queue := queue_of(step)
			if pool.free_people() <= 0 and not _preempt_for(pool, queue[0].stream.priority):
				break
			var order: WorkOrder = queue.pop_front()
			order.state = WorkOrder.State.WORKING
			step.started += 1
			step.queue_minutes += time - order.queued_at
			pool.busy.append(order)


func _most_urgent_step(pool: SimPool) -> SimStep:
	var best: SimStep = null
	for step in pool.steps:
		var queue := queue_of(step)
		if queue.is_empty():
			continue
		if best == null or _more_urgent(queue[0], queue_of(best)[0]):
			best = step
	return best


func _more_urgent(a: WorkOrder, b: WorkOrder) -> bool:
	if a.stream.priority != b.stream.priority:
		return a.stream.priority > b.stream.priority
	return a.queued_at < b.queued_at


## Pause the least urgent busy order with a lower priority. True if one was paused.
func _preempt_for(pool: SimPool, priority: int) -> bool:
	var victim: WorkOrder = null
	for order in pool.busy:
		if order.stream.priority < priority and (victim == null or order.stream.priority < victim.stream.priority):
			victim = order
	if victim == null:
		return false
	pool.busy.erase(victim)
	victim.state = WorkOrder.State.QUEUED
	victim.queued_at = time
	queue_of(victim.current_step()).push_front(victim)
	_emit("preempted", victim)
	return true


func _finish_order(order: WorkOrder) -> void:
	order.state = WorkOrder.State.DONE
	order.stream.active -= 1
	var lead := time - order.born
	order.stream.finished.append({
		"done_at": time, "lead_minutes": lead, "on_time": time <= order.due, "reworks": order.reworks,
	})
	_emit("finished", order)


func _emit(type: String, order: WorkOrder, extra: Dictionary = {}) -> void:
	var e := {"t": time, "type": type, "order": order.id, "stream": order.stream.id, "step": order.step_index}
	e.merge(extra)
	events.append(e)
	if events.size() > MAX_EVENTS:
		events = events.slice(events.size() - MAX_EVENTS)


## Hand recent events to the caller and forget them.
func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out
