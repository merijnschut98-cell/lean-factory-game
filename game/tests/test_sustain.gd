extends TestCase
## Improvements must be sustained, or they decay (faster the weaker the
## sustaining habits), and stagnation is regression (CLAUDE.md §2; design:
## docs/superpowers/specs/2026-10-15-sustain-and-drift-design.md).

const DESIGN := "connections.design"


## custom_design resolved with standard_designs (decay_days 30), standardised or not.
func _resolved(standardise: bool, r: Region = RulesFixture.region()) -> Region:
	r.activate("custom_design")
	r.use_tool(DESIGN, "time_study")
	r.use_tool(DESIGN, "documents")
	r.ask("connections.intake", "walk")
	r.use_tool(DESIGN, "data")
	var a3 := RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs",
		["custom_design:0", "custom_design:2", "custom_design:4"], "throughput")
	assert_eq(r.submit_a3("custom_design", a3), "")
	r.advance_days(Region.CHECK_DAYS)
	assert_true(r.check("custom_design")["passed"])
	assert_false(r.act("custom_design", standardise).is_empty())
	return r


func _phase(r: Region) -> ProblemState.Phase:
	return r.state["custom_design"].phase


# ── Graded sustainment, accelerating with neglect ──────────────────────────

func test_the_life_of_a_fix_grows_with_the_sustain_strength() -> void:
	assert_near(Sustain.life_days(30.0, 0.0), 30.0, 1e-9, "no habits: the countermeasure's own decay")
	assert_near(Sustain.life_days(30.0, 0.6), 30.0 / 0.46, 1e-9)
	assert_near(Sustain.life_days(30.0, 1.0), 300.0, 1e-9, "every habit: slow, but it still wears when neglected")
	assert_near(Sustain.health(0.0), 1.0, 1e-9)
	assert_near(Sustain.health(1.0), 0.5, 1e-9, "a full life of neglect: the recurrence threshold")


func test_a_fix_that_used_to_stay_has_a_long_base() -> void:
	var r := RulesFixture.region()
	assert_eq(Sustain.base_days(r.countermeasures["standard_designs"]), 30.0)
	assert_eq(Sustain.base_days(r.countermeasures["poka_yoke_form"]), Sustain.STRUCTURAL_DAYS,
		"built into a system: it still erodes, over about a year")


## Merijn (2026-10-15): slowly, but faster the longer nothing is done about it.
func test_wear_accelerates_with_neglect() -> void:
	var r := _resolved(true)
	r.advance_days(20)
	var first := 1.0 - r.health("custom_design")
	var h := r.health("custom_design")
	r.advance_days(20)
	var second := h - r.health("custom_design")
	assert_true(second > first * 2.0, "the second 20 days cost more than the first (%.3f vs %.3f)" % [second, first])
	assert_near(r.state["custom_design"].neglect, 40.0, 1e-6, "days since anything was done about it")


func test_weaker_sustainment_erodes_faster() -> void:
	var loose := _resolved(false)
	var kept := _resolved(true)
	assert_eq(loose.sustain("custom_design"), {"strength": 0.0, "mechanisms": []})
	assert_eq(kept.sustain("custom_design"), {"strength": Sustain.WEIGHTS["standard_work"], "mechanisms": ["standard_work"]})
	assert_near(loose.health("custom_design"), 1.0, 1e-9, "fresh at the Act")
	for r in [loose, kept]:
		r.advance_days(20)
	assert_true(kept.health("custom_design") > loose.health("custom_design"), "standard work slows the wear")
	assert_true(loose.health("custom_design") < 1.0 and loose.health("custom_design") > 0.5)
	assert_near(loose.days_to_recur("custom_design"), 10.0, 0.05)
	loose.advance_days(11)
	kept.advance_days(11)
	assert_eq(_phase(loose), ProblemState.Phase.DORMANT, "no habits: gone after its 30 days, as before")
	assert_eq(_phase(kept), ProblemState.Phase.RESOLVED)


func test_a_standardised_fix_still_erodes_slowly() -> void:
	var r := _resolved(true)
	var life := Sustain.life_days(30.0, Sustain.WEIGHTS["standard_work"])
	assert_near(r.days_to_recur("custom_design"), life, 0.05)
	r.advance_days(floorf(life) - 1)
	assert_eq(_phase(r), ProblemState.Phase.RESOLVED)
	assert_true(r.health("custom_design") < 0.55, "worn almost to the threshold")
	r.advance_days(2)
	assert_eq(_phase(r), ProblemState.Phase.DORMANT, "standard work alone does not hold it forever")
	assert_true(r.drain_events().any(func(e: Dictionary) -> bool: return e["type"] == "recurred"))


