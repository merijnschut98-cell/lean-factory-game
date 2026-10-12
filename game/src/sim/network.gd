class_name Network
extends RefCounted
## The work-order simulation: value streams of steps, pools of people,
## external waits and stock, advanced in fixed ticks on a weekly calendar.
##
## Pure logic: no nodes, no rendering, all randomness from `rng`, so a run
## replays exactly from its seed. The world and UI read the state and drain
## `events`; they never change it directly.

const DEFAULT_PATH := "res://data/value_streams.json"
const MAX_EVENTS := 2000

var time := 0
var rng: Rng
var pools: Dictionary[String, SimPool] = {}
var stock: Dictionary[String, SimStock] = {}
var streams: Array[ValueStream] = []
## Problem, countermeasure and event effects (see set_effects).
var _modifiers := SimModifiers.new()
## Something wrong in the configuration; the network is unusable when set.
var error := ""
## Jump over idle stretches (nights, quiet weekends). Only switched off to prove in
## tests that skipping changes nothing.
var skip_idle := true
## Recent happenings for the world/UI to animate: {t, type, ...}.
var events: Array[Dictionary] = []

## Orders in an external wait, sorted by `wait_until` (earliest first).
var _waiting: Array[WorkOrder] = []
## Queue per work step (kept here, not on the step, to avoid reference cycles).
var _queues: Dictionary[SimStep, Array] = {}
## Today's scheduled arrivals: [{at: int, stream: ValueStream}], sorted by time.
var _arrivals: Array[Dictionary] = []
## `pools` as a list, for the per-tick loops (iterating a Dictionary's values allocates).
var _pool_list: Array[SimPool] = []
var _day := 0
var _next_id := 1


static func load_file(path: String = DEFAULT_PATH, seed_value: int = 1) -> Network:
	var file := JsonFile.read_dict(path)
	if not file["error"].is_empty():
		var net := Network.new()
		net.error = file["error"]
		return net
	return Network.create(file["data"], seed_value)


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
		pool.schedule = WeekSchedule.from_blocks(p.get("schedule", []))
		if pool.schedule == null:
			net.error = "pool %s: bad schedule" % pool.id
			return net
		net.pools[pool.id] = pool
		net._pool_list.append(pool)
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
	else:
		net._start_day()  # day 0; later days start on their first tick
	return net


func _build_stream(v: Dictionary) -> ValueStream:
	var stream := ValueStream.new()
	stream.id = v["id"]
	stream.name = v["name"]
	if v.has("norm_hours"):
		stream.norm_minutes = SimCalendar.hours(float(v["norm_hours"]))
	else:
		stream.norm_minutes = SimCalendar.days(float(v["norm_days"]))
	stream.priority = int(v["priority"])
	stream.preempts = bool(v.get("preempts", false))
	for a: Dictionary in v.get("arrivals", []):
		var when := WeekSchedule.from_blocks([a])
		if when == null:
			error = "stream %s: bad arrival schedule" % stream.id
			return null
		stream.arrivals.append(ValueStream.Arrivals.new(float(a["per_week"]), when))
	var ids: Array = v["steps"].map(func(s: Dictionary) -> String: return s["id"])
	for s: Dictionary in v["steps"]:
		var step := SimStep.new()
		step.id = s["id"]
		step.name = s["name"]
		step.applies = float(s.get("applies", 1.0))
		match s["kind"]:
			"work":
				step.kind = SimStep.Kind.WORK
				step.pool_ids = PackedStringArray(s["pool"] if s["pool"] is Array else [s["pool"]])
				step.touch_minutes = SimCalendar.hours(float(s["touch_hours"]))
				step.ftr = float(s["ftr"])
				step.rework_index = ids.find(s.get("rework_to", step.id))
				step.rework_wait_minutes = SimCalendar.days(float(s.get("rework_wait_days", 0.0)))
				for pool_id in step.pool_ids:
					if not pools.has(pool_id):
						error = "step %s: unknown pool %s" % [step.id, pool_id]
						return null
					pools[pool_id].steps.append(step)
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
	return _queues[step]


