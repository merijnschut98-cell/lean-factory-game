class_name DialogDef
extends RefCounted
## One conversation from content/dialogs.yaml: who it is with, when it can be
## had (a mission's, or a check-in's trigger), what the person says (position,
## layers, replies) and what can be put on the table. No field marks a reply
## or a proposal right; the rules (Dialog) judge each move.
## Validated by tools/build_content.py; this only refuses what would break the
## rules.

var id: String
var name: String
var person: String
## persuade | checkin | expert (Dialog.KINDS)
var kind: String
## persuade: available while this mission is active.
var mission: String
## Missions during which the talk stays open too (an optional talk over
## several days: Rachid, Tuesday to Thursday).
var also_during := PackedStringArray()
## A clue id ("problem:index") that opens the talk once found; "" for none.
var requires_clue: String
## Further conditions (needs_met); {} for none.
var needs: Dictionary = {}
## The problem whose fix this person owns (buy-in, People.buy_in); "".
var owns: String
## The team whose KPI menu the proposals come from; "".
var kpi_team: String
## The scene's mood for the first talk; "" for the day's own.
var mood: String
## Moves before the person has to go; -1: the default (Dialog.patience_for).
var patience := -1
var opening: String
## Said instead of the opening when this talk was had before; "" for none.
var retry_opening: String
## {text, tags}
var position: Dictionary = {}
## [{id: interest | concern, at, via, text, tags, lead_in?, condition?, unlocks?}]
var layers: Array = []
## Clue ids that land when shown at the right moment.
var data := PackedStringArray()
## [{id, name, text, kpis?, addresses, reply, hidden?}]
var proposals: Array = []
## [{id, name, text, addresses, reply?}]
var experiments: Array = []
## {id (a hidden proposal), text}: their own idea, in "Denkt mee"; {} for none.
var co_proposal: Dictionary = {}
## What upgrades an agreement under condition to commitment; {} for none.
var condition_needs: Dictionary = {}
## {text, routes: [{needs, hint}]}; {} for none.
var block: Dictionary = {}
## Overrides of the bank: move → the player's line; move → {situation: {text, tags}}; outcome → text.
var lines: Dictionary = {}
var replies: Dictionary = {}
var outcomes: Dictionary = {}
## [{needs, mood?, position?, layers?}]: fact-keyed versions (the first met wins).
var variants: Array = []
## checkin: {morale_below?, needs?, beat?, after_days?} (beat: a dated beat,
## Missions.beats; the talk opens after_days after it)
var trigger: Dictionary = {}
## persuade: [{when (a fact atom), text}]: what the person says once, after a
## partial agreement, when `when` comes true (the upgrade is felt; audit C15).
var beats_after: Array = []
## A first talk (Act 0): it cannot be ruined (Dialog.TUTORIAL_PATIENCE).
var tutorial := false
## A tutorial talk's moves of the day (Ruud's morning card): a good way
## through, never the only one.
var teaches := PackedStringArray()
## A check-in's line on the dagstart while its prompt is open ("Ahmed is stil
## sinds Henk weg is."); "" for none.
var prompt: String
## What the person says the first time a talk falls into "Dicht" (R-D3); "" for none.
var warning: String
## The person's need for this one scene (Dialog.NEEDS); "" for their own.
var need: String
## expert: what the player can ask, in order (ExpertTalk): [{id, ask (the
## player's question), answer (in the expert's voice), needs? (a needs
## expression), trust? (0–100 it waits for), unlocks? ({clue?, explainer?,
## facts?})}].
var topics: Array = []
## expert: what they say when the player rounds off.
var closing: String
var error := ""


