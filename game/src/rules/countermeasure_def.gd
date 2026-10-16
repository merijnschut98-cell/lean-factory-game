class_name CountermeasureDef
extends RefCounted
## A countermeasure from the content: what it costs (improvement budget in
## euros and team hours), what it changes in the simulation once it works,
## and how well it works at each maturity gap.

## What a countermeasure can open in the game (mirrored in build_content.py).
const UNLOCKS: Array[String] = [KpiBoard.UNLOCK]

var id: String
var name: String
## 1–4: the maturity a region needs to sustain it.
var tier: int
var category: String
var budget: int
## pool id → hours the team spends on the improvement (taken from daily work).
var team_hours: Dictionary[String, float] = {}
var effects: Array = []
## Effectiveness at a maturity gap of 0, 1 and 2: {full, reduced, minimal}.
var multipliers: Dictionary = {}
## Days an unsustained fix lasts (see Sustain.base_days; -1: built in, it
## lasts about a year).
var decay_days := -1
## A board or dashboard the teams look at daily: while it holds, it helps
## sustain the other fixes in its value stream (Sustain, visual_management).
var sustains := false
## What it opens in the game once it works: "" or "kpi_board" (the quarterly
## KPI review of the departments).
var unlocks := ""
## Path dependence: the facts it needs (Facts.met: {all, any, none}), and the
## hint shown while they are not met ("niet voorbereid"): a place or a team,
## never the route.
var needs: Dictionary = {}
var preparation := ""
## A fix that does not respect people: team → trust change at the Act
## (tier-2 draft §0.1).
var trust: Dictionary = {}
## The later cost of a short-term fix (tier-2 draft §0.1): {after_days, days,
## effects, cost}: `after_days` after the Act its effects run for `days` and
## `cost` is paid.
var aftermath: Dictionary = {}
var error := ""


static func from_dict(d: Dictionary) -> CountermeasureDef:
	var c := CountermeasureDef.new()
	c.id = d.get("id", "")
	c.name = d.get("name", "")
	if c.id.is_empty() or c.name.is_empty():
		c.error = "countermeasure %s: needs an id and a name" % c.id
		return c
	var m: Variant = d.get("multipliers")
	if not (m is Dictionary and m.has("full") and m.has("reduced") and m.has("minimal")):
		c.error = "countermeasure %s: 'multipliers' needs full, reduced and minimal" % c.id
		return c
	c.multipliers = m
	c.tier = int(d.get("tier", 1))
	c.category = d.get("category", "")
	c.budget = int(d.get("budget", 0))
	var hours: Dictionary = d.get("team_hours", {})
	for pool: String in hours:
		c.team_hours[pool] = float(hours[pool])
	c.effects = d.get("effects", []).duplicate(true)
	c.decay_days = int(d["decay_days"]) if d.get("decay_days") != null else -1
	c.unlocks = str(d.get("unlocks", ""))
	c.needs = JsonFile.dict_or_empty(d.get("needs")).duplicate(true)
	c.preparation = str(d.get("preparation", ""))
	c.trust = JsonFile.dict_or_empty(d.get("trust")).duplicate()
	c.aftermath = JsonFile.dict_or_empty(d.get("aftermath")).duplicate(true)
	if not d.get("sustains", false) is bool:
		c.error = "countermeasure %s: 'sustains' must be true or false" % c.id
		return c
	c.sustains = d.get("sustains", false)
	if not c.unlocks.is_empty() and not UNLOCKS.has(c.unlocks):
		c.error = "countermeasure %s: 'unlocks' must be one of %s" % [c.id, UNLOCKS]
	return c
