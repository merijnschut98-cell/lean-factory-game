class_name PersonDef
extends RefCounted
## One person of the recurring cast (content/dialogs.yaml `people`): who they
## are, where the player finds them, their team, how they tend to respond (the
## archetype, never shown) and where trust and morale start.

var id: String
var name: String
var role: String
## The work step where the player finds them ("stream.step").
var place: String
## Their pool id: team trust, and the team a blame hits.
var team: String
var archetype: String
## What they need from a talk (Dialog.NEEDS; "" for none): hidden, it weighs
## how each move lands (person-needs spec §1).
var need: String
## 0–100: trust in the player, and enthusiasm for the work, at the start.
var trust := 50
var morale := 60
var voice: String
## How others name them in a line ("Joost", "mevrouw El Amrani"); the first
## word of the name when the content gives none.
var short: String
var error := ""


static func from_dict(d: Dictionary) -> PersonDef:
	var p := PersonDef.new()
	p.id = str(d.get("id", ""))
	p.name = str(d.get("name", ""))
	p.role = str(d.get("role", ""))
	p.place = str(d.get("place", ""))
	p.team = str(d.get("team", ""))
	p.archetype = str(d.get("archetype", ""))
	p.need = str(d.get("need", ""))
	p.trust = clampi(int(d.get("trust", 50)), 0, 100)
	p.morale = clampi(int(d.get("morale", 60)), 0, 100)
	p.voice = str(d.get("voice", ""))
	p.short = str(d.get("short", p.name.get_slice(" ", 0)))
	if p.id.is_empty() or p.name.is_empty() or p.place.is_empty():
		p.error = "person %s: needs an id, a name and a place" % p.id
	elif not p.archetype in Dialog.ARCHETYPES:
		p.error = "person %s: unknown archetype %s" % [p.id, p.archetype]
	elif not (p.need.is_empty() or p.need in Dialog.NEEDS):
		p.error = "person %s: unknown need %s" % [p.id, p.need]
	return p
