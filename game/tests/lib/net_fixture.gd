class_name NetFixture
## Builds small Network configurations for tests, in the value_streams.json shape.


static func pool(id: String, headcount: int = 1, availability: float = 1.0,
		shift: Array = ["08:00", "16:00"]) -> Dictionary:
	return {"id": id, "name": id, "headcount": headcount, "availability": availability, "shift": shift}


static func work(id: String, pool_id: String, hours: float, ftr: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": "work", "pool": pool_id, "touch_hours": hours, "ftr": ftr}
	d.merge(extra)
	return d


static func wait(id: String, days: float, spread: float = 0.0, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "name": id, "kind": "wait", "days": days, "spread": spread}
	d.merge(extra)
	return d


static func material(id: String, item: String, quantity: int = 1) -> Dictionary:
	return {"id": id, "name": id, "kind": "material", "item": item, "quantity": quantity}


static func stream(id: String, steps: Array, arrivals: float = 4.0, priority: int = 1, norm_days: float = 30.0) -> Dictionary:
	return {"id": id, "name": id, "arrivals_per_day": arrivals, "norm_days": norm_days, "priority": priority, "steps": steps}


static func net(pools: Array, streams: Array, stock: Array = [], seed_value: int = 7) -> Network:
	return Network.create({"pools": pools, "stock": stock, "streams": streams}, seed_value)
