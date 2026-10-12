extends TestCase


func test_same_seed_same_sequence() -> void:
	var a := Rng.new(42)
	var b := Rng.new(42)
	for i in 100:
		assert_eq(a.int_range(0, 1 << 30), b.int_range(0, 1 << 30), "draw %d" % i)


func test_different_seeds_differ() -> void:
	assert_ne(Rng.new(1).int_range(0, 1 << 30), Rng.new(2).int_range(0, 1 << 30))


func test_state_round_trip_continues_sequence() -> void:
	var a := Rng.new(7)
	for i in 10:
		a.int_range(0, 1 << 30)
	var b := Rng.new(999)
	b.set_state(a.get_state())
	assert_eq(a.int_range(0, 1 << 30), b.int_range(0, 1 << 30))


func test_around_stays_in_band() -> void:
	var r := Rng.new(5)
	for i in 1000:
		assert_between(r.around(100.0, 0.15), 85.0, 115.0)