## Turn on, or replace, the effects of one source (a problem, a countermeasure,
## an event). Returns an error and changes nothing if any effect is invalid.
func set_effects(source: String, effects: Array) -> String:
	return _modifiers.set_source(self, source, effects)


func clear_effects(source: String) -> void:
	_modifiers.clear_source(self, source)


## Active effects by source (a copy), for saves and the UI.
func effects() -> Dictionary[String, Array]:
	return _modifiers.sources()


func stream(stream_id: String) -> ValueStream:
	for s in streams:
		if s.id == stream_id:
			return s
	return null


# ── Time ────────────────────────────────────────────────────────────────────

func advance(minutes: int) -> void:
	var end := time + minutes
	while time < end:
		var next := _next_busy_tick() if skip_idle else time + SimCalendar.TICK
		time = mini(end, maxi(time + SimCalendar.TICK, next))
		_tick()


## While nobody is working, only arrivals, waits, deliveries, a new day
## (attendance) or a shift starting for a pool with queued work can change
## anything, so the clock can jump straight to the earliest of those (on the
## tick grid). Results are identical to stepping tick by tick.
func _next_busy_tick() -> int:
	var after := time + SimCalendar.TICK
	for pool in _pool_list:
		if not pool.busy.is_empty():
			return after
	var next := (SimCalendar.day_of(time) + 1) * SimCalendar.MINUTES_PER_DAY
	for pool in _pool_list:
		if pool.present > 0 and _most_urgent_step(pool) != null:
			next = mini(next, pool.schedule.next_start(after))
	if not _arrivals.is_empty():
		next = mini(next, _arrivals[0]["at"])
	if not _waiting.is_empty():
		next = mini(next, _waiting[0].wait_until)
	for item: SimStock in stock.values():
		if not item.deliveries.is_empty():
			next = mini(next, item.deliveries[0]["at"])
	# Round up to the tick grid so events land on the same ticks as before.
	return ceili(next / float(SimCalendar.TICK)) * SimCalendar.TICK


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
	for pool in _pool_list:
		pool.roll_presence(rng)
	var day_start := SimCalendar.day_of(time) * SimCalendar.MINUTES_PER_DAY
	for s in streams:
		for source in s.arrivals:
			var slots := source.when.slots_on_day(SimCalendar.weekday(time))
			if slots.is_empty():
				continue
			# Today's share of the weekly rate, at random moments within today's slots.
			var mean := source.per_week * slots.size() * SimCalendar.TICK / 60.0 / source.when.hours()
			for i in rng.poisson(mean):
				var at := day_start + slots[rng.int_range(0, slots.size() - 1)] + rng.int_range(0, SimCalendar.TICK - 1)
				_arrivals.append({"at": at, "stream": s})
	_arrivals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])


# ── Flow ────────────────────────────────────────────────────────────────────

func _release_arrivals() -> void:
	while not _arrivals.is_empty() and _arrivals[0]["at"] <= time:
		open_order(_arrivals.pop_front()["stream"])


## A new order enters stream `s` now (scheduled arrivals, and later events
## such as a storm).
func open_order(s: ValueStream) -> WorkOrder:
	var order := WorkOrder.new(_next_id, s, time)
	_next_id += 1
	s.active += 1
	_emit("arrived", order)
	_enter(order, 0)
	return order


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
			order.remaining = step.touch_minutes
			order.queued_at = time
			queue_of(step).append(order)
		SimStep.Kind.WAIT:
			_wait(order, int(rng.around(step.wait_minutes, step.spread)), index + 1)
		SimStep.Kind.MATERIAL:
			_take_material(order, step)


func _wait(order: WorkOrder, minutes: int, then_step: int) -> void:
	order.wait_until = time + minutes
	order.pending_step = then_step
	# Insert after equal times so orders that wait equally long leave in FIFO order.
	var at := _waiting.bsearch_custom(order, func(a: WorkOrder, b: WorkOrder) -> bool: return a.wait_until <= b.wait_until)
	_waiting.insert(at, order)