static func from_dict(d: Dictionary) -> DialogDef:
	var g := DialogDef.new()
	g.id = str(d.get("id", ""))
	g.name = str(d.get("name", ""))
	g.person = str(d.get("person", ""))
	g.kind = str(d.get("kind", ""))
	g.mission = str(d.get("mission", ""))
	g.requires_clue = str(d.get("requires_clue", "")) if d.get("requires_clue") != null else ""
	g.owns = str(d.get("owns", ""))
	g.kpi_team = str(d.get("kpi_team", ""))
	g.mood = str(d.get("mood", ""))
	g.patience = int(d.get("patience", -1))
	g.opening = str(d.get("opening", ""))
	g.retry_opening = str(d.get("retry_opening", ""))
	g.prompt = str(d.get("prompt", ""))
	g.warning = str(d.get("warning", ""))
	g.need = str(d.get("need", ""))
	g.closing = str(d.get("closing", ""))
	g.data = PackedStringArray(d.get("data", []))
	g.tutorial = d.get("tutorial", false) == true
	g.teaches = PackedStringArray(d.get("teaches", []))
	g.also_during = PackedStringArray(d.get("also_during", []) if d.get("also_during") is Array else [])
	for key: String in ["needs", "position", "co_proposal", "condition_needs", "block", "lines", "replies", "outcomes", "trigger"]:
		g.set(key, JsonFile.dict_or_empty(d.get(key)).duplicate(true))
	for key: String in ["layers", "proposals", "experiments", "variants", "beats_after", "topics"]:
		var items: Variant = d.get(key, [])
		g.set(key, items.filter(func(i: Variant) -> bool: return i is Dictionary).duplicate(true) if items is Array else [])
	if g.id.is_empty() or g.person.is_empty():
		g.error = "dialog %s: needs an id and a person" % g.id
	elif not g.kind in Dialog.KINDS:
		g.error = "dialog %s: unknown kind %s" % [g.id, g.kind]
	elif g.kind == ExpertTalk.KIND:
		g.error = _topics_error(g)
	elif g.layers.map(func(l: Dictionary) -> Variant: return l.get("id")) != ["interest", "concern"]:
		g.error = "dialog %s: needs the layers interest, then concern" % g.id
	elif str(g.position.get("text", "")).is_empty():
		g.error = "dialog %s: needs a position" % g.id
	elif not g.layers.all(func(l: Dictionary) -> bool: return (l.get("at") is int or l.get("at") is float) and l.get("via") is Array):
		g.error = "dialog %s: every layer needs a threshold (at) and its ways in (via)" % g.id
	elif not (g.proposals + g.experiments).all(func(i: Dictionary) -> bool: return i.get("id") is String):
		g.error = "dialog %s: every proposal and experiment needs an id" % g.id
	return g


## An expert talk's topics: at least one, each with an id, a question and an answer.
static func _topics_error(g: DialogDef) -> String:
	if g.topics.is_empty():
		return "dialog %s: an expert talk needs topics" % g.id
	for t: Dictionary in g.topics:
		if not (t.get("id") is String and t.get("ask") is String and t.get("answer") is String):
			return "dialog %s: every topic needs an id, an ask and an answer" % g.id
	return ""


## A topic by id; {} when there is none.
func topic(topic_id: String) -> Dictionary:
	for t: Dictionary in topics:
		if t.get("id") == topic_id:
			return t
	return {}


## The version a talk uses given the facts: the first variant whose needs are
## met, or -1 for the dialog as written.
func version(facts: Dictionary) -> int:
	for i in variants.size():
		if needs_met(variants[i].get("needs", {}), facts):
			return i
	return -1


## The layers, position and scene mood of a version (a variant falls back to
## the dialog's own for what it does not change).
func layers_of(v: int) -> Array:
	return variants[v].get("layers", layers) if v >= 0 else layers


func position_of(v: int) -> Dictionary:
	return variants[v].get("position", position) if v >= 0 else position


func mood_of(v: int) -> String:
	return str(variants[v].get("mood", mood)) if v >= 0 else mood


## A proposal or experiment by id; {} when there is none.
func item(item_id: String) -> Dictionary:
	for i: Dictionary in proposals + experiments:
		if i.get("id") == item_id:
			return i
	return {}


## Whether a needs expression ({all?, any?, none?}; Facts, the catalogue's
## C19) holds for `facts` (atom → true: GameSession asks Missions.knows for
## the world's, People adds the talks'). An empty expression holds.
static func needs_met(expr: Dictionary, facts: Dictionary) -> bool:
	return Facts.met(expr, func(atom: String) -> bool: return facts.has(atom))
