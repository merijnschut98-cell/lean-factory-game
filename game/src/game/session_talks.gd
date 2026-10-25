class_name SessionTalks
extends RefCounted
## The talking side of a game (GameSession.talks): what people say in passing (greetings,
## quick lines, coffee chatter; Phase 2 §1.4, §2.4) and the talks with named people, move
## by move (rules/dialog.gd, rules/people.gd; docs/superpowers/specs/2026-10-15-dialog-system-design.md
## §10), expert talks topic by topic. A talk runs with no time passing; when it ends, its
## minutes pass once and what it changed reaches the world (team trust, a blame, a learned
## clue). GameSession forwards its public calls here, passing itself: this helper keeps no
## reference to the session, so the two never hold each other.

## A greeting remembers a talk this many days back (Friday's talk still on Monday).
const GREETING_MEMORY_DAYS := 3
## How full a team's work feels (load_of), from its pool's share of present hours spent
## busy over the last LOAD_DAYS (SimPool.load_since) and its queue in working days
## (Network.queue_days). ESTIMATES for the quick line's tone, read off a fresh game (the
## teams run 0.25-0.98 busy): from 85 % busy, or three days of queue, it feels full; under
## 40 % busy with half a day of queue it feels quiet.
const LOAD_DAYS := 5
const BUSY_SHARE := 0.85
const CALM_SHARE := 0.4
const BUSY_QUEUE_DAYS := 3.0
const CALM_QUEUE_DAYS := 0.5
## Under this morale (0-100) a person's quick line is a tired one (People's own scale: the
## leave clock starts at 20, a friendly week is 55 and up). An ESTIMATE.
const TIRED_MORALE := 40
## The hour bands of a quick line (minutes since midnight): before half eleven is morning,
## from half five it is late.
const MORNING_UNTIL := 11 * 60 + 30
const LATE_FROM := 17 * 60 + 30
## Promise kinds that name a date (content's PROMISE_KINDS); the others are an action.
const DATE_PROMISES: Array[String] = ["delivery_date"]

## The talk in progress, if any.
var talk: Dialog = null
## An expert talk in progress instead (topic by topic, ExpertTalk), if any.
var expert: ExpertTalk = null
## What people said in passing today (Phase 2 §1.4): person id → the day they greeted
## you; "a|b" → the day that pair chatted (saved: passing_to_dict); how many quick lines
## were said (variety).
var _greeted: Dictionary[String, int] = {}
var _chatted: Dictionary[String, int] = {}
var _quick_said := 0


# ── In passing (Phase 2 §1.4, §2.4): greetings, quick lines, coffee chatter ──

## The morning hello of `person_id` by your name, once a day: their line after what
## yesterday left (greeting_fact), else an ordinary morning. "" when they greeted you
## today already or have no greeting.
func greet(s: GameSession, person_id: String) -> String:
	var today := SimCalendar.day_of(s.region.net.time)
	if _greeted.get(person_id, -1) == today:
		return ""
	var line := s.catalog.reactions.greeting(person_id, greeting_fact(s, person_id), hash(person_id) + today)
	if not line.is_empty():
		_greeted[person_id] = today
	return s.fill_tokens(line)


## What a person remembers this morning (one of Reactions.FACTS, or ""): how the last talk
## went when it was on an earlier day, at most GREETING_MEMORY_DAYS ago (a ruined or
## pressured talk first, then an agreement, then being heard), else a fix at their place
## that was standardised that recently.
static func greeting_fact(s: GameSession, person_id: String) -> String:
	var people := s.people
	var region := s.region
	var now := region.net.time
	var log: Array = people.talk_log.get(person_id, [])
	var at := int(log[-1].get("at", -1)) if not log.is_empty() else -1
	var ago := SimCalendar.day_of(now) - SimCalendar.day_of(at)
	if at >= 0 and ago >= 1 and ago <= GREETING_MEMORY_DAYS:
		var flags: Array = people.memory.get(person_id, {}).get("flags", [])
		for flag: String in ["ruined", "pressured"]:
			if flag in flags:
				return flag
		if log[-1].get("outcome") == "commitment":
			return "committed"
		if "heard" in flags:
			return "heard"
	var p: PersonDef = people.persons.get(person_id)
	for problem: ProblemDef in region.problem_list() if p != null else []:
		var st: ProblemState = region.state[problem.id]
		if problem.step == p.place and st.standardised and st.phase == ProblemState.Phase.RESOLVED \
				and now - st.check_at <= SimCalendar.days(GREETING_MEMORY_DAYS):
			return "standardised"
	return ""


