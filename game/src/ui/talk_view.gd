class_name TalkView
extends UiPanel
## A talk with a named person, staged as two people talking (phase 2 design
## §2, S1-G), over the whole screen with no panel behind it. Watch, then choose:
##   SPEAK: their words as a film's subtitle that types out and waits for the
##   key (SceneLines: the first press completes, the next goes on, ← re-reads),
##   your own line small over their answer with ▲/▼ after it; the world frames
##   their face (Office.stage_talk).
##   CHOOSE: back to the two of you; their last line stays as the subtitle and
##   the four sentences sit above it (keys 1–4, "Afronden" under them).
##   SUMMARY_SCREEN: after their last words the talk's note (TalkSummary),
##   once; the same note waits in the journal.
## On screen through the talk: the name and role, five small trust pips (a ▲
## or ▼ flashes beside them when trust moves), the subtitle and the sentences.
## Openness and its band, the mood and the layers are not instruments here:
## the person's body shows them (pose_for_band, hesitate on the cue) and the
## note names them afterwards. Sentences are whole sentences, never a move's
## name, none styled by fit (Merijn's playtest, 2026-10-19).
## Settings: STANDING (at their desk), WALKING (the player walks between lines
## and the camera follows the pair), PHONE (nobody to see: the phone raised and
## the subtitles carry it).

## The note asks to talk the main mission's talk over with the coach.
signal coach_requested
## The talk went to another phase (SPEAK, CHOOSE, SUMMARY_SCREEN): the world restages.
signal phase_changed(phase: String)

const SPEAK := "speak"
const CHOOSE := "choose"
const SUMMARY_SCREEN := "summary"
const STANDING := "standing"
const WALKING := "walking"
const PHONE := "phone"
const ARROWS := {2: "▲▲", 1: "▲", 0: "", -1: "▼", -2: "▼▼"}
## Your line over their answer, the arrow after it.
const YOU := "Jij: %s"
const TRUST := "Vertrouwen"
const TALK_IT_OVER := "Bespreek met %s"
## The phone's screen in a call.
const ON_THE_PHONE := "In gesprek"
## Ruud after an Act 0 talk (tutorial talks spec §3): in person on the first
## day, by phone after that. One move named, never a score.
const RUUD_DROPPED_BY := "Ruud kwam even langs"
const RUUD_MESSAGE := "Bericht van Ruud"
## From this minute of the day Ruud has gone home: he texts.
const RUUD_HOME_AT := 18 * 60
## The keys of the offered sentences, in order.
const OPTION_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4]
const SENTENCE_FONT := 17
const KEY_HINT_FONT := 11
const KEY_HINT_AT := Vector2(4, 0)
## The subtitle's width, as SceneLines' (the sentences line up over it).
const WIDTH := 900.0
## Space at the screen's edges, and under the subtitle (as SceneLines').
const MARGIN := 16
const BOTTOM := 22
## How long the trust arrow stays before it fades, and the fade.
const TRUST_FLASH_S := 1.0
const TRUST_FADE_S := 0.6

## start_dialog's result while a talk is open ({} when none is).
var talk: Dictionary = {}
## The last move's result (choose_move), {} before the first.
var last: Dictionary = {}
## Layer id → its line once heard (session.dialog_layers, then each reveal).
var heard: Dictionary = {}
## Openness after each move, the start first.
var trace: Array = []
## The sentences on offer this turn (session.dialog_offers), [] when none.
var offers: Array[Dictionary] = []
## Where the talk takes place (STANDING, WALKING, PHONE).
var setting := STANDING
## Who is talked with in the world (null on the phone, and in tests).
var person: OfficePerson
## What they say, one line at a time.
var lines: SceneLines
## The summary's curve, its moves under its points (null mid-talk).
var summary_trace: TraceLine
## How the last move (or the talk's end) moved trust: 1, -1 or 0.
var trust_moved := 0
## The ▲ or ▼ beside the pips, shown while trust_moved is not 0.
var trust_flash: Label
## A line over the sentences until the first move, once in the game (the first
## talk, PLAN 2.7d B7); "" for none.
var first_hint := ""
var _pips: Label
var _choose: VBoxContainer
var _hint: Label
var _sentences: VBoxContainer
var _still_who: Label
var _still_text: Label
var _summary: VBoxContainer
var _phone: PanelContainer
var _phone_name: Label
## "Bespreek met Ruud" beside the close button, after a main mission's talk.
var _talk_over: Button
## The last line they said ({who, text}) and the band their body shows.
var _said: Dictionary = {}
var _posed := -1
var _trust_seen := 0
var _phase := ""


