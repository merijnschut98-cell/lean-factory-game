extends TestCase


func test_week_starts_monday() -> void:
	assert_eq(SimCalendar.weekday(0), 0)
	assert_eq(SimCalendar.weekday(SimCalendar.days(5)), 5, "Saturday")
	assert_eq(SimCalendar.weekday(SimCalendar.days(7)), 0, "next Monday")
	assert_eq(SimCalendar.hours(1.5), 90)


func test_parse_hhmm() -> void:
	assert_eq(SimCalendar.parse_hhmm("07:30"), 450)
	assert_eq(SimCalendar.parse_hhmm("24:00"), 1440)
	assert_eq(SimCalendar.parse_hhmm("930"), -1)
	assert_eq(SimCalendar.parse_hhmm("ab:cd"), -1)


func test_parse_days() -> void:
	assert_eq(SimCalendar.parse_days("mon-fri"), PackedInt32Array([0, 1, 2, 3, 4]))
	assert_eq(SimCalendar.parse_days("sat"), PackedInt32Array([5]))
	assert_eq(SimCalendar.parse_days("mon-sun").size(), 7)
	assert_eq(SimCalendar.parse_days("fri-mon"), PackedInt32Array(), "ranges do not wrap")
	assert_eq(SimCalendar.parse_days("x"), PackedInt32Array())


func _day_shift() -> WeekSchedule:
	return WeekSchedule.from_blocks([NetFixture.block("mon-fri", "07:00", "15:00")])


func _on_call() -> WeekSchedule:
	return WeekSchedule.from_blocks(NetFixture.on_call())


func test_week_schedule_hours_and_membership() -> void:
	var day := _day_shift()
	assert_near(day.hours(), 40.0, 1e-9)
	assert_true(day.contains(SimCalendar.parse_hhmm("07:00")))
	assert_false(day.contains(SimCalendar.parse_hhmm("15:00")), "the end is exclusive")
	assert_false(day.contains(SimCalendar.days(5) + 500), "Saturday")
	assert_true(day.contains(SimCalendar.WEEK + 500), "repeats every week")


func test_week_schedule_runs_through_midnight() -> void:
	var on_call := _on_call()
	assert_near(on_call.hours(), 128.0, 1e-9)
	assert_true(on_call.contains(SimCalendar.parse_hhmm("23:55")))
	assert_true(on_call.contains(SimCalendar.days(1) + 5), "Tuesday 00:05")
	assert_false(on_call.contains(SimCalendar.days(1) + 600), "Tuesday 10:00 is day shift")


func test_next_start() -> void:
	var day := _day_shift()
	var friday_4pm := SimCalendar.days(4) + 960
	assert_eq(day.next_start(friday_4pm), SimCalendar.WEEK + 420, "Monday 07:00")
	assert_eq(day.next_start(500), 500, "already on")
	assert_eq(day.next_start(SimCalendar.days(6) + 1435), SimCalendar.WEEK + 420, "wraps from Sunday night")


func test_overlap_and_day_slots() -> void:
	var always := WeekSchedule.from_blocks([NetFixture.block("mon-sun", "00:00", "24:00")])
	assert_near(_day_shift().overlap_hours(always), 40.0, 1e-9)
	assert_near(_day_shift().overlap_hours(_on_call()), 0.0, 1e-9)
	assert_eq(_day_shift().slots_on_day(0).size(), 48)
	assert_eq(_day_shift().slots_on_day(0)[0], 420)
	assert_eq(_day_shift().slots_on_day(6).size(), 0)


func test_bad_blocks_are_refused() -> void:
	assert_eq(WeekSchedule.from_blocks([]), null, "no hours at all")
	assert_eq(WeekSchedule.from_blocks([{"days": "mon", "from": "15:00", "to": "07:00"}]), null)
	assert_eq(WeekSchedule.from_blocks([{"days": "maandag", "from": "07:00", "to": "15:00"}]), null)
	assert_eq(WeekSchedule.from_blocks([{"days": "mon", "from": "07:00"}]), null)