## One line about today when there is nothing to discuss (E on a person; no panel): tired
## when their morale is low, else busy or calm by their team's queue, else the hour.
func quick_line(s: GameSession, person_id: String) -> String:
	_quick_said += 1
	var line := s.catalog.reactions.quick_line(person_id, quick_mood(s, person_id), hash(person_id) + _quick_said)
	return s.fill_tokens(line)


## The mood of a quick line now (one of Reactions.MOODS).
static func quick_mood(s: GameSession, person_id: String) -> String:
	if int(s.people.morale.get(person_id, 100)) < TIRED_MORALE:
		return "tired"
	var load := load_of(s, person_id)
	if not load.is_empty():
		return load
	var minute := s.minute_of_day()
	return "morning" if minute < MORNING_UNTIL else ("late" if minute >= LATE_FROM else "afternoon")


## How full their team's work is: busy, calm, or "" (in between, or no team or queue known).
static func load_of(s: GameSession, person_id: String) -> String:
	var net := s.region.net
	var p: PersonDef = s.people.persons.get(person_id)
	var step := net.step_at(p.place) if p != null else null
	if step == null or step.pool_ids.is_empty():
		return ""
	var busy: float = net.pools[step.pool_ids[0]].load_since(SimCalendar.day_of(net.time) - LOAD_DAYS)
	var queue := net.queue_days(step)
	if busy >= BUSY_SHARE or queue >= BUSY_QUEUE_DAYS:
		return "busy"
	return "calm" if busy < CALM_SHARE and queue < CALM_QUEUE_DAYS else ""


## Two colleagues at the coffee corner: their exchange [first line, second line], once a
## day per pair; [] when they chatted today or nothing fits their teams and load.
func chatter(s: GameSession, first: String, second: String) -> Array[String]:
	var now := s.region.net.time
	var today := SimCalendar.day_of(now)
	var pair := first + "|" + second if first < second else second + "|" + first
	var out: Array[String] = []
	if _chatted.get(pair, -1) == today:
		return out
	var persons := s.people.persons
	var teams := [first, second].map(func(id: String) -> String:
		return persons[id].team if persons.has(id) else "")
	var loads := [load_of(s, first), load_of(s, second)]
	var load := "busy" if "busy" in loads else ("calm" if loads.all(func(l: String) -> bool: return l == "calm") else "")
	out = s.catalog.reactions.chatter_for(teams, load, hash(pair) + today,
		SimCalendar.weekday(now - SimCalendar.days(GameSession.WARMUP_DAYS)))
	if not out.is_empty():
		_chatted[pair] = today
	out.assign(out.map(s.fill_tokens))
	return out


## Today's greetings and chatter for the save, so "once a day" survives a reload.
func passing_to_dict() -> Dictionary:
	return {"greeted": _greeted.duplicate(), "chatted": _chatted.duplicate()}


## Restore passing_to_dict() output, untrusted: an entry that is not id → day is
## dropped; junk or an old save without it is nobody greeted yet.
func load_passing(d: Variant) -> void:
	var saved := JsonFile.dict_or_empty(d)
	_greeted = _days_by_id(saved.get("greeted"))
	_chatted = _days_by_id(saved.get("chatted"))


static func _days_by_id(v: Variant) -> Dictionary[String, int]:
	var out: Dictionary[String, int] = {}
	var days := JsonFile.dict_or_empty(v)
	for id: Variant in days:
		if id is String and days[id] is int:
			out[id] = days[id]
	return out


# ── People and their talks ──────────────────────────────────────────────────

