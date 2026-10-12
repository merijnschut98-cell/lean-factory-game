extends TestCase
## Save and load: a restored game continues exactly as if it had never stopped.


## Through JSON text, as a save file would go.
func _via_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


func _busy_network() -> Network:
	var net := Network.load_file(Network.DEFAULT_PATH, 11)
	net.set_effects("problem:slow_design", [NetFixture.effect("connections.design", "touch_time", 1.25)])
	net.set_effects("cm:conwip", [NetFixture.effect("connections", "wip_limit", 150)])
	net.advance_days(45)
	return net


func test_a_restored_network_continues_exactly() -> void:
	var original := _busy_network()
	var saved := _via_json(NetworkState.capture(original))
	var restored := Network.load_file(Network.DEFAULT_PATH, 999)  # any seed: the saved state wins
	var result := NetworkState.restore(restored, saved)
	assert_eq(result["error"], "")
	assert_eq(result["dropped"], [])
	original.drain_events()
	original.advance_days(30)
	restored.advance_days(30)
	for s in original.streams:
		assert_eq(restored.stream(s.id).finished, s.finished, s.id)
		assert_eq(restored.stream(s.id).active, s.active, s.id)
	assert_eq(restored.drain_events(), original.drain_events())
	assert_data_eq(restored.effects(), original.effects())
	assert_eq(restored.stream("connections").step("design").stats_since(0),
		original.stream("connections").step("design").stats_since(0))


func test_the_random_state_survives_json() -> void:
	var net := _busy_network()
	var saved := _via_json(NetworkState.capture(net))
	assert_true(saved["rng"] is String, "64-bit state as text: JSON numbers are doubles")


func test_orders_of_steps_that_no_longer_exist_are_dropped_and_reported() -> void:
	var saved := _via_json(NetworkState.capture(_busy_network()))
	var queue: Array = saved["queues"]["connections.design"]
	assert_true(queue.size() > 0)
	saved["queues"]["connections.redesign"] = queue.duplicate(true)
	saved["queues"].erase("connections.design")
	var net := Network.load_file(Network.DEFAULT_PATH)
	var result := NetworkState.restore(net, saved)
	assert_eq(result["error"], "")
	assert_eq(result["dropped"].size(), queue.size())
	assert_eq(net.queue_of(net.stream("connections").step("design")).size(), 0)


func test_corrupt_network_data_is_refused() -> void:
	for bad: Variant in [{}, {"time": "noon"}, {"time": 10, "rng": 5}, [], "x"]:
		var net := Network.load_file(Network.DEFAULT_PATH)
		assert_ne(NetworkState.restore(net, bad if bad is Dictionary else {"broken": bad})["error"], "", str(bad))


func _region() -> Region:
	var profile := Profile.new()
	return Region.new(RulesFixture.net(), RulesFixture.problem_defs(), RulesFixture.countermeasure_defs(), profile)


func _mid_experiment() -> Region:
	var r := _region()
	r.activate("custom_design")
	r.activate("revision_backlog")
	r.use_tool("connections.design", "time_study")
	r.use_tool("connections.design", "documents")
	r.ask("connections.revision", "behind")
	var options: Dictionary = Investigation.cause_options(r.problems["custom_design"], r.problem_list())
	r.submit_a3("custom_design", {"waste": "overprocessing", "cause": options["correct"],
		"evidence": ["custom_design:0", "custom_design:2"], "cm": "standard_designs", "prediction": "throughput"})
	r.advance_days(5)
	return r


func _restore_region(original: Region) -> Region:
	var net := RulesFixture.net(123)
	var restored := Region.new(net, RulesFixture.problem_defs(), RulesFixture.countermeasure_defs(), Profile.new())
	assert_eq(NetworkState.restore(net, _via_json(NetworkState.capture(original.net)))["error"], "")
	assert_eq(RegionState.restore(restored, _via_json(RegionState.capture(original)))["error"], "")
	return restored


func test_a_restored_region_finishes_the_experiment_the_same_way() -> void:
	var original := _mid_experiment()
	var restored := _restore_region(original)
	assert_eq(restored.state["custom_design"].phase, ProblemState.Phase.DOING)
	assert_eq(restored.trust_of("connections.revision"), -1)
	assert_eq(restored.found, original.found)
	assert_eq(restored.profile.budget, original.profile.budget)
	for r in [original, restored]:
		r.advance_days(Region.CHECK_DAYS)
	var a := original.check("custom_design")
	var b := restored.check("custom_design")
	assert_data_eq(b, a)
	assert_data_eq(restored.act("custom_design", true), original.act("custom_design", true))
	assert_eq(restored.profile.xp, original.profile.xp)


func test_unknown_problems_in_a_save_are_ignored_and_reported() -> void:
	var saved := _via_json(RegionState.capture(_mid_experiment()))
	saved["problems"]["retired_problem"] = saved["problems"]["custom_design"].duplicate(true)
	var r := _region()
	var result := RegionState.restore(r, saved)
	assert_eq(result["error"], "")
	assert_eq(result["dropped"], ["retired_problem"])


func test_save_files_round_trip_and_refuse_bad_input() -> void:
	var original := _mid_experiment()
	assert_eq(SaveFile.write("test_slot", original), "")
	var net := RulesFixture.net(1)
	var loaded := Region.new(net, RulesFixture.problem_defs(), RulesFixture.countermeasure_defs(), Profile.new())
	assert_eq(SaveFile.read("test_slot", loaded)["error"], "")
	assert_eq(loaded.net.time, original.net.time)
	assert_eq(loaded.state["custom_design"].phase, ProblemState.Phase.DOING)
	assert_ne(SaveFile.write("../escape", original), "", "slot names cannot leave the saves folder")
	assert_ne(SaveFile.read("missing_slot", loaded)["error"], "")
	var file := FileAccess.open(SaveFile.path_of("test_slot"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveFile.VERSION + 1}))
	file.close()
	assert_true("version" in SaveFile.read("test_slot", loaded)["error"])
	DirAccess.remove_absolute(SaveFile.path_of("test_slot"))
