extends TestCase
## One followed customer dossier (Merijn, 2026-10-15; audit §3.0): the El
## Amrani family's connection is a real order in the simulation, so its
## delivery day is computed, not scripted. And containment in a safety
## mission (audit §2.4.1): contain now, fix the cause next.


func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	return s


func test_the_el_amrani_dossier_is_a_real_order() -> void:
	var s := _session()
	var dossier := s.followed_order()
	assert_eq(dossier["step"], "intake", "the whole stream ahead: %s" % dossier)
	assert_true(dossier["age_days"] > 0.0)
	assert_eq(dossier["delivered_days"], -1.0)
	var age: float = dossier["age_days"]
	_catch_missing_documents(s)
	assert_eq(s.wait_days(7), "")
	assert_near(s.followed_order()["age_days"], age + 7.0, 0.01)
	for week in 29:   # looked at once a week, as a player passing by would
		s.wait_days(7)
	var done := s.followed_order()
	assert_true(done["delivered_days"] > 0.0, "delivered at last: %s" % done)
	assert_true(done["touch_hours"] > 1.0, "hours of work against weeks of waiting")


## The intake catches missing documents now: the fix for incomplete_application in
## place and holding (as a resolved, unworn fix reads).
func _catch_missing_documents(s: GameSession) -> void:
	s.region.state[FollowedOrder.DEFECT_PROBLEM].phase = ProblemState.Phase.RESOLVED
	s.pass_time(0)


## The day of play the dossier is connected (its real done_at), looking once a week (-1: not by `days`).
func _connected_day(s: GameSession, days: int) -> float:
	for week in ceili(days / 7.0):
		if s.followed.delivered_at >= 0:
			break
		s.wait_days(7.0)
	return (s.followed.delivered_at - s.missions.play_start) / 1440.0 if s.followed.delivered_at >= 0 else -1.0


## Winter 1's stakes (coordinator's ruling, PLAN 1.8a / D14): her application misses a
## document today's intake does not ask for, so it goes back to her and joins the queue
## again, loop after loop, while incomplete_application stands unfixed.
func test_the_dossier_loops_at_intake_while_missing_documents_go_uncaught() -> void:
	var s := _session()
	assert_eq(s.followed.defect_at(s.region.net), FollowedOrder.DEFECT_STEP)
	var dossier := _connected_day(s, 60)
	assert_eq(dossier, -1.0, "not connected in two months")
	var o: WorkOrder = s.region.net.open_orders(s.region.net.stream(FollowedOrder.STREAM)).filter(
		func(w: WorkOrder) -> bool: return w.id == s.followed.order_id)[0]
	assert_true(o.reworks >= 5, "back to the customer again and again: %d" % o.reworks)
	assert_true(o.step_index <= o.stream.step_index(FollowedOrder.DEFECT_STEP), "still at intake")


## Once the intake catches it (the bottleneck branch's fix holds), her dossier goes on
## and is connected within a normal lead time; the other branch's fix does not help her.
func test_the_dossier_goes_on_once_the_intake_catches_it_and_only_then() -> void:
	var s := _session()
	s.wait_days(10.0)
	_catch_missing_documents(s)
	assert_eq(s.followed.defect_at(s.region.net), "")
	var day := _connected_day(s, 80)
	assert_between(day, 11.0, 60.0, "connected after the fix, within a lead time: %s" % day)
	var other := _session()
	other.wait_days(10.0)
	other.region.state["installer_not_ready"].phase = ProblemState.Phase.RESOLVED   # the non-bottleneck branch
	other.pass_time(0)
	assert_eq(other.followed.defect_at(other.region.net), FollowedOrder.DEFECT_STEP, "still uncaught")
	assert_eq(_connected_day(other, 50), -1.0, "the other branch's fix does not reach her")


## A heavier connection (winter 1's stakes, PLAN 1.8a / D14): the heat pump needs more
## than the house has, so the dossier always takes the netcheck, never a permit or a
## reinforcement (a meter-cabinet job), whatever the stream's shares say.
func test_the_dossier_is_a_heavier_connection_with_its_own_route() -> void:
	var s := _session()
	var o: WorkOrder = s.region.net.open_orders(s.region.net.stream(FollowedOrder.STREAM)).filter(
		func(w: WorkOrder) -> bool: return w.id == s.followed.order_id)[0]
	assert_eq(o.needs, FollowedOrder.ROUTE)
	var copy := WorkOrder.from_dict(bytes_to_var(var_to_bytes(o.to_dict())), o.stream)
	assert_eq(copy.needs, o.needs, "saved with the order")
	var stream := s.region.net.stream(FollowedOrder.STREAM)
	for i in 20:   # the stream's shares no longer decide for this order
		assert_true(s.region.net.call("_needed", stream.steps[stream.step_index("grid_study")], o), "the netcheck")
		assert_false(s.region.net.call("_needed", stream.steps[stream.step_index("permit")], o), "no permit")
		assert_false(s.region.net.call("_needed", stream.steps[stream.step_index("grid_reinforcement")], o))


