class_name NetworkState
## Captures and restores everything a Network needs to continue exactly as if
## it had never stopped: clock, random state, effects, every order wherever it
## is, stock, recent finished records and daily step statistics.
##
## Restoring goes into a Network freshly built from the current content.
## Orders and items are matched by id ("stream.step"), never by index; what
## the content no longer has is dropped and reported, not guessed at.
## Native Godot types throughout: SaveFile keeps them exact (var_to_bytes).

const SHAPE := {
	"time": TYPE_INT, "day": TYPE_INT, "next_id": TYPE_INT, "rng": TYPE_DICTIONARY, "effects": TYPE_DICTIONARY,
	"pools": TYPE_DICTIONARY, "queues": TYPE_DICTIONARY, "waiting": TYPE_ARRAY, "held": TYPE_DICTIONARY,
	"arrivals": TYPE_ARRAY, "stock": TYPE_DICTIONARY, "streams": TYPE_DICTIONARY,
}


static func capture(net: Network) -> Dictionary:
	var to_dicts := func(orders: Array) -> Array: return orders.map(func(o: WorkOrder) -> Dictionary: return o.to_dict())
	var pools := {}
	for pool in net._pool_list:
		pools[pool.id] = {"present": pool.present, "busy": to_dicts.call(pool.busy), "daily": pool.daily.export_days()}
	var queues := {}
	var held := {}
	var streams := {}
	for s in net.streams:
		held[s.id] = to_dicts.call(net._held[s.id])
		var daily := {}
		for step in s.steps:
			daily[step.id] = step.daily.export_days()
			if step.kind == SimStep.Kind.WORK:
				queues[s.id + "." + step.id] = to_dicts.call(net.queue_of(step))
		streams[s.id] = {"finished": s.finished.duplicate(true), "daily": daily}
	var stock := {}
	for item: SimStock in net.stock.values():
		stock[item.id] = {"level": item.level, "deliveries": item.deliveries.duplicate(true), "waiting": to_dicts.call(item.waiting)}
	return {
		"time": net.time, "day": net._day, "next_id": net._next_id, "rng": net.random_states(),
		"effects": net.effects(), "pools": pools, "queues": queues, "waiting": to_dicts.call(net._waiting),
		"held": held, "arrivals": net._arrivals.map(func(a: Dictionary) -> Dictionary:
			return {"at": a["at"], "stream": a["stream"].id, "failure_demand": a.get("failure_demand", false)}),
		"stock": stock, "streams": streams,
	}


## A network that continues exactly like `net` from here (a "what if" runs on
## it): built from the same content, restored from capture(net), with the
## pool settings that are not effects. `net` itself is only read.
static func copy(net: Network) -> Network:
	var twin := Network.create(net.config, net.run_seed)
	twin.skip_idle = net.skip_idle
	for pool: SimPool in net._pool_list:
		twin.pools[pool.id].pull_limit_days = pool.pull_limit_days
	var result := restore(twin, capture(net))
	if not result["error"].is_empty():
		twin.error = result["error"]
	return twin


