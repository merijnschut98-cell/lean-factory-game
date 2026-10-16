extends TestCase
## The route test (PLAN 1.6c; four-tier audit §4.4, T6): no fixed sequence of
## moves wins more than half of a tier's persuasion talks, measured on the real
## rules over the real content. And the content tests of the dialog spec §9.3
## (D10, T7, T11): every persuasion has three routes at least, pushing early
## costs, pressure gives compliance.


## The most tier-1 talks one route may win today (target: half, PLAN 1.6c).
const TIER1_RATCHET := 10


func _catalog() -> Catalog:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	return c


func test_the_checker_finds_a_route_that_wins() -> void:
	var talk := DialogRoutes.start(DialogFixture.def(), DialogFixture.person(), DialogFixture.bank(), 50)
	var best := DialogRoutes.best_route([talk, talk])
	assert_eq(best["wins"], 2, "the same talk twice: one route wins both")
	assert_true(DialogRoutes.wins(talk, best["route"]), "and replays as a win")
	assert_eq(best["route"].back(), "ask_commitment")


## THE ROUTE TEST, on tier 1 as it will be: the talks in content/dialogs.yaml,
## and the Acts 0–II scripts' persuasion talks not in content yet
## (tests/data/tier1_scripts.json, from tools/dialog_drafts.py; regenerate it
## when the scripts change). The later tiers are measured from their drafts
## with game/tools/route_check.gd (PLAN 1.6c has the numbers). The Act 0 week's
## own tutorial talks are measured apart (the next test): they cannot be lost.
func test_no_fixed_route_wins_more_than_half_of_the_persuasion_talks() -> void:
	var c := _catalog()
	var talks := DialogRoutes.tier1_talks(c)
	assert_eq(talks.size(), 20, "the twenty persuasion talks of Acts 0–II")
	var best := DialogRoutes.best_route(talks)
	# The target is half (10 of 20). Measured 2026-10-16 with E1–E5, needs and
	# wear-out: 11; after the scripts' route variety (El Amrani winnable;
	# Petra, Mieke and Rob's concerns opened by data, a summary, a story): 8
	# (PLAN 1.6c). The limit is the target; it may only go down.
	assert_true(best["wins"] <= TIER1_RATCHET,
		"%d of %d talks won by one route: %s (%s)" % [best["wins"], talks.size(), " ".join(best["route"]),
		", ".join(best["won"])])


## D10 / T7: no golden path. Three winning routes at least, each pair
## differing in two positions or more.
func test_every_persuasion_has_three_different_routes() -> void:
	for talk in DialogRoutes.content_talks(_catalog()):
		var distinct := DialogRoutes.distinct(DialogRoutes.best_route([talk])["winners"])
		assert_true(distinct.size() >= 3, "%s: %d distinct routes" % [talk.def.id, distinct.size()])


## The Act 0 week (tutorial talks spec §1, §5): the day's move is a good way
## through, never the only one, and no talk can be lost, however hard it is pushed.
func test_every_tutorial_talk_is_won_without_its_day_s_move_and_never_ruined() -> void:
	var tutorials := DialogRoutes.content_talks(_catalog()).filter(func(t: Dialog) -> bool: return t.def.tutorial)
	assert_eq(tutorials.size(), 11, "anouk_seven and the ten talks of the training week")
	for talk: Dialog in tutorials:
		assert_eq(DialogRoutes.best_route([talk], DialogRoutes.WIDTH, Array(talk.def.teaches))["wins"], 1,
			"%s: a route without %s" % [talk.def.id, talk.def.teaches])
		var pushed := talk.copy()
		DialogFixture.play(pushed, ["confront", "pressure", "confront", "pressure", "confront"])
		assert_true(pushed.openness >= Dialog.RUINED_BELOW and pushed.outcome != "ruined", talk.def.id)


## T11: steering before listening costs, and pressure gets a yes without the
## person: after the first listening moves of the talk's own best route (a
## customer at 20 is lost to pressure at once, which is no yes at all).
func test_pushing_early_costs_and_pressure_gives_compliance() -> void:
	for talk in DialogRoutes.content_talks(_catalog()):
		var pushed := talk.copy()
		var r := pushed.say("propose", DialogRoutes.pick(pushed, "propose"))
		assert_true(r["delta"] < 0, "%s: a proposal before listening costs" % talk.def.id)
		var listened := []
		for move: String in DialogRoutes.best_route([talk])["route"]:
			if not move in Dialog.LISTEN or listened.size() == 2:
				break
			listened.append(move)
		var pressed := talk.copy()
		DialogFixture.play(pressed, listened + ["pressure", "propose:" + DialogRoutes.pick(pressed, "propose"), "ask_commitment"])
		assert_eq(pressed.outcome, "compliance", "%s after %s" % [talk.def.id, listened])


## A copy plays on exactly as the talk it was taken from.
func test_a_copy_of_a_talk_is_the_whole_talk() -> void:
	var talk := DialogFixture.talk(50)
	DialogFixture.play(talk, ["mood", "reflect", "open_question"])
	var c := talk.copy()
	for p: Dictionary in talk.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not p["name"] in ["def", "who", "bank"]:
			assert_true(p["name"] in Dialog.COPIED, "copy() knows %s" % p["name"])
	assert_eq(Dialog.STATE_KEYS, Dialog.COPIED.find("trace"), "state_key() reads up to the trace")
	assert_eq(c.state_key(), talk.state_key())
	assert_eq(c.say("reflect"), talk.say("reflect"))