func _init() -> void:
	super("", Vector2.ZERO)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header := close_button.get_parent()
	header.get_parent().mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.hide()
	rule.hide()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(stage)
	stage.add_child(_name_tag())
	lines = SceneLines.new()
	lines.lines_done.connect(_sync)
	stage.add_child(lines)
	stage.add_child(_choose_box())
	stage.add_child(_summary_box())
	stage.add_child(_phone_screen())


## Over the whole screen: the talk is the world, with a few words over it.
func _place() -> void:
	if is_inside_tree():
		position = Vector2.ZERO
		size = get_parent_area_size()


## Top left, under the HUD's bar: the name and role, the pips, the flash.
func _name_tag() -> PanelContainer:
	var tag := PanelContainer.new()
	var style := SceneLines.subtitle_style()
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	tag.add_theme_stylebox_override("panel", style)
	tag.position = Vector2(MARGIN, DOCK_TOP)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	tag.add_child(row)
	title_label.get_parent().remove_child(title_label)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", UiTheme.SMALL + 2)
	title_label.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(title_label)
	_pips = label("", UiTheme.SMALL, Palette.VOLTANA_GREEN)
	_pips.tooltip_text = TRUST
	row.add_child(_pips)
	trust_flash = label("", UiTheme.SMALL, Color.WHITE)
	trust_flash.visible = false
	row.add_child(trust_flash)
	return tag


## Bottom centre: the first hint, the four sentences and "Afronden", then
## their last line as the subtitle.
func _choose_box() -> VBoxContainer:
	_choose = _bottom_column()
	_hint = paragraph("", Color(1, 1, 1, 0.75), UiTheme.SMALL)
	_choose.add_child(_hint)
	_sentences = VBoxContainer.new()
	_sentences.add_theme_constant_override("separation", 6)
	_choose.add_child(_sentences)
	var still := PanelContainer.new()
	still.add_theme_stylebox_override("panel", SceneLines.subtitle_style())
	still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choose.add_child(still)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	still.add_child(box)
	_still_who = label("", UiTheme.SMALL, Palette.VOLTANA_GREEN)
	box.add_child(_still_who)
	_still_text = paragraph("", Color.WHITE, 22)
	box.add_child(_still_text)
	return _choose


## Bottom centre: the note, and under it the way to the coach and the close.
func _summary_box() -> VBoxContainer:
	_summary = _bottom_column()
	_summary.custom_minimum_size.x = WIDTH + 200
	return _summary


func _bottom_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_bottom = -BOTTOM
	column.custom_minimum_size.x = WIDTH
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.visible = false
	return column


## Right of centre in a call: the phone raised, the caller on its screen.
func _phone_screen() -> PanelContainer:
	_phone = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.95)
	style.border_color = Color(0.25, 0.27, 0.3)
	style.set_border_width_all(6)
	style.set_corner_radius_all(26)
	style.set_content_margin_all(22)
	_phone.add_theme_stylebox_override("panel", style)
	_phone.custom_minimum_size = Vector2(230, 400)
	_phone.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_phone.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_phone.grow_vertical = Control.GROW_DIRECTION_BOTH
	_phone.offset_right = -120
	_phone.offset_top = -260
	_phone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.visible = false
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	_phone.add_child(box)
	_phone_name = label("", 20, Color.WHITE)
	_phone_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phone_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_phone_name)
	var on := label(ON_THE_PHONE, UiTheme.SMALL, Palette.VOLTANA_GREEN)
	on.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(on)
	return _phone


