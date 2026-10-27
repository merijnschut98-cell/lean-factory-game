class_name Objective
## The objective line (PLAN 2.13 C; Merijn's playtest, 2026-10-19): the next concrete
## step of the training day or the main mission, short and in-world ("Kijk bij Intake
## hoe een aanvraag binnenkomt", "Praat met Anouk (Werkvoorbereiding)"). Derived from the
## goal and its progress, never stored; a mission's `steps:` (content/missions.yaml) word
## its own steps, the rest take DEFAULTS. It names where and with whom, never a tool, a
## problem or a countermeasure, and never what is wrong: the how is the player's. The
## minimap marker points at the same place (MinimapTargets reads step()).
##
## A step: {mission, step (a STEPS key), text, and where: place ("stream.step") |
## person (id) | desk (true: your desk at Aansluitingen) | obeya (true)}. No step: {}.
## PLAN 2.10: the A3 is written at your desk; the Check is read, and the Act decided, at
## Petra's screen at Meetdata (CHECK_PERSON; the obeya wall when she is not in the content).

## The line stays one short line on the HUD (build_content.py MAX_STEP_CHARS).
const MAX_CHARS := 60
## No main mission and no training day: the board is where the next one waits.
const BOARD_TEXT := "Kies je volgende opdracht op het missiebord"
## The first day's walk (Opening.WALK): Ruud leads.
const FOLLOW_TEXT := "Loop met Ruud mee"
## Home time (UX audit #18): from HOME_FROM through the night until HOME_UNTIL the front door
## offers going home (OfficeHome) and the HUD's line says so (line): under the step as
## HOME_HINT, or HOME_TEXT alone when there is no step. The step itself (of) never changes
## with the hour: the phone's Missions card and the minimap read it.
const HOME_FROM := 17 * 60
const HOME_UNTIL := 7 * 60
const HOME_TEXT := "Tijd om naar huis te gaan (voordeur, begane grond)"
const HOME_HINT := "Na vijven: naar huis via de voordeur, begane grond"
## Each step's default text: {team} the team at the place (or the person's), {naam} the
## person. A mission's `steps:` override any of them.
const DEFAULTS := {
	"look": "Ga kijken bij {team}",
	"again": "Kijk nog eens bij {team}, op een andere manier",
	"dig": "Zoek uit wat er speelt bij {team}",
	"a3": "Schrijf je A3 aan je bureau",
	"wait": "Kijk hoe je experiment loopt bij {team}",
	"check": "Bekijk de Check op het scherm van {naam}",
	"act": "Beslis bij het scherm van {naam} hoe je verdergaat",
	"talk": "Praat met {naam} ({team})",
	"go": "Je wordt verwacht",
}
## `go`: a scene milestone's way to the room its scene plays in (content words it).
const STEPS: Array[String] = ["look", "again", "dig", "a3", "wait", "check", "act", "talk", "go"]
## A talk the mission needs (MissionDef.talk_goals) comes once the player has looked: it
## takes the place of these steps ("" when the goal is met and only the talk is left), so
## the person is met before the digging (phase-2 design §3.4). The Check and the Act at
## Petra's screen stay first.
const TALK_BEFORE: Array[String] = ["dig", "a3", "wait", ""]
## Key clues found before the A3 becomes the next step (or all of them, when fewer).
const A3_CLUES := 2
## Whose screen the Check is read at: Petra keeps the stream's numbers (Meetdata).
const CHECK_PERSON := "petra"

const P := ProblemState.Phase


## The objective now: the training day's step, else a scene milestone's (the story's
## moment waits in its room), else the (first) main mission's, else the board when a
## mission waits there; {} when there is nothing to do. During the first day's scene
## (`layer`, Opening) only the walk behind Ruud has a line.
static func of(s: GameSession, layer: SessionLayer = null) -> Dictionary:
	if layer != null and Opening.running(layer):
		return {"step": "follow", "text": FOLLOW_TEXT} if layer.opening_beat == Opening.WALK else {}
	var leading := s.missions.active("training")
	leading.append_array(s.missions.active("milestone").filter(func(m: MissionDef) -> bool: return m.goal_type == "scene"))
	leading.append_array(s.missions.active("main"))
	if not leading.is_empty():
		return step(leading[0], s)
	return {"step": "board", "text": BOARD_TEXT} if not s.available_missions().is_empty() else {}


## Whether `minute` of the day is home time: the evening and the night (HOME_FROM–HOME_UNTIL).
static func home_time(minute: int) -> bool:
	return minute >= HOME_FROM or minute < HOME_UNTIL


## The HUD's objective line: the step's text, and in home time (not in the first day's
## scene) the home hint under it, or the home line alone when there is no step.
static func line(s: GameSession, layer: SessionLayer = null) -> String:
	var step := str(of(s, layer).get("text", ""))
	return step if layer != null and Opening.running(layer) else with_home(step, s.minute_of_day())


## `step`'s line at `minute`: in home time the hint under it, or HOME_TEXT for no step.
static func with_home(step: String, minute: int) -> String:
	if not home_time(minute):
		return step
	return HOME_TEXT if step.is_empty() else step + "\n" + HOME_HINT


