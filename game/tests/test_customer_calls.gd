extends TestCase
## The customer call (PLAN 2.4, phase 2 design §1.7 and §2.5): a customer is
## reached by phone. At the KCC (begane grond) you sit down at a free desk, put
## on the headset and take the next call; and a customer whose talk is due
## rings the player's phone, once a day, in office hours. Answering opens the
## call; letting it go costs nothing and leaves a voicemail in Berichten
## (respect the player's time). A promise made on the phone (a date or an
## action) is kept as a fact the simulation checks later:
## promised:<dialog>:<ISO date> for a date, promised:<dialog>:<kind> for an action.

const SCENE := "res://src/world/office/office.tscn"
const EL_AMRANI_MISSIONS := ["fix_unused_capacity", "fix_incomplete_application"]


func _session() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(s.error, "")
	return s


## Mrs El Amrani's fourth call is due: fix_status_callers is on.
func _calling(s: GameSession) -> GameSession:
	for id in EL_AMRANI_MISSIONS:
		s.missions.done_once[id] = true
	assert_eq(s.accept("fix_status_callers"), "")
	return s


## A minute of the current play day (office hours by default).
static func _at(s: GameSession, minute: int) -> void:
	s.region.net.time = SimCalendar.days(SimCalendar.day_of(s.region.net.time)) + minute


# ── Who calls ───────────────────────────────────────────────────────────────

func test_customers_are_marked_and_leave_a_voicemail_line() -> void:
	var s := _session()
	for id in ["el_amrani", "ilse"]:
		var p: PersonDef = s.people.persons[id]
		assert_true(p.customer, id + " is a customer")
		assert_false(p.voicemail.is_empty(), id + " has a voicemail line")
	assert_false(s.people.persons["joost"].customer, "a colleague is not")


func test_a_customer_call_is_due_only_when_their_talk_is() -> void:
	var s := _session()
	assert_eq(s.customer_calls(), [], "nobody: no customer talk is on")
	_calling(s)
	var calls := s.customer_calls()
	assert_eq(calls.map(func(c: Dictionary) -> String: return c["person"]), ["el_amrani"])
	assert_eq(calls[0]["dialog"], "el_amrani_fourth_call")
	assert_eq(calls[0]["name"], "Fatima El Amrani")


# ── The promise ─────────────────────────────────────────────────────────────

## Agree on a proposal at the end of the call (the moves that lead there are
## the dialog tests' business; this is about what the agreement leaves behind).
func _agree(s: GameSession, proposal: String) -> Dictionary:
	assert_eq(s.start_dialog("el_amrani")["dialog"], "el_amrani_fourth_call")
	s._talk.openness = 60
	s._talk.revealed = {"interest": true, "concern": true}
	s._talk.table = proposal
	return s.choose_move("ask_commitment")


func test_a_date_promised_on_the_phone_is_kept_as_a_fact_with_the_date() -> void:
	var s := _calling(_session())
	var r := _agree(s, "name_a_date")
	assert_true(r["ended"])
	assert_true(r["outcome"] in ["partial", "commitment"], r["outcome"])
	var day := SimCalendar.day_of(s.region.net.time)
	var due := GameSession.iso_date(SimCalendar.days(day + 42))
	assert_true(s.knows("promised:el_amrani_fourth_call:" + due), "the date six weeks on: " + due)
	assert_eq(s.missions.facts.with_prefix("promised:el_amrani_fourth_call:").size(), 1, "one promise")


func test_an_action_promised_is_kept_by_its_kind() -> void:
	var s := _calling(_session())
	_agree(s, "honest_window_and_contact")
	assert_true(s.knows("promised:el_amrani_fourth_call:callback"))


func test_iso_dates_read_the_game_s_calendar() -> void:
	assert_eq(GameSession.iso_date(SimCalendar.days(GameSession.WARMUP_DAYS)), "2026-10-12", "day 0 of play")
	assert_eq(GameSession.iso_date(SimCalendar.days(GameSession.WARMUP_DAYS + 50)), "2026-12-01")


func test_a_promise_fact_survives_a_save() -> void:
	var f := Facts.new()
	f.load_list(["promised:el_amrani_fourth_call:2026-12-01"])
	assert_true(f.has("promised:el_amrani_fourth_call:2026-12-01"))


# ── The phone rings ─────────────────────────────────────────────────────────

func test_the_phone_rings_once_a_day_in_office_hours() -> void:
	var s := _calling(_session())
	var layer := SessionLayer.new()
	_at(s, 7 * 60)
	assert_eq(CustomerCalls.ringing(s, layer), {}, "not before the KCC opens")
	_at(s, 10 * 60)
	var call := CustomerCalls.ringing(s, layer)
	assert_eq(call.get("person"), "el_amrani")
	CustomerCalls.rang(s, layer, call)
	assert_eq(CustomerCalls.ringing(s, layer), {}, "once a day")
	s.region.net.time += SimCalendar.days(1)
	assert_eq(CustomerCalls.ringing(s, layer).get("person"), "el_amrani", "and again the next day")


