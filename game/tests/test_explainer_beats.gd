extends TestCase
## T5: Ruud's beats on the whiteboard (spec 2026-10-16-explainer-spanning-
## stroom-weerstand §4): the order, the waits and their timeouts, the small-
## load branches, the skip, the state carried over the cross-fade, the reel
## locked until R8, and Esc at any beat.

const ID := "spanning_stroom_weerstand"


func _beats() -> ExplainerBeats:
	var defs := ExplainerDef.load_all()
	assert_eq(defs["error"], "", "explainers.json")
	var b := ExplainerBeats.new(defs["explainers"][ID])
	b.start()
	return b


## Reading beats move on by themselves; tick until the beat changes.
func _until_not(b: ExplainerBeats, id: String, limit: float = 60.0) -> void:
	var t := 0.0
	while b.beat_id() == id and t < limit:
		b.tick(0.5)
		t += 0.5


func test_it_opens_in_the_garden_on_a1() -> void:
	var b := _beats()
	assert_eq(b.beat_id(), "a1")
	assert_eq(b.phase(), "tuin")
	assert_false(b.done)


func test_a_player_who_follows_ruud_walks_every_main_beat() -> void:
	var b := _beats()
	var seen: Array[String] = [b.beat_id()]
	var step := func() -> void:
		if seen[-1] != b.beat_id():
			seen.append(b.beat_id())
	b.toggle("kettle")  # a1: a valve open
	step.call()
	b.toggle("heater")  # a2: a second one
	step.call()
	for id in ["a3", "a4", "x", "r1", "r2", "r3"]:
		assert_eq(b.beat_id(), id)
		_until_not(b, id)
		step.call()
	b.toggle("heater")  # the kettle alone, then the heater back on
	b.toggle("heater")
	while not b.done and seen.size() < 30:
		if b.beat_id() == "r8a":
			b.toggle("haspel")
		_until_not(b, b.beat_id())
		step.call()
	assert_true(b.done, "closes after R8")
	assert_eq(seen, ["a1", "a2", "a3", "a4", "x", "r1", "r2", "r3", "r4_already_on", "r5", "r7", "r8a", "r8b"] as Array[String],
		"the kettle was on from the garden (R4's variant); the heater was on, so R6 is skipped")


func test_a_wait_advances_on_its_control() -> void:
	var b := _beats()
	b.toggle("lamp")
	assert_eq(b.beat_id(), "a2_dripper", "only the dripper: Ruud suggests the big one")
	b.toggle("kettle")
	assert_eq(b.beat_id(), "a3")


func test_every_wait_moves_on_by_itself_after_its_timeout() -> void:
	var b := _beats()
	b.tick(9.5)
	assert_eq(b.beat_id(), "a1", "still waiting at 9,5 s")
	b.tick(0.6)
	assert_eq(b.beat_id(), "a2", "10 s: on by itself")
	b.tick(10.1)
	assert_eq(b.beat_id(), "a3")


func test_space_skips_any_beat() -> void:
	var b := _beats()
	b.next()
	assert_eq(b.beat_id(), "a2")
	b.next()
	assert_eq(b.beat_id(), "a3")


func _to(b: ExplainerBeats, id: String) -> void:
	while b.beat_id() != id and not b.done:
		b.next()


func test_r4_waits_for_the_kettle_when_it_is_off() -> void:
	var b := _beats()
	_to(b, "r4")
	assert_eq(b.beat_id(), "r4", "nothing on: the plain R4")
	b.toggle("kettle")
	assert_eq(b.beat_id(), "r5")


func test_r5_with_only_the_lamp_waits_for_the_kettle_then_plays_r5() -> void:
	var b := _beats()
	_to(b, "r4")
	b.toggle("lamp")
	b.tick(10.1)
	assert_eq(b.beat_id(), "r5_lamp", "a lamp only: almost nothing")
	b.toggle("kettle")
	assert_eq(b.beat_id(), "r5", "then R5 itself")


func test_r6_is_skipped_when_the_heater_is_already_on() -> void:
	var b := _beats()
	_to(b, "r4")
	b.toggle("kettle")
	_until_not(b, "r5")
	assert_eq(b.beat_id(), "r6", "heater off: R6 asks for it")
	b.toggle("heater")
	assert_eq(b.beat_id(), "r7", "the kettle was seen alone: the plain R7")


func test_r7_asks_for_the_heater_again_if_the_kettle_never_ran_alone() -> void:
	var b := _beats()
	b.toggle("kettle")
	b.toggle("heater")
	_to(b, "r5")
	b.next()
	assert_eq(b.beat_id(), "r7_never_alone", "R6 skipped; the kettle never ran alone")
	b.toggle("heater")
	assert_eq(b.beat_id(), "r7_never_alone", "off: still waiting for it to come back")
	b.toggle("heater")
	assert_eq(b.beat_id(), "r7")


func test_the_reel_is_locked_until_r8() -> void:
	var b := _beats()
	assert_false(b.toggle("haspel"), "A1: the reel does not move")
	_to(b, "r7")
	assert_false(b.toggle("haspel"), "R7: still not")
	assert_eq(b.haspel, 1)
	_to(b, "r8a")
	assert_true(b.toggle("haspel"))
	assert_eq(b.haspel, 2)
	assert_eq(b.beat_id(), "r8b", "the swap answers R8's wait")


func test_the_switches_carry_over_the_cross_fade() -> void:
	var b := _beats()
	b.toggle("kettle")
	b.toggle("lamp")
	_to(b, "r1")
	assert_eq(b.phase(), "meterkast")
	assert_eq(b.on, {"lamp": true, "kettle": true, "heater": false})


func test_esc_closes_at_any_beat() -> void:
	for stop in ["a1", "a3", "x", "r5", "r8b"]:
		var b := _beats()
		_to(b, stop)
		b.close()
		assert_true(b.done, stop)
		assert_true(b.closed_early, stop)


func test_no_beat_offers_a_choice() -> void:
	var def: ExplainerDef = ExplainerDef.load_all()["explainers"][ID]
	for beat: Dictionary in def.beats:
		assert_false(beat.has("choices"), beat["id"])
		assert_false(beat.has("answers"), beat["id"])