## Mission `m`'s next step (see the class doc). `reachable(place) -> bool`, when given,
## skips a walk's steps the player cannot get to (the minimap: a step in no room).
static func step(m: MissionDef, s: GameSession, reachable := Callable()) -> Dictionary:
	var out := _where(m, s, reachable)
	var talk := s.missions.pending_talk(m)
	if not talk.is_empty() and out.get("step", "") in TALK_BEFORE:
		out = _talk(s, talk)
	if out.is_empty() and not m.ends_with_talk.is_empty() and not s.talked(m.ends_with_talk):
		out = _talk(s, m.ends_with_talk)
	if out.is_empty():
		return {}
	out["mission"] = m.id
	out["text"] = _text(m, s, out)
	return out


static func _where(m: MissionDef, s: GameSession, reachable: Callable) -> Dictionary:
	match m.goal_type:
		"talk_to":
			return _talk(s, m.goal_dialog)
		"walk":
			var stream := s.region.net.stream(m.goal_stream)
			for st in stream.steps if stream != null else []:
				var place := m.goal_stream + "." + st.id
				if st.kind == SimStep.Kind.WORK and not s.region.observed.has(place) \
						and (not reachable.is_valid() or reachable.call(place)):
					return {"step": "look", "place": place}
		"observe":
			var seen: Dictionary = s.missions.progress.get(m.id, {}).get("seen", {})
			for place in m.goal_places:
				if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
					return {"step": "look", "place": place}
			if seen.size() < m.goal_uses and not m.goal_places.is_empty():
				return {"step": "again", "place": m.goal_places[0]}
		"investigate", "solve", "check", "rework_fix", "sustain":
			return _problem_step(m, s)
		"scene":
			var scene: Dictionary = s.catalog.scenes.get(m.scene, {})
			return {"step": "go", "room": scene["room"]} if scene.has("room") else {}
	return {}


## Where a problem's mission stands in the PDCA loop: go and see, dig, the A3, the
## experiment running, the Check, the Act.
static func _problem_step(m: MissionDef, s: GameSession) -> Dictionary:
	var st: ProblemState = s.region.state.get(m.goal_problem)
	var p: ProblemDef = s.region.problems.get(m.goal_problem)
	if st == null or p == null:
		return {}
	match st.phase:
		P.SPOTTED:
			var keys := p.clues.filter(func(c: Clue) -> bool: return c.key).size()
			if m.goal_type != "investigate" and s.region.key_clues_found(p.id) >= mini(A3_CLUES, keys):
				return {"step": "a3", "desk": true}
			return {"step": "dig", "place": p.step}
		P.DOING:
			return {"step": "wait", "place": p.step}
		P.CHECK_READY:
			return _at_check_screen(s, "check")
		P.CHECKED:
			return _at_check_screen(s, "act")
		P.RESOLVED:
			return {}
	return {"step": "look", "place": p.step}


## The Check's step at Petra's screen; at the obeya wall when she is not in the content.
static func _at_check_screen(s: GameSession, step: String) -> Dictionary:
	return {"step": step, "person": CHECK_PERSON} if s.people.persons.has(CHECK_PERSON) else {"step": step, "obeya": true}


static func _talk(s: GameSession, dialog_id: String) -> Dictionary:
	var d: DialogDef = s.people.dialogs.get(dialog_id)
	return {"step": "talk", "person": d.person} if d != null and s.people.persons.has(d.person) else {}


## The step's text: the mission's own (for `look`, per place when it maps them), else the
## default, its tokens filled.
static func _text(m: MissionDef, s: GameSession, where: Dictionary) -> String:
	var own: Variant = m.steps.get(where["step"])
	if own is Dictionary:
		own = own.get(where.get("place", ""))
	var text: String = own if own is String and not own.is_empty() else DEFAULTS[where["step"]]
	var who: PersonDef = s.people.persons.get(where.get("person", ""))
	return text.replace("{team}", _team(s, where, who)).replace("{naam}", who.short if who != null else "")


## The team's short name ("Intake", "Werkvoorbereiding") at the step's place, or the
## person's team. A wait has no team: the work waits for the next team on the stream.
static func _team(s: GameSession, where: Dictionary, who: PersonDef) -> String:
	var pools := s.region.net.pools
	if who != null and pools.has(who.team):
		return _short(pools[who.team].name)
	var place: String = where.get("place", who.place if who != null else "")
	var at := s.region.net.step_at(place)
	var stream := s.region.net.stream(place.get_slice(".", 0))
	if at == null or stream == null:
		return ""
	for st in stream.steps.slice(stream.steps.find(at)):
		if not st.pool_ids.is_empty() and pools.has(st.pool_ids[0]):
			return _short(pools[st.pool_ids[0]].name)
	return _short(at.name)


## "Intake & aanvraagbeheer" → "Intake", "Storingsdienst (consignatie)" → "Storingsdienst".
static func _short(team: String) -> String:
	return team.get_slice(" & ", 0).get_slice(" (", 0)