## Open a person's talk in `where` (STANDING, WALKING; the world makes it a
## call when they are not here): "" or start_dialog's error code.
func start(person_id: String, where: String = STANDING) -> String:
	var opened := session.start_dialog(person_id)
	if opened.has("error"):
		return opened["error"]
	talk = opened
	setting = where
	last = {}
	heard = {}
	for layer in session.dialog_layers():
		if layer["heard"]:
			heard[layer["id"]] = layer["text"]
	trace = opened["meter"]["trace"].duplicate()
	trust_moved = 0
	_trust_seen = opened["meter"]["trust"]
	person = null   # the world stages who (stage)
	lines.clear()
	_speak([_line(talk["opening"]), _line(talk["position"].get("text", ""))])
	refresh()
	return ""


## Who is talked with in the world (null: nobody here, so a call), posed
## for the band the talk is in now.
func stage(in_world: OfficePerson) -> void:
	person = in_world
	if person == null and not talk.is_empty():
		setting = PHONE
	_posed = -1
	if talking():
		_pose(meter()["band"])
	refresh()


## The talk is open and not yet over.
func talking() -> bool:
	return not talk.is_empty() and not last.get("ended", false)


## SPEAK while they speak, CHOOSE while you choose, SUMMARY_SCREEN after; "" for no talk.
func phase() -> String:
	if talk.is_empty():
		return ""
	if lines.speaking():
		return SPEAK
	return CHOOSE if talking() else SUMMARY_SCREEN


## Whether the four sentences are on screen.
func choices_shown() -> bool:
	return _choose.visible


## Whether the phone is up (a call).
func phone_shown() -> bool:
	return _phone.visible


## Their last line ({who, text}).
func said_last() -> Dictionary:
	return _said


## Make a move (with its pick): choose_move's result. The sentences make only
## the offered ones (choose_option).
func choose(move: String, pick: String = "") -> Dictionary:
	var result := session.choose_move(move, pick)
	if result.has("error"):
		return result
	last = result
	first_hint = ""
	# At the end the talk's outcome moves trust too (a partial's +5).
	var trust: int = result.get("summary", {}).get("trust", result["trust"])
	trust_moved = signi(trust - _trust_seen)
	_trust_seen = trust
	trace.append(result["openness"])
	if not result["revealed"].is_empty():
		heard[result["revealed"]] = result["reply"]
	_pose(Dialog.band_of(result["openness"]))
	_answer(result)
	if result["ended"]:
		acted.emit()
	refresh()
	return result


## Their answer to your line: your line (and its arrow) over it; on the cue a
## hesitation, and the line trails off; their own idea after it.
func _answer(result: Dictionary) -> void:
	var reply := _line(result["reply"])
	var arrow := arrow_text(result.get("arrow", 0))
	reply["lead"] = (YOU % result["line"]) + ("  " + arrow if not arrow.is_empty() else "")
	if result.get("cue", false):
		if person != null:
			person.hesitate()
		if not reply["text"].ends_with("…"):
			reply["text"] += " …"
	var said: Array[Dictionary] = [reply]
	if not result.get("co_proposal", {}).is_empty():
		said.append(_line(result["co_proposal"]["text"]))
	lines.finish()   # a move made over their words (Afronden): those words were heard
	_speak(said)


func _line(text: String) -> Dictionary:
	return {"who": talk["name"], "text": text}


func _speak(said: Array[Dictionary]) -> void:
	lines.say(said)
	_said = said[-1]
	_sync()


## The body of `band`, when it is another than it shows.
func _pose(band: int) -> void:
	if person != null and band != _posed:
		_posed = band
		person.pose_for_band(band)


## Say the offered sentence at `index`: choose_move's result ({} for none).
func choose_option(index: int) -> Dictionary:
	if not talking() or index < 0 or index >= offers.size():
		return {}
	return choose(offers[index]["move"], offers[index]["pick"])


