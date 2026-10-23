class_name KpiDef
extends RefCounted
## One KPI from content/kpis.yaml: what a department can be steered by, and
## the work rules it sets for the team (start, order and/or care). Leading
## KPIs say what the team controls today; lagging KPIs report the result.

const KINDS := ["leading", "lagging"]
## What a team's care can be: "normal" is the habit (see KpiMenu.care).
const CARE_RULES := ["normal", "careful", "hasty"]
## A KPI's rule → the values it may take.
const RULES := {"start": SimPool.START_RULES, "order": SimPool.ORDER_RULES, "care": CARE_RULES}
## What a KPI asks of a team (content/kpis.yaml `focus`; never shown): the board's
## choice is the fact steers:<focus> (KpiMenu.steers).
const FOCI: Array[String] = ["output", "flow", "customer"]

var id: String
var name: String
## The department (pool id) this KPI belongs to.
var pool: String
var kind: String
## Rule → value, each optional: {start, order, care}.
var rules: Dictionary = {}
var note: String
## output | flow | customer; "" when the content names none (a test's menu).
var focus := ""
## The number the board writes on its card (KpiReading.MEASURES), and where it is
## measured: a stream id, a place, or "" for the KPI's own team.
var measure := ""
var at := ""
## Why the definition is unusable; "" when fine.
var error := ""


static func from_dict(d: Dictionary) -> KpiDef:
	var k := KpiDef.new()
	k.id = str(d.get("id", ""))
	k.name = str(d.get("name", ""))
	k.pool = str(d.get("pool", ""))
	k.kind = str(d.get("kind", ""))
	k.note = str(d.get("note", ""))
	k.focus = str(d.get("focus", ""))
	k.measure = str(d.get("measure", ""))
	k.at = str(d.get("at", ""))
	if k.id.is_empty() or k.name.is_empty() or k.pool.is_empty():
		k.error = "kpi %s: needs an id, a name and a pool" % k.id
		return k
	if not k.kind in KINDS:
		k.error = "kpi %s: 'kind' must be one of %s" % [k.id, KINDS]
		return k
	if not k.focus.is_empty() and not k.focus in FOCI or not k.measure.is_empty() and not k.measure in KpiReading.MEASURES:
		k.error = "kpi %s: 'focus' must be one of %s, 'measure' one of %s" % [k.id, FOCI, KpiReading.MEASURES]
		return k
	var rules := JsonFile.dict_or_empty(d.get("rules"))
	for rule: String in rules:
		if not RULES.has(rule) or not rules[rule] in RULES[rule]:
			k.error = "kpi %s: rule %s=%s is not one of %s" % [k.id, rule, rules[rule], RULES.get(rule, [])]
			return k
		k.rules[rule] = rules[rule]
	return k
