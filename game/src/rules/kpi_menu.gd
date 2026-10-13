class_name KpiMenu
extends RefCounted
## The KPI menus per department (content/kpis.yaml) and their translation
## into work rules. A department follows two of its KPIs; each KPI sets
## rules, and two KPIs that set the same rule differently give mixed
## signals, so that rule keeps the habit.

## Pool id → its KPIs (at most 5).
var menus: Dictionary[String, Array] = {}
## Pool id → the places ("stream.step") of its work steps, where care applies.
var pool_steps: Dictionary[String, PackedStringArray] = {}
## Pull holds a job while the next team has this many days of work queued.
var pull_limit_days := 3.0
var review_question := ""
## Care level → {touch_time (factor), ftr (addition)} for every work step.
var care: Dictionary = {}


## `defs` are the loaded KPIs, `doc` kpis.json, `streams` value_streams.json.
static func from_docs(defs: Array, doc: Dictionary, streams: Dictionary) -> KpiMenu:
	var m := KpiMenu.new()
	m.pull_limit_days = float(doc.get("pull_limit_days", m.pull_limit_days))
	m.review_question = str(doc.get("review_question", ""))
	m.care = JsonFile.dict_or_empty(doc.get("care"))
	for k: KpiDef in defs:
		m.menus.get_or_add(k.pool, []).append(k)
	for stream: Dictionary in streams.get("streams", []):
		for step: Dictionary in stream.get("steps", []):
			if step.get("kind") != "work":
				continue
			var pools: Array = step["pool"] if step.get("pool") is Array else [step.get("pool", "")]
			for pool: String in pools:
				var places: PackedStringArray = m.pool_steps.get(pool, PackedStringArray())
				places.append("%s.%s" % [stream.get("id", ""), step.get("id", "")])
				m.pool_steps[pool] = places
	return m


## The rule effects of a department following these KPIs: start and order on
## the pool, care on each of its work steps. A rule the KPIs disagree on is
## left out (the habit), as is care that comes out normal.
func effects_for(pool_id: String, kpi_ids: PackedStringArray) -> Array:
	var chosen := (menus.get(pool_id, []) as Array).filter(func(k: KpiDef) -> bool: return kpi_ids.has(k.id))
	var effects := []
	for rule in ["start", "order"]:
		var value := _agreed(chosen, rule)
		if not value.is_empty():
			effects.append({"target": pool_id, "property": rule + "_rule", "value": value})
	var level := _agreed(chosen, "care")
	if care.has(level):
		for place in pool_steps.get(pool_id, PackedStringArray()):
			effects.append({"target": place, "property": "touch_time", "value": float(care[level]["touch_time"])})
			effects.append({"target": place, "property": "ftr", "value": float(care[level]["ftr"])})
	return effects


## `effects` with every `kpis` effect replaced by its rule effects.
func expand(effects: Array) -> Array:
	var expanded := []
	for e: Dictionary in effects:
		if e.get("property") == "kpis" and e.get("value") is Array:
			expanded.append_array(effects_for(e["target"], PackedStringArray(e["value"])))
		else:
			expanded.append(e)
	return expanded


## The value of `rule` that all chosen KPIs setting it agree on; "" when none sets it or they differ.
func _agreed(chosen: Array, rule: String) -> String:
	var values := []
	for k: KpiDef in chosen:
		if k.rules.has(rule) and not values.has(k.rules[rule]):
			values.append(k.rules[rule])
	return values[0] if values.size() == 1 else ""
