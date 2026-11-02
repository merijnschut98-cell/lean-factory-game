extends TestCase
## The talk staged as two people talking (phase 2 design §2, S1-G): watch,
## then choose. They speak: a face shot and a subtitle that waits for the key.
## You choose: the two-shot, their last line under four sentences. On screen
## only the name and role, five small trust pips and the ▲/▼ after your line;
## the openness, its band, the mood and the layers go to the talk's note in
## the journal, written by the rules and shown once as the last screen.

const SCENE := "res://src/world/office/office.tscn"
const LISTEN_TO_JOOST := ["mood", "paraphrase", "inquiry", "reflect", "silence"]


## A person who records what the talk asks of their body.
class SpyPerson extends OfficePerson:
	var bands: Array[int] = []
	var hesitations := 0

	func pose_for_band(band: int) -> void:
		bands.append(band)

	func hesitate() -> void:
		hesitations += 1


## Act II's main mission open with Joost's own words found (his talk opens).
func _silo() -> GameSession:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	return s


func _view(s: GameSession) -> TalkView:
	var view := TalkView.new()
	view.session = s
	assert_eq(view.start("joost"), "")
	return view


## What a talk must never put on screen while it runs: the instruments.
func _instruments(s: GameSession) -> Array[String]:
	var out: Array[String] = ["Openheid", "Stemming", "Standpunt", "Belang", "Zorg", "Er zit meer achter"]
	out.append_array(Array(TalkView.labels_of(s).get("bands", []), TYPE_STRING, "", null))
	return out


func test_mid_talk_no_openness_band_mood_or_layer_tracker_is_on_screen() -> void:
	var s := _silo()
	var view := _view(s)
	var banned := _instruments(s)
	for move in LISTEN_TO_JOOST:
		for text in texts_in(view):
			for word in banned:
				assert_false(text.contains(word), "on screen mid-talk: \"%s\" in \"%s\"" % [word, text])
		assert_true(view.find_children("*", "OpennessBar", true, false).is_empty(), "no openness bar")
		assert_true(view.find_children("*", "MoodFace", true, false).is_empty(), "no 2D face")
		view.choose(move)
		if not view.talking():
			break
	view.free()


func test_the_name_role_and_five_small_trust_pips_are_on_screen() -> void:
	var s := _silo()
	var view := _view(s)
	assert_eq(view.title_label.text, "Joost van Dijk  ·  " + view.talk["role"])
	assert_true(shows(view, TalkView.pips(s.dialog_meter()["trust_pips"])), "the pips by the name")
	view.choose("pressure")
	assert_eq(view.trust_flash.text, "▼", "a trust change flashes")
	view.free()


## Keys a player sees and trust they see move (UX audit #12): a 20 px key chip left of each
## sentence, and the pips and their ▲/▼ at 18 px.
func test_each_sentence_has_its_key_chip_and_the_pips_are_readable() -> void:
	var view := _view(_silo())
	view.lines.finish()
	assert_eq(view.phase(), TalkView.CHOOSE)
	var chips := view.find_children(TalkView.KEY_CHIP, "PanelContainer", true, false)
	assert_eq(chips.size(), view.offers.size(), "one chip per sentence")
	for i in chips.size():
		var key: Label = chips[i].get_child(0)
		assert_eq(key.text, OS.get_keycode_string(TalkView.OPTION_KEYS[i]), "the chip shows its key")
		assert_eq(key.get_theme_font_size("font_size"), TalkView.KEY_CHIP_FONT)
		var row: Node = chips[i].get_parent()
		assert_true(row is HBoxContainer and row.get_child(0) == chips[i] and row.get_child(1) is Button,
			"left of its sentence, not on it")
	assert_eq(TalkView.KEY_CHIP_FONT, 20)
	view.choose("pressure")
	for l: Label in [view._pips, view.trust_flash]:
		assert_true(l.get_theme_font_size("font_size") >= 18, "readable: %d" % l.get_theme_font_size("font_size"))
	assert_eq(view.trust_flash.text, "▼", "the flash still works")
	view.free()


