class_name MissionDef
extends RefCounted
## One mission from content/missions.yaml: a main mission (one at a time,
## with the coach), a small side mission, or a day of the training week
## (Inwerkweek: with the coach, no side slot), or a milestone (phase-2 design
## §3.1: a dated moment of the story that opens itself and takes no slot), unlocked
## by earlier missions and the player's belt, with a goal the rules can check.

const KINDS := ["main", "side", "training", "milestone"]
const GOALS := ["walk", "investigate", "solve", "observe", "check", "sustain", "rework_fix", "talk_to", "scene",
	"story_order"]
## A milestone's goals: its scene played (content/scenes.yaml), or the story's order
## met by its day (drie winters S12).
const MILESTONE_GOALS := ["scene", "story_order"]
## What a story_order goal is judged by: its mission's deadline_on_day.
const STORY_BY := ["deadline"]
## Day 0 of play (GameSession.PLAY_START_DATE): opens_on {date} counts from it.
const PLAY_START := "2026-10-12"
## How a payoff reaches the player: a call on the phone, a letter on the desk.
const PAYOFF_BY := ["call", "letter"]
const _DATE :="^\\d{4}-\\d{2}-\\d{2}$"
## A talk_to goal's outcomes: partial | commitment (dialog spec §5.1).
const TALK_OUTCOMES := ["partial", "commitment"]
const FORK_ROLES := ["bottleneck", "non_bottleneck"]

