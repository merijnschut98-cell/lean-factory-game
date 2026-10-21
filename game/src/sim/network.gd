class_name Network
extends RefCounted
## The work-order simulation: value streams of steps, pools of people,
## external waits and stock, advanced in fixed ticks on a weekly calendar.
##
## Pure logic: no nodes, no rendering, all randomness from seeded Rngs (one
## per purpose, see _new_rng), so a run replays exactly from its seed. The
## world and UI read the state and drain `events`; they never change it directly.

const DEFAULT_PATH := "res://data/value_streams.json"
const MAX_EVENTS := 2000
## Days of finished records and step statistics kept (KPI windows, Check,
## the value stream map); older history is dropped so memory and saves stay bounded.
const HISTORY_DAYS := 120

var time := 0
var run_seed := 1
## The value_streams.json structure this network was built from (copies are built from it too).
var config: Dictionary = {}
## One random sequence per purpose ("step:connections.design", …), see _new_rng.
var _rngs: Dictionary[String, Rng] = {}
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
## Orders held back by a stream's WIP limit, not yet started: stream id → orders.
var _held: Dictionary[String, Array] = {}
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
	net.run_seed = seed_value
	net.config = config
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
		pool.reserve = p.get("reserve", {})
		pool.rng = net._new_rng("presence:" + pool.id)
		net.pools[pool.id] = pool
		net._pool_list.append(pool)
	for s: Dictionary in config.get("stock", []):
		var item := SimStock.new()
		item.id = s["id"]
		item.name = s["name"]
		item.level = int(s["level"])
		item.reorder_point = int(s["reorder_point"])
		item.order_quantity = int(s["order_quantity"])
		item.lead_minutes = _days(s, "lead_days")
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
		stream.norm_minutes = _days(v, "norm_days")
	stream.priority = int(v["priority"])
	stream.preempts = bool(v.get("preempts", false))
	stream.wip_limit = int(v.get("wip_limit", 0))
	var calls: Dictionary = v.get("status_calls", {})
	stream.calls_to = calls.get("to", "")
	stream.call_after_minutes = _days(calls, "after_days")
	stream.call_rate = float(calls.get("per_week", 0.0))
	stream.calls_rng = _new_rng("calls:" + stream.id)
	_held[stream.id] = [] as Array[WorkOrder]
	for a: Dictionary in v.get("arrivals", []):
		var when := WeekSchedule.from_blocks([a])
		if when == null:
			error = "stream %s: bad arrival schedule" % stream.id
			return null
		var source := ValueStream.Arrivals.new(float(a["per_week"]), when)
		source.id = str(a.get("id", ""))
		source.rng = _new_rng("arrivals:%s.%s" % [stream.id, source.id if source.id else str(stream.arrivals.size())])
		stream.arrivals.append(source)
	var ids: Array = v["steps"].map(func(s: Dictionary) -> String: return s["id"])
	for s: Dictionary in v["steps"]:
		var step := SimStep.new()
		step.id = s["id"]
		step.name = s["name"]
		step.applies = float(s.get("applies", 1.0))
		step.rng = _new_rng("step:%s.%s" % [stream.id, step.id])
		match s["kind"]:
			"work":
				step.kind = SimStep.Kind.WORK
				step.pool_ids = PackedStringArray(s["pool"] if s["pool"] is Array else [s["pool"]])
				step.touch_minutes = SimCalendar.hours(float(s["touch_hours"]))
				step.ftr = float(s["ftr"])
				step.fail_minutes = SimCalendar.hours(float(s.get("fail_hours", 0.0)))
				# Where an order goes back to, and after how long: on rework, after an
				# interruption, or when its dossier went stale.
				step.rework_index = ids.find(s.get("rework_to", step.id))
				step.rework_wait_minutes = _days(s, "rework_wait_days")
				step.interrupt_index = ids.find(s.get("interrupt_to", ""))
				step.interrupt_wait_minutes = _days(s, "interrupt_wait_days")
				step.stale_index = ids.find(s.get("stale_to", ""))
				step.stale_wait_minutes = _days(s, "stale_wait_days")
				step.stale_after_minutes = _days(s, "stale_after_days")
				for pool_id in step.pool_ids:
					if not pools.has(pool_id):
						error = "step %s: unknown pool %s" % [step.id, pool_id]
						return null
					pools[pool_id].steps.append(step)
				_queues[step] = [] as Array[WorkOrder]
			"wait":
				step.kind = SimStep.Kind.WAIT
				step.wait_minutes = _days(s, "days")
				step.spread = float(s.get("spread", 0.0))
				step.batch_minutes = _days(s, "batch_days")
				step.starts_with = s.get("starts_with", "")
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


