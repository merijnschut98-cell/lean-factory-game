class_name NetworkState
## Captures and restores everything a Network needs to continue exactly as if
## it had never stopped: clock, random state, effects, every order wherever it
## is, stock, finished records and the daily step statistics.
##
## Restoring goes into a Network freshly built from the current content.
## Orders and items are matched by id ("stream.step"), never by index; what
## the content no longer has is dropped and reported, not guessed at.
## Numbers come back from JSON as floats and are converted back explicitly;
## the 64-bit random state is stored as text.

const KEYS := ["time", "day", "next_id", "rng", "effects", "pools", "queues", "waiting", "held",
	"arrivals", "stock", "streams", "daily"]


static func capture(net: Network) -> Dictionary:
	var pools := {}
	for pool in net._pool_list:
		pools[pool.id] = {"present": pool.present, "busy": pool.busy.map(_order)}
	var queues := {}
	var daily := {}
	var held := {}
	var streams := {}
	for s in net.streams:
		held[s.id] = net._held[s.id].map(_order)
		streams[s.id] = {"finished": s.finished.duplicate(true)}
		for step in s.steps:
			daily[s.id + "." + step.id] = step.export_daily()
			if step.kind == SimStep.Kind.WORK:
				queues[s.id + "." + step.id] = net.queue_of(step).map(_order)
	var stock := {}
	for item: SimStock in net.stock.values():
		stock[item.id] = {"level": item.level, "deliveries": item.deliveries.duplicate(true), "waiting": item.waiting.map(_order)}
	return {
		"time": net.time, "day": net._day, "next_id": net._next_id, "rng": str(net.rng.get_state()),
		"effects": net.effects(), "pools": pools, "queues": queues, "waiting": net._waiting.map(_order),
		"held": held, "arrivals": net._arrivals.map(func(a: Dictionary) -> Dictionary: return {"at": a["at"], "stream": a["stream"].id}),
		"stock": stock, "streams": streams, "daily": daily,
	}


static func _order(o: WorkOrder) -> Dictionary:
	var steps := o.stream.steps
	var early := {}
	for index in o.early:
		early[steps[index].id] = o.early[index]
	return {
		"id": o.id, "stream": o.stream.id, "step": steps[o.step_index].id, "born": o.born, "due": o.due,
		"remaining": o.remaining, "queued_at": o.queued_at, "started": o.started, "wait_until": o.wait_until,
		"pending": steps[o.pending_step].id if o.pending_step < steps.size() else "", "reworks": o.reworks,
		"early": early,
	}


