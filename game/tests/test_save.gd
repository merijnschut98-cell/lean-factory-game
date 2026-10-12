extends TestCase
## Save and load: a restored game continues exactly as if it had never stopped.


## Through bytes, the way SaveFile stores it.
func _via_file(data: Dictionary) -> Dictionary:
	return bytes_to_var(var_to_bytes(data))


func _busy_network() -> Network:
	var net := Network.load_file(Network.DEFAULT_PATH, 11)
	net.set_effects("problem:slow_design", [NetFixture.effect("connections.design", "touch_time", 1.25)])
	net.set_effects("cm:conwip", [NetFixture.effect("connections", "wip_limit", 150)])
	net.advance_days(45)
	return net


func test_a_restored_network_continues_exactly() -> void:
	var original := _busy_network()
	var restored := Network.load_file(Network.DEFAULT_PATH, 999)  # any seed: the saved state wins
	var result := NetworkState.restore(restored, _via_file(NetworkState.capture(original)))
	assert_eq(result["error"], "")
	assert_eq(result["dropped"], [])
	assert_eq(restored.random_states(), original.random_states(), "every 64-bit random state survives")
	original.drain_events()
	original.advance_days(30)
	restored.advance_days(30)
	for s in original.streams:
		assert_eq(restored.stream(s.id).finished, s.finished, s.id)
		assert_eq(restored.stream(s.id).active, s.active, s.id)
	assert_eq(restored.drain_events(), original.drain_events())
	assert_eq(restored.effects(), original.effects())
	assert_eq(restored.stream("connections").step("design").stats_since(0),
		original.stream("connections").step("design").stats_since(0))
	assert_eq(restored.pools["monteurs"].load_since(0), original.pools["monteurs"].load_since(0), "actual load history")


func test_history_is_bounded() -> void:
	var net := Network.load_file(Network.DEFAULT_PATH, 11)
	net.advance_days(Network.HISTORY_DAYS + 60)
	var oldest: int = net.stream("connections").finished[0]["done_at"]
	assert_true(oldest >= net.time - SimCalendar.days(Network.HISTORY_DAYS + 1), "old finished records are dropped")
	assert_eq(net.stream("connections").step("design").stats_since(0),
		net.stream("connections").step("design").stats_since(SimCalendar.day_of(net.time) - Network.HISTORY_DAYS),
		"so are old daily statistics")


func test_orders_of_steps_that_no_longer_exist_are_dropped_and_reported() -> void:
	var saved := _via_file(NetworkState.capture(_busy_network()))
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
	var good := _via_file(NetworkState.capture(Network.load_file(Network.DEFAULT_PATH)))
	for key in ["time", "rng", "pools", "waiting"]:
		var bad := good.duplicate(true)
		bad[key] = "garbage"
		assert_true(key in NetworkState.restore(Network.load_file(Network.DEFAULT_PATH), bad)["error"], key)
	assert_ne(NetworkState.restore(Network.load_file(Network.DEFAULT_PATH), {})["error"], "")


func _mid_experiment() -> Region:
	var r := RulesFixture.region()
	r.activate("custom_design")
	r.activate("revision_backlog")
	r.use_tool("connections.design", "time_study")
	r.use_tool("connections.design", "documents")
	r.ask("connections.revision", "behind")
	r.submit_a3("custom_design", RulesFixture.a3(r, "custom_design", "overprocessing", "standard_designs",
		["custom_design:0", "custom_design:2"], "throughput"))
	r.advance_days(5)
	return r


func test_a_restored_region_finishes_the_experiment_the_same_way() -> void:
	var original := _mid_experiment()
	var restored := RulesFixture.region(0, 123)
	assert_eq(RegionState.restore(restored, _via_file(RegionState.capture(original)))["error"], "")
	assert_eq(restored.state["custom_design"].phase, ProblemState.Phase.DOING)
	assert_eq(restored.trust_of("connections.revision"), -1)
	assert_eq(restored.found, original.found)
	assert_eq(restored.profile.budget, original.profile.budget)
	for r in [original, restored]:
		r.advance_days(Region.CHECK_DAYS)
	assert_eq(restored.check("custom_design"), original.check("custom_design"))
	assert_eq(restored.act("custom_design", true), original.act("custom_design", true))
	assert_eq(restored.profile.xp, original.profile.xp)


func test_unknown_problems_in_a_save_are_ignored_and_reported() -> void:
	var saved := _via_file(RegionState.capture(_mid_experiment()))
	saved["problems"]["retired_problem"] = saved["problems"]["custom_design"].duplicate(true)
	var result := RegionState.restore(RulesFixture.region(), saved)
	assert_eq(result["error"], "")
	assert_eq(result["dropped"], ["retired_problem"])


func test_save_files_round_trip_and_refuse_bad_input() -> void:
	var original := _mid_experiment()
	assert_eq(SaveFile.write("test_slot", original), "")
	var loaded := RulesFixture.region(0, 1)
	assert_eq(SaveFile.read("test_slot", loaded)["error"], "")
	assert_eq(loaded.net.time, original.net.time)
	assert_eq(loaded.state["custom_design"].phase, ProblemState.Phase.DOING)
	assert_ne(SaveFile.write("../escape", original), "", "slot names cannot leave the saves folder")
	assert_ne(SaveFile.read("missing_slot", loaded)["error"], "")
	var file := FileAccess.open(SaveFile.path_of("test_slot"), FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"version": SaveFile.VERSION + 1}))
	file.close()
	assert_true("version" in SaveFile.read("test_slot", loaded)["error"])
	DirAccess.remove_absolute(SaveFile.path_of("test_slot"))
