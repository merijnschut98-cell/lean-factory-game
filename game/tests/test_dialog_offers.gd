extends TestCase
## Talks as four sentences (Merijn's playtest, 2026-10-19; PLAN 2.13 B): each
## turn offers up to four things to say, the MORE PIES move hidden under each:
## at least one that fits the moment, one or two plausible but weaker, at most
## one that costs; steering only once the talk is ready for it; the order
## shuffled per seed, so no position is the right one.

const TOOLS := ["perspective", "show_data", "propose_experiment", "pressure", "confront", "repair"]


## How option `o` would land now, judged by the rules on a copy (the oracle
## the offers are checked against): fits | weak | costly.
static func _fit(d: Dialog, o: Dictionary) -> String:
	var c := d.copy()
	var r := c.say(o["move"], o["pick"])
	if o["move"] in ["pressure", "confront"] or r["delta"] <= Dialog.COSTLY_AT:
		return "costly"
	if (r["lands"] and r["delta"] > 0) or not str(r["revealed"]).is_empty() or (c._lead_in_said and not d._lead_in_said) \
			or r["outcome"] in ["commitment", "lifted"]:
		return "fits"
	return "weak"


## Every option the rules allow now that fits (moves() with every pick).
static func _anything_fits(d: Dialog) -> bool:
	for m: Dictionary in d.moves():
		for p: Dictionary in m.get("picks", [{"id": ""}]):
			if m["id"] != "close" and _fit(d, {"move": m["id"], "pick": p["id"]}) == "fits":
				return true
	return false


## Play `d` through its offers, choosing with `choose(offers) -> index`; calls
## `check(d, offers)` before every choice. Returns the talk.
static func _play_offers(d: Dialog, choose: Callable, check: Callable = func(_d: Dialog, _o: Array) -> void: pass) -> Dialog:
	while d.outcome.is_empty():
		var offers := d.offer()
		check.call(d, offers)
		if offers.is_empty():
			break
		var o: Dictionary = offers[choose.call(offers)]
		d.say(o["move"], o["pick"])
	return d


## The fitting option if there is one, else the first.
static func _first_fit(d: Dialog) -> Callable:
	return func(offers: Array) -> int:
		for i in offers.size():
			if _fit(d, offers[i]) == "fits":
				return i
		return 0


func _catalog() -> Catalog:
	var c := Catalog.load_from()
	assert_eq(c.error, "")
	return c


func test_a_turn_offers_four_sentences_until_the_talk_ends() -> void:
	var d := DialogFixture.talk()
	var offers := d.offer()
	assert_eq(offers.size(), Dialog.OFFERED, "four options")
	for o: Dictionary in offers:
		assert_eq(o.keys().filter(func(k: String) -> bool: return not k in ["move", "pick", "line"]), [], "move, pick and line only")
		assert_false(str(o["line"]).is_empty(), "a sentence for " + o["move"])
		assert_true(o["move"] in Dialog.MOVES)
	d.say("close")
	assert_eq(d.offer(), [], "nothing to say after the end")


func test_an_offer_is_what_the_player_then_says() -> void:
	var d := DialogFixture.talk()
	for i in 4:
		var o: Dictionary = d.offer()[i % 2]
		assert_eq(d.say(o["move"], o["pick"])["line"], o["line"], "the sentence on the button is the one said")


func test_the_same_seed_and_moment_give_the_same_offer_and_seeds_differ() -> void:
	var d := DialogFixture.talk(35, {"seed": 7})
	assert_eq(d.offer(), d.offer(), "asked twice: the same")
	assert_eq(d.copy().offer(), d.offer(), "a copy: the same")
	assert_eq(DialogFixture.talk(35, {"seed": 7}).offer(), d.offer(), "the same seed: the same")
	var orders := {}
	for seed in 12:
		orders[str(DialogFixture.talk(35, {"seed": seed}).offer())] = true
	assert_true(orders.size() > 3, "the order and the choice change with the seed: %d different" % orders.size())