func test_your_line_carries_the_arrow_after_it() -> void:
	var view := _view(_silo())
	var said: Dictionary = view.offers[0]
	var r := view.choose_option(0)
	var you := TalkView.YOU % said["line"]
	var arrow := TalkView.arrow_text(r["arrow"])
	assert_true(shows(view, (you + "  " + arrow) if not arrow.is_empty() else you), "your line, then the arrow")
	view.free()


func test_they_speak_then_you_choose() -> void:
	var view := _view(_silo())
	assert_eq(view.phase(), TalkView.SPEAK, "the talk opens on their words")
	assert_true(view.lines.speaking())
	assert_false(view.press_key(KEY_1), "no choosing while they speak")
	assert_false(view.choices_shown(), "no sentences while they speak")
	view.lines.press()   # the first press shows the whole line
	assert_eq(view.phase(), TalkView.SPEAK, "the line waits for the key")
	view.lines.finish()
	assert_eq(view.phase(), TalkView.CHOOSE)
	assert_true(view.choices_shown(), "the four sentences")
	assert_true(shows(view, str(view.said_last().get("text", ""))), "their last line stays as a subtitle")
	assert_true(view.press_key(KEY_1), "1 says the first sentence")
	assert_eq(view.phase(), TalkView.SPEAK, "and they answer")
	view.free()


func test_the_body_takes_the_band_and_hesitates_on_the_cue() -> void:
	var s := _silo()
	var view := _view(s)
	var joost := SpyPerson.new()
	view.stage(joost)
	assert_eq(joost.bands, [s.dialog_meter()["band"]], "the pose of the band the talk opens in")
	var cue := false
	for move in LISTEN_TO_JOOST + ["empathy"]:
		var before: int = joost.bands[-1]
		var r := view.choose(move)
		cue = cue or r["cue"]
		var band := Dialog.band_of(r["openness"])
		if band != before:
			assert_eq(joost.bands[-1], band, "a new band, a new pose after " + move)
		else:
			assert_eq(joost.bands[-1], before, "no pose change within a band")
		if not view.talking():
			break
	assert_true(joost.bands.size() >= 2, "the pose changed on this path")
	for i in range(1, joost.bands.size()):
		assert_true(joost.bands[i] != joost.bands[i - 1], "only on a change")
	if cue:
		assert_true(joost.hesitations > 0, "the cue is a hesitation")
	view.free()
	joost.free()


## A talk that runs out of time ends on the person's word on how it went, after
## their reply (Merijn's playtest 2026-10-30: "no clarity about how the talk went").
func test_a_talk_out_of_time_ends_on_their_word_on_how_it_went() -> void:
	var view := _view(_silo())
	var r := {}
	while view.talking():
		r = view.choose("mood")
	assert_false(str(r["farewell"]).is_empty(), "ran out of time: a farewell")
	var queued: Array = view.lines.queue.map(func(l: Dictionary) -> String: return str(l.get("text", "")))
	assert_eq(queued.slice(-2), [r["reply"], r["farewell"]], "their reply, then their word on it")
	view.free()