func test_a_call_let_go_is_a_voicemail_never_a_cost() -> void:
	var s := _calling(_session())
	var layer := SessionLayer.new()
	_at(s, 10 * 60)
	var before := [s.people.trust["el_amrani"], s.people.morale["el_amrani"], s.region.reputation]
	var call := CustomerCalls.ringing(s, layer)
	CustomerCalls.rang(s, layer, call)
	CustomerCalls.missed(s, layer, call)
	assert_eq([s.people.trust["el_amrani"], s.people.morale["el_amrani"], s.region.reputation], before, "nothing lost")
	assert_eq(PhoneMessages.unread_in(layer).size(), 1, "a message in Berichten")
	var m := PhoneMessages.render(s, layer.inbox[0])
	assert_true(m["from"].contains("Fatima El Amrani"), m["from"])
	assert_true(m["lines"][0].contains(s.people.persons["el_amrani"].voicemail), "her voicemail")
	assert_eq(s.start_dialog("el_amrani")["dialog"], "el_amrani_fourth_call", "her talk waits")


func test_which_day_a_call_rang_survives_a_save() -> void:
	var layer := SessionLayer.new()
	layer.rang["el_amrani_fourth_call"] = 3
	var back := SessionLayer.new()
	back.load_dict(JSON.parse_string(JSON.stringify(layer.to_dict())))
	assert_eq(back.rang, {"el_amrani_fourth_call": 3})
	back.load_dict({"rang": {"x": "nee", "y": 2}})
	assert_eq(back.rang, {"y": 2}, "junk dropped")


# ── In the office ───────────────────────────────────────────────────────────

func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func test_an_incoming_call_rings_and_can_be_answered() -> void:
	var office := _office()
	_calling(office.session)
	_at(office.session, 10 * 60)
	office.ui.after_action()
	var ring := office.ui.incoming
	assert_true(ring.visible, "the phone rings")
	assert_true(shows(ring, "Fatima El Amrani"), "her name on the screen")
	ring.answer()
	assert_false(ring.visible)
	assert_true(office.ui.talk_view.talking(), "the call opens")
	assert_eq(office.ui.talk_view.setting, TalkView.PHONE)
	office.free()


func test_an_incoming_call_can_be_let_go_and_leaves_a_message() -> void:
	var office := _office()
	_calling(office.session)
	_at(office.session, 10 * 60)
	office.ui.after_action()
	var unread := office.ui.phone.unread_count()
	office.ui.incoming.decline()
	assert_false(office.ui.incoming.visible)
	assert_false(office.ui.talk_view.visible, "no talk")
	assert_eq(office.ui.phone.unread_count(), unread + 1, "a voicemail in Berichten")
	office.ui.after_action()
	assert_false(office.ui.incoming.visible, "it does not ring again today")
	office.free()


func test_the_kcc_has_a_free_desk_with_a_headset() -> void:
	for c: Dictionary in CharacterModel.cast():
		assert_false(str(c.get("office", {}).get("seat", "")) == OfficeHeadset.DESK, "nobody sits there: " + str(c["id"]))
	var office := _office()
	_calling(office.session)   # the KCC opens with El Amrani's mission
	office.reload_rooms()
	office.floors.go_to("ground", "lift", true)
	var headset := office.interactable(OfficeHeadset.ID)
	assert_true(headset != null, "a headset place at the KCC")
	assert_eq(office.prompt_for(headset), tr(OfficeHeadset.PROMPT))
	office.free()


func test_the_headset_offers_a_call_only_when_a_customer_talk_is_due() -> void:
	var office := _office()
	office.floors.go_to("ground", "lift", true)
	var headset := Interactable.create(OfficeHeadset.ID, OfficeHeadset.stand(office))   # the KCC is shut so far
	office.add_child(headset)
	office.interact(headset)
	assert_false(office.ui.talk_view.visible, "no call waiting: no talk")
	assert_false(office.player.seated, "nobody to talk to: you stay standing")
	_calling(office.session)
	office.interact(headset)
	assert_true(office.ui.talk_view.talking(), "the next call")
	assert_eq(office.ui.talk_view.setting, TalkView.HEADSET, "on the headset, not the phone")
	assert_false(office.ui.talk_view.phone_shown(), "no phone raised")
	assert_true(office.player.seated, "sitting at the desk")
	office.ui.close_panels()
	office.ui.close_panels()
	assert_false(office.player.seated, "up again after the call")
	office.free()
