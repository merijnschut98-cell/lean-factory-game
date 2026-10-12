class_name Capacity
## Static capacity analysis of a Network: how many people-hours each pool
## needs per working day against what it has, and which pool constrains each
## value stream end to end. Rework loops count: a step with 80% first-time-
## right is visited 1.25 times per order, plus any loops coming back from later steps.


## Expected visits per order to each step of a stream, including skips
## (`applies`) and rework loops. Solved by fixed-point iteration.
static func expected_visits(stream: ValueStream) -> PackedFloat64Array:
	var n := stream.steps.size()
	var visits := PackedFloat64Array()
	visits.resize(n)
	var arrive := PackedFloat64Array()
	arrive.resize(n + 1)
	for iteration in 1000:
		# Inflow to each step: new orders at step 0, plus rework sent back
		# by every work step (from the previous iteration's visit counts).
		arrive.fill(0.0)
		arrive[0] = 1.0
		for i in n:
			var step := stream.steps[i]
			if step.kind == SimStep.Kind.WORK:
				arrive[step.rework_index] += visits[i] * (1.0 - step.ftr)
		var changed := 0.0
		for i in n:
			var step := stream.steps[i]
			var v := arrive[i] * step.applies
			arrive[i + 1] += arrive[i] - v + v * (step.ftr if step.kind == SimStep.Kind.WORK else 1.0)
			changed = maxf(changed, absf(v - visits[i]))
			visits[i] = v
		if changed < 1e-9:
			break
	return visits


## People-hours per working day that `stream` needs from each pool: {pool_id: hours}.
## Pass `visits` when already computed; otherwise it is solved here.
static func stream_load(stream: ValueStream, visits: PackedFloat64Array = PackedFloat64Array()) -> Dictionary[String, float]:
	if visits.is_empty():
		visits = expected_visits(stream)
	var load: Dictionary[String, float] = {}
	for i in stream.steps.size():
		var step := stream.steps[i]
		if step.kind == SimStep.Kind.WORK:
			load[step.pool_id] = load.get(step.pool_id, 0.0) + stream.arrivals_per_day * visits[i] * step.touch_minutes / 60.0
	return load


## Full analysis:
## {pools: {id: {available, load, utilisation}},
##  streams: {id: {constraint_pool, constraint_step, utilisation, capacity_per_day}}}
static func analyse(net: Network) -> Dictionary:
	var loads := {}
	var visits := {}
	var total: Dictionary[String, float] = {}
	for s in net.streams:
		visits[s.id] = expected_visits(s)
		loads[s.id] = stream_load(s, visits[s.id])
		for pool_id: String in loads[s.id]:
			total[pool_id] = total.get(pool_id, 0.0) + loads[s.id][pool_id]
	var pools := {}
	for pool: SimPool in net.pools.values():
		var available := pool.available_hours()
		pools[pool.id] = {
			"available": available,
			"load": total.get(pool.id, 0.0),
			"utilisation": total.get(pool.id, 0.0) / available if available > 0.0 else INF,
		}
	var result_streams := {}
	for s in net.streams:
		result_streams[s.id] = _stream_constraint(s, loads[s.id], visits[s.id], pools)
	return {"pools": pools, "streams": result_streams}


static func _stream_constraint(s: ValueStream, own: Dictionary[String, float], visits: PackedFloat64Array,
		pools: Dictionary) -> Dictionary:
	var worst := ""
	var capacity := INF
	for pool_id: String in own:
		var p: Dictionary = pools[pool_id]
		if worst == "" or p["utilisation"] > pools[worst]["utilisation"]:
			worst = pool_id
		# Orders per day this stream could push through the pool, given the others' load.
		var hours_per_order: float = own[pool_id] / s.arrivals_per_day if s.arrivals_per_day > 0.0 else 0.0
		if hours_per_order > 0.0:
			var spare: float = p["available"] - (p["load"] - own[pool_id])
			capacity = minf(capacity, maxf(0.0, spare) / hours_per_order)
	var step_id := ""
	var step_load := -1.0
	for i in s.steps.size():
		var step := s.steps[i]
		if step.kind == SimStep.Kind.WORK and step.pool_id == worst and visits[i] * step.touch_minutes > step_load:
			step_load = visits[i] * step.touch_minutes
			step_id = step.id
	return {
		"constraint_pool": worst,
		"constraint_step": step_id,
		"utilisation": pools[worst]["utilisation"] if worst != "" else 0.0,
		"capacity_per_day": capacity,
	}