var id: String
var name: String
var kind: String
var tier: int
var requires_missions := PackedStringArray()
## Belt index (Progression.BELTS) the player needs.
var requires_belt := 0
## The region's maturity (1–4) and reputation (0–100) it needs.
var requires_maturity := 1
var requires_reputation := 0
## Trust per team (pool id → at least) it needs.
var requires_trust: Dictionary[String, int] = {}
## At least one of these missions done (after a fork).
var requires_any_of := PackedStringArray()
## Facts it needs (Facts.met: {all, any, none}).
var requires_facts: Dictionary = {}
## Story as data: the act (0 the training week; -1 none), the chapter title on
## the board, and a side chain it belongs to (sector, henk, ...).
var act := -1
var chapter: String
var arc: String
## A fork in the main quest: its group and role (bottleneck |
## non_bottleneck); debrief_first is the debrief when this branch was done
## first.
var fork_group: String
var fork_role: String
var debrief_first: String
## Debriefs that read the play (audit §5.7): blamed | poor_fix |
## not_standardised → text.
var debrief_variants: Dictionary[String, String] = {}
## The briefing when the mission is back because its fix faded.
var reopen_text: String
## A safety mission's containment (audit §2.4.1): {name, budget, days,
## effects}, a short measure against an acute risk, taken once while the
## mission is active; it fades after `days` and is not the fix.
var containment: Dictionary = {}
## Facts ("flag:<name>") its completion sets, and the ones a missed deadline sets
## (a door that closes for a later act: flag:el_amrani_complaint).
var sets_flags := PackedStringArray()
var sets_flags_on_fail := PackedStringArray()
## A milestone's scene (an id in content/scenes.yaml), for a `scene` goal.
var scene: String
## The day of play (0: PLAY_START) it becomes available, from `opens_on: {day}` or
## `{date: "YYYY-MM-DD"}`; -1: as soon as it is unlocked.
var opens_on_day := -1
## The day of play its deadline falls on, whenever it opened (the first frost); -1: none.
var deadline_on_day := -1
## What reaches the player once it is done in time (Berichten): [{who (a cast id),
## by (call | letter), text}], her call on your phone and her letter on your desk.
var payoff: Array[Dictionary] = []
## A milestone's own short line when its moment passes (the toast, UI chrome): "De
## vorst is er."; "" for the plain one (UiText.MILESTONE_PASSED).
var missed: String
var briefing: String
var debrief: String
## Said when the deadline passes (e.g. Henk has retired).
var fail_text: String
## walk {stream} · investigate {problem, clues} · solve {problem} ·
## observe {places, tool?, uses?} · check {problem} · sustain {problem}
## (its fix back in use: audited, or held by a routine; Missions' check-ins) ·
## rework_fix {problem} (a poor fix swapped for a better one; Repairs)
var goal_type: String
var goal_stream: String
var goal_problem: String
## talk_to: the dialog, and the least outcome that meets the goal.
var goal_dialog: String
var goal_outcome := "commitment"
## A talk of this mission that must have been had, however it went, before
## the goal counts (Monday ends with Anouk at seven: D9 talks audit A2); "".
var ends_with_talk: String
## The talks the mission needs besides its goal (`talk_to:` in content, phase-2 design
## §3.1): [{dialog, outcome (partial | commitment)}]. It completes once its goal and
## every one of them are met (Missions.pending_talk); the objective line names them.
var talk_goals: Array[Dictionary] = []
## story_order: the followed story (FollowedOrder.STORY), what it is judged by
## (STORY_BY), the facts that meet it (Facts.met) and the dialog whose promised
## date the simulation checks (People.promises; "" for none).
var goal_story: String
var goal_by: String
var goal_met_if: Dictionary = {}
var goal_promise: String
var goal_clues := 0
## observe: a gemba tool (goal_tool, or any tool or question when empty) used
## at every place, goal_uses different place-tool pairs in all.
var goal_places := PackedStringArray()
var goal_tool: String
var goal_uses := 1
## The gemba tools the player learns when the mission is taken on (the
## training week's growing toolbox, PLAN 2.12; PlaceActions).
var grant_tools := PackedStringArray()
## A shorter Check for the goal's problem while this mission is active (the
## training week); -1: Region.CHECK_DAYS.
var check_days := -1
## Training only: a staged situation for the week's lessons, effects on the
## simulation ({target, property, value}) from the day it is accepted until
## the training week ends or is skipped.
var setup: Array = []
## Concept ids whose glossary cards the mission brings when accepted.
var teaches := PackedStringArray()
## Days to complete from when the mission opens (a real event: the clock runs
## whether or not the player takes it on); -1: no deadline.
var deadline_days := -1
## A dated story beat this mission's deadline marks (drie winters S2): it
## falls on the deadline's day whether the mission was done, failed or never
## taken on (Henk retires on his day), e.g. henk_farewell; "" for none.
var deadline_beat: String
## Countermeasures a missed deadline closes for good (Henk's knowledge transfer).
var fail_closes := PackedStringArray()
var reward_xp := 0
var reward_budget := 0
## Reputation the first completion earns (Reputation: a main mission's or a
## side mission's by default, none for a training day).
var reward_reputation := 0
## Trust per team (pool id → change) the first completion earns.
var reward_trust: Dictionary[String, int] = {}
## Main missions: what the coach may tell at a stage, now and then (in turn,
## when a stage has several), and the mission's own questions per stage,
## asked before the general bank.
var insights: Dictionary[String, Array] = {}
var questions: Dictionary[String, Array] = {}
## The objective line's own texts per step (Objective.STEPS → text; `look` may map
## each of an observe goal's places to its text); a step without one gets
## Objective's default.
var steps: Dictionary = {}
var error := ""


