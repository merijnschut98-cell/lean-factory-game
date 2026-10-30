extends TestCase
## Strain (PLAN 3.1-A): what the work puts on a person, from the team's smoothed load,
## their morale and recent pressure. The office reads it (who stays late, posture, chatter,
## a sick day); no other file holds a threshold for it.

const MISSION := "fix_custom_design"
const FIX := "custom_design"
const FIXING := "standard_designs"


## A new game with the stack at Werkvoorbereiding as the main mission: a problem only stays on
## while a mission holds it (MissionSync.retire_orphans), so its mission takes it on.
func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.accept(MISSION), "")
	return s


## The fix in place as Region.act leaves it: the problem gone, its countermeasure's effects on.
func _fix_in_place(s: GameSession) -> void:
	s.region.deactivate(FIX)
	s.region.state[FIX].phase = ProblemState.Phase.RESOLVED
	s.region.net.set_effects("cm:" + FIX, s.region.countermeasures[FIXING].effects)


## Pim (team prep) pressed today, worn down: fed `days` days of a heavy load.
func _worn_pim(pressed: bool, morale: int, days: int) -> People:
	var people := DialogFixture.people()
	people.morale["pim"] = morale
	if pressed:
		people.talk_log["pim"] = [{"dialog": "talk", "at": 0, "outcome": "ruined", "trace": [], "moves": ["pressure"]}]
	for day in days + 1:
		people.daily(DialogFixture.world({"now": SimCalendar.days(day), "loads": {"prep": 1.2}}))
	return people


func _off_days_in_week(people: People, week: int) -> int:
	var off := 0
	for day in range(week * 7, week * 7 + 7):
		if people.off_on("pim", day):
			off += 1
			assert_true(day % 7 < 5, "a sick day is a working day")
	return off


# ── The reading ─────────────────────────────────────────────────────────────

func test_reading_is_zero_on_an_ordinary_day() -> void:
	assert_eq(Strain.reading(People.LOAD_NORM, 60, false), 0.0)


func test_reading_weights_each_part() -> void:
	assert_near(Strain.reading(People.LOAD_NORM + People.LOAD_SPAN, Strain.STRAIN_MORALE, false), Strain.LOAD_W, 1e-9)
	assert_near(Strain.reading(0.5, People.LEAVE_MORALE, false), Strain.MORALE_W, 1e-9)
	assert_near(Strain.reading(0.5, 60, true), Strain.PRESSURE_W, 1e-9)
	assert_eq(Strain.reading(2.0, 0, true), 1.0)


func test_neglect_without_load_never_keeps_someone_late() -> void:
	assert_true(Strain.reading(People.LOAD_NORM, People.NEGLECT_FLOOR, false) < Strain.LATE_AT)


func test_the_bands() -> void:
	assert_eq(Strain.BANDS, ["low", "mid", "high"] as Array[String], "mirrored in tools/build_content.py CHATTER_STRAINS")
	assert_eq(Strain.band(Strain.EASY_BELOW - 0.01), "low")
	assert_eq(Strain.band(Strain.EASY_BELOW), "mid")
	assert_eq(Strain.band(Strain.LATE_AT - 0.01), "mid")
	assert_eq(Strain.band(Strain.LATE_AT), "high")


func test_sick_weekday_is_a_working_day_and_stable() -> void:
	for week in 30:
		var day := Strain.sick_weekday("anouk", week)
		assert_between(day, 0, 4, "week %d" % week)
		assert_eq(day, Strain.sick_weekday("anouk", week), "the same every time")


# ── Smoothing ───────────────────────────────────────────────────────────────

func test_smoothing_over_a_span_equals_day_by_day() -> void:
	var stepwise := 1.08
	for i in 14:
		stepwise = Strain.smoothed(stepwise, 0.70, 1)
	assert_near(Strain.smoothed(1.08, 0.70, 14), stepwise, 1e-9)
	assert_eq(Strain.smoothed(1.08, 0.70, 0), 1.08, "no day, no change")