## Restore a capture() into `net`, a Network freshly built from content.
## Returns {error, dropped}: error means the data is unusable (discard the
## network); dropped lists what the current content no longer has.
static func restore(net: Network, d: Dictionary) -> Dictionary:
	var error := JsonFile.shape_error(d, SHAPE)
	if not error.is_empty():
		return {"error": error, "dropped": []}
	var dropped: Array[String] = []
	_clear(net)
	net.time = d["time"]
	net._day = d["day"]
	net._next_id = d["next_id"]
	for purpose: String in d["rng"]:
		if not net.restore_random_state(purpose, d["rng"][purpose]):
			dropped.append("random sequence " + purpose)
	for source: String in d["effects"]:
		var effect_error := net.set_effects(source, d["effects"][source])
		if not effect_error.is_empty():
			dropped.append(effect_error)
	_restore_pools(net, d["pools"], dropped)
	_restore_queues(net, d["queues"], dropped)
	net._waiting.append_array(_orders(net, d["waiting"], dropped))
	for stream_id: String in d["held"]:
		if net._held.has(stream_id):
			net._held[stream_id].append_array(_orders(net, d["held"][stream_id], dropped))
	for a: Dictionary in d["arrivals"]:
		var s := net.stream(str(a.get("stream", "")))
		if s == null:
			dropped.append("arrival for %s" % a.get("stream"))
		else:
			net._arrivals.append({"at": int(a.get("at", 0)), "stream": s, "failure_demand": bool(a.get("failure_demand", false))})
	_restore_stock(net, d["stock"], dropped)
	for s in net.streams:
		var saved: Dictionary = d["streams"].get(s.id, {})
		s.finished.assign(saved.get("finished", []))
		var daily: Dictionary = saved.get("daily", {})
		for step in s.steps:
			step.daily.import_days(daily.get(step.id, {}))
	return {"error": "", "dropped": dropped}


## Empty the containers a fresh network filled on creation (day 0).
static func _clear(net: Network) -> void:
	net._arrivals.clear()
	net._waiting.clear()
	for step: SimStep in net._queues:
		net._queues[step].clear()
	for stream_id in net._held:
		net._held[stream_id].clear()
	for pool in net._pool_list:
		pool.busy.clear()
	for item: SimStock in net.stock.values():
		item.deliveries.clear()
		item.waiting.clear()
	for s in net.streams:
		s.active = 0
		s.finished.clear()
	net.events.clear()


static func _restore_pools(net: Network, saved: Dictionary, dropped: Array[String]) -> void:
	for pool_id: String in saved:
		var pool: SimPool = net.pools.get(pool_id)
		if pool == null:
			dropped.append("pool " + pool_id)
			continue
		pool.present = int(saved[pool_id].get("present", 0))
		pool.daily.import_days(saved[pool_id].get("daily", {}))
		for o in _orders(net, saved[pool_id].get("busy", []), dropped):
			if pool_id in o.current_step().pool_ids:
				pool.busy.append(o)
			else:
				_drop(o, "busy in " + pool_id, dropped)


static func _restore_queues(net: Network, saved: Dictionary, dropped: Array[String]) -> void:
	for place: String in saved:
		var step := net.step_at(place)
		var orders := _orders(net, saved[place], dropped)
		if step != null and step.kind == SimStep.Kind.WORK:
			net.queue_of(step).append_array(orders)
		else:
			for o in orders:
				_drop(o, "queued at " + place, dropped)


static func _restore_stock(net: Network, saved: Dictionary, dropped: Array[String]) -> void:
	for item_id: String in saved:
		var item: SimStock = net.stock.get(item_id)
		if item == null:
			dropped.append("stock " + item_id)
			continue
		item.level = int(saved[item_id].get("level", item.level))
		item.deliveries.assign(saved[item_id].get("deliveries", []))
		item.waiting.append_array(_orders(net, saved[item_id].get("waiting", []), dropped))


## Rebuild orders; each one counts towards its stream's backlog.
static func _orders(net: Network, saved: Variant, dropped: Array[String]) -> Array[WorkOrder]:
	var out: Array[WorkOrder] = []
	if not saved is Array:
		dropped.append("a list of orders")
		return out
	for od: Variant in saved:
		var s := net.stream(str(od.get("stream", ""))) if od is Dictionary else null
		var o := WorkOrder.from_dict(od, s) if s != null else null
		if o == null:
			dropped.append("order %s" % [od.get("id", "?") if od is Dictionary else od])
			continue
		s.active += 1
		out.append(o)
	return out


static func _drop(o: WorkOrder, why: String, dropped: Array[String]) -> void:
	o.stream.active -= 1
	dropped.append("order %d (%s)" % [o.id, why])
