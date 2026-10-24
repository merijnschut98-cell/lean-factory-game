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


## Arc S11: her call is a talk on two missions, so a player who never reached
## the status callers still hears from her before the frost.
func test_her_call_rings_before_the_frost_without_the_status_callers() -> void:
	var s := _session()
	s.missions.done_once["walk_connections"] = true
	s.missions.play_start -= SimCalendar.days(49)   # 30 November: Voor de vorst opens
	s.pass_time(0)
	assert_eq(s.missions.status("winter_el_amrani"), "active")
	assert_ne(s.missions.status("fix_status_callers"), "active")
	var calls := s.customer_calls().filter(func(c: Dictionary) -> bool: return c["person"] == "el_amrani")
	assert_eq(calls.map(func(c: Dictionary) -> String: return c["dialog"]), ["el_amrani_fourth_call"])
	_at(s, 10 * 60)
	assert_eq(CustomerCalls.ringing(s, SessionLayer.new()).get("dialog"), "el_amrani_fourth_call", "her phone call")


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


func test_a_ringing_call_taken_at_the_headset_leaves_no_voicemail() -> void:
	var office := _office()
	_calling(office.session)
	_at(office.session, 10 * 60)
	office.ui.after_action()
	assert_true(office.ui.incoming.visible)
	var unread := office.ui.phone.unread_count()
	assert_eq(office.ui.open_talk("el_amrani", TalkView.HEADSET), "")
	assert_false(office.ui.incoming.visible, "she is on the line now")
	assert_eq(office.ui.phone.unread_count(), unread, "no voicemail")
	office.free()


static func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	return key


## Review S3 #2: a view over the world that is not a panel (the KPI board) lets the
## ringing call go to voicemail, rings nothing while it is up, and its keys stay its own.
func test_the_kpi_board_lets_a_ringing_call_go_and_keeps_its_keys() -> void:
	var office := _office()
	_calling(office.session)
	_at(office.session, 10 * 60)
	office.session.hang_kpi_board()
	office.floors.go_to("second", "lift", true)
	office.ui.after_action()
	var ring := office.ui.incoming
	var call := ring.call.duplicate()
	assert_true(ring.visible, "the phone rings")
	var unread := office.ui.phone.unread_count()
	assert_true(office.open_kpi_board() != null, "the board opens")
	assert_false(ring.visible, "the call goes to voicemail")
	assert_eq(office.ui.phone.unread_count(), unread + 1, "her voicemail in Berichten")
	assert_false(office.world_free())
	ring.ring(call)   # a ring that slipped through
	ring._shortcut_input(_key(IncomingCall.ANSWER_KEY))
	assert_false(office.ui.talk_view.visible, "1 is the board's key: no talk opens")
	assert_true(office.kpi_board != null and not office.player.active, "the world stays locked")
	office.free()


func test_no_call_rings_over_a_view_on_the_world() -> void:
	var office := _office()
	_calling(office.session)
	_at(office.session, 10 * 60)
	office.session.hang_kpi_board()
	office.floors.go_to("second", "lift", true)
	assert_true(office.open_kpi_board() != null)
	office.ui.after_action()
	assert_false(office.ui.incoming.visible, "not while the board is up")
	office.kpi_board.close()
	assert_true(office.world_free())
	assert_true(office.ui.incoming.visible, "it rings once the world is free again (today's ring was not used)")
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


## Ilse's queue is a customer call too: the KCC opens with her mission.
func test_the_kcc_opens_for_ilse_s_call() -> void:
	var office := _office()
	office.session.missions.progress["fix_unused_capacity"] = {"status": "active", "asks": {}, "seen": {}}
	office.reload_rooms()
	office.floors.go_to("ground", "lift", true)
	assert_true(office.interactable(OfficeHeadset.ID) != null, "the headset place at the KCC")
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


## On the call you wear the desk's headset: on your head, gone from the desk;
## after it, back on the desk.
func test_the_player_wears_the_desk_s_headset_on_the_call() -> void:
	var office := _office()
	_calling(office.session)
	office.reload_rooms()
	office.floors.go_to("ground", "lift", true)
	var on_desk := office.find_marker(OfficeHeadset.DESK + "_headset")
	assert_false(office.player.wears_headset(), "not before the call")
	office.interact(office.interactable(OfficeHeadset.ID))
	assert_true(office.ui.talk_view.talking())
	assert_true(office.player.wears_headset(), "on your head")
	assert_false(on_desk.visible, "gone from the desk")
	office.ui.close_panels()
	office.ui.close_panels()
	assert_false(office.player.wears_headset(), "off again after the call")
	assert_true(on_desk.visible, "back on the desk")
	office.free()
