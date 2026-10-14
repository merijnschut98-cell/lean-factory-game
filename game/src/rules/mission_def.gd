class_name MissionDef
extends RefCounted
## One mission from content/missions.yaml: a main mission (one at a time,
## with the coach), a small side mission, or a day of the training week
## (Inwerkweek: with the coach, no side slot), unlocked by earlier missions and
## the player's belt, with a goal the rules can check.

const KINDS := ["main", "side", "training"]
const GOALS := ["walk", "investigate", "solve", "observe", "check"]

var id: String
var name: String
var kind: String
var tier: int
var requires_missions := PackedStringArray()
## Belt index (Progression.BELTS) the player needs.
var requires_belt := 0
var briefing: String
var debrief: String
## Said when the deadline passes (e.g. Henk has retired).
var fail_text: String
## walk {stream} · investigate {problem, clues} · solve {problem} ·
## observe {places, tool?, uses?} · check {problem}
var goal_type: String
var goal_stream: String
var goal_problem: String
var goal_clues := 0
## observe: a gemba tool (goal_tool, or any tool or question when empty) used
## at every place, goal_uses different place-tool pairs in all.
var goal_places := PackedStringArray()
var goal_tool: String
var goal_uses := 1
## A shorter Check for the goal's problem while this mission is active (the
## training week); -1: Region.CHECK_DAYS.
var check_days := -1
## Concept ids whose glossary cards the mission brings when accepted.
var teaches := PackedStringArray()
## Days to complete from when the mission opens (a real event: the clock runs
## whether or not the player takes it on); -1: no deadline.
var deadline_days := -1
## Countermeasures a missed deadline closes for good (Henk's knowledge transfer).
var fail_closes := PackedStringArray()
var reward_xp := 0
var reward_budget := 0
## Main missions: what the coach may tell at a stage, now and then.
var insights: Dictionary[String, String] = {}
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
	m.check_days = int(d.get("check_days", -1))
	m.teaches = PackedStringArray(d.get("teaches", []))
	m.deadline_days = int(d.get("deadline_days", -1))
	m.fail_closes = PackedStringArray(d.get("fail_closes", []))
	var rewards := JsonFile.dict_or_empty(d.get("rewards"))
	m.reward_xp = int(rewards.get("xp", 0))
	m.reward_budget = int(rewards.get("budget", 0))
	var insights := JsonFile.dict_or_empty(d.get("insights"))
	for stage: Variant in insights:
		m.insights[str(stage)] = str(insights[stage])
	if m.id.is_empty() or m.name.is_empty():
		m.error = "mission %s: needs an id and a name" % m.id
	elif not m.kind in KINDS or not m.goal_type in GOALS:
		m.error = "mission %s: unknown kind %s or goal %s" % [m.id, m.kind, m.goal_type]
	elif m.goal_type == "observe" and m.goal_places.is_empty():
		m.error = "mission %s: an observe goal needs places" % m.id
	return m