## Over every content talk, played by a player who takes the fitting option:
## one fits whenever anything fits, never two that cost, and steering waits
## until the talk is ready.
func test_every_offer_has_one_that_fits_at_most_one_that_costs_and_no_early_steering() -> void:
	var offers_seen := [0]  # a lambda captures a copy of an int, not of an array
	for talk: Dialog in DialogRoutes.content_talks(_catalog()):
		var d := talk.copy()
		_play_offers(d, _first_fit(d), func(now: Dialog, offers: Array) -> void:
			offers_seen[0] += 1
			assert_eq(offers.size(), Dialog.OFFERED, "%s after %s: four options" % [now.def.id, now.made])
			var fits := offers.filter(func(o: Dictionary) -> bool: return _fit(now, o) == "fits")
			var costly := offers.filter(func(o: Dictionary) -> bool: return _fit(now, o) == "costly")
			assert_true(costly.size() <= 1, "%s after %s: %d costly" % [now.def.id, now.made, costly.size()])
			if _anything_fits(now):
				assert_true(fits.size() >= 1, "%s after %s: nothing that fits in %s" % [now.def.id, now.made, offers])
			if not now.heard:
				for o: Dictionary in offers:
					assert_false(o["move"] in Dialog.STEER, "%s after %s: %s before the person feels heard" % [
						now.def.id, now.made, o["move"]]))
	assert_true(offers_seen[0] > 50, "the talks were played: %d turns" % offers_seen[0])


## The Act 0 week: sentences only, no data, experiments, perspective or
## pressure; the proposal and the ask once the talk is there; still won
## through what is offered.
func test_a_tutorial_talk_offers_no_tools_and_is_won_through_its_offers() -> void:
	for talk: Dialog in DialogRoutes.content_talks(_catalog()).filter(func(t: Dialog) -> bool: return t.def.tutorial):
		var d := talk.copy()
		_play_offers(d, _first_fit(d), func(now: Dialog, offers: Array) -> void:
			for o: Dictionary in offers:
				assert_false(o["move"] in TOOLS, "%s after %s: %s in a tutorial" % [now.def.id, now.made, o["move"]]))
		assert_eq(DialogRoutes.best_route([talk], DialogRoutes.WIDTH, [], false)["wins"], 1, talk.def.id + " through its offers")


## No position is "the right one": always taking the same button wins at
## most half of the persuasion talks.
func test_no_fixed_position_wins_more_than_half() -> void:
	var talks := DialogRoutes.content_talks(_catalog())
	for position in Dialog.OFFERED:
		var won := DialogRoutes.position_wins(talks, position)
		assert_true(won.size() * 2 <= talks.size(), "button %d wins %d of %d: %s" % [position + 1, won.size(), talks.size(), won])


## bank.player takes a list of variants per move (a single line stays valid):
## the same move twice in a talk says something else.
func test_the_player_s_lines_vary_without_repeating_in_a_talk() -> void:
	var bank := DialogFixture.bank()
	bank["player"]["open_question"] = ["Een.", "Twee.", "Drie."]
	assert_eq(Dialog.bank_error(bank), "", "a list of lines")
	var d := Dialog.new(DialogFixture.def(), DialogFixture.person(), bank, {"openness": 35, "seed": 3})
	var said := []
	for move: String in ["open_question", "mood", "open_question", "mood", "open_question"]:
		var line: String = d.say(move)["line"]
		if move == "open_question":
			said.append(line)
	said.sort()
	assert_eq(said, ["Drie.", "Een.", "Twee."], "each variant once")
	bank["player"]["open_question"] = []
	assert_ne(Dialog.bank_error(bank), "", "an empty list is no line")
	bank["player"]["open_question"] = ["Een.", 2]
	assert_ne(Dialog.bank_error(bank), "", "every variant a line")


## A clue you show is a sentence of its own: the session puts the clue in.
func test_showing_data_says_what_you_found() -> void:
	var d := DialogFixture.talk(50, {"seed": 1})
	DialogFixture.play(d, ["open_question", "paraphrase"])
	var data: Array = d.offer(20).filter(func(o: Dictionary) -> bool: return o["move"] == "show_data")
	assert_false(data.is_empty(), "heard, open enough: the data is offered")
	for o: Dictionary in data:
		assert_true(str(o["line"]).contains(Dialog.DATA_TOKEN), "the line names the clue: " + str(o["line"]))


## In the game: the session deals the four sentences of the talk in progress,
## a shown clue's own text in its line.
func test_the_session_offers_sentences_with_the_clue_in_them() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	assert_eq(s.dialog_offers(), [], "no talk, nothing to say")
	s.start_dialog("joost")
	var offers := s.dialog_offers()
	assert_eq(offers.size(), Dialog.OFFERED)
	for o: Dictionary in offers:
		assert_false(str(o["line"]).contains("{"), "filled: " + str(o["line"]))
	var clue: String = s.clues_found("silo_kpis").filter(func(c: Clue) -> bool: return c.id == "silo_kpis:4")[0].text
	var r := s.choose_move("show_data", "silo_kpis:4")
	assert_true(str(r["line"]).contains(clue), "the clue in what you said: " + str(r["line"]))
	assert_false(str(r["line"]).contains(Dialog.DATA_TOKEN))
