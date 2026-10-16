class_name MissionDef
extends RefCounted
## One mission from content/missions.yaml: a main mission (one at a time,
## with the coach), a small side mission, or a day of the training week
## (Inwerkweek: with the coach, no side slot), unlocked by earlier missions and
## the player's belt, with a goal the rules can check.

const KINDS := ["main", "side", "training"]
const GOALS := ["walk", "investigate", "solve", "observe", "check", "sustain", "rework_fix", "talk_to"]
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
## Facts ("flag:<name>") its completion sets.
var sets_flags := PackedStringArray()
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
var goal_clues := 0
## observe: a gemba tool (goal_tool, or any tool or question when empty) used
## at every place, goal_uses different place-tool pairs in all.
var goal_places := PackedStringArray()
var goal_tool: String
var goal_uses := 1
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
	m.check_days = int(d.get("check_days", -1))
	m.teaches = PackedStringArray(d.get("teaches", []))
	var setup: Variant = d.get("setup", [])
	m.setup = setup.duplicate(true) if setup is Array else []
	m.deadline_days = int(d.get("deadline_days", -1))
	m.fail_closes = PackedStringArray(d.get("fail_closes", []))
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
	if m.id.is_empty() or m.name.is_empty():
		m.error = "mission %s: needs an id and a name" % m.id
	elif not m.kind in KINDS or not m.goal_type in GOALS:
		m.error = "mission %s: unknown kind %s or goal %s" % [m.id, m.kind, m.goal_type]
	elif m.goal_type == "observe" and m.goal_places.is_empty():
		m.error = "mission %s: an observe goal needs places" % m.id
	elif m.goal_type == "talk_to" and (m.goal_dialog.is_empty() or not m.goal_outcome in TALK_OUTCOMES):
		m.error = "mission %s: a talk_to goal needs a dialog and an outcome (partial | commitment)" % m.id
	elif not m.setup.is_empty() and m.kind != "training":
		m.error = "mission %s: only a training day has a setup" % m.id
	return m
