class_name Capacity
## Static capacity analysis of a Network: how many people-hours each pool
## needs per week against what it has, and which pool constrains each
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


## People-hours per week that `stream` needs from each pool: {pool_id: hours}.
## Pass `visits` when already computed; otherwise it is solved here.
static func stream_load(stream: ValueStream, pools: Dictionary[String, SimPool],
		visits: PackedFloat64Array = PackedFloat64Array()) -> Dictionary[String, float]:
	if visits.is_empty():
		visits = expected_visits(stream)
	var load: Dictionary[String, float] = {}
	var per_week := stream.per_week()
	for i in stream.steps.size():
		var step := stream.steps[i]
		if step.kind != SimStep.Kind.WORK:
			continue
		var hours := per_week * visits[i] * step.minutes_per_visit() / 60.0
		var shares := _pool_shares(stream, step.pool_ids, pools)
		for j in step.pool_ids.size():
			load[step.pool_ids[j]] = load.get(step.pool_ids[j], 0.0) + hours * shares[j]
	return load


## How a step served by several pools divides its work: by the share of the
## stream's arrivals that falls in each pool's hours. Exact for quick work
## such as outages (done around the moment it arrives); an estimate otherwise.
static func _pool_shares(stream: ValueStream, pool_ids: PackedStringArray, pools: Dictionary[String, SimPool]) -> PackedFloat64Array:
	var shares := PackedFloat64Array()
	shares.resize(pool_ids.size())
	if pool_ids.size() == 1:
		shares[0] = 1.0
		return shares
	var total := 0.0
	for j in pool_ids.size():
		for a in stream.arrivals:
			shares[j] += a.per_week * a.when.overlap_hours(pools[pool_ids[j]].schedule) / a.when.hours()
		total += shares[j]
	for j in pool_ids.size():
		shares[j] = shares[j] / total if total > 0.0 else 1.0 / pool_ids.size()
	return shares


## Full analysis:
## {pools: {id: {available, load, utilisation}},
##  streams: {id: {constraint_pool, constraint_step, utilisation, capacity_per_week}}}
## Hours are people-hours per week.
static func analyse(net: Network) -> Dictionary:
	var loads := {}
	var visits := {}
	var total: Dictionary[String, float] = {}
	for s in net.streams:
		visits[s.id] = expected_visits(s)
		loads[s.id] = stream_load(s, net.pools, visits[s.id])
		for pool_id: String in loads[s.id]:
			total[pool_id] = total.get(pool_id, 0.0) + loads[s.id][pool_id]
	var pools := {}
	for pool: SimPool in net.pools.values():
		var available := pool.hours_per_week()
		pools[pool.id] = {
			"available": available,
			# Idle reserved people-hours (an outage reserve not used by its own
			# stream): no other stream can use them.
			"held_for": pool.reserve.get("stream", ""),
			"idle_held": _idle_held(pool, loads),
			"load": total.get(pool.id, 0.0),
			"utilisation": total.get(pool.id, 0.0) / available if available > 0.0 else INF,
		}
	var result_streams := {}
	for s in net.streams:
		result_streams[s.id] = _stream_constraint(s, loads[s.id], visits[s.id], pools)
	return {"pools": pools, "streams": result_streams}


static func _idle_held(pool: SimPool, loads: Dictionary) -> float:
	var people := mini(int(pool.reserve.get("people", 0)), pool.headcount)
	if people == 0:
		return 0.0
	var used: float = loads.get(pool.reserve["stream"], {}).get(pool.id, 0.0)
	return maxf(0.0, pool.hours_per_week() * people / pool.headcount - used)


static func _stream_constraint(s: ValueStream, own: Dictionary[String, float], visits: PackedFloat64Array,
		pools: Dictionary) -> Dictionary:
	var worst := ""
	var capacity := INF
	var per_week := s.per_week()
	for pool_id: String in own:
		var p: Dictionary = pools[pool_id]
		if worst == "" or p["utilisation"] > pools[worst]["utilisation"]:
			worst = pool_id
		# Orders per week this stream could push through the pool, given the others' load.
		var hours_per_order: float = own[pool_id] / per_week if per_week > 0.0 else 0.0
		if hours_per_order > 0.0:
			var others: float = p["load"] - own[pool_id] + (p["idle_held"] if p["held_for"] != s.id else 0.0)
			var spare: float = p["available"] - others
			capacity = minf(capacity, maxf(0.0, spare) / hours_per_order)
	var step_id := ""
	var step_load := -1.0
	for i in s.steps.size():
		var step := s.steps[i]
		if step.kind != SimStep.Kind.WORK or not worst in step.pool_ids:
			continue
		var load := visits[i] * step.minutes_per_visit()
		if load > step_load:
			step_load = load
			step_id = step.id
	return {
		"constraint_pool": worst,
		"constraint_step": step_id,
		"utilisation": pools[worst]["utilisation"] if worst != "" else 0.0,
		"capacity_per_week": capacity,
	}
