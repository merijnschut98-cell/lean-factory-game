class_name SimModifiers
extends RefCounted
## Problem and countermeasure effects on top of the content's base values.
##
## An effect is {target, property, value}, e.g. {target: "connections.design",
## property: "touch_time", value: 1.3}. Factors multiply, additions add, and
## levers (SET: an outage reserve, a frozen planning window, permits in
## parallel) take the value of the most recently set source. Effects are grouped by source
## ("problem:custom_design", "cm:standard_designs"), so each can be switched
## off, saved and compared. Every change recomputes the touched fields from
## their untouched base values (clamp(base × factors + additions)) and writes
## them into the plain sim fields, so the simulation and Capacity read
## effective values without lookups. Changes apply to work from then on;
## attendance follows a headcount change from the next day.
##
## Holds no reference to the Network (that would be a cycle): the Network
## passes itself in. Read the active effects through Network.effects().

enum Op { ADD, MUL, SET }

## What each property changes, how effects combine, and the bounds.
## `step_kind` limits a step property to the steps that have that field;
## `unit` converts the value (days) to the field (minutes); `valid` names the
## check for a lever's value. `demand` scales every arrival source of the stream.
const PROPERTIES := {
	"touch_time": {"kind": "step", "step_kind": SimStep.Kind.WORK, "field": "touch_minutes", "op": Op.MUL, "min": 1.0},
	"ftr": {"kind": "step", "step_kind": SimStep.Kind.WORK, "field": "ftr", "op": Op.ADD, "min": 0.05, "max": 1.0},
	"applies": {"kind": "step", "field": "applies", "op": Op.ADD, "min": 0.0, "max": 1.0},
	"wait_time": {"kind": "step", "step_kind": SimStep.Kind.WAIT, "field": "wait_minutes", "op": Op.MUL, "min": 0.0},
	"availability": {"kind": "pool", "field": "availability", "op": Op.ADD, "min": 0.0, "max": 1.0},
	"headcount": {"kind": "pool", "field": "headcount", "op": Op.ADD, "min": 0.0},
	"lead_time": {"kind": "stock", "field": "lead_minutes", "op": Op.MUL, "min": 0.0},
	"reorder_point": {"kind": "stock", "field": "reorder_point", "op": Op.ADD, "min": 0.0},
	"demand": {"kind": "arrivals", "field": "per_week", "op": Op.MUL, "min": 0.0},
	"reserve": {"kind": "pool", "field": "reserve", "op": Op.SET, "valid": "reserve"},
	"preempts": {"kind": "stream", "field": "preempts", "op": Op.SET, "valid": "bool"},
	"batch_days": {"kind": "step", "step_kind": SimStep.Kind.WAIT, "field": "batch_minutes", "op": Op.ADD,
		"min": 0.0, "unit": SimCalendar.MINUTES_PER_DAY},
	"starts_with": {"kind": "step", "step_kind": SimStep.Kind.WAIT, "field": "starts_with", "op": Op.SET,
		"valid": "earlier_step"},
}

## source → its effects.
var _sources: Dictionary[String, Array] = {}
## Content values of every field an effect has touched: {object: {field: value}}.
var _base: Dictionary[Object, Dictionary] = {}


## Active effects by source (a copy), for saves and the UI.
func sources() -> Dictionary[String, Array]:
	return _sources.duplicate(true)


## Turn on, or replace, the effects of `source`. Returns an error and changes
## nothing if any effect is invalid.
func set_source(net: Network, source: String, effects: Array) -> String:
	for e: Variant in effects:
		var error := _check(net, e)
		if not error.is_empty():
			return "%s: %s" % [source, error]
	_sources[source] = effects.duplicate(true)
	_apply(net)
	return ""


func clear_source(net: Network, source: String) -> void:
	if _sources.erase(source):
		_apply(net)


## The effects at strength `k` (0 = none, 1 = full), e.g. a problem partly
## removed by a countermeasure: a factor f becomes 1 + (f − 1)·k, an addition
## v becomes v·k. A lever is in place or not, so it stays as it is.
static func scaled(effects: Array, k: float) -> Array:
	return effects.map(func(e: Dictionary) -> Dictionary:
		var out := e.duplicate()
		match PROPERTIES[e["property"]]["op"]:
			Op.MUL:
				out["value"] = 1.0 + (e["value"] - 1.0) * k
			Op.ADD:
				out["value"] = e["value"] * k
		return out)


