extends TestCase
## The screenshot tool's arguments (PLAN 3.0): <state> <png> [frames] first, then named
## ones (--at HH:MM, --season name); flags it does not know (--designer) are left alone.


func test_parse_positional_only() -> void:
	var shot := PlayShotArgs.parse(PackedStringArray(["people_desks", "/tmp/a.png"]))
	assert_eq(shot["state"], "people_desks")
	assert_eq(shot["out"], "/tmp/a.png")
	assert_eq(shot["frames"], 20, "frames default to 20")
	assert_eq(shot["at"], -1, "no clock asked for")
	assert_eq(shot["season"], "", "no season asked for")
	assert_eq(shot["error"], "", "nothing wrong with no flags")
	shot = PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "30"]))
	assert_eq(shot["frames"], 30)


func test_parse_at_and_season() -> void:
	var shot := PlayShotArgs.parse(PackedStringArray(
		["people_desks", "/tmp/a.png", "30", "--at", "18:30", "--season", "winter"]))
	assert_eq(shot["frames"], 30)
	assert_eq(shot["at"], 18 * 60 + 30)
	assert_eq(shot["season"], "winter")
	assert_eq(shot["error"], "", "a good clock and season")
	shot = PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--at", "7:05"]))
	assert_eq(shot["at"], 7 * 60 + 5, "a one-digit hour is fine")
	assert_eq(shot["frames"], 20, "named arguments are not frames")


func test_bad_at_is_minus_one() -> void:
	for bad: String in ["25:99", "18:60", "24:00", "1830", "ab:cd", "18:3", "", "-1:30"]:
		var shot := PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--at", bad]))
		assert_eq(shot["at"], -1, "'%s' is no time of day" % bad)
		assert_true("--at" in shot["error"], "a bad '%s' is said: %s" % [bad, shot["error"]])
	var missing := PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--at"]))
	assert_eq(missing["at"], -1, "--at without a value")
	assert_true("--at" in missing["error"], "and said")


## A flag's value never starts with --: the next flag stays a flag, the missing value is the error.
func test_a_flag_does_not_swallow_the_next_flag() -> void:
	var shot := PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--at", "--season", "winter", "12"]))
	assert_eq(shot["at"], -1)
	assert_eq(shot["season"], "winter", "--season still counts")
	assert_eq(shot["frames"], 12)
	assert_true("--at" in shot["error"], shot["error"])
	shot = PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--season", "--at", "09:15"]))
	assert_eq(shot["season"], "")
	assert_eq(shot["at"], 9 * 60 + 15, "--at still counts")
	assert_true("--season" in shot["error"], shot["error"])
	shot = PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--season"]))
	assert_true("--season" in shot["error"], "a flag at the end has no value")


func test_unknown_flags_are_left_alone() -> void:
	var shot := PlayShotArgs.parse(PackedStringArray(["designer_page", "/tmp/a.png", "--designer"]))
	assert_eq(shot["state"], "designer_page")
	assert_eq(shot["frames"], 20, "--designer is no frames")
	shot = PlayShotArgs.parse(PackedStringArray(["office", "/tmp/a.png", "--designer", "--at", "09:15", "12"]))
	assert_eq(shot["at"], 9 * 60 + 15)
	assert_eq(shot["frames"], 12, "a positional after the flags still counts")
	assert_eq(shot["out"], "/tmp/a.png")