func test_erosion_brings_the_problem_back_in_part() -> void:
	var r := _resolved(false)
	var step := r.net.stream("connections").step("design")
	var fixed := step.touch_minutes
	assert_eq(r.weekly_cost(), 0.0, "fresh: the problem is gone")
	r.advance_days(20)
	var h := r.health("custom_design")
	assert_true(step.touch_minutes > fixed, "the extra work creeps back (%d vs %d)" % [step.touch_minutes, fixed])
	assert_true(step.touch_minutes < 360, "but not all of it")
	assert_near(r.weekly_cost(), 700.0 * (1.0 - h), 1e-6, "and its cost with it")
	assert_true(r.drain_events().any(func(e: Dictionary) -> bool: return e == {"type": "slipping", "problem": "custom_design"}),
		"the slide is announced before the recurrence")


func test_a_board_and_steering_kpis_strengthen_sustainment() -> void:
	var cms := RulesFixture.countermeasures()
	cms[3]["sustains"] = true  # revision_at_source: say, an end-to-end board for the stream
	var r := _resolved(true, RulesFixture.region(50000, 5, RulesFixture.problems(), cms))
	r.state["revision_backlog"].phase = ProblemState.Phase.RESOLVED
	r.state["revision_backlog"].a3 = {"cm": "revision_at_source"}
	r.board.chosen["prep"] = PackedStringArray(["a", "b"])  # the design team steers by KPIs
	var s := r.sustain("custom_design")
	assert_eq(s["mechanisms"], ["standard_work", "visual_management", "kpis"])
	assert_near(s["strength"], 1.0, 1e-9)
	assert_near(r.days_to_recur("custom_design"), 300.0, 0.05)
	assert_false(r.sustain("revision_backlog")["mechanisms"].has("visual_management"), "a board does not hold itself")


func test_an_audit_refreshes_standardised_fixes_only() -> void:
	var kept := _resolved(true)
	var loose := _resolved(false)
	for r in [kept, loose]:
		r.advance_days(20)
	assert_eq(kept.audit(DESIGN), {"refreshed": ["custom_design"], "no_standard": []})
	assert_near(kept.health("custom_design"), 1.0, 1e-9, "the standard is back in use")
	assert_eq(kept.state["custom_design"].neglect, 0.0, "and the neglect clock starts again")
	assert_true(kept.profile.concepts.has("leader_standard_work"))
	var worn := loose.health("custom_design")
	assert_eq(loose.audit(DESIGN), {"refreshed": [], "no_standard": ["custom_design"]})
	assert_eq(loose.health("custom_design"), worn, "nothing to audit against")
	assert_eq(kept.audit("connections.intake"), {"refreshed": [], "no_standard": []})


## Merijn (2026-10-15): with planned audits or routines it does not decay,
## it stays the same. The routine costs the team a little time every week.
func test_a_planned_routine_holds_a_standardised_fix() -> void:
	var kept := _resolved(true)
	var loose := _resolved(false)
	var prep := kept.net.pools["prep"]
	for r in [kept, loose]:
		r.advance_days(10)
		assert_eq(r.plan_routine(DESIGN), "")
	var h := kept.health("custom_design")
	assert_near(prep.availability, 1.0 - Sustain.ROUTINE_HOURS_PER_WEEK / (2.0 * prep.schedule.hours()), 1e-9,
		"a little of the team's week")
	assert_eq(kept.days_to_recur("custom_design"), INF, "held while the routine runs")
	for r in [kept, loose]:
		r.advance_days(200)
	assert_eq(_phase(kept), ProblemState.Phase.RESOLVED)
	assert_near(kept.health("custom_design"), h, 1e-9, "it stays the same")
	assert_eq(_phase(loose), ProblemState.Phase.DORMANT, "a routine has no standard to hold an unstandardised fix to")
	assert_eq(kept.stop_routine(DESIGN), "")
	assert_eq(prep.availability, 1.0, "the team's time is back")
	assert_eq(kept.state["custom_design"].neglect, 0.0, "neglect counts from the routine's end")
	kept.advance_days(5)
	assert_true(kept.health("custom_design") < h, "and the wear resumes")


func test_a_routine_needs_a_team_and_is_planned_once() -> void:
	var r := RulesFixture.region()
	assert_eq(r.plan_routine("connections.permit"), "no_team", "a permit wait has nobody to hold a routine")
	assert_eq(r.plan_routine("nowhere.step"), "unknown_place")
	assert_eq(r.plan_routine(DESIGN), "")
	assert_eq(r.plan_routine(DESIGN), "planned")
	assert_eq(r.routines.keys(), [DESIGN])
	assert_eq(r.stop_routine("connections.intake"), "not_planned")


# ── Stagnation drift ────────────────────────────────────────────────────────

func test_drift_is_off_until_started() -> void:
	var r := RulesFixture.region()
	r.advance_days(400)
	assert_eq(r.drift_level(), 0.0)
	assert_false(r.net.effects().has(Region.DRIFT_SOURCE))


