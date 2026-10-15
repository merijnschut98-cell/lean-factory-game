extends TestCase
## Department KPIs (content/kpis.yaml): the menus are well formed, and the
## chosen KPIs translate into work rules (start, order, care) as ordinary
## effects, so nothing downstream ever sees a `kpis` effect.


func _menu() -> KpiMenu:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	return c.kpis


func _by_property(effects: Array, property: String) -> Array:
	return effects.filter(func(e: Dictionary) -> bool: return e["property"] == property)


func test_the_real_menus_follow_the_rules() -> void:
	var menu := _menu()
	assert_eq(menu.menus.keys().size(), 4)
	for pool: String in menu.menus:
		var kinds := {}
		assert_true(menu.menus[pool].size() <= 5, pool)
		for k: KpiDef in menu.menus[pool]:
			assert_eq(k.pool, pool, k.id)
			assert_eq(k.error, "", k.id)
			assert_true(k.id.begins_with(pool), k.id)
			assert_false(k.rules.is_empty(), k.id)
			kinds[k.kind] = true
		assert_eq(kinds.keys().size(), 2, "%s has a leading and a lagging KPI" % pool)
	assert_eq(menu.pull_limit_days, 3.0)
	assert_false(menu.review_question.is_empty())


func test_a_lagging_and_a_leading_kpi_set_all_their_rules() -> void:
	var effects := _menu().effects_for("intake", PackedStringArray(["intake_lead_time", "intake_oldest"]))
	assert_eq(_by_property(effects, "start_rule"), [NetFixture.effect("intake", "start_rule", "pull")])
	assert_eq(_by_property(effects, "order_rule"), [NetFixture.effect("intake", "order_rule", "oldest")])
	assert_eq(effects.size(), 2, "no care chosen: no care effects")


func test_conflicting_kpis_fall_back_to_the_habit() -> void:
	# intake_output: push, shortest. intake_lead_time: pull. Mixed signals on start.
	var effects := _menu().effects_for("intake", PackedStringArray(["intake_output", "intake_lead_time"]))
	assert_eq(_by_property(effects, "start_rule").size(), 0, "push against pull: the habit")
	assert_eq(_by_property(effects, "order_rule"), [NetFixture.effect("intake", "order_rule", "shortest")])


func test_two_kpis_that_agree_keep_the_rule() -> void:
	var effects := _menu().effects_for("intake", PackedStringArray(["intake_output", "intake_utilisation"]))
	assert_eq(_by_property(effects, "start_rule"), [NetFixture.effect("intake", "start_rule", "push")])


func test_careful_care_slows_and_improves_every_step_of_the_team() -> void:
	var net := Network.load_file(Network.DEFAULT_PATH)
	var steps: Array[String] = []
	for stream in net.streams:
		for step in stream.steps:
			if step.kind == SimStep.Kind.WORK and step.pool_ids.has("intake"):
				steps.append("%s.%s" % [stream.id, step.id])
	assert_true(steps.size() >= 2, "intake works on several steps")
	var menu := _menu()
	assert_eq(Array(menu.pool_steps["intake"]), steps)
	var effects := menu.effects_for("intake", PackedStringArray(["intake_complete"]))
	var touch := _by_property(effects, "touch_time")
	var ftr := _by_property(effects, "ftr")
	assert_eq(touch.size(), steps.size())
	assert_eq(ftr.size(), steps.size())
	for place in steps:
		assert_true(touch.has(NetFixture.effect(place, "touch_time", 1.1)), place)
		assert_true(ftr.has(NetFixture.effect(place, "ftr", 0.05)), place)
	assert_eq(net.set_effects("kpi:test", effects), "", "the real network accepts them")


func test_hasty_care_speeds_up_and_hurts_quality() -> void:
	var effects := _menu().effects_for("contact_centre", PackedStringArray(["contact_centre_handle_time"]))
	assert_eq(_by_property(effects, "touch_time"), [NetFixture.effect("customer_contact.answer", "touch_time", 0.9)])
	assert_eq(_by_property(effects, "ftr"), [NetFixture.effect("customer_contact.answer", "ftr", -0.05)])


func test_opposite_care_cancels_out() -> void:
	# The contact centre pairs hasty handling time with careful first-contact resolution.
	var effects := _menu().effects_for("contact_centre",
		PackedStringArray(["contact_centre_handle_time", "contact_centre_resolved"]))
	assert_eq(_by_property(effects, "touch_time").size(), 0, "hasty against careful: normal")


func test_unknown_kpis_and_other_pools_are_ignored() -> void:
	var menu := _menu()
	assert_eq(menu.effects_for("intake", PackedStringArray(["work_prep_oldest", "nonsense"])), [])
	assert_eq(menu.effects_for("nobody", PackedStringArray(["intake_oldest"])), [])


func test_a_bad_kpi_definition_reports_its_error() -> void:
	assert_ne(KpiDef.from_dict({"id": "x_y", "name": "X", "pool": "x", "kind": "medium", "rules": {"order": "oldest"}}).error, "")
	assert_ne(KpiDef.from_dict({"id": "x_y", "name": "X", "pool": "x", "kind": "leading", "rules": {"order": "random"}}).error, "")
	assert_ne(KpiDef.from_dict({"id": "", "name": "X"}).error, "")
	assert_eq(KpiDef.from_dict({"id": "x_y", "name": "X", "pool": "x", "kind": "leading", "rules": {"care": "hasty"}}).error, "")


## A problem (or countermeasure) lists the KPIs a department follows; the
## catalogue turns them into rule effects at load, and the real network takes them.
func test_the_catalog_expands_kpi_effects() -> void:
	var dir := "user://kpi_catalog_test"
	DirAccess.make_dir_recursive_absolute(dir)
	for file in ["countermeasures", "missions", "value_streams", "kpis", "concepts", "discoveries"]:
		assert_eq(DirAccess.copy_absolute("res://data/%s.json" % file, "%s/%s.json" % [dir, file]), OK)
	var kpi_effect := {"target": "intake", "property": "kpis", "value": ["intake_lead_time", "intake_oldest"]}
	var problem: Dictionary = JsonFile.read_dict("res://data/problems_tier1.json")["data"]["problems"][0]
	problem["effects"] = problem["effects"] + [kpi_effect]
	var cm: Dictionary = JsonFile.read_dict("res://data/countermeasures.json")["data"]
	cm["countermeasures"][0]["effects"] = cm["countermeasures"][0]["effects"] + [kpi_effect]
	for path_doc in [["problems_tier1", {"problems": [problem]}], ["countermeasures", cm]]:
		var f := FileAccess.open("%s/%s.json" % [dir, path_doc[0]], FileAccess.WRITE)
		f.store_string(JSON.stringify(path_doc[1]))
		f.close()
	var c := Catalog.load_from(dir)
	assert_eq(c.error, "")
	var net := Network.load_file(Network.DEFAULT_PATH)
	for effects: Array in [c.problems[0].effects, c.countermeasures[0].effects]:
		assert_eq(effects.filter(func(e: Dictionary) -> bool: return e["property"] == "kpis").size(), 0)
		assert_eq(_by_property(effects, "start_rule"), [NetFixture.effect("intake", "start_rule", "pull")])
		assert_eq(_by_property(effects, "order_rule"), [NetFixture.effect("intake", "order_rule", "oldest")])
		assert_eq(net.set_effects("test", effects), "")
	assert_eq(net.pools["intake"].start_rule, "pull")
	assert_eq(net.pools["intake"].order_rule, "oldest")
