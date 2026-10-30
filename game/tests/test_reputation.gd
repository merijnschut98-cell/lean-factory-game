extends TestCase
## Reputation: how the MT sees the CI lead, a measure of its own (Merijn,
## 2026-10-15), under the three principles: lasting improvements and owning a
## regression pay, blaming people and missed promises cost (CLAUDE.md §2).


func _log() -> Missions:
	return RulesFixture.mission_log(RulesFixture.region())


func _walk_connections(log: Missions) -> void:
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()


func _changes(log: Missions) -> Array:
	var out := []
	for e in log.region.drain_events():
		if e["type"] == "reputation":
			out.append([e["change"], e["reason"]])
	return out


func test_reputation_starts_at_30_and_stays_within_0_and_100() -> void:
	var rep := Reputation.new()
	assert_eq(rep.value, Reputation.START)
	assert_eq(rep.change(-80, "test")["value"], 0)
	assert_eq(rep.change(-1, "test"), {}, "nothing changed: no event")
	rep.change(500, "test")
	assert_eq(rep.value, Reputation.MAX)


func test_completed_missions_earn_reputation_by_kind() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_revision")
	log.region.state["revision_backlog"].phase = ProblemState.Phase.RESOLVED
	log.update()
	assert_eq(_changes(log), [[Reputation.MAIN_MISSION, "mission"], [Reputation.SIDE_MISSION, "mission"]])
	assert_eq(log.region.reputation.value, Reputation.START + Reputation.MAIN_MISSION + Reputation.SIDE_MISSION)


func test_a_mission_can_name_its_reputation_and_trust_rewards() -> void:
	var m := MissionDef.from_dict({"id": "x", "name": "x", "kind": "side", "goal": {"type": "walk", "stream": "meters"},
		"briefing": "b", "debrief": "d", "rewards": {"xp": 10, "reputation": 0, "trust": {"crew": 1, "gis": -1}}})
	assert_eq(m.error, "")
	assert_eq(m.reward_reputation, 0)
	assert_eq(m.reward_trust, {"crew": 1, "gis": -1})
	var log := Missions.new(RulesFixture.region(), [m] as Array[MissionDef], RulesFixture.coach())
	log.accept("x")
	log.region.use_tool("meters.visit", "shadow")
	log.update()
	assert_eq(log.status("x"), "completed")
	assert_eq(log.region.reputation.value, Reputation.START, "a reputation of 0 is no reputation")
	assert_eq([log.region.trust["crew"], log.region.trust["gis"]], [1, -1])


func test_blaming_a_team_costs_reputation() -> void:
	var r := RulesFixture.region()
	r.ask("connections.design", "who")
	assert_eq(r.reputation.value, Reputation.START + Reputation.BLAME)


func test_a_missed_deadline_costs_reputation() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.region.drain_events()
	log.region.advance_days(11)
	log.update()
	assert_true(log.failed("henk"))
	assert_eq(_changes(log), [[Reputation.DEADLINE_MISSED, "deadline"]])


func test_a_bad_period_costs_reputation() -> void:
	var r := RulesFixture.region(100)
	r.grant(0, -500)
	assert_true(r.in_bad_period())
	assert_eq(r.reputation.value, Reputation.START + Reputation.BAD_PERIOD)


## A fix that moved the whole stream's flow (impact 4–5) shows the MT what
## bottleneck-first means; doing a faded mission again (owning the
## regression) earns a little, without a second XP reward.
func test_flow_gains_and_owning_a_regression_earn_reputation() -> void:
	var log := _log()
	log.accept("walk_connections")
	_walk_connections(log)
	log.accept("fix_design")
	var r := log.region
	var st: ProblemState = r.state["custom_design"]
	st.phase = ProblemState.Phase.RESOLVED
	st.a3 = {"cm": "standard_designs"}
	st.score = {"total": 20, "impact": Reputation.FLOW_IMPACT}
	r.drain_events()
	log.update()
	assert_eq(_changes(log), [[Reputation.MAIN_MISSION, "mission"], [Reputation.FLOW_GAIN, "flow"]])
	r.state["custom_design"] = ProblemState.new("custom_design")  # the fix faded
	log.update()
	log.accept("fix_design")
	r.state["custom_design"].phase = ProblemState.Phase.RESOLVED
	var xp := r.profile.xp
	log.update()
	assert_eq(_changes(log), [[Reputation.REOPENED, "reopened"]])
	assert_eq(r.profile.xp, xp, "no second XP")


func test_reputation_survives_save_and_old_saves_start_at_30() -> void:
	var r := RulesFixture.region()
	r.earn_reputation(12, "test")
	var saved := RegionState.capture(r)
	var restored := RulesFixture.region()
	assert_eq(RegionState.restore(restored, saved)["error"], "")
	assert_eq(restored.reputation.value, Reputation.START + 12)
	saved.erase("reputation")
	var old := RulesFixture.region()
	RegionState.restore(old, saved)
	assert_eq(old.reputation.value, Reputation.START)