func test_the_summary_lands_in_the_journal_and_shows_once() -> void:
	var s := _silo()
	var view := _view(s)
	for move in LISTEN_TO_JOOST:
		view.choose(move)
	var r := view.close_talk()
	assert_true(r["ended"])
	var talk: Dictionary = s.person("joost")["talks"][0]
	var note: Dictionary = TalkSummary.of(talk)
	assert_eq(note["outcome"], r["outcome"])
	assert_eq(talk["moves"], ["mood", "paraphrase", "inquiry", "reflect", "silence", "close"], "the trace, with the moves")
	assert_true(note["heard"].has("position") and note["heard"].has("interest"), "what was heard, per layer")
	assert_eq(note["band"], Dialog.band_of(r["openness"]), "the band it ended in")
	assert_false(str(note["mood"]).is_empty(), "the mood")
	view.lines.finish()
	assert_eq(view.phase(), TalkView.SUMMARY_SCREEN, "after their last words, the note")
	assert_true(shows(view, TalkSummary.SUMMARY), "shown as the talk's last screen")
	assert_true(shows(view, "Standpunt"), "the layers, named afterwards")
	assert_true(TalkSummary.notes(s).any(func(n: Dictionary) -> bool: return n["person"] == "joost"),
		"and in the journal's notes")
	view.free()


func test_a_saved_note_that_is_not_a_note_reads_as_empty() -> void:
	var note := TalkSummary.of({"dialog": "x", "at": 0, "outcome": "heard", "trace": [], "moves": [],
		"summary": {"heard": "nee", "hints": 4, "band": "drie", "mood": 7}})
	assert_eq(note["heard"], {})
	assert_eq(note["hints"], [])
	assert_eq(note["band"], -1)
	assert_eq(note["mood"], "")


# ── In the office: the camera and the settings ───────────────────────────────

func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _open_silo_in(office: Office) -> void:
	var s := office.session
	s.missions.done_once["fix_unused_capacity"] = true
	s.accept("fix_silo_kpis")
	s.region.found["silo_kpis:4"] = true
	office.people.refresh(s)


func test_the_camera_shows_their_face_while_they_speak_and_both_while_you_choose() -> void:
	var office := _office()
	_open_silo_in(office)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2
	office.use(joost)
	var view := office.ui.talk_view
	assert_true(view.talking())
	assert_eq(view.phase(), TalkView.SPEAK)
	assert_true(office.rig.shot in [CameraRig.FACE, CameraRig.CONVERSE], "their face while they speak")
	view.lines.finish()
	assert_eq(view.phase(), TalkView.CHOOSE)
	assert_eq(office.rig.shot, CameraRig.TWO_SHOT, "the two of you while you choose")
	view.press_key(KEY_1)
	assert_true(office.rig.shot in [CameraRig.FACE, CameraRig.CONVERSE], "their face again for the answer")
	office.free()


## In open floor the face shot is a face shot, from the side that sees the face.
func test_the_face_shot_looks_at_the_face_from_the_front() -> void:
	var office := _office()
	_open_silo_in(office)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2
	office.use(joost)
	assert_eq(office.rig.shot, CameraRig.FACE, "open floor beside his desk: a face shot")
	if office.rig.shot == CameraRig.FACE:
		office.rig.snap()
		var to_camera := (office.rig.camera.position - joost.position) * Vector3(1, 0, 1)
		var to_player := (office.player.position - joost.position) * Vector3(1, 0, 1)
		assert_true(to_camera.normalized().dot(to_player.normalized()) > 0.5, "on the player's side of him")
		assert_true(to_camera.length() < CameraRig.TALK_DISTANCE, "closer than the over-the-shoulder view")
	office.free()


func test_the_journal_keeps_the_talk_s_note() -> void:
	var office := _office()
	_open_silo_in(office)
	assert_eq(office.ui.open_talk("joost"), "")
	for move in LISTEN_TO_JOOST:
		office.ui.talk_view.choose(move)
	office.ui.close_panels()
	office.ui.close_panels()
	office.ui.toggle_phone(Phone.NOTES)
	assert_true(shows(office.ui.journal, TalkSummary.HEADING.left(12)), "the talk's note")
	assert_true(shows(office.ui.journal, "Standpunt"), "what was heard")
	office.free()


