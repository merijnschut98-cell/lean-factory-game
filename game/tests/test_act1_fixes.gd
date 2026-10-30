extends TestCase
## Act I's fixes on the real network at Act I's maturity (Act 0/I mission audit,
## 2026-10-24; tests/test_act_fixes.py checks the same from the content's numbers).
## The designed failed Check of Klaar maar niet af (designed-failed-checks §1): the
## automatic EAN registration is offered and works only half, the close-out at
## completion passes on lead time.

const PROBLEM := "done_but_not_closed"


func _region() -> Region:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	var r := s.region
	assert_eq(r.maturity(), 1, "Act I is played at maturity 1")
	assert_true(r.activate(PROBLEM))
	r.use_tool("connections.close_out_wait", "data")  # the two weeks at 'administratief open'
	return r


func _check(cm: String) -> Dictionary:
	var r := _region()
	assert_true(r.available_countermeasures().any(func(c: CountermeasureDef) -> bool: return c.id == cm),
		cm + " is offered in Act I")
	var a3 := RulesFixture.a3(r, PROBLEM, "inventory", cm, [PROBLEM + ":0"], "lead_time")
	assert_eq(r.submit_a3(PROBLEM, a3), "")
	r.advance_days(Region.CHECK_DAYS)
	return r.check(PROBLEM)


func test_the_automatic_registration_is_too_early_in_act1() -> void:
	var result := _check("automatic_ean_registration")
	assert_false(result["passed"])
	assert_eq(result["lesson"], "too_early")


func test_closing_out_at_completion_passes_on_lead_time() -> void:
	var result := _check("close_out_at_completion")
	assert_true(result["passed"], str(result.get("gains", {})))
