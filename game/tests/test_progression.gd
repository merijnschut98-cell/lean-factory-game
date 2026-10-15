extends TestCase
## Belts and XP pacing (Merijn, 2026-10-15: belts at 2k / 6k / 30k / 110k XP),
## so the top belt is not reached inside tier 1 (QA autoplay #18), and mission
## rewards that follow how well the problem was solved.


func test_belt_thresholds() -> void:
	assert_eq(Progression.BELTS.map(func(b: Dictionary) -> int: return b["xp"]), [0, 2000, 6000, 30000, 110000])
	assert_eq(Progression.belt_index(1999), 0)
	assert_eq(Progression.belt_index(2000), 1)
	assert_eq(Progression.belt_index(6000), 2)
	assert_eq(Progression.belt_index(29999), 2)
	assert_eq(Progression.belt_index(110000), 4)
	assert_near(Progression.belt_progress(1000), 0.5, 1e-9)


## Everything tier 1 can pay at most: every mission's reward and the best
## score on every problem (Pdca.xp_for). Even then the expert ends tier 1
## between green and black, and yellow comes only after the first fork.
func test_the_expert_path_through_tier_1_ends_green_below_black() -> void:
	var c := Catalog.load_from()
	var best := {"total": Pdca.MAX_SCORE}
	var xp := 0
	var before_fork := 0
	for m in c.missions:
		if m.tier == 1:
			xp += m.reward_xp
			if m.kind == "training" or m.id in ["walk_connections", "fix_custom_design"]:
				before_fork += m.reward_xp
	for p in c.problems:
		if p.tier == 1:
			xp += Pdca.xp_for(best, p.tier)
			if p.id in ["training_tray", "custom_design"]:
				before_fork += Pdca.xp_for(best, p.tier)
	assert_eq(Progression.belt_index(xp), 2, "%d XP: green, not black" % xp)
	assert_eq(Progression.belt_index(before_fork), 0, "%d XP before the fork: still white" % before_fork)