func test_a_phone_call_has_no_face_shot() -> void:
	var office := _office()
	var s := office.session
	for id in ["fix_unused_capacity", "fix_incomplete_application"]:
		s.missions.done_once[id] = true
	assert_eq(s.accept("fix_status_callers"), "")
	assert_true(office.people.person("el_amrani") == null, "she is not in the office")
	assert_eq(office.ui.open_talk("el_amrani"), "")
	var view := office.ui.talk_view
	assert_eq(view.setting, TalkView.PHONE, "a call")
	assert_eq(view.phase(), TalkView.SPEAK)
	assert_true(office.rig.shot != CameraRig.FACE, "no face to show")
	assert_true(view.phone_shown(), "the phone, raised")
	view.lines.finish()
	assert_true(office.rig.shot != CameraRig.TWO_SHOT, "nobody to stand beside")
	office.free()


func test_a_walking_talk_lets_the_player_walk_between_lines() -> void:
	var office := _office()
	_open_silo_in(office)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2
	assert_eq(office.ui.open_talk("joost", TalkView.WALKING), "")
	var view := office.ui.talk_view
	assert_eq(view.setting, TalkView.WALKING)
	assert_true(office.player.active, "free to walk")
	assert_eq(office.rig.shot, CameraRig.TWO_SHOT, "a two-shot that follows")
	var before: Vector3 = office.rig._inspect["at"]
	office.player.position += Vector3(1.0, 0, 0)
	office.staging.follow_walking_talk(0.1)
	assert_true(office.rig._inspect["at"].distance_to(before) > 0.1, "the camera follows the pair")
	office.free()


## After the talk the person goes back to their work: their own pose, their whole turn.
func test_after_the_talk_the_person_drops_the_talk_s_posture() -> void:
	var office := _office()
	_open_silo_in(office)
	var joost := office.people.person("joost")
	office.player.position = joost.position + joost.basis.x * 1.1 - joost.basis.z * 0.2
	office.use(joost)
	assert_eq(office.people.held, joost, "he stays for the talk")
	joost.pose_for_band(0)   # closed for a moment: half turned away
	for move in LISTEN_TO_JOOST:
		office.ui.talk_view.choose(move)
	office.ui.close_panels()
	office.ui.close_panels()
	assert_false(office.ui.talk_view.visible, "the talk is closed")
	assert_true(joost.clip in ["sit", "sit_tired"], "back to his typing, not '%s'" % joost.clip)
	assert_eq(joost._turn_share, 1.0, "a whole turn again")
	assert_false(joost._talking, "no longer in a talk")
	assert_false(joost.facing(), "back to his screen")
	assert_true(office.people.held == null, "and free to go")
	office.free()


# ── An expert talk (phase 2 design §2.5): questions, answers, no meters ───────

## Petra (nothing to discuss in a returning player's first week) explains her meters.
func _expert_view() -> TalkView:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var d := DialogDef.from_dict({"id": "petra_expert", "name": "Petra legt uit", "person": "petra", "kind": "expert",
		"opening": "Wat wil je weten?", "closing": "Graag gedaan.", "topics": [
			{"id": "molen", "ask": "Wat is de Molen?", "answer": "Ons register.",
				"unlocks": {"clue": "silent_meter:0"}},
			{"id": "board", "ask": "Hoe werkt die tekening?", "answer": "Kijk maar mee.",
				"unlocks": {"explainer": "spanning_stroom_weerstand"}},
			{"id": "map", "ask": "Wat staat er in je map?", "answer": "Alles."}]})
	s.people.dialogs[d.id] = d
	s.missions.done_once["fix_silent_meter"] = true   # the Molen's clue is its problem's (ExpertTalk.is_open)
	var view := TalkView.new()
	view.session = s
	assert_eq(view.start("petra"), "")
	return view