## A key pressed while you choose: 1–4 say the sentence beside it. False when
## the key means nothing now (left for others; while they speak, the line's).
func press_key(key: Key) -> bool:
	var i := OPTION_KEYS.find(key)
	if phase() != CHOOSE or i < 0 or i >= offers.size():
		return false
	choose_option(i)
	return true


func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key != null and key.pressed and not key.echo and press_key(key.physical_keycode):
		get_viewport().set_input_as_handled()


## End the talk gracefully ("Afronden"); {} when no talk runs.
func close_talk() -> Dictionary:
	return choose("close") if talking() else {}


## Each frame: the line types out; ← may bring a line back.
func step(dt: float) -> void:
	lines.step(dt)
	_sync()


func _process(delta: float) -> void:
	if visible:
		step(delta)


## Show what belongs to the phase, and tell the world when it changed.
func _sync() -> void:
	var now := phase()
	_choose.visible = now == CHOOSE
	_summary.visible = now == SUMMARY_SCREEN
	if now != _phase:
		_phase = now
		phase_changed.emit(now)


## "▲▲", "▲", "", "▼" or "▼▼" for a reply's arrow: never a number.
static func arrow_text(arrow: int) -> String:
	return ARROWS[clampi(arrow, -2, 2)]


## "●●○○○": filled pips of five.
static func pips(filled: int) -> String:
	var n := clampi(filled, 0, 5)
	return "●".repeat(n) + "○".repeat(5 - n)


## An outcome's Dutch name from the content's bank ("Staat erachter").
static func outcome_name(s: GameSession, outcome: String) -> String:
	return str(labels_of(s).get("outcomes", {}).get(outcome, outcome))


## A band's Dutch name ("Luistert"); "" for none.
static func band_name(s: GameSession, band: int) -> String:
	var bands: Array = labels_of(s).get("bands", [])
	return str(bands[band]) if band >= 0 and band < bands.size() else ""


## The bank's labels (chips, bands, cue, outcomes): Dutch lives in content.
static func labels_of(s: GameSession) -> Dictionary:
	return JsonFile.dict_or_empty(s.catalog.dialog_bank.get("labels"))


func refresh() -> void:
	if talk.is_empty():
		return
	title_label.text = "%s  ·  %s" % [talk["name"], talk["role"]]
	_pips.text = pips(meter()["trust_pips"])
	_flash_trust()
	offers = session.dialog_offers()  # [] once the talk has ended
	_fill_sentences()
	_still_who.text = str(_said.get("who", ""))
	_still_text.text = str(_said.get("text", ""))
	_phone.visible = setting == PHONE
	_phone_name.text = talk["name"]
	summary_trace = null
	clear(_summary)
	if not talking():
		_fill_summary()
	_sync()


## The meter as it stands: the session's while the talk runs, else from the
## last move.
func meter() -> Dictionary:
	if talking():
		return session.dialog_meter()
	var openness: int = last.get("openness", 0)
	return {"openness": openness, "band": Dialog.band_of(openness),
		"trust_pips": floori(last.get("trust", 0) / float(Dialog.TRUST_PER_PIP)), "mood": talk["meter"]["mood"]}


## ▲ or ▼ beside the pips when the last move moved trust; in the tree it
## fades after a moment.
func _flash_trust() -> void:
	trust_flash.text = arrow_text(trust_moved)
	trust_flash.add_theme_color_override("font_color", Palette.VOLTANA_GREEN if trust_moved > 0 else Palette.SAFETY_ORANGE)
	trust_flash.visible = trust_moved != 0
	trust_flash.modulate.a = 1.0
	if trust_flash.visible and is_inside_tree():
		var fade := create_tween()
		fade.tween_interval(TRUST_FLASH_S)
		fade.tween_property(trust_flash, "modulate:a", 0.0, TRUST_FADE_S)