# ── Through the simulation ──────────────────────────────────────────────────

func test_a_holding_fix_sends_anouk_home_within_14_days() -> void:
	var s := _session()
	s.wait_days(21)
	assert_true(OfficeDay.late_ids(s, ["anouk"]).has("anouk"), "the problem keeps her late: %.2f" % s.strain_of("anouk"))
	_fix_in_place(s)
	s.wait_days(14)
	assert_false(OfficeDay.late_ids(s, ["anouk"]).has("anouk"), "the fix holds, she goes home: %.2f" % s.strain_of("anouk"))


func test_the_problem_back_brings_her_desk_lamp_back_within_14_days() -> void:
	var s := _session()
	s.wait_days(21)
	_fix_in_place(s)
	s.wait_days(14)
	s.region.deactivate(FIX)  # the fix fades: its effects go and the problem is the mission's again
	assert_true(s.region.activate(FIX))
	s.wait_days(14)
	assert_true(OfficeDay.late_ids(s, ["anouk"]).has("anouk"), "late again: %.2f" % s.strain_of("anouk"))


# ── Absence ─────────────────────────────────────────────────────────────────

func test_absence_needs_load_wear_and_pressure() -> void:
	var worn := _worn_pim(true, 25, Strain.ABSENT_AFTER_DAYS)
	for week in range(3, 6):
		assert_eq(_off_days_in_week(worn, week), 1, "week %d: one day off" % week)
	assert_false(worn.off_on("pim", Strain.ABSENT_AFTER_DAYS - 2), "not before the weeks of strain are in")
	# Load alone wears no one below NEGLECT_FLOOR (People._drift): that is as far as it goes without pressure.
	var calm := _worn_pim(false, People.NEGLECT_FLOOR, Strain.ABSENT_AFTER_DAYS)
	for week in range(3, 6):
		assert_eq(_off_days_in_week(calm, week), 0, "week %d: no pressure, no day off" % week)


func test_a_sick_day_takes_a_head_from_the_team_for_that_day() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var pool: SimPool = s.region.net.pools["work_prep"]
	var heads := pool.headcount
	# Anouk's strain stands at the absence level (load, wear), for three weeks already.
	s.people.load_seen["work_prep"] = 1.2
	s.people.morale["anouk"] = People.LEAVE_MORALE
	s.people.strained_since["anouk"] = 0
	var today := SimCalendar.day_of(s.region.net.time)
	var sick: int = range(today + 2, today + 9).filter(func(d: int) -> bool: return s.people.off_on("anouk", d))[0]
	while SimCalendar.day_of(s.region.net.time) + 2 < sick:
		s.wait_days(1)
		assert_false(s.region.net.effects().has(GameSession.ABSENT_SOURCE + "work_prep"), "nobody off tomorrow")
	s.wait_days(1)   # the evening before: tomorrow she is off
	assert_eq(s.region.net.effects()[GameSession.ABSENT_SOURCE + "work_prep"],
		[{"target": "work_prep", "property": "headcount", "value": -1}] as Array, "set for tomorrow")
	assert_eq(pool.headcount, heads - 1)
	assert_false(s.absent_today("anouk"), "today she is in")
	s.wait_days(1)
	assert_true(s.absent_today("anouk"), "the day itself")
	assert_eq(SimCalendar.day_of(s.region.net.time), sick)
	s.wait_days(1)
	assert_false(s.region.net.effects().has(GameSession.ABSENT_SOURCE + "work_prep"), "back the day after")
	assert_eq(pool.headcount, heads)


func test_someone_who_left_has_no_strain() -> void:
	var people := _worn_pim(true, 25, Strain.ABSENT_AFTER_DAYS)
	var now := SimCalendar.days(Strain.ABSENT_AFTER_DAYS)
	assert_true(people.strain("pim", now) > Strain.ABSENT_AT)
	people.left["pim"] = true
	assert_eq(people.strain("pim", now), 0.0)
	assert_eq(_off_days_in_week(people, 4), 0)
	assert_eq(people.strain("nobody", now), 0.0, "an unknown person")