func test_the_followed_order_survives_a_save() -> void:
	var s := _session()
	var copy := FollowedOrder.new()
	copy.load_dict(bytes_to_var(var_to_bytes(s.followed.to_dict())))
	assert_eq(copy.order_id, s.followed.order_id)
	assert_eq(copy.born, s.followed.born)


## Containment is the real exception to long term first: a short measure
## against an acute risk, paid once, that fades by itself; it does not end the
## mission (the root cause still needs its fix).
func test_containment_in_a_safety_mission() -> void:
	var s := _session()
	var m: MissionDef = s.missions.defs["fix_digging_damage"]
	assert_false(m.containment.is_empty(), "digging damage is a safety mission")
	assert_eq(s.contain("fix_digging_damage"), "not_active")
	for id in ["fix_done_but_not_closed", "fix_status_callers", "fix_incomplete_application", "fix_custom_design"]:
		s.missions.done_once[id] = true
	assert_eq(s.accept("fix_digging_damage"), "")
	var budget := s.budget()
	assert_eq(s.contain("fix_digging_damage"), "")
	assert_eq(s.budget(), budget - int(m.containment["budget"]))
	assert_true(s.region.net.effects().has("contain:fix_digging_damage"))
	assert_eq(s.contain("fix_digging_damage"), "contained", "once")
	assert_eq(s.missions.status("fix_digging_damage"), "active", "containing is not fixing")
	s.wait_days(int(m.containment["days"]) + 1)
	assert_false(s.region.net.effects().has("contain:fix_digging_damage"), "it fades by itself")
	assert_eq(s.contain("fix_custom_design"), "not_active")
	assert_eq(s.wait_days(0), "bad_days")


func _found(s: GameSession) -> Array:
	return s.drain_events().filter(func(e: Dictionary) -> bool: return e["type"] == "discovery").map(
		func(e: Dictionary) -> String: return e["id"])


## D14: the family's dossier delivered within 18 weeks of its birth (the
## industry norm) is a discovery, computed from the simulation.
func test_the_dossier_delivered_in_time_is_a_discovery() -> void:
	var s := _session()
	_catch_missing_documents(s)   # her missing document is caught at intake from the start
	s.drain_events()
	var found := []
	for week in 30:
		if s.followed_order()["delivered_days"] >= 0.0:
			break
		assert_eq(s.wait_days(7), "")
		found += _found(s)
	assert_true(s.followed_order()["delivered_days"] <= 126.0, "the base flow delivers within the norm")
	assert_true("dossier_el_amrani" in found, "found: %s" % [found])


func test_a_late_dossier_earns_nothing() -> void:
	var s := _session()
	s.followed.delivered_at = s.followed.born + SimCalendar.days(127)
	s.wait_days(1)
	assert_false("dossier_el_amrani" in _found(s))


## The letter's weeks are the followed order's own (never scripted).
func test_the_briefings_read_the_dossiers_age() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, true)
	var weeks := FollowedOrder.weeks_text(s.followed_order()["age_days"])
	assert_true(s.mission_briefing("training_mon").contains("al %s op een aansluiting" % weeks), s.mission_briefing("training_mon"))
	assert_false(s.mission_briefing("training_mon").contains("{"), "no placeholder left")
	assert_true(s.mission_briefing("walk_connections").contains("nu %s onderweg" % weeks))
	assert_eq(FollowedOrder.weeks_text(3.0), "één week", "never less than one")
	assert_eq(FollowedOrder.weeks_text(8.0), "één week")
	assert_eq(FollowedOrder.weeks_text(77.0), "elf weken")
	assert_eq(FollowedOrder.weeks_text(220.0), "31 weken")


func _accept_digging_damage(s: GameSession) -> void:
	for id in ["fix_done_but_not_closed", "fix_status_callers", "fix_incomplete_application", "fix_custom_design"]:
		s.missions.done_once[id] = true
	assert_eq(s.accept("fix_digging_damage"), "")


func _resolve(s: GameSession, problem_id: String) -> void:
	var st: ProblemState = s.region.state[problem_id]
	st.phase = ProblemState.Phase.RESOLVED
	st.cause_correct = true
	s.wait_days(1)


## D28: contain within two days of accepting, then fix the cause: the real
## exception to long term first, and containing is not fixing.
func test_contain_then_fix_is_a_discovery() -> void:
	var s := _session()
	_accept_digging_damage(s)
	s.wait_days(1)
	assert_eq(s.contain("fix_digging_damage"), "")
	assert_false("eerst_veilig" in _found(s), "containment alone pays nothing")
	_resolve(s, "digging_damage")
	assert_true("eerst_veilig" in _found(s))


func test_a_late_containment_earns_nothing() -> void:
	var s := _session()
	_accept_digging_damage(s)
	s.wait_days(3)
	assert_eq(s.contain("fix_digging_damage"), "")
	_resolve(s, "digging_damage")
	assert_false("eerst_veilig" in _found(s))