## A random sequence of its own for `purpose`, registered for saves (built
## once per arrival source, team, step and stream while creating the network).
func _new_rng(purpose: String) -> Rng:
	_rngs[purpose] = Rng.for_purpose(run_seed, purpose)
	return _rngs[purpose]


## Continue a saved sequence. False when the content no longer has it.
func restore_random_state(purpose: String, state: int) -> bool:
	if not _rngs.has(purpose):
		return false
	_rngs[purpose].set_state(state)
	return true


## Every sequence's state, for saves: purpose → state.
func random_states() -> Dictionary:
	var out := {}
	for purpose: String in _rngs:
		out[purpose] = _rngs[purpose].get_state()
	return out


static func _days(d: Dictionary, key: String) -> int:
	return SimCalendar.days(float(d.get(key, 0.0)))


## The queue of a work step (only work steps have one; waiting_at counts any step).
func queue_of(step: SimStep) -> Array[WorkOrder]:
	return _queues[step]


## How many orders wait at `step` now: in its queue at a work step, out on
## the wait at a wait step (a permit), for stock at a material step.
func waiting_at(step: SimStep) -> int:
	if step.kind == SimStep.Kind.WORK:
		return queue_of(step).size()
	var orders := _waiting if step.kind == SimStep.Kind.WAIT else stock[step.item_id].waiting
	return orders.filter(func(o: WorkOrder) -> bool: return o.current_step() == step).size()


## How many orders are out on a wait before they come back to `step` (sent back for
## rework or gone stale: an application waiting for the customer's missing details).
func returning_to(step: SimStep) -> int:
	return _waiting.filter(func(o: WorkOrder) -> bool:
		return o.pending_step <= o.step_index and o.stream.steps[o.pending_step] == step).size()


## Turn on, or replace, the effects of one source (a problem, a countermeasure,
## an event). Returns an error and changes nothing if any effect is invalid.
func set_effects(source: String, effects: Array) -> String:
	var error := _modifiers.set_source(self, source, effects)
	_release_all_held()
	return error


func clear_effects(source: String) -> void:
	_modifiers.clear_source(self, source)
	_release_all_held()


## Move these effect sources after all others: a later lever wins.
func move_effects_last(sources: Array) -> void:
	_modifiers.move_last(self, sources)
	_release_all_held()


## Held orders start on an arrival, a finish, or here: a changed WIP limit.
func _release_all_held() -> void:
	for s in streams:
		_release_held(s)


## Active effects by source (a copy), for saves and the UI.
func effects() -> Dictionary[String, Array]:
	return _modifiers.sources()


## The step at a place "stream.step" (null if there is none).
func step_at(place: String) -> SimStep:
	var s := stream(place.get_slice(".", 0))
	return s.step(place.get_slice(".", 1)) if s != null and place.get_slice_count(".") == 2 else null


## Orders of a stream waiting for its WIP limit, not yet started.
func held(stream_id: String) -> int:
	return _held[stream_id].size()


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
	_forget_old_history()
	for pool in _pool_list:
		pool.roll_presence()
		var slots := pool.schedule.slots_on_day(SimCalendar.weekday(time)).size()
		pool.daily.add(_day, SimPool.PRESENT, pool.present * slots * SimCalendar.TICK)
	for s in streams:
		for source in s.arrivals:
			_schedule_arrivals(s, source.when, source.per_week, source.rng)
		_schedule_status_calls(s)
	_arrivals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])


func _forget_old_history() -> void:
	var day := SimCalendar.day_of(time) - HISTORY_DAYS - 1
	if day < 0:
		return
	for s in streams:
		s.forget_before(SimCalendar.days(day + 1))
		for step in s.steps:
			step.daily.forget_day(day)
	for pool in _pool_list:
		pool.daily.forget_day(day)


## Today's share of a weekly rate `per_week`, at random moments within
## today's slots of `when`.
func _schedule_arrivals(s: ValueStream, when: WeekSchedule, per_week: float, rng: Rng, failure_demand: bool = false) -> void:
	var slots := when.slots_on_day(SimCalendar.weekday(time))
	if slots.is_empty() or per_week <= 0.0:
		return
	var day_start := SimCalendar.day_of(time) * SimCalendar.MINUTES_PER_DAY
	for i in rng.poisson(per_week * slots.size() * SimCalendar.TICK / 60.0 / when.hours()):
		var at := day_start + slots[rng.int_range(0, slots.size() - 1)] + rng.int_range(0, SimCalendar.TICK - 1)
		_arrivals.append({"at": at, "stream": s, "failure_demand": failure_demand})