## Restore a capture() into `net`, a Network freshly built from content.
## Returns {error, dropped}: error means the data is unusable (discard the
## network); dropped lists what the current content no longer has.
static func restore(net: Network, d: Dictionary) -> Dictionary:
	var error := _check(d)
	if not error.is_empty():
		return {"error": error, "dropped": []}
	var dropped: Array[String] = []
	_clear(net)
	net.time = int(d["time"])
	net._day = int(d["day"])
	net._next_id = int(d["next_id"])
	net.rng.set_state(String(d["rng"]).to_int())
	for source: String in d["effects"]:
		var effect_error := net.set_effects(source, d["effects"][source])
		if not effect_error.is_empty():
			dropped.append(effect_error)
	for pool_id: String in d["pools"]:
		var pool: SimPool = net.pools.get(pool_id)
		if pool == null:
			dropped.append("pool " + pool_id)
			continue
		pool.present = int(d["pools"][pool_id]["present"])
		for o in _orders(net, d["pools"][pool_id]["busy"], dropped):
			if pool_id in o.current_step().pool_ids:
				pool.busy.append(o)
			else:
				_drop(o, "busy in " + pool_id, dropped)
	for place: String in d["queues"]:
		var step := net.step_at(place)
		var orders := _orders(net, d["queues"][place], dropped)
		if step == null or step.kind != SimStep.Kind.WORK:
			for o in orders:
				_drop(o, "queued at " + place, dropped)
			continue
		net.queue_of(step).append_array(orders)
	net._waiting.append_array(_orders(net, d["waiting"], dropped))
	for stream_id: String in d["held"]:
		var orders := _orders(net, d["held"][stream_id], dropped)
		if net._held.has(stream_id):
			net._held[stream_id].append_array(orders)
	for a: Dictionary in d["arrivals"]:
		var s := net.stream(a.get("stream", ""))
		if s == null:
			dropped.append("arrival for " + str(a.get("stream")))
		else:
			net._arrivals.append({"at": int(a["at"]), "stream": s})
	for item_id: String in d["stock"]:
		var item: SimStock = net.stock.get(item_id)
		var saved: Dictionary = d["stock"][item_id]
		if item == null:
			dropped.append("stock " + item_id)
			continue
		item.level = int(saved["level"])
		for delivery: Dictionary in saved["deliveries"]:
			item.deliveries.append({"at": int(delivery["at"]), "quantity": int(delivery["quantity"])})
		item.waiting.append_array(_orders(net, saved["waiting"], dropped))
	for s in net.streams:
		var finished: Array = d["streams"].get(s.id, {}).get("finished", [])
		for f: Dictionary in finished:
			s.finished.append({"done_at": int(f["done_at"]), "lead_minutes": int(f["lead_minutes"]),
				"on_time": bool(f["on_time"]), "reworks": int(f["reworks"])})
		for step in s.steps:
			step.import_daily(d["daily"].get(s.id + "." + step.id, {}))
	return {"error": "", "dropped": dropped}


static func _check(d: Dictionary) -> String:
	for key in KEYS:
		if not d.has(key):
			return "save is missing '%s'" % key
	for key in ["time", "day", "next_id"]:
		if not (d[key] is float or d[key] is int):
			return "'%s' must be a number" % key
	if not (d["rng"] is String and d["rng"].is_valid_int()):
		return "'rng' must be a whole number as text"
	for key in ["effects", "pools", "queues", "held", "stock", "streams", "daily"]:
		if not d[key] is Dictionary:
			return "'%s' must be an object" % key
	for key in ["waiting", "arrivals"]:
		if not d[key] is Array:
			return "'%s' must be a list" % key
	return ""


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


## Rebuild orders; each one counts towards its stream's backlog.
static func _orders(net: Network, saved: Variant, dropped: Array[String]) -> Array[WorkOrder]:
	var out: Array[WorkOrder] = []
	if not saved is Array:
		dropped.append("a list of orders")
		return out
	for od: Variant in saved:
		var o := _order_from(net, od)
		if o == null:
			dropped.append("order %s" % [od.get("id", "?") if od is Dictionary else od])
		else:
			o.stream.active += 1
			out.append(o)
	return out


static func _drop(o: WorkOrder, why: String, dropped: Array[String]) -> void:
	o.stream.active -= 1
	dropped.append("order %d (%s)" % [o.id, why])


static func _order_from(net: Network, od: Variant) -> WorkOrder:
	if not od is Dictionary:
		return null
	var s := net.stream(od.get("stream", ""))
	if s == null:
		return null
	var at := s.steps.find(s.step(od.get("step", "")))
	var pending: String = od.get("pending", "")
	var pending_at := s.steps.size() if pending.is_empty() else s.steps.find(s.step(pending))
	if at < 0 or pending_at < 0:
		return null
	var o := WorkOrder.new(int(od.get("id", 0)), s, int(od.get("born", 0)))
	o.due = int(od.get("due", o.due))
	o.step_index = at
	o.pending_step = pending_at
	o.remaining = int(od.get("remaining", 0))
	o.queued_at = int(od.get("queued_at", 0))
	o.started = bool(od.get("started", false))
	o.wait_until = int(od.get("wait_until", 0))
	o.reworks = int(od.get("reworks", 0))
	var early: Dictionary = od.get("early", {})
	for step_id: String in early:
		var index := s.steps.find(s.step(step_id))
		if index >= 0:
			o.early[index] = int(early[step_id])
	return o