static func from_dict(d: Dictionary) -> MissionDef:
	var m := MissionDef.new()
	m.id = str(d.get("id", ""))
	m.name = str(d.get("name", ""))
	m.kind = str(d.get("kind", ""))
	m.tier = int(d.get("tier", 1))
	var requires := JsonFile.dict_or_empty(d.get("requires"))
	m.requires_missions = PackedStringArray(requires.get("missions", []))
	m.requires_belt = int(requires.get("belt", 0))
	m.requires_maturity = int(requires.get("maturity", 1))
	m.requires_reputation = int(requires.get("reputation", 0))
	var trust_needed := JsonFile.dict_or_empty(requires.get("trust"))
	for team: Variant in trust_needed:
		m.requires_trust[str(team)] = int(trust_needed[team])
	m.requires_any_of = PackedStringArray(requires.get("any_of", []))
	m.requires_facts = JsonFile.dict_or_empty(requires.get("facts")).duplicate(true)
	m.act = int(d.get("act", -1))
	m.chapter = str(d.get("chapter", ""))
	m.arc = str(d.get("arc", ""))
	var fork := JsonFile.dict_or_empty(d.get("fork"))
	m.fork_group = str(fork.get("group", ""))
	m.fork_role = str(fork.get("role", ""))
	m.debrief_first = str(d.get("debrief_first", ""))
	var variants := JsonFile.dict_or_empty(d.get("debrief_variants"))
	for key: Variant in variants:
		m.debrief_variants[str(key)] = str(variants[key])
	m.reopen_text = str(d.get("reopen", ""))
	m.sets_flags = PackedStringArray(d.get("sets_flags", []))
	m.sets_flags_on_fail = PackedStringArray(d.get("sets_flags_on_fail", []))
	m.scene = str(d.get("scene", ""))
	m.opens_on_day = _opens_on(d.get("opens_on"))
	m.deadline_on_day = int(d.get("deadline_on_day", -1))
	m.missed = str(d.get("missed", ""))
	var payoff: Variant = d.get("payoff", [])
	for p: Variant in payoff if payoff is Array else []:
		var entry := JsonFile.dict_or_empty(p)
		if str(entry.get("by", "")) in PAYOFF_BY:
			m.payoff.append({"who": str(entry.get("who", "")), "by": entry["by"], "text": str(entry.get("text", ""))})
	m.containment = JsonFile.dict_or_empty(d.get("containment")).duplicate(true)
	m.briefing = str(d.get("briefing", ""))
	m.debrief = str(d.get("debrief", ""))
	m.fail_text = str(d.get("fail", ""))
	var goal := JsonFile.dict_or_empty(d.get("goal"))
	m.goal_type = str(goal.get("type", ""))
	m.goal_stream = str(goal.get("stream", ""))
	m.goal_problem = str(goal.get("problem", ""))
	m.goal_clues = int(goal.get("clues", 0))
	m.goal_places = PackedStringArray(goal.get("places", []))
	m.goal_tool = str(goal.get("tool", ""))
	m.goal_uses = int(goal.get("uses", 1))
	m.goal_dialog = str(goal.get("dialog", ""))
	m.goal_outcome = str(goal.get("outcome", "commitment"))
	m.goal_story = str(goal.get("story", ""))
	m.goal_by = str(goal.get("by", ""))
	m.goal_met_if = JsonFile.dict_or_empty(goal.get("met_if")).duplicate(true)
	m.goal_promise = str(goal.get("promise", ""))
	m.ends_with_talk = str(d.get("ends_with_talk", "")) if d.get("ends_with_talk") is String else ""
	var talks: Variant = d.get("talk_to", [])
	var bad_talk := not talks is Array
	for t: Variant in talks if talks is Array else []:
		var entry := JsonFile.dict_or_empty(t)
		var talk := {"dialog": str(entry.get("dialog", "")), "outcome": str(entry.get("outcome", "commitment"))}
		bad_talk = bad_talk or talk["dialog"].is_empty() or not talk["outcome"] in TALK_OUTCOMES
		m.talk_goals.append(talk)
	m.check_days = int(d.get("check_days", -1))
	m.grant_tools = PackedStringArray(Array(d.get("grant_tools", [])).filter(
		func(t: Variant) -> bool: return t is String and Investigation.TOOLS.has(t))) if d.get("grant_tools") is Array \
		else PackedStringArray()
	m.teaches = PackedStringArray(d.get("teaches", []))
	var setup: Variant = d.get("setup", [])
	m.setup = setup.duplicate(true) if setup is Array else []
	m.deadline_days = int(d.get("deadline_days", -1))
	m.fail_closes = PackedStringArray(d.get("fail_closes", []))
	m.deadline_beat = str(d.get("deadline_beat", ""))
	var rewards := JsonFile.dict_or_empty(d.get("rewards"))
	m.reward_xp = int(rewards.get("xp", 0))
	m.reward_budget = int(rewards.get("budget", 0))
	var default_reputation: int = {"main": Reputation.MAIN_MISSION, "side": Reputation.SIDE_MISSION}.get(m.kind, 0)
	m.reward_reputation = int(rewards.get("reputation", default_reputation))
	var trust := JsonFile.dict_or_empty(rewards.get("trust"))
	for team: Variant in trust:
		m.reward_trust[str(team)] = int(trust[team])
	for key in ["insights", "questions"]:
		var by_stage := JsonFile.dict_or_empty(d.get(key))
		for stage: Variant in by_stage:
			var lines: Variant = by_stage[stage]
			(m.insights if key == "insights" else m.questions)[str(stage)] = \
				(lines as Array).map(func(l: Variant) -> String: return str(l)) if lines is Array else [str(lines)]
	m.steps = JsonFile.dict_or_empty(d.get("steps")).duplicate(true)
	if m.id.is_empty() or m.name.is_empty():
		m.error = "mission %s: needs an id and a name" % m.id
	elif not m.kind in KINDS or not m.goal_type in GOALS:
		m.error = "mission %s: unknown kind %s or goal %s" % [m.id, m.kind, m.goal_type]
	elif m.goal_type == "observe" and m.goal_places.is_empty():
		m.error = "mission %s: an observe goal needs places" % m.id
	elif m.goal_type == "talk_to" and (m.goal_dialog.is_empty() or not m.goal_outcome in TALK_OUTCOMES):
		m.error = "mission %s: a talk_to goal needs a dialog and an outcome (partial | commitment)" % m.id
	elif bad_talk:
		m.error = "mission %s: talk_to lists talks, each with a dialog and an outcome (partial | commitment)" % m.id
	elif not m.deadline_beat.is_empty() and m.deadline_days < 0:
		m.error = "mission %s: a deadline_beat needs deadline_days" % m.id
	elif not m.setup.is_empty() and m.kind != "training":
		m.error = "mission %s: only a training day has a setup" % m.id
	elif (m.kind == "milestone") != (m.goal_type in MILESTONE_GOALS):
		m.error = "mission %s: a milestone, and only a milestone, has a scene or story_order goal" % m.id
	elif m.goal_type == "scene" and m.scene.is_empty():
		m.error = "mission %s: a scene goal names its scene" % m.id
	elif m.goal_type == "story_order" and (m.goal_story.is_empty() or not m.goal_by in STORY_BY
			or m.goal_met_if.is_empty() or m.deadline_on_day < 0):
		m.error = "mission %s: a story_order goal needs a story, by: deadline, met_if and a deadline_on_day" % m.id
	elif m.opens_on_day == -2:
		m.error = "mission %s: opens_on is {day: N} or {date: YYYY-MM-DD} from %s on" % [m.id, PLAY_START]
	return m


## The day of play `opens_on` names: {day: N}, or {date: "YYYY-MM-DD"} counted from
## PLAY_START; -1 when it is absent, -2 when it is malformed.
static func _opens_on(v: Variant) -> int:
	if v == null:
		return -1
	var on := JsonFile.dict_or_empty(v)
	if on.size() != 1:
		return -2
	if on.has("day"):
		var day: Variant = on["day"]
		return int(day) if (day is int or day is float) and day >= 0 else -2
	var day := day_of(on.get("date"))
	return day if day >= 0 else -2


## The day of play (0: PLAY_START) of an ISO date "YYYY-MM-DD"; -1 when it is no such
## date or before play.
static func day_of(date: Variant) -> int:
	if not date is String or RegEx.create_from_string(_DATE).search(date) == null:
		return -1
	var days := int(Time.get_unix_time_from_datetime_string(date) - Time.get_unix_time_from_datetime_string(PLAY_START)) / 86400
	return days if days >= 0 else -1