## Failure demand: customers of late orders call the contact stream, at its
## opening hours (its first arrival schedule). "Late" is the customer's
## patience (`call_after_minutes`), not the legal norm.
func _schedule_status_calls(s: ValueStream) -> void:
	var contact := stream(s.calls_to) if s.call_rate > 0.0 else null
	if contact == null or contact.arrivals.is_empty():
		return
	var since := time - s.call_after_minutes
	var late := 0
	for o in open_orders(s):
		if o.born < since:
			late += 1
	_schedule_arrivals(contact, contact.arrivals[0].when, late * s.call_rate, s.calls_rng, true)


## Open orders of `s`, wherever they are: held, queued, in work, waiting.
func open_orders(s: ValueStream) -> Array[WorkOrder]:
	var lists: Array = [_held[s.id], _waiting]
	for step in s.steps:
		if step.kind == SimStep.Kind.WORK:
			lists.append(queue_of(step))
	for pool in _pool_list:
		lists.append(pool.busy)
	for item: SimStock in stock.values():
		lists.append(item.waiting)
	var out: Array[WorkOrder] = []
	for orders: Array in lists:
		for o: WorkOrder in orders:
			if o.stream == s:
				out.append(o)
	return out


## The KPI wip_age: the age of the open work at this quantile.
const WIP_AGE_QUANTILE := 0.85


## The age in days of the open work at quantile `q` (0 with none). Lead time
## counts finished orders only, so a long wait hides the oldest work; this
## shows it (the KPI wip_age).
func open_age_days(s: ValueStream, q: float = WIP_AGE_QUANTILE) -> float:
	var ages: Array[float] = []
	for o in open_orders(s):
		ages.append((time - o.born) / float(SimCalendar.MINUTES_PER_DAY))
	ages.sort()
	return ValueStream.percentile(ages, q)


# ── Flow ────────────────────────────────────────────────────────────────────

func _release_arrivals() -> void:
	while not _arrivals.is_empty() and _arrivals[0]["at"] <= time:
		var a: Dictionary = _arrivals.pop_front()
		open_order(a["stream"], a["failure_demand"])


## A new order enters stream `s` now (scheduled arrivals, status calls, and
## later events such as a storm). `failure_demand`: caused by a failure
## elsewhere (a customer asking where their order stands), not new value.
func open_order(s: ValueStream, failure_demand: bool = false) -> WorkOrder:
	var order := WorkOrder.new(_next_id, s, time)
	order.failure_demand = failure_demand
	_next_id += 1
	s.active += 1
	_emit("arrived", order, {"failure_demand": failure_demand})
	_held[s.id].append(order)
	_release_held(s)
	return order


## Start held orders while the stream's WIP limit allows.
func _release_held(s: ValueStream) -> void:
	while _can_release(s):
		_enter(_held[s.id].pop_front(), 0)


func _can_release(s: ValueStream) -> bool:
	var held_orders: Array = _held[s.id]
	return not held_orders.is_empty() and (s.wip_limit <= 0 or s.active - held_orders.size() < s.wip_limit)


## Put an order into step `index`, skipping steps it does not need.
func _enter(order: WorkOrder, index: int) -> void:
	var steps := order.stream.steps
	while index < steps.size() and not _needed(steps[index]):
		index += 1
	if index >= steps.size():
		_finish_order(order)
		return
	order.step_index = index
	var step := steps[index]
	_record(step, SimStep.Stat.ENTERED)
	_start_parallel_waits(order, index)
	match step.kind:
		SimStep.Kind.WORK:
			order.remaining = step.touch_minutes
			order.queued_at = time
			order.started = false
			queue_of(step).append(order)
		SimStep.Kind.WAIT:
			# A wait that started in parallel only costs what is left of it.
			var ready: int = order.early[index] if order.early.has(index) else _wait_ready(step)
			_record(step, SimStep.Stat.WAIT_MINUTES, maxi(0, ready - time))
			if ready > time:
				_wait(order, ready - time, index + 1)
			else:
				_enter(order, index + 1)
		SimStep.Kind.MATERIAL:
			_take_material(order, step)


## Whether this order needs the step (`applies` is the share that does).
func _needed(step: SimStep) -> bool:
	return step.applies >= 1.0 or step.rng.chance(step.applies)


## Start the waits that run in parallel with step `index` (once per order:
## rework that passes the step again does not request a permit twice).
func _start_parallel_waits(order: WorkOrder, index: int) -> void:
	var steps := order.stream.steps
	for j in range(index + 1, steps.size()):
		var w := steps[j]
		if w.starts_with == steps[index].id and not order.early.has(j):
			order.early[j] = _wait_ready(w)


