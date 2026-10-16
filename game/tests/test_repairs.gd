extends TestCase
## Repair side quests (catalogue C20, §2.15): a poor fix brings, some weeks
## later and only once its weakness shows in the problem's KPI, a small side
## mission to swap it for a better one. Doing it records `repaired:`, which
## opens options that need the better fix; skipping it is allowed.

const PROBLEM := "custom_design"
const REPAIR := "repair_custom_design"


func _log() -> Missions:
	var log := RulesFixture.mission_log(RulesFixture.region())
	log.accept("walk_connections")
	for step in log.region.net.stream("connections").steps:
		if step.kind == SimStep.Kind.WORK:
			log.region.use_tool("connections." + step.id, "shadow")
	log.update()
	return log


## Solve custom_design through the PDCA loop with `cm`.
func _solve(log: Missions, cm: String) -> void:
	var r := log.region
	log.accept("fix_design")
	r.use_tool("connections.design", "time_study")
	assert_eq(r.submit_a3(PROBLEM, RulesFixture.a3(r, PROBLEM, "overprocessing", cm, ["custom_design:0"], "lead_time")), "")
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check(PROBLEM)["passed"])
	r.act(PROBLEM, true)
	r.plan_routine("connections.design")  # held as it is while the weeks pass
	log.update()
	assert_eq(log.status("fix_design"), "completed")


## The weak fix shows (stubbed): days pass, the quest opens.
func _open_repair(log: Missions) -> void:
	log.repairs.gap_of = func(_r: Region, _p: String) -> float: return 0.1
	log.region.advance_days(Repairs.AFTER_DAYS)
	log.update()


func test_a_poor_fix_brings_its_repair_quest_once_the_weakness_shows() -> void:
	var log := _log()
	_solve(log, "delegated_approval")  # fit 0.6 against the best 1.0
	assert_true(log.knows("poor_fix:" + PROBLEM))
	log.repairs.gap_of = func(_r: Region, _p: String) -> float: return 0.01
	log.region.advance_days(Repairs.AFTER_DAYS)
	log.update()
	assert_false(log.defs.has(REPAIR), "the KPI does not show it yet: no verdict without a symptom")
	log.repairs.gap_of = func(_r: Region, _p: String) -> float: return 0.1
	log.region.advance_days(Repairs.RETRY_DAYS)
	log.update()
	assert_eq(log.status(REPAIR), "available")
	assert_eq(log.defs[REPAIR].kind, "side", "small, without the coach")
	assert_true(log.drain_events().has({"type": "repair", "mission": REPAIR}))


func test_a_good_fix_never_brings_a_repair_quest() -> void:
	var log := _log()
	_solve(log, "standard_designs")
	_open_repair(log)
	assert_false(log.defs.has(REPAIR))


## The real forecast: the poor fix leaves the problem's KPI behind the best
## countermeasure's on the same network and random sequences.
func test_the_weakness_is_measured_against_the_best_countermeasure() -> void:
	var log := _log()
	_solve(log, "delegated_approval")
	assert_true(Repairs.kpi_gap(log.region, PROBLEM) > 0.0)


func test_reworking_swaps_the_fix_without_the_problem_coming_back() -> void:
	var log := _log()
	_solve(log, "delegated_approval")
	_open_repair(log)
	var r := log.region
	var xp := r.profile.xp
	assert_eq(log.accept(REPAIR), "")
	assert_eq(r.state[PROBLEM].phase, ProblemState.Phase.SPOTTED, "a new A3, from what was found")
	assert_true(r.net.effects().has("cm:" + PROBLEM), "the old fix keeps running meanwhile")
	assert_false(r.net.effects().has("problem:" + PROBLEM), "the problem does not come back")
	var same := RulesFixture.a3(r, PROBLEM, "overprocessing", "delegated_approval", ["custom_design:0"], "lead_time")
	assert_eq(r.submit_a3(PROBLEM, same), "same_countermeasure")
	var better := RulesFixture.a3(r, PROBLEM, "overprocessing", "standard_designs", ["custom_design:0"], "lead_time")
	assert_eq(r.submit_a3(PROBLEM, better), "")
	assert_false(r.net.effects().has("problem:" + PROBLEM))
	r.advance_days(Region.CHECK_DAYS)
	var check := r.check(PROBLEM)
	assert_true(check["passed"], "%s" % check)
	r.act(PROBLEM, true)
	log.update()
	assert_eq(log.status(REPAIR), "completed")
	assert_true(log.knows("repaired:" + PROBLEM), "repaired")
	assert_true(log.knows("chose:custom_design:standard_designs"), "chose")
	assert_false(log.knows("poor_fix:" + PROBLEM))
	assert_true(r.profile.xp > xp, "a small reward")


## A rework whose Check fails goes back to the gemba with the old fix still
## in place; dropping the quest leaves the old fix as it was.
func test_a_failed_or_dropped_rework_keeps_the_old_fix() -> void:
	var log := _log()
	_solve(log, "delegated_approval")
	_open_repair(log)
	var r := log.region
	var design := r.net.stream("connections").step("design")
	var fixed_minutes := design.touch_minutes
	log.accept(REPAIR)
	var wrong := RulesFixture.a3(r, PROBLEM, "overprocessing", "poka_yoke_form", ["custom_design:0"], "lead_time")
	r.closed.erase("poka_yoke_form")  # Henk's deadline closed it meanwhile
	assert_eq(r.submit_a3(PROBLEM, wrong), "")
	r.advance_days(Region.CHECK_DAYS)
	assert_false(r.check(PROBLEM)["passed"])
	assert_eq(r.state[PROBLEM].phase, ProblemState.Phase.SPOTTED)
	assert_eq(design.touch_minutes, fixed_minutes, "the old fix, not the mismatch, and not the problem")
	assert_eq(log.abandon(REPAIR), "")
	assert_eq(r.state[PROBLEM].phase, ProblemState.Phase.RESOLVED, "the old fix stays")
	assert_eq(r.state[PROBLEM].a3["cm"], "delegated_approval")
	assert_eq(design.touch_minutes, fixed_minutes)
	assert_true(log.knows("poor_fix:" + PROBLEM))
	assert_eq(log.status(REPAIR), "available", "it can be taken on later")


func test_a_repair_quest_survives_a_save() -> void:
	var log := _log()
	_solve(log, "delegated_approval")
	_open_repair(log)
	log.accept(REPAIR)
	var region := RulesFixture.region()
	assert_eq(RegionState.restore(region, bytes_to_var(var_to_bytes(RegionState.capture(log.region))))["error"], "")
	var restored := RulesFixture.mission_log(region)
	assert_eq(restored.load_dict(bytes_to_var(var_to_bytes(log.to_dict()))), [])
	assert_eq(restored.status(REPAIR), "active")
	assert_eq(region.state[PROBLEM].rework_from["cm"], "delegated_approval")