## The objects an effect changes: a pool, stock item or step ("stream.step";
## step ids repeat across streams), or for a stream every arrival source.
## Empty when the target does not exist.
static func targets(net: Network, property: String, target: String) -> Array:
	match PROPERTIES[property]["kind"]:
		"pool":
			return [net.pools[target]] if net.pools.has(target) else []
		"stock":
			return [net.stock[target]] if net.stock.has(target) else []
		"stream":
			var s := net.stream(target)
			return [s] if s != null else []
		"arrivals":
			var s := net.stream(target)
			return s.arrivals.duplicate() if s != null else []
	var parts := target.split(".")
	var owner := net.stream(parts[0]) if parts.size() == 2 else null
	var step := owner.step(parts[1]) if owner != null else null
	return [step] if step != null else []


func _check(net: Network, e: Variant) -> String:
	if not (e is Dictionary and e.get("target") is String and e.get("property") is String and e.has("value")):
		return "an effect needs a target, a property and a value (got %s)" % [e]
	var spec: Dictionary = PROPERTIES.get(e["property"], {})
	if spec.is_empty():
		return "unknown property %s" % e["property"]
	var found := targets(net, e["property"], e["target"])
	if found.is_empty():
		return "no %s called %s" % ["stream" if spec["kind"] == "arrivals" else spec["kind"], e["target"]]
	if spec.has("step_kind") and (found[0] as SimStep).kind != spec["step_kind"]:
		return "step %s has no %s" % [e["target"], e["property"]]
	var value: Variant = e["value"]
	if spec["op"] == Op.SET:
		return _check_lever(net, spec["valid"], e["target"], found[0], value)
	if not (value is float or value is int):
		return "%s needs a number (got %s)" % [e["property"], value]
	if spec["op"] == Op.MUL and value <= 0:
		return "%s is a factor and must be above 0" % e["property"]
	return ""


func _check_lever(net: Network, valid: String, target: String, obj: Object, value: Variant) -> String:
	match valid:
		"bool":
			return "" if value is bool else "needs true or false (got %s)" % [value]
		"reserve":
			# {} (no reserve) or {stream, people} with people up to the headcount.
			if value is Dictionary and (value.is_empty() or (net.stream(value.get("stream", "")) != null
					and (value.get("people") is int or value.get("people") is float)
					and value["people"] >= 0 and value["people"] <= (obj as SimPool).headcount)):
				return ""
			return "a reserve is {stream, people} with a known stream and people up to the headcount (got %s)" % [value]
	# earlier_step: "" (in sequence) or a step before the target in the same stream.
	var steps := net.stream(target.get_slice(".", 0)).steps
	var at := steps.find(obj)
	if value is String and (value == "" or steps.slice(0, at).any(func(s: SimStep) -> bool: return s.id == value)):
		return ""
	return "%s can only start with an earlier step (got %s)" % [target, value]


## Combine every source's effects per field (factors multiply, additions
## add), then write base-with-effects into every field ever touched, so a
## field whose effects were all cleared gets its base value back.
func _apply(net: Network) -> void:
	var combined: Dictionary[Object, Dictionary] = {}  # {object: {property: factor or addition}}
	for effects in _sources.values():
		for e: Dictionary in effects:
			var spec: Dictionary = PROPERTIES[e["property"]]
			for obj: Object in targets(net, e["property"], e["target"]):
				_base.get_or_add(obj, {}).get_or_add(spec["field"], obj.get(spec["field"]))
				var by_property: Dictionary = combined.get_or_add(obj, {})
				match spec["op"]:
					Op.MUL:
						by_property[e["property"]] = by_property.get(e["property"], 1.0) * e["value"]
					Op.ADD:
						by_property[e["property"]] = by_property.get(e["property"], 0.0) + e["value"] * spec.get("unit", 1)
					Op.SET:
						by_property[e["property"]] = e["value"]
	for obj in _base:
		for field: String in _base[obj]:
			obj.set(field, _base[obj][field])
		for property: String in combined.get(obj, {}):
			var spec: Dictionary = PROPERTIES[property]
			if spec["op"] == Op.SET:
				obj.set(spec["field"], combined[obj][property])
				continue
			var base: Variant = _base[obj][spec["field"]]
			var change: float = combined[obj][property]
			var value := float(base) * change if spec["op"] == Op.MUL else float(base) + change
			value = clampf(value, spec["min"], spec.get("max", INF))
			obj.set(spec["field"], roundi(value) if base is int else value)
