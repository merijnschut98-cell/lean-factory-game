extends TestCase


func test_week_starts_monday_and_weekend_is_off() -> void:
	assert_eq(SimCalendar.weekday(0), 0)
	assert_true(SimCalendar.is_workday(SimCalendar.days(4)), "Friday")
	assert_false(SimCalendar.is_workday(SimCalendar.days(5)), "Saturday")
	assert_false(SimCalendar.is_workday(SimCalendar.days(6)), "Sunday")
	assert_true(SimCalendar.is_workday(SimCalendar.days(7)), "next Monday")


func test_parse_hhmm() -> void:
	assert_eq(SimCalendar.parse_hhmm("07:30"), 450)
	assert_eq(SimCalendar.parse_hhmm("16:00"), 960)
	assert_eq(SimCalendar.parse_hhmm("930"), -1)
	assert_eq(SimCalendar.parse_hhmm("ab:cd"), -1)


func test_pool_shift() -> void:
	var p := SimPool.new()
	p.shift_start = 450
	p.shift_end = 930
	assert_true(p.is_on_shift(500))
	assert_false(p.is_on_shift(940))
	assert_false(p.is_on_shift(SimCalendar.days(5) + 500), "Saturday")