## Who could use a talk now, for the dagstart (spec §5.7; at most one by the
## cadence in People): [{person, name, dialog, line}].
static func checkin_prompts(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in s.people.prompt_lines():
		p["name"] = s.people.persons[p["person"]].name
		out.append(p)
	return out


## What the player knows of a person (the journal's Mensen tab): {id, name,
## role, place, trust_pips, morale_band (0 low · 1 middling · 2 high),
## cooldown_until, outcomes (dialog id → its best outcome), observed (what they
## said, newest first: People.observed), talks (newest first: People.talk_log),
## note (the player's own, "" for none), open (_still_open), talk_ready (they
## have a talk for you now)}; {} for an unknown id.
static func person(s: GameSession, person_id: String) -> Dictionary:
	var people := s.people
	var p: PersonDef = people.persons.get(person_id)
	if p == null:
		return {}
	var known := people.facts(facts(s))
	var outcomes := {}
	for d: DialogDef in people.dialogs.values():
		if d.person == person_id and people.outcomes.has(d.id):
			outcomes[d.id] = people.effective_outcome(d.id, known)
	var morale: int = people.morale[person_id]
	return {"id": p.id, "name": p.name, "role": p.role, "place": p.place,
		"trust_pips": floori(people.trust[person_id] / float(Dialog.TRUST_PER_PIP)),
		"morale_band": 0 if morale < 30 else (1 if morale < 70 else 2),
		"cooldown_until": int(people.memory.get(person_id, {}).get("cooldown_until", 0)), "outcomes": outcomes,
		"observed": _filled(s, _newest_first(people.observed.get(person_id, []))),
		"talks": _filled(s, _newest_first(people.talk_log.get(person_id, []))), "note": people.note.get(person_id, ""),
		"open": _still_open(people, person_id, known),
		"talk_ready": not people.cooling_down(person_id, s.region.net.time) and people.dialog_for(person_id, world(s, p)) != null}


## What a person's agreements still wait for (the Mensen tab, U16): [{dialog,
## outcome (partial | blocked), wait_for (a heard concern's condition, else
## ""), hints (a block's route hints)}].
static func _still_open(people: People, person_id: String, known: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: DialogDef in people.dialogs.values():
		var o := people.effective_outcome(d.id, known) if d.person == person_id else ""
		if o == "partial":
			out.append({"dialog": d.id, "outcome": o, "wait_for": _heard_wait_for(people, d), "hints": []})
		elif o == "blocked":
			out.append({"dialog": d.id, "outcome": o, "wait_for": "",
				"hints": d.block.get("routes", []).map(func(r: Dictionary) -> String: return str(r.get("hint", "")))})
	return out


## The concern's `wait_for` of a dialog whose concern the player heard ("" if
## not heard or it names nothing): a condition never shows before its concern.
static func _heard_wait_for(people: People, d: DialogDef) -> String:
	for key: String in people.revealed:
		if key.get_slice("/", 0) == d.id and people.revealed[key].has("concern"):
			var layers := d.layers_of(int(key.get_slice("/", 1)))
			if layers.size() > 1:
				return str(layers[1].get("wait_for", ""))
	return ""


static func _newest_first(entries: Array) -> Array:
	var out := entries.duplicate(true)
	out.reverse()
	return out


## Open the talk a person has for the player: {dialog, kind, person, name, short,
## role, opening, position ({text, tags}), meter, moves}, or an error:
## in_dialog | unknown_person | cooling_down (after a ruined talk; the UI says
## the bank's special.cooling_down line) | nothing_to_say.
func start_dialog(s: GameSession, person_id: String) -> Dictionary:
	if talk != null or expert != null:
		return {"error": "in_dialog"}
	var people := s.people
	var p: PersonDef = people.persons.get(person_id)
	if p == null:
		return {"error": "unknown_person"}
	if people.cooling_down(person_id, s.region.net.time):
		return {"error": "cooling_down"}
	var here := world(s, p)
	var d := people.dialog_for(person_id, here)
	if d == null:
		return {"error": "nothing_to_say"}
	if d.kind == ExpertTalk.KIND:   # topic by topic: no position, no moves (phase 2 design §2.5)
		expert = people.start_expert(d, here)
		return _filled(s, {"dialog": d.id, "kind": d.kind, "person": p.id, "name": p.name, "short": p.short,
			"role": p.role, "opening": people.opening(d), "position": {}, "meter": expert.meter(), "moves": []})
	talk = people.start(d, here)
	return _filled(s, {"dialog": d.id, "kind": d.kind, "person": p.id, "name": p.name, "short": p.short, "role": p.role,
		"opening": people.opening(d, talk.version), "position": talk.position(), "meter": talk.meter(), "moves": talk.moves()})


## The moves of the talk in progress (Dialog.moves); [] when there is none.
func dialog_moves(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if talk != null:
		out.assign(_filled(s, talk.moves()))
	return out


## This turn's sentences in the talk in progress (Dialog.offer: [{move, pick,
## line}], a shown clue's text in its line); [] when there is none.
func dialog_offers(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if expert != null:
		out.assign(_filled(s, expert.offer()))
	if talk != null:
		for o: Dictionary in talk.offer():
			out.append(_filled(s, _with_clue(s, o, o["pick"])))
	return out


## `said` (an offer or a move's result) with the text of the clue it shows
## (`clue_id`) in its line, for Dialog.DATA_TOKEN.
static func _with_clue(s: GameSession, said: Dictionary, clue_id: String) -> Dictionary:
	if said.get("move") != "show_data" or not Dialog.DATA_TOKEN in str(said.get("line", "")):
		return said
	var p: ProblemDef = s.region.problems.get(clue_id.get_slice(":", 0))
	var clues := p.clues.filter(func(c: Clue) -> bool: return c.id == clue_id) if p != null else []
	var text: String = clues[0].text if not clues.is_empty() else ""
	return said.merged({"line": str(said["line"]).replace(Dialog.DATA_TOKEN, text).strip_edges()}, true)


## The meter of the talk in progress (Dialog.meter); {} when there is none.
func dialog_meter() -> Dictionary:
	if expert != null:
		return expert.meter()
	return talk.meter() if talk != null else {}


## The layers of the talk in progress, for the layer tracker: [{id
## (position | interest | concern), text ("" until heard), heard}]; the
## position is heard from the start, a layer from an earlier talk stays heard.
## [] when there is no talk.
func dialog_layers(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if talk == null:
		return out
	out.append({"id": "position", "text": str(talk.position().get("text", "")), "heard": true})
	for layer: Dictionary in talk.layers():
		var heard := talk.revealed.has(layer["id"])
		out.append({"id": str(layer["id"]), "text": str(layer.get("text", "")) if heard else "", "heard": heard})
	out.assign(_filled(s, out))
	return out


## Make a move in the talk (a pick for show_data, propose_experiment and
## propose: one the moves offered). Dialog.say's result; when the talk ended,
## with `summary` (People.finish), and its minutes have passed. Errors:
## no_dialog | unknown_move | bad_pick (and nothing changes).
func choose_move(s: GameSession, move: String, pick: String = "") -> Dictionary:
	if expert != null:
		return _ask_expert(s, move, pick)
	if talk == null:
		return {"error": "no_dialog"}
	var result := talk.say(move, pick)
	if result.get("ended", false):
		result["summary"] = _finish_talk(s)
	return _filled(s, _with_clue(s, result, pick))


## A question in the expert talk (ExpertTalk.ASK with the topic id) or its close
## (ExpertTalk.CLOSE, as "Afronden"): ExpertTalk.say's result. A topic's new
## clue is found at once; when the talk ends, with `summary`
## (People.finish_expert) and its minutes passed.
func _ask_expert(s: GameSession, move: String, pick: String) -> Dictionary:
	var result := expert.say(move, pick)
	if result.has("error"):
		return result
	if not str(result["clue"]).is_empty():
		s.region.found[result["clue"]] = true
	if result["ended"]:
		var t := expert
		expert = null
		result["summary"] = s.people.finish_expert(t, s.region.net.time)
		s._after(t.minutes())
	return _filled(s, result)


## Every text in a talk's result, filled (GameSession.fill_tokens).
static func _filled(s: GameSession, v: Variant) -> Variant:
	if v is String:
		return s.fill_tokens(v)
	if v is Dictionary:
		var d := {}
		for k: Variant in v:
			d[k] = _filled(s, v[k])
		return d
	if v is Array:
		return (v as Array).map(func(e: Variant) -> Variant: return _filled(s, e))
	return v


## What a talk needs to know about the world, for person `p`.
static func world(s: GameSession, p: PersonDef) -> Dictionary:
	var region := s.region
	var missions := s.missions
	var blamed := region.problem_list().any(func(problem: ProblemDef) -> bool:
		var step := region.net.step_at(problem.step)
		return region.state[problem.id].blamed and region.state[problem.id].is_open() \
			and step != null and p.team in step.pool_ids)
	return {
		"main": missions.active("main").map(func(m: MissionDef) -> String: return m.id),
		"active": missions.active().map(func(m: MissionDef) -> String: return m.id),
		"found": region.found, "facts": facts(s), "problems": missions.worked_problems(),
		"team_trust": region.trust.get(p.team, 0), "blamed": blamed,
		"now": region.net.time, "beats": missions.beats(), "seed": region.net.run_seed,
	}


## The world's facts a talk can need, as Missions.knows answers them (the
## catalogue's C19: done:, failed:, chose:, checked:, flags and measures such
## as reputation>=40), for every atom the dialogs name.
static func facts(s: GameSession) -> Dictionary:
	var out := {}
	for atom: String in s.people.atoms():
		if s.missions.knows(atom):
			out[atom] = true
	return out


## The active main mission talk `def` is on ("" for none): with `missions:` (arc S11)
## not always the first it names, so the coach's after-talk question finds it.
static func talk_main(missions: Missions, def: DialogDef) -> String:
	for m in missions.active("main"):
		if m.id in def.missions:
			return m.id
	return ""


## The talk ended: People applies it, the world takes what it changed (a blame
## by the gemba's own rule, a commitment's team trust, a learned clue), then
## its minutes pass.
func _finish_talk(s: GameSession) -> Dictionary:
	var d := talk
	talk = null
	var region := s.region
	var main := talk_main(s.missions, d.def)
	var morale_before: int = s.people.morale[d.who.id]
	var summary := s.people.finish(d, region.net.time, main)
	_keep_promise(s, d)
	s.discoveries.note_talk(s, {"person": d.who.id, "team": d.who.team, "kind": d.def.kind, "outcome": d.outcome,
		"listened_first": not d.steered_early and d.revealed.has("concern"), "silence_reveal": d.concern_by == "silence",
		"own_idea": d.own_idea(), "morale_before": morale_before, "pressured": d.pressured, "confronted": d.confronted})
	if summary["confronted"]:
		region.ask(d.who.place, "behind")
	if summary["team_trust"] > 0:
		region.trust[d.who.team] = mini(1, region.trust.get(d.who.team, 0) + summary["team_trust"])
	if not summary["clue"].is_empty():
		region.found[summary["clue"]] = true
	if summary["reputation"] != 0:
		region.earn_reputation(summary["reputation"], "dialog_" + summary["outcome"])
	s._after(d.minutes())
	return summary


## A promise agreed in talk `d` (a proposal with `promise`, PLAN 2.4) becomes a
## fact the simulation checks: promised:<dialog>:<ISO date> for a date promised
## (`days` from today), promised:<dialog>:<kind> for an action (a callback). It
## replaces the dialog's earlier promise only when this talk's agreement is now
## the best one (People.finish keeps that).
static func _keep_promise(s: GameSession, d: Dialog) -> void:
	if not d.outcome in People.BUY_IN_OF or s.people.agreed.get(d.def.id) != d.table:
		return
	var promise := JsonFile.dict_or_empty(d.def.item(d.table).get("promise"))
	if promise.is_empty():
		return
	var kind := str(promise.get("kind", ""))
	var value := GameSession.iso_date(s.region.net.time + SimCalendar.days(int(promise.get("days", 0)))) \
		if kind in DATE_PROMISES else kind
	s.missions.facts.remove_prefix("%s%s:" % [Facts.PROMISED, d.def.id])
	s.missions.facts.add("%s%s:%s" % [Facts.PROMISED, d.def.id, value])


## Customers whose talk is due now (PLAN 2.4): the KCC's headset takes their
## call, and they ring the player's phone (CustomerCalls). [{person, dialog,
## name}], in content order; [] when none.
static func customer_calls(s: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: PersonDef in s.people.persons.values():
		if not p.customer or s.people.cooling_down(p.id, s.region.net.time):
			continue
		var d := s.people.dialog_for(p.id, world(s, p))
		if d != null:
			out.append({"person": p.id, "dialog": d.id, "name": p.name})
	return out


## Whether expert talk `dialog_id` still has a clue to tell for an active mission's problem:
## a topic open now whose clue is not found yet (CustomerCalls: only then does an expert ring
## unasked, R-1 #6).
static func expert_serves_active(s: GameSession, dialog_id: String) -> bool:
	var people := s.people
	var d: DialogDef = people.dialogs.get(dialog_id)
	if d == null:
		return false
	var problems := {}
	for m in s.missions.active():
		problems[m.goal_problem] = true
	var known := people.facts(facts(s))
	var asked := people.asked_topics(dialog_id)
	return d.topics.any(func(t: Dictionary) -> bool:
		var clue := ExpertTalk.clue_of(t)
		return not clue.is_empty() and not s.region.found.has(clue) and not t["id"] in asked \
			and ExpertTalk.is_open(t, known, people.trust[d.person], problems))
