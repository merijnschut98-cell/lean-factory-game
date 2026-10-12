extends TestCase


func test_same_seed_same_sequence() -> void:
	var a := Rng.new(42)
	var b := Rng.new(42)
	for i in 100:
		assert_eq(a.next(), b.next(), "draw %d" % i)


func test_different_seeds_differ() -> void:
	assert_ne(Rng.new(1).next(), Rng.new(2).next())


func test_state_round_trip_continues_sequence() -> void:
	var a := Rng.new(7)
	for i in 10:
		a.next()
	var b := Rng.new(999)
	b.set_state(a.get_state())
	assert_eq(a.next(), b.next())


func test_exp_mean_is_close_to_mean() -> void:
	var r := Rng.new(3)
	var total := 0.0
	for i in 20000:
		total += r.exp_mean(30.0)
	assert_near(total / 20000.0, 30.0, 1.0)


func test_around_stays_in_band() -> void:
	var r := Rng.new(5)
	for i in 1000:
		assert_between(r.around(100.0, 0.15), 85.0, 115.0)


func test_pick_on_empty_is_null() -> void:
	assert_eq(Rng.new(1).pick([]), null)