func test_drift_grows_without_improvement_and_is_capped() -> void:
	var r := RulesFixture.region()
	var crew := r.net.pools["crew"]
	r.start_drift()
	r.advance_days(Sustain.DRIFT_GRACE_DAYS)
	assert_eq(r.drift_level(), 0.0, "a month without a finished improvement is a normal pace")
	assert_eq(crew.availability, 1.0)
	r.advance_days(Sustain.DRIFT_RAMP_DAYS / 2.0)
	assert_near(r.drift_level(), 0.5, 0.01)
	assert_near(crew.availability, 1.0 - Sustain.DRIFT_AVAILABILITY * 0.5, 0.001, "people leave, vacancies stay open")
	assert_true(r.net.stream("connections").arrivals[0].per_week > 15.0, "the energy transition keeps adding requests")
	r.advance_days(Sustain.DRIFT_RAMP_DAYS)
	assert_eq(r.drift_level(), 1.0, "capped: gentle, never the end")
	assert_near(crew.availability, 1.0 - Sustain.DRIFT_AVAILABILITY, 1e-6)
	assert_eq(r.stagnant_days(), Sustain.DRIFT_GRACE_DAYS + 1.5 * Sustain.DRIFT_RAMP_DAYS)


func test_a_resolved_improvement_resets_drift() -> void:
	var r := RulesFixture.region()
	r.start_drift()
	r.advance_days(200)
	assert_true(r.drift_level() > 0.0)
	_resolved(true, r)
	assert_eq(r.drift_level(), 0.0, "the region improves again")
	assert_eq(r.stagnant_days(), 0.0)
	assert_eq(r.net.pools["crew"].availability, 1.0)


# ── Save / load ─────────────────────────────────────────────────────────────

func test_wear_and_drift_survive_a_save() -> void:
	var r := _resolved(true)
	r.start_drift()
	r.advance_days(50)
	assert_eq(r.plan_routine("connections.intake"), "")
	var restored := RulesFixture.region(0, 99)
	var saved: Dictionary = bytes_to_var(var_to_bytes(RegionState.capture(r)))  # the way SaveFile stores it
	assert_eq(RegionState.restore(restored, saved)["error"], "")
	assert_near(restored.health("custom_design"), r.health("custom_design"), 1e-9)
	assert_true(restored.state["custom_design"].standardised)
	assert_eq(restored.state["custom_design"].neglect, r.state["custom_design"].neglect)
	assert_eq(restored.routines, r.routines)
	assert_eq(restored.stagnant_days(), r.stagnant_days())
	assert_eq(restored.net.effects(), r.net.effects(), "erosion and drift come back with the network")
	for each in [r, restored]:
		each.advance_days(30)
	assert_eq(restored.state["custom_design"].phase, r.state["custom_design"].phase)
	assert_near(restored.drift_level(), r.drift_level(), 1e-9)


func test_an_old_save_reads_its_act_as_sustainment() -> void:
	var st := ProblemState.new("custom_design")
	var saved := st.to_dict()
	saved.erase("standardised")
	saved.erase("wear")
	saved.erase("neglect")
	saved["phase"] = "RESOLVED"
	saved["recur_at"] = -1
	assert_true(st.load_dict(saved))
	assert_true(st.standardised, "an old save's fix that never faded was standardised")
	assert_eq([st.wear, st.neglect], [0.0, 0.0])
	saved["recur_at"] = 1000
	assert_true(st.load_dict(saved))
	assert_false(st.standardised)
	var r := RulesFixture.region()
	var old := RegionState.capture(r)
	old.erase("drift_from")
	assert_eq(RegionState.restore(RulesFixture.region(), old)["error"], "")


# ── Buy-in: commitment versus compliance (dialog spec §4.2) ─────────────────

func test_a_fix_its_owner_stands_behind_lasts_longer() -> void:
	var r := _resolved(true)
	var life := Sustain.life_days(30.0, Sustain.WEIGHTS["standard_work"])
	assert_eq(r.state["custom_design"].buy_in, "none", "today's behaviour: nobody owns it")
	assert_near(r.life_days("custom_design"), life, 1e-9)
	r.state["custom_design"].buy_in = "commitment"
	assert_near(r.life_days("custom_design"), life * 1.25, 1e-9)
	r.state["custom_design"].buy_in = "compliance"
	assert_near(r.life_days("custom_design"), life * 0.6, 1e-9, "compliance lasts while the pressure lasts")
	# The spec's example: the Obeya (45 days), standardised.
	assert_near(Sustain.life_days(45.0, 0.6) * Sustain.BUY_IN["commitment"], 122.3, 0.1)
	assert_near(Sustain.life_days(45.0, 0.6) * Sustain.BUY_IN["compliance"], 58.7, 0.1)


func test_buy_in_is_saved_and_an_old_save_has_none() -> void:
	var st := ProblemState.new("custom_design")
	st.buy_in = "compliance"
	var restored := ProblemState.new("custom_design")
	assert_true(restored.load_dict(st.to_dict()))
	assert_eq(restored.buy_in, "compliance")
	var old := st.to_dict()
	old.erase("buy_in")
	assert_true(restored.load_dict(old))
	assert_eq(restored.buy_in, "none")
	old["buy_in"] = "bribed"
	assert_true(restored.load_dict(old))
	assert_eq(restored.buy_in, "none", "an unknown buy-in reads as none")