func test_an_expert_talk_shows_the_person_their_line_and_the_questions_only() -> void:
	var view := _expert_view()
	assert_true(view.expert(), "an expert talk")
	assert_eq(view.said_last()["text"], "Wat wil je weten?", "their opening, no position after it")
	view.lines.finish()
	assert_eq(view.offers.map(func(o: Dictionary) -> String: return o["line"]),
		["Wat is de Molen?", "Hoe werkt die tekening?", "Wat staat er in je map?"])
	for q in ["Wat is de Molen?", "Wat staat er in je map?"]:
		assert_true(shows(view, q), "the question on screen: " + q)
	assert_true(shows(view, TalkView.pips(view.session.dialog_meter()["trust_pips"])), "the small trust pips stay")
	for word in _instruments(view.session):
		for text in texts_in(view):
			assert_false(text.contains(word), "no instrument: \"%s\" in \"%s\"" % [word, text])
	view.free()


func test_an_answer_carries_no_arrow_and_a_new_clue_points_at_notities() -> void:
	var view := _expert_view()
	view.lines.finish()
	var r := view.choose_option(0)
	assert_eq(r["reply"], "Ons register.")
	assert_true(shows(view, TalkView.YOU % "Wat is de Molen?"), "your question over the answer, no arrow after it")
	view.lines.finish()
	assert_true(shows(view, TalkSummary.NEW_CLUE), "the clue is noted")
	assert_eq(view.offers.size(), 2, "the asked question is gone")
	view.free()


func test_a_topic_with_an_explainer_asks_for_it() -> void:
	var view := _expert_view()
	var asked: Array[String] = []
	view.explainer_requested.connect(func(id: String) -> void: asked.append(id))
	view.choose(ExpertTalk.ASK, "board")
	assert_eq(asked, ["spanning_stroom_weerstand"])
	view.free()


func test_after_their_goodbye_an_expert_talk_closes_without_a_summary() -> void:
	var view := _expert_view()
	var closed := [0]
	view.close_requested.connect(func() -> void: closed[0] += 1)
	view.choose_option(0)
	var r := view.close_talk()
	assert_true(r["ended"])
	assert_eq(view.said_last()["text"], "Graag gedaan.")
	assert_eq(closed[0], 0, "their goodbye is read first")
	view.lines.finish()
	assert_eq(closed[0], 1, "then the talk closes")
	assert_true(view.summary_trace == null, "no curve: nothing was measured")
	view.free()


func test_an_expert_s_explainer_opens_over_the_talk_and_gives_it_back() -> void:
	var office := _office()
	office.ui.talk_view.free()   # replaced by the expert's view below
	office.ui.talk_view = _expert_view()
	office.ui.talk_view.explainer_requested.connect(office.open_talk_explainer)
	office.ui.talk_view.choose(ExpertTalk.ASK, "board")
	assert_true(office.explainer != null, "the drawing opens")
	assert_eq(office.ui.talk_view.process_mode, Node.PROCESS_MODE_DISABLED, "the talk's keys wait")
	office.explainer.closed.emit("spanning_stroom_weerstand")
	assert_true(office.explainer == null)
	assert_eq(office.ui.talk_view.process_mode, Node.PROCESS_MODE_INHERIT, "back to the talk")
	office.ui.talk_view.free()
	office.free()


## The summary sends the player to the phone's app by its name, not the old journal.
func test_a_new_clue_points_at_notities() -> void:
	assert_true(TalkSummary.NEW_CLUE.contains(Phone.NAMES[Phone.NOTES]), TalkSummary.NEW_CLUE)
	assert_false(TalkSummary.NEW_CLUE.contains("journaal"))


## Another person staged in the talk view lets the first go.
func test_restaging_the_talk_lets_the_first_person_go() -> void:
	var view := _view(_silo())
	var first := OfficePerson.create({"id": "kim", "office": {"pose": "idle"}})
	view.stage(first)
	first.face_toward(Vector3(1, 0, 0), true)
	first.pose_for_band(0)
	view.stage(null)
	assert_eq(first.clip, "idle", "the first person back to their idle")
	assert_eq(first._turn_share, 1.0)
	view.free()
	first.free()
