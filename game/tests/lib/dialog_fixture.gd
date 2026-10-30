class_name DialogFixture
## A small dialog in the shape of content/dialogs.yaml, with a bank whose
## reply tags the tests control (the real bank is content and may change).


static func bank() -> Dictionary:
	var player := {}
	var chips := {}
	for move: String in Dialog.MOVES:
		player[move] = "speler " + move
		chips[move] = "chip " + move
	player["show_data"] += " " + Dialog.DATA_TOKEN
	var replies := {}
	for move: String in ["mood", "open_question", "reflect", "empathy", "paraphrase", "inquiry", "experience", "silence",
			"perspective", "show_data", "propose_experiment"]:
		replies[move] = {"lands": {"text": move + " landt"}, "misses": {"text": move + " mist"}}
	replies["mood"]["lands"]["tags"] = ["feeling"]
	replies["open_question"]["lands"]["tags"] = ["claim"]
	for move: String in ["pressure", "confront", "repair"]:
		replies[move] = {"lands": {"text": move + " landt"}}
	var outcomes := {}
	var outcome_labels := {}
	for outcome: String in Dialog.OUTCOMES:
		outcomes[outcome] = "uitkomst " + outcome
		outcome_labels[outcome] = "label " + outcome
	var wear_out := {}
	for archetype: String in Dialog.ARCHETYPES:
		wear_out[archetype] = {"ask": archetype + " vraagt", "say": archetype + " zegt"}
	var ruud_names := {"none": "niets {person}", "week_end": "weekend"}
	for move: String in Dialog.LISTEN:
		ruud_names[move] = "naam %s {person}" % move
	return {
		"wear_out": wear_out, "ruud_names": ruud_names,
		"labels": {"bands": ["Dicht", "Op z'n hoede", "Luistert", "Open", "Denkt mee"], "cue": "Er zit meer achter…",
			"chips": chips, "outcomes": outcome_labels},
		"player": player, "replies": replies, "outcomes": outcomes,
		"coach": {"questions": ["Wat wilde je dat {person} dacht?", "Waar veranderde het?"],
			"after": {"pressure": "{person} zei ja. En het gezicht?", "ruined": "Wie praatte er?",
				"blocked": "Wie kan het wel beslissen?", "commitment": "Wiens idee was het?"}},
		"special": {"no_repair": "niets te herstellen", "repeat": "herhaling", "refusal": "weigering", "no_proposal": "geen voorstel", "other_data": "En?",
			"lucky_guess": "Hm. Misschien.", "patience_low": "Ik heb nog vijf minuten.", "cooling_down": "Niet nu.",
			"lead_in_again": "Weet je, van daarnet…", "proposal_again": "Daar denk ik over na."},
	}


static func dialog_data(extra: Dictionary = {}) -> Dictionary:
	var d := {
		"id": "talk", "name": "Een gesprek", "person": "pim", "kind": "persuade", "mission": "fix_design",
		"owns": "custom_design", "kpi_team": "prep", "opening": "Opening.", "retry_opening": "Jij weer.",
		"position": {"text": "Positie.", "tags": ["claim"]},
		"layers": [
			{"id": "interest", "at": 55, "via": ["inquiry", "open_question", "paraphrase"], "text": "Belang.",
				"tags": ["claim", "feeling"]},
			{"id": "concern", "at": 70, "via": ["silence", "reflect", "empathy", "inquiry"],
				"lead_in": {"text": "En…", "tags": ["hesitation"]}, "text": "Zorg.", "tags": ["admission"],
				"condition": "Als de baas het goedvindt.",
				"unlocks": {"clue": "custom_design:5", "facts": ["heard:talk"], "proposals": ["secret"]}},
		],
		"data": ["custom_design:0"],
		"proposals": [
			{"id": "good", "name": "Goed", "text": "Voorstel goed.", "kpis": ["prep_output"], "addresses": ["concern"],
				"reply": "Dat helpt."},
			{"id": "bare", "name": "Kaal", "text": "Voorstel kaal.", "addresses": [], "reply": "Bezwaar."},
			{"id": "secret", "name": "Geheim", "text": "Samen.", "hidden": true, "addresses": ["concern"],
				"reply": "Samen dan."},
		],
		"experiments": [{"id": "trial", "name": "Proef", "text": "Een proef.", "addresses": ["concern"]}],
		"co_proposal": {"id": "secret", "text": "Ons eigen idee."},
		"outcomes": {"ruined": "Klaar."},
	}
	d.merge(extra, true)
	return d


static func def(extra: Dictionary = {}) -> DialogDef:
	return DialogDef.from_dict(dialog_data(extra))


## A check-in with the same person: no mission, opened by low morale.
static func checkin(extra: Dictionary = {}) -> DialogDef:
	var data := dialog_data({"id": "checkin", "kind": "checkin", "trigger": {"morale_below": 50}})
	for key in ["mission", "owns", "kpi_team", "condition_needs", "co_proposal", "data"]:
		data.erase(key)
	data.merge(extra, true)
	return DialogDef.from_dict(data)


static func people(defs: Array = [def()], who: Array = [person()]) -> People:
	var d: Array[DialogDef] = []
	d.assign(defs)
	var p: Array[PersonDef] = []
	p.assign(who)
	return People.new(p, d, bank())


## What People needs to know about the world when a talk starts.
static func world(extra: Dictionary = {}) -> Dictionary:
	var w := {"main": ["fix_design"], "active": ["fix_design"], "found": {"custom_design:0": true}, "facts": {},
		"problems": {"custom_design": true}, "team_trust": 0, "blamed": false, "now": 0}
	w.merge(extra, true)
	return w


static func person(archetype: String = "defender", trust: int = 50, morale: int = 50, need: String = "") -> PersonDef:
	return PersonDef.from_dict({"id": "pim", "name": "Pim", "role": "teamleider", "place": "connections.design",
		"team": "prep", "archetype": archetype, "trust": trust, "morale": morale, "need": need})


## A conversation at `openness` (the default start state otherwise).
static func talk(openness: int = 35, start: Dictionary = {}, d: DialogDef = def(), who: PersonDef = person()) -> Dialog:
	var s := {"openness": openness, "trust": who.trust, "mood": "neutraal", "found": {"custom_design:0": true,
		"custom_design:1": true}, "facts": {}, "retry": false, "version": -1, "revealed": {}}
	s.merge(start, true)
	return Dialog.new(d, who, bank(), s)


## Play moves in order (a move "propose:good" picks "good", "show_data:p:0"
## picks clue "p:0"); returns the last result. A refused move is a test error.
static func play(d: Dialog, moves: Array) -> Dictionary:
	return play_with(func(move: String, pick: String) -> Dictionary: return d.say(move, pick), moves)


## play() through any `say(move, pick)`, e.g. GameSession.choose_move.
static func play_with(say: Callable, moves: Array) -> Dictionary:
	var result := {}
	for m: String in moves:
		var colon := m.find(":")
		result = say.call(m.left(colon) if colon >= 0 else m, m.substr(colon + 1) if colon >= 0 else "")
		if result.has("error"):
			push_error("move %s refused: %s" % [m, result["error"]])
	return result