## When a wait starting now is over: from the next batch moment, plus the
## (varying) duration.
func _wait_ready(step: SimStep) -> int:
	var start := time
	if step.batch_minutes > 0:
		start = ceili(time / float(step.batch_minutes)) * step.batch_minutes
	return start + int(step.rng.around(step.wait_minutes, step.spread))


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
	order.queued_at = time  # the stock-out wait is recorded at delivery
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
			_record(order.current_step(), SimStep.Stat.WAIT_MINUTES, time - order.queued_at)
			_enter(order, order.step_index + 1)
		_reorder_if_needed(item)


## People on shift work another tick on their orders. At the end of a shift,
## unfinished work goes back to the front of its queue for the next shift (or
## another pool serving the step) to pick up.
func _progress_work() -> void:
	for pool in _pool_list:
		if pool.busy.is_empty():
			continue
		if not pool.is_on_shift(time):
			for i in range(pool.busy.size() - 1, -1, -1):
				_emit("handover", pool.busy[i])
				queue_of(pool.busy[i].current_step()).push_front(pool.busy[i])
			pool.busy.clear()
			continue
		var worked := 0
		for i in range(pool.busy.size() - 1, -1, -1):
			worked += _work_on(pool, pool.busy[i], SimCalendar.TICK)
		pool.daily.add(_day, SimPool.BUSY, worked)


## Someone in `pool` works `minutes` on `order`; a job that is done leaves
## the rest of the minutes to the next job that person starts this tick.
## Returns the minutes worked.
func _work_on(pool: SimPool, order: WorkOrder, minutes: int) -> int:
	var used := mini(minutes, order.remaining)
	order.remaining -= used
	if order.remaining <= 0:
		pool.busy.erase(order)
		if minutes > used:
			pool.spare.append(minutes - used)
		_complete_work(order)
	return used


## Whether this attempt fails is known when work starts, so a failed attempt
## can cost less than the job (`fail_minutes`).
func _draw_outcome(order: WorkOrder, step: SimStep) -> void:
	order.failing = step.ftr < 1.0 and not step.rng.chance(step.ftr)
	if order.failing:
		order.remaining = step.failed_minutes()


func _complete_work(order: WorkOrder) -> void:
	var step := order.current_step()
	if order.failing:
		order.reworks += 1
		_record(step, SimStep.Stat.REWORKED)
		_emit("rework", order)
		_send_back(order, step.rework_index, step.rework_wait_minutes)
		return
	_record(step, SimStep.Stat.DONE)
	_enter(order, order.step_index + 1)


## A dossier that waited too long is out of date when work would start: it
## goes back (e.g. the customer confirms their details again).
func _went_stale(order: WorkOrder, step: SimStep) -> bool:
	if step.stale_after_minutes <= 0 or time - order.queued_at <= step.stale_after_minutes:
		return false
	_emit("stale", order)
	_record(step, SimStep.Stat.STALE)
	_send_back(order, step.stale_index, step.stale_wait_minutes)
	return true


func _record(step: SimStep, stat: SimStep.Stat, amount: int = 1) -> void:
	step.record(_day, stat, amount)


## Send an order back to an earlier step (rework, re-planning), after
## `wait_minutes` if there is a wait (e.g. for the customer).
func _send_back(order: WorkOrder, index: int, wait_minutes: int) -> void:
	if wait_minutes > 0:
		_wait(order, wait_minutes, index)
	else:
		_enter(order, index)


## Give free people the most urgent waiting work: highest stream priority
## first, then by the pool's order rule (by default the order that has queued
## longest), skipping work a pull pool holds back. When nobody is free, an
## order of a pre-empting stream (outages) interrupts the least urgent
## lower-priority order in progress.
func _assign_work() -> void:
	for pool in _pool_list:
		var worked := 0
		while pool.is_on_shift(time):
			var step := _next_step_for(pool)
			if step == null:
				break
			var queue := queue_of(step)
			var order: WorkOrder = queue.pop_at(_head_index(pool, queue))
			if not order.started:
				if _went_stale(order, step):
					continue
				order.started = true
				_draw_outcome(order, step)
				_record(step, SimStep.Stat.STARTED)
				_record(step, SimStep.Stat.QUEUE_MINUTES, time - order.queued_at)
			pool.busy.append(order)
			if not pool.spare.is_empty():
				worked += _work_on(pool, order, pool.spare.pop_back())
		pool.spare.clear()  # minutes left in this tick only
		if worked > 0:
			pool.daily.add(_day, SimPool.BUSY, worked)