func test_a_span_counts_the_reading_of_today_for_each_working_day_in_it() -> void:
	var people := DialogFixture.people()
	people.morale["pim"] = 25
	people.daily(DialogFixture.world({"now": 0, "loads": {"prep": 1.2}}))
	assert_eq(people.late_log, [] as Array[int], "no day has passed yet")
	people.daily(DialogFixture.world({"now": SimCalendar.days(14), "loads": {"prep": 1.2}}))
	assert_eq(people.late_log.size(), 10, "days 1 to 14 hold ten working days")
	assert_true(people.late_log.all(func(n: int) -> bool: return n == 1), "Pim at the late level on each: %s" % [people.late_log])
	people.daily(DialogFixture.world({"now": SimCalendar.days(14 + 60), "loads": {"prep": 1.2}}))
	assert_eq(people.late_log.size(), People.LATE_LOG_DAYS, "the last twenty working days")


func test_sick_days_are_counted_for_the_working_days_of_a_span() -> void:
	var worn := _worn_pim(true, 25, Strain.ABSENT_AFTER_DAYS)
	var expected := 0
	for day in range(1, Strain.ABSENT_AFTER_DAYS + 1):
		expected += 1 if worn.off_on("pim", day) else 0
	assert_eq(worn.sick_days, expected)
	var later := Strain.ABSENT_AFTER_DAYS + 28
	worn.daily(DialogFixture.world({"now": SimCalendar.days(later), "loads": {"prep": 1.2}}))
	for day in range(Strain.ABSENT_AFTER_DAYS + 1, later + 1):
		expected += 1 if worn.off_on("pim", day) else 0
	assert_eq(worn.sick_days, expected, "the working days of the span, each with its own weekday off")
	assert_true(expected >= 4, "about one a week: %d" % expected)


func test_pressure_is_a_move_in_the_last_month_or_a_fix_won_by_compliance() -> void:
	var people := DialogFixture.people()
	var now := SimCalendar.days(100)
	assert_false(people.pressed("pim", now))
	people.talk_log["pim"] = [{"dialog": "talk", "at": now - SimCalendar.days(Strain.PRESSED_DAYS), "outcome": "ruined", "trace": [], "moves": ["mood", "confront"]}]
	assert_true(people.pressed("pim", now), "a confrontation, thirty days ago")
	assert_false(people.pressed("pim", now + 1), "and a minute more is a month ago")
	people.talk_log.clear()
	people.outcomes["talk"] = "compliance"
	assert_true(people.pressed("pim", now), "the fix Pim owns was won by compliance")
	people.outcomes["talk"] = "commitment"
	assert_false(people.pressed("pim", now))


func test_old_save_without_strain_state_loads_calm() -> void:
	var people := DialogFixture.people()
	people.morale["pim"] = 25
	assert_eq(people.load_dict({"morale": {"pim": 25}}), [])
	assert_eq(people.strain("pim", 0), 0.0, "nothing measured yet")
	assert_true(people.load_seen.is_empty() and people.strained_since.is_empty() and people.late_log.is_empty())
	assert_eq(people.sick_days, 0)
	people.daily(DialogFixture.world({"now": 0, "loads": {"prep": 1.2}}))
	assert_true(people.strain("pim", 0) > 0.0, "the first day measures")


func test_no_threshold_outside_strain() -> void:
	for script: Script in [OfficeDay, OfficePerson]:
		var constants := script.get_script_constant_map()
		for name in ["LOAD_NORM", "LOW_MORALE", "TIRED_ENERGY"]:
			assert_false(constants.has(name), "%s has no %s" % [script.resource_path.get_file(), name])
