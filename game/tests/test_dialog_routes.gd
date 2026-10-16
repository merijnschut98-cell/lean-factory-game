extends TestCase
## The route test (PLAN 1.6c; four-tier audit §4.4, T6): no fixed sequence of
## moves wins more than half of a tier's persuasion talks, measured on the real
## rules over the real content. And the content tests of the dialog spec §9.3
## (D10, T7, T11): every persuasion has three routes at least, pushing early
## costs, pressure gives compliance.


## The most tier-1 talks one route may win today (target: half, PLAN 1.6c).
const TIER1_RATCHET := 11


func _catalog() -> Catalog:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	return c


## Every persuasion talk in content, at the start People gives it on a first
## meeting (no team trust, no memory).
func _talks(c: Catalog) -> Array[Dialog]:
	var people := People.new(c.persons, c.dialogs, c.dialog_bank)
	var out: Array[Dialog] = []
	for d: DialogDef in c.dialogs:
		if d.kind != "persuade":
			continue
		var first := people.start(d, {"main": [d.mission], "active": [d.mission], "found": {}, "facts": {},
			"team_trust": 0, "blamed": false, "now": 0})
		out.append(DialogRoutes.start(d, people.persons[d.person], c.dialog_bank, first.openness))
	return out


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
## with game/tools/route_check.gd (PLAN 1.6c has the numbers).
func test_no_fixed_route_wins_more_than_half_of_the_persuasion_talks() -> void:
	var c := _catalog()
	var talks := _talks(c)
	var ids := talks.map(func(t: Dialog) -> String: return t.def.id)
	var scripts: Dictionary = JsonFile.read_dict("res://tests/data/tier1_scripts.json")["data"]
	var persons := {}
	for p: Dictionary in scripts["people"]:
		persons[p["id"]] = PersonDef.from_dict(p.merged({"place": "script"}))
	for d: Dictionary in scripts["dialogs"]:
		if not d["id"] in ids:
			talks.append(DialogRoutes.start(DialogDef.from_dict(d), persons[d["person"]], c.dialog_bank, int(d["start"])))
	assert_eq(talks.size(), 20, "the twenty persuasion talks of Acts 0–II")
	var best := DialogRoutes.best_route(talks)
	# The target is half (10 of 20). Measured 2026-10-16 with E1–E5, needs and
	# wear-out: 11 (PLAN 1.6c). Until the content reaches the target this is a
	# ratchet: it may only go down.
	assert_true(best["wins"] <= TIER1_RATCHET,
		"%d of %d talks won by one route: %s (%s)" % [best["wins"], talks.size(), " ".join(best["route"]),
		", ".join(best["won"])])


## D10 / T7: no golden path. Three winning routes at least, each pair
## differing in two positions or more.
func test_every_persuasion_has_three_different_routes() -> void:
	for talk in _talks(_catalog()):
		var distinct := []
		for r: Array in DialogRoutes.best_route([talk])["winners"]:
			if distinct.all(func(o: Array) -> bool: return _differ(o, r) >= 2):
				distinct.append(r)
		assert_true(distinct.size() >= 3, "%s: %d distinct routes" % [talk.def.id, distinct.size()])


## T11: steering before listening costs, and pressure gets a yes without the person.
func test_pushing_early_costs_and_pressure_gives_compliance() -> void:
	for talk in _talks(_catalog()):
		var pushed := talk.copy()
		var r := pushed.say("propose", DialogRoutes.pick(pushed, "propose"))
		assert_true(r["delta"] < 0, "%s: a proposal before listening costs" % talk.def.id)
		var pressed := talk.copy()
		DialogFixture.play(pressed, ["open_question", "pressure", "propose:" + DialogRoutes.pick(pressed, "propose"), "ask_commitment"])
		assert_eq(pressed.outcome, "compliance", talk.def.id)


## A copy plays on exactly as the talk it was taken from.
func test_a_copy_of_a_talk_is_the_whole_talk() -> void:
	var talk := DialogFixture.talk(50)
	DialogFixture.play(talk, ["mood", "reflect", "open_question"])
	var c := talk.copy()
	for p: Dictionary in talk.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not p["name"] in ["def", "who", "bank"]:
			assert_true(p["name"] in Dialog.COPIED, "copy() knows %s" % p["name"])
	assert_eq(c.state_key(), talk.state_key())
	assert_eq(c.say("reflect"), talk.say("reflect"))


func _differ(a: Array, b: Array) -> int:
	var n := absi(a.size() - b.size())
	for i in mini(a.size(), b.size()):
		n += 1 if a[i] != b[i] else 0
	return n