func _finish_waits() -> void:
	while not _waiting.is_empty() and _waiting[0].wait_until <= time:
		var order: WorkOrder = _waiting.pop_front()
		_enter(order, order.pending_step)


func _take_material(order: WorkOrder, step: SimStep) -> void:
	var item := stock[step.item_id]
	if item.level >= step.quantity:
		item.level -= step.quantity
		_reorder_if_needed(item)
		_enter(order, order.step_index + 1)
		return
	item.waiting.append(order)
	_emit("stockout", order, {"item": item.id})
	_reorder_if_needed(item)


func _reorder_if_needed(item: SimStock) -> void:
	if item.needs_reorder():
		# Lead time is fixed, so appending keeps deliveries in arrival order.
		item.deliveries.append({"at": time + item.lead_minutes, "quantity": item.order_quantity})
		_emit("reordered", null, {"item": item.id})


func _deliver_stock() -> void:
	for item: SimStock in stock.values():
		if item.deliveries.is_empty() or item.deliveries[0]["at"] > time:
			continue
		while not item.deliveries.is_empty() and item.deliveries[0]["at"] <= time:
			item.level += item.deliveries.pop_front()["quantity"]
		while not item.waiting.is_empty():
			var order := item.waiting[0]
			var need := order.current_step().quantity
			if item.level < need:
				break
			item.waiting.pop_front()
			item.level -= need
			_enter(order, order.step_index + 1)
		_reorder_if_needed(item)


## Put interrupted work back at the front of its queue.
func _requeue(order: WorkOrder, why: String) -> void:
	queue_of(order.current_step()).push_front(order)
	_emit(why, order)


## People on shift work another tick on their orders. At the end of a shift,
## unfinished work goes back to the front of its queue for the next shift (or
## another pool serving the step) to pick up.
func _progress_work() -> void:
	for pool in _pool_list:
		if pool.busy.is_empty():
			continue
		if not pool.is_on_shift(time):
			for i in range(pool.busy.size() - 1, -1, -1):
				_requeue(pool.busy[i], "handover")
			pool.busy.clear()
			continue
		for i in range(pool.busy.size() - 1, -1, -1):
			var order := pool.busy[i]
			order.remaining -= SimCalendar.TICK
			if order.remaining <= 0:
				pool.busy.remove_at(i)
				_complete_work(order)


func _complete_work(order: WorkOrder) -> void:
	var step := order.current_step()
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
## order of a pre-empting stream (outages) interrupts the least urgent
## lower-priority order in progress.
func _assign_work() -> void:
	for pool in _pool_list:
		if not pool.is_on_shift(time):
			continue
		while true:
			var step := _most_urgent_step(pool)
			if step == null:
				break
			var queue := queue_of(step)
			var urgent := queue[0].stream
			if pool.free_people() <= 0 and not (urgent.preempts and _preempt_for(pool, urgent.priority)):
				break
			pool.busy.append(queue.pop_front())


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
	_requeue(victim, "preempted")
	return true


func _finish_order(order: WorkOrder) -> void:
	order.stream.active -= 1
	var lead := time - order.born
	order.stream.finished.append({
		"done_at": time, "lead_minutes": lead, "on_time": time <= order.due, "reworks": order.reworks,
	})
	_emit("finished", order)


## The single way events are recorded: {t, type, order?, stream?, step?, ...extra}.
## When nobody drains them (headless runs), the oldest half is dropped at once.
func _emit(type: String, order: WorkOrder, extra: Dictionary = {}) -> void:
	var e := {"t": time, "type": type}
	if order != null:
		e.merge({"order": order.id, "stream": order.stream.id, "step": order.step_index})
	e.merge(extra)
	events.append(e)
	if events.size() > MAX_EVENTS:
		events = events.slice(MAX_EVENTS / 2)


## Hand recent events to the caller and forget them.
func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out