## The sentences on offer, one under the other, each with its key; none
## styled by fit and none named by its move. "Afronden" under them.
func _fill_sentences() -> void:
	clear(_sentences)
	_hint.text = first_hint
	_hint.visible = not first_hint.is_empty()
	if not talking():
		return
	for i in offers.size():
		var b := button(str(offers[i]["line"]), choose_option.bind(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", SENTENCE_FONT)
		_sentences.add_child(_with_key(b, OPTION_KEYS[i] if i < OPTION_KEYS.size() else KEY_NONE))
	var end := button(str(labels_of(session).get("chips", {}).get("close", "")), close_talk)
	end.flat = true
	end.add_theme_font_size_override("font_size", UiTheme.SMALL)
	end.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	end.size_flags_horizontal = Control.SIZE_SHRINK_END
	_sentences.add_child(end)


## A sentence with its key in its top-left corner, small and dimmed, taking
## no width of the line (KEY_NONE: the sentence alone).
static func _with_key(sentence: Button, key: Key) -> Button:
	if key != KEY_NONE:
		var hint := label(OS.get_keycode_string(key), KEY_HINT_FONT, Color.WHITE)
		hint.modulate.a = 0.6
		hint.position = KEY_HINT_AT
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sentence.add_child(hint)
	return sentence


## The talk's note as the rules kept it (TalkSummary), with Ruud's word after
## an Act 0 talk; under it the way to the coach and the close.
func _fill_summary() -> void:
	var talks: Array = session.person(talk["person"]).get("talks", [])
	if talks.is_empty():
		return
	var note := TalkSummary.of(talks[0], talk["person"])
	var card := TalkSummary.card(session, note, "", _ruud(note))
	_summary.add_child(card)
	summary_trace = card.find_children("*", "TraceLine", true, false)[0]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	_summary.add_child(row)
	_talk_over = button(TALK_IT_OVER % session.catalog.coach.get("name", "Ruud"), coach_requested.emit)
	_talk_over.visible = is_main_talk()
	row.add_child(_talk_over)
	row.add_child(button(tr(CLOSE), close_requested.emit))


## Ruud's word after an Act 0 talk ({heading, lines}; {} outside Act 0, where
## the rules give no line): in person on Monday's working day, by text in the
## evening (he has gone home, 2.7d B7) and after; after Friday's last talk his
## question for the weekend.
func _ruud(note: Dictionary) -> Dictionary:
	if note["ruud_names"].is_empty():
		return {}
	var monday := SimCalendar.weekday(session.region.net.time - SimCalendar.days(GameSession.WARMUP_DAYS)) == 0 \
		and session.minute_of_day() < RUUD_HOME_AT
	var said: Array[String] = [note["ruud_names"]]
	var d: DialogDef = session.people.dialogs.get(talk.get("dialog", ""))
	if d != null and week_ends(session, d):
		var week_end := str(JsonFile.dict_or_empty(session.catalog.dialog_bank.get("ruud_names")).get("week_end", ""))
		if not week_end.is_empty():
			said.append(week_end)
	return {"heading": tr(RUUD_DROPPED_BY if monday else RUUD_MESSAGE), "lines": said}


## Whether talk `d` closes the Act 0 week: a tutorial talk of the last
## training day, with every tutorial talk of that day had.
static func week_ends(s: GameSession, d: DialogDef) -> bool:
	var training := s.missions.defs.values().filter(func(m: MissionDef) -> bool: return m.kind == "training")
	if not d.tutorial or training.is_empty() or d.mission != training[-1].id:
		return false
	return s.people.dialogs.values().all(func(o: DialogDef) -> bool:
		return not (o.tutorial and o.mission == d.mission) or s.people.outcomes.has(o.id))


## Whether this talk belongs to the main mission (the coach talks it over).
func is_main_talk() -> bool:
	var d: DialogDef = session.people.dialogs.get(talk.get("dialog", ""))
	return d != null and not d.mission.is_empty() \
		and session.missions.active("main").any(func(m: MissionDef) -> bool: return m.id == d.mission)
