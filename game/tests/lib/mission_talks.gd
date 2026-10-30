class_name MissionTalks
## Have the talks a mission needs (MissionDef.talk_goals) as a listening player would:
## the autoplay talker's moves, one try a day, until each is met. For tests that play a
## mission end to end on the real content.

const Autoplay := preload("res://tools/autoplay.gd")
const MAX_DAYS := 8


## A talker bound to session `s` (its record ready for talks).
static func listener(s: GameSession, persona := "talker"):
	var bot = Autoplay.Persona.new(persona, 11)
	bot.s = s
	bot.record = {"talks": [], "refusals": [], "assisted": []}
	return bot


## Talk until mission `id` needs no more talks (or MAX_DAYS passed). Returns whether it
## needs none now.
static func win(s: GameSession, id: String) -> bool:
	var bot = listener(s)
	var m: MissionDef = s.missions.defs[id]
	for day in MAX_DAYS:
		var needed := s.missions.pending_talk(m)
		if needed.is_empty():
			return true
		bot._converse(s.people.dialogs[needed])
		if not s.missions.pending_talk(m).is_empty():
			s.wait_days(1.0)
	return s.missions.pending_talk(m).is_empty()
