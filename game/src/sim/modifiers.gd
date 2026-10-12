class_name SimModifiers
extends RefCounted
## Problem and countermeasure effects on top of the content's base values.
##
## An effect is {target, property, value}, e.g. {target: "connections.design",
## property: "touch_time", value: 1.3}. Effects are grouped by source
## ("problem:custom_design", "cm:standard_designs"), so each can be switched
## off, saved and compared. Every change recomputes the touched fields from
## their untouched base values (clamp(base × factors + additions)) and writes
## them into the plain sim fields, so the simulation and Capacity read
## effective values without lookups. Changes apply to work from then on;
## attendance follows a headcount change from the next day.
##
## Holds no reference to the Network (that would be a cycle): the Network
## passes itself in. Read the active effects through Network.effects().

enum Op { ADD, MUL }

## What each property changes, how effects combine, and the bounds.
## `step_kind` limits a step property to the steps that have that field.
## `demand` scales every arrival source of the stream.
const PROPERTIES := {
	"touch_time": {"kind": "step", "step_kind": SimStep.Kind.WORK, "field": "touch_minutes", "op": Op.MUL, "min": 1.0},
	"ftr": {"kind": "step", "step_kind": SimStep.Kind.WORK, "field": "ftr", "op": Op.ADD, "min": 0.05, "max": 1.0},
	"applies": {"kind": "step", "field": "applies", "op": Op.ADD, "min": 0.0, "max": 1.0},
	"wait_time": {"kind": "step", "step_kind": SimStep.Kind.WAIT, "field": "wait_minutes", "op": Op.MUL, "min": 0.0},
	"availability": {"kind": "pool", "field": "availability", "op": Op.ADD, "min": 0.0, "max": 1.0},
	"headcount": {"kind": "pool", "field": "headcount", "op": Op.ADD, "min": 0.0},
	"lead_time": {"kind": "stock", "field": "lead_minutes", "op": Op.MUL, "min": 0.0},
	"reorder_point": {"kind": "stock", "field": "reorder_point", "op": Op.ADD, "min": 0.0},
	"demand": {"kind": "stream", "field": "per_week", "op": Op.MUL, "min": 0.0},
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
## removed by a countermeasure: a factor f becomes 1 + (f − 1)·k, an addition v becomes v·k.
static func scaled(effects: Array, k: float) -> Array:
	return effects.map(func(e: Dictionary) -> Dictionary:
		var out := e.duplicate()
		var v: float = e["value"]
		out["value"] = 1.0 + (v - 1.0) * k if PROPERTIES[e["property"]]["op"] == Op.MUL else v * k
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
			return s.arrivals.duplicate() if s != null else []
	var parts := target.split(".")
	var owner := net.stream(parts[0]) if parts.size() == 2 else null
	var step := owner.step(parts[1]) if owner != null else null
	return [step] if step != null else []


func _check(net: Network, e: Variant) -> String:
	if not (e is Dictionary and e.get("target") is String and e.get("property") is String
			and (e.get("value") is float or e.get("value") is int)):
		return "an effect needs a target, a property and a numeric value (got %s)" % [e]
	var spec: Dictionary = PROPERTIES.get(e["property"], {})
	if spec.is_empty():
		return "unknown property %s" % e["property"]
	if spec["op"] == Op.MUL and e["value"] <= 0:
		return "%s is a factor and must be above 0" % e["property"]
	var found := targets(net, e["property"], e["target"])
	if found.is_empty():
		return "no %s called %s" % [spec["kind"], e["target"]]
	if spec.has("step_kind") and (found[0] as SimStep).kind != spec["step_kind"]:
		return "step %s has no %s" % [e["target"], e["property"]]
	return ""


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
				if spec["op"] == Op.MUL:
					by_property[e["property"]] = by_property.get(e["property"], 1.0) * e["value"]
				else:
					by_property[e["property"]] = by_property.get(e["property"], 0.0) + e["value"]
	for obj in _base:
		for field: String in _base[obj]:
			obj.set(field, _base[obj][field])
		for property: String in combined.get(obj, {}):
			var spec: Dictionary = PROPERTIES[property]
			var base: Variant = _base[obj][spec["field"]]
			var change: float = combined[obj][property]
			var value := float(base) * change if spec["op"] == Op.MUL else float(base) + change
			value = clampf(value, spec["min"], spec.get("max", INF))
			obj.set(spec["field"], roundi(value) if base is int else value)
