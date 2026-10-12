class_name NetFixture
## Builds small Network configurations for tests, in the value_streams.json shape.


## One schedule block, e.g. block("mon-sun", "00:00", "24:00") for around the clock.
static func block(days: String, from: String, to: String) -> Dictionary:
	return {"days": days, "from": from, "to": to}


static func pool(id: String, headcount: int = 1, availability: float = 1.0,
		schedule: Array = [block("mon-fri", "08:00", "16:00")]) -> Dictionary:
	return {"id": id, "name": id, "headcount": headcount, "availability": availability, "schedule": schedule}


## `pool` is one pool id or a list of them.
static func work(id: String, pool: Variant, hours: float, ftr: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": "work", "pool": pool, "touch_hours": hours, "ftr": ftr}
	d.merge(extra)
	return d


static func wait(id: String, days: float, spread: float = 0.0, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": "wait", "days": days, "spread": spread}
	d.merge(extra)
	return d


static func material(id: String, item: String, quantity: int = 1) -> Dictionary:
	return {"id": id, "name": id, "kind": "material", "item": item, "quantity": quantity}


static func stock(id: String, level: int, reorder_point: int, order_quantity: int, lead_days: float) -> Dictionary:
	return {"id": id, "name": id, "level": level, "reorder_point": reorder_point,
		"order_quantity": order_quantity, "lead_days": lead_days}


## `per_week` arrivals on working days between 08:00 and 17:00; `extra` overrides
## or adds fields (e.g. {"preempts": true} or a different "arrivals" list).
static func stream(id: String, steps: Array, per_week: float = 20.0, priority: int = 1, extra: Dictionary = {}) -> Dictionary:
	var arrivals := block("mon-fri", "08:00", "17:00")
	arrivals["per_week"] = per_week
	var d := {"id": id, "name": id, "arrivals": [arrivals], "norm_days": 30.0, "priority": priority, "steps": steps}
	d.merge(extra, true)
	return d


## Weeknights and weekends: the schedule of the storingsdienst (on-call crew).
static func on_call() -> Array:
	return [block("mon-fri", "00:00", "07:00"), block("mon-fri", "15:00", "24:00"), block("sat-sun", "00:00", "24:00")]


## Events of one type still in `net.events`.
static func events(net: Network, type: String) -> Array[Dictionary]:
	return net.events.filter(func(e: Dictionary) -> bool: return e["type"] == type)


## Around-the-clock arrivals, `per_week` on average.
static func always(per_week: float) -> Array:
	var a := block("mon-sun", "00:00", "24:00")
	a["per_week"] = per_week
	return [a]


static func net(pools: Array, streams: Array, stock: Array = [], seed_value: int = 7) -> Network:
	return Network.create({"pools": pools, "stock": stock, "streams": streams}, seed_value)
