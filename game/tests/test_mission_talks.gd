extends TestCase
## The talks a mission needs (phase-2 design §3.1, S1-H): every Act I mission's
## `talk_to` goal is met through a real talk on the real content, the objective names the
## person once the player has looked, and a yes won by pressure pays half.

const Autoplay := preload("res://tools/autoplay.gd")
const P := ProblemState.Phase
## Days a listening player may need for one talk (one try a day).
const MAX_TRIES := 8


## A campaign session with only mission `id` active, its problem resolved, and a
## listening player (the autoplay talker) to talk with.
func _with_only(id: String, persona := "talker") -> Array:
	var bot = Autoplay.Persona.new(persona, 11)
	bot.s = GameSession.new_game(11, Catalog.DATA_DIR, false)
	bot.record = {"talks": [], "refusals": [], "assisted": []}
	var s: GameSession = bot.s
	for other: String in s.missions.progress.keys():
		if s.missions.progress[other]["status"] == "active":
			s.missions.progress.erase(other)
	var m: MissionDef = s.missions.defs[id]
	s.missions.progress[id] = {"status": "active", "asks": {}, "seen": {}}
	s.region.activate(m.goal_problem)
	s.region.state[m.goal_problem].phase = P.RESOLVED
	return [bot, s, m]


func _talk_missions() -> Array[MissionDef]:
	var out: Array[MissionDef] = []
	for m: MissionDef in GameSession.new_game(11, Catalog.DATA_DIR, false).missions.defs.values():
		if not m.talk_goals.is_empty():
			out.append(m)
	return out


func test_every_act_one_talk_goal_is_met_through_a_real_talk() -> void:
	var missions := _talk_missions()
	assert_true(missions.size() >= 8, "the Act I missions' talks: %d" % missions.size())
	for m in missions:
		var made := _with_only(m.id)
		var bot = made[0]
		var s: GameSession = made[1]
		for t in MAX_TRIES:
			var needed := s.missions.pending_talk(m)
			if needed.is_empty():
				break
			var outcome: String = bot._converse(s.people.dialogs[needed])
			assert_false(outcome.begins_with("error"), "%s: %s" % [m.id, outcome])
			s.wait_days(1.0)
		assert_eq(s.missions.pending_talk(m), "", m.id + ": its talk was won by listening")
		assert_eq(s.missions.status(m.id), "completed", m.id + ": done once the talk was had")


func test_until_the_talk_is_had_the_mission_waits_and_the_objective_names_the_person() -> void:
	var made := _with_only("fix_custom_design")
	var s: GameSession = made[1]
	var m: MissionDef = made[2]
	s.wait_days(1.0)
	assert_eq(s.missions.status(m.id), "active", "fixed, but Joost was never asked")
	var o := Objective.step(m, s)
	assert_eq([o["step"], o["person"], o["text"]], ["talk", "joost", "Praat met Joost (Werkvoorbereiding)"])
	s.region.state[m.goal_problem].phase = P.ACTIVE
	assert_eq(Objective.step(m, s)["step"], "look", "first the player goes and looks")
	s.region.state[m.goal_problem].phase = P.SPOTTED
	assert_eq(Objective.step(m, s)["step"], "talk", "then meets the person, before digging")
	s.region.state[m.goal_problem].phase = P.CHECK_READY
	assert_eq(Objective.step(m, s)["step"], "check", "the Check at the obeya wall comes first")


func test_a_yes_under_pressure_completes_the_mission_at_half_pay() -> void:
	var made := _with_only("fix_custom_design", "never-talks")
	var bot = made[0]
	var s: GameSession = made[1]
	var xp := s.xp()
	assert_eq(bot._push(s.people.dialogs["joost_vacancies"]), "compliance")
	s.wait_days(1.0)
	assert_eq(s.missions.status("fix_custom_design"), "completed")
	var reward: int = s.missions.defs["fix_custom_design"].reward_xp
	assert_true(s.xp() - xp <= reward / 2, "half the reward at most: %d of %d" % [s.xp() - xp, reward])