## The step whose head order someone in `pool` starts now: the most urgent
## one if someone is free for it (or it may interrupt lower-priority work),
## otherwise the most urgent one someone is free for (reserved people only
## take the work they are held for).
func _next_step_for(pool: SimPool) -> SimStep:
	var top := _most_urgent_step(pool)
	if top == null:
		return null
	var urgent := queue_of(top)[0].stream  # one stream per step: any order will do
	if pool.free_for(urgent) > 0:
		return top
	if pool.free_people() <= 0:
		return top if urgent.preempts and _preempt_for(pool, urgent.priority) else null
	return _most_urgent_step(pool, true)  # people are free, but held in reserve


## The step with the most urgent head order; with `startable`, only steps
## someone is free for. A `pull` pool does not start new work while the next
## work step is full.
func _most_urgent_step(pool: SimPool, startable: bool = false) -> SimStep:
	var best: SimStep = null
	var best_head: WorkOrder = null
	for step in pool.steps:
		var queue := queue_of(step)
		if queue.is_empty() or (startable and pool.free_for(queue[0].stream) <= 0):
			continue
		var head := queue[_head_index(pool, queue)]
		if pool.start_rule == "pull" and not head.started and _downstream_is_full(head, pool.pull_limit_days):
			continue
		if best == null or _more_urgent(head, best_head, pool.order_rule):
			best = step
			best_head = head
	return best


## Where in `queue` the order that `pool` takes first sits, by its order rule.
## Started work (handed over at shift end, or paused) waits at the front and
## resumes first; the rule only ranks orders not yet started.
func _head_index(pool: SimPool, queue: Array[WorkOrder]) -> int:
	if pool.order_rule == "first_come" or queue[0].started:
		return 0
	var best := 0
	var best_key := _rule_key(queue[0], pool.order_rule)
	for i in range(1, queue.size()):
		var key := _rule_key(queue[i], pool.order_rule)
		if key < best_key:
			best = i
			best_key = key
	return best


## Smaller goes first.
func _rule_key(order: WorkOrder, rule: String) -> int:
	match rule:
		"oldest":
			return order.born
		"shortest":
			return order.remaining
		"due":
			return order.due
	return order.queued_at


func _more_urgent(a: WorkOrder, b: WorkOrder, rule: String) -> bool:
	if a.stream.priority != b.stream.priority:
		return a.stream.priority > b.stream.priority
	if rule != "first_come" and a.started != b.started:
		return a.started  # unfinished work resumes before the rule picks something new
	return _rule_key(a, rule) < _rule_key(b, rule)


## Whether the next work step after `order`'s has `limit_days` or more queued
## (never for the last work step: nothing downstream to overload).
func _downstream_is_full(order: WorkOrder, limit_days: float) -> bool:
	var steps := order.stream.steps
	for i in range(order.step_index + 1, steps.size()):
		if steps[i].kind == SimStep.Kind.WORK:
			return queue_days(steps[i]) >= limit_days
	return false


## Days of work queued at `step`: its waiting touch minutes over what its
## first pool does in a working day. Infinite when that pool has no capacity;
## 0 at a wait or material step, where no team's work is queued.
func queue_days(step: SimStep) -> float:
	if step.kind != SimStep.Kind.WORK:
		return 0.0
	var minutes := 0
	for order in queue_of(step):
		minutes += order.remaining
	if minutes == 0:
		return 0.0
	var capacity := pools[step.pool_ids[0]].minutes_per_day()
	return minutes / capacity if capacity > 0.0 else INF


## Pause the least urgent busy order with a lower priority. True if one was paused.
func _preempt_for(pool: SimPool, priority: int) -> bool:
	var victim: WorkOrder = null
	for order in pool.busy:
		if order.stream.priority < priority and (victim == null or order.stream.priority < victim.stream.priority):
			victim = order
	if victim == null:
		return false
	pool.busy.erase(victim)
	_emit("preempted", victim)
	var step := victim.current_step()
	_record(step, SimStep.Stat.INTERRUPTED)
	if step.interrupt_index < 0:
		queue_of(step).push_front(victim)  # resumes first
	else:
		# Pulled away: the job has to be planned again (a new appointment).
		_send_back(victim, step.interrupt_index, step.interrupt_wait_minutes)
	return true


func _finish_order(order: WorkOrder) -> void:
	order.stream.active -= 1
	var lead := time - order.born
	order.stream.finished.append({
		"done_at": time, "lead_minutes": lead, "on_time": time <= order.due, "reworks": order.reworks,
		"failure_demand": order.failure_demand,
	})
	_emit("finished", order)
	_release_held(order.stream)


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
