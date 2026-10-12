class_name ProblemDef
extends RefCounted
## A problem from the content: where it shows, what it does to the simulation,
## its hidden root cause, the clues that lead there, and the countermeasures
## that help. Several countermeasures can help, each with its own fit (0–1):
## there is rarely one right answer, but some improve more than others.

const SEVERITIES := ["low", "medium", "high", "critical"]
const VISIBILITIES := ["obvious", "subtle", "hidden"]

var id: String
var tier: int
var name: String
## Where the problem shows: "stream.step".
var step: String
var waste: String
var severity: String
var visibility: String
## The KPI it hurts most (what a good prediction names).
var kpi: String
var root_cause: String
var plausible_causes: PackedStringArray
## countermeasure id → fit (0–1).
var countermeasures: Dictionary[String, float] = {}
var mismatch_note: String
var effects: Array = []
## Euros it costs every week while active (overtime, damage repairs, claims).
var cost_per_week := 0
var teaches: PackedStringArray
var clues: Array[Clue] = []
## Why the definition is unusable; "" when fine.
var error := ""


static func from_dict(d: Dictionary) -> ProblemDef:
	var p := ProblemDef.new()
	for key in ["id", "name", "step", "waste", "severity", "visibility", "kpi", "root_cause"]:
		if not d.get(key) is String or d[key].is_empty():
			p.error = "problem %s: '%s' must be a non-empty string" % [d.get("id", "?"), key]
			return p
	p.id = d["id"]
	p.tier = int(d.get("tier", 1))
	p.name = d["name"]
	p.step = d["step"]
	p.waste = d["waste"]
	p.severity = d["severity"]
	p.visibility = d["visibility"]
	p.kpi = d["kpi"]
	p.root_cause = d["root_cause"]
	p.plausible_causes = PackedStringArray(d.get("plausible_causes", []))
	p.mismatch_note = d.get("mismatch_note", "")
	p.effects = d.get("effects", []).duplicate(true)
	p.cost_per_week = int(d.get("cost_per_week", 0))
	p.teaches = PackedStringArray(d.get("teaches", []))
	var fits: Dictionary = d.get("countermeasures", {})
	for cm: String in fits:
		p.countermeasures[cm] = float(fits[cm])
	for i in d.get("clues", []).size():
		var c: Dictionary = d["clues"][i]
		var clue := Clue.new()
		clue.id = "%s:%d" % [p.id, i]
		clue.tool = c.get("tool", "")
		clue.text = c.get("text", "")
		clue.key = bool(c.get("key", false))
		clue.depth = int(c.get("depth", 0))
		clue.at = c.get("at", p.step)
		clue.note = c.get("note", "")
		clue.teaches = PackedStringArray(c.get("teaches", []))
		if not Investigation.TOOLS.has(clue.tool):
			p.error = "problem %s clue %d: unknown tool %s" % [p.id, i, clue.tool]
		p.clues.append(clue)
	if not p.waste in Investigation.WASTES:
		p.error = "problem %s: unknown waste %s" % [p.id, p.waste]
	elif not p.severity in SEVERITIES or not p.visibility in VISIBILITIES or not p.kpi in Investigation.KPIS:
		p.error = "problem %s: unknown severity, visibility or kpi" % p.id
	return p


func stream_id() -> String:
	return step.get_slice(".", 0)

