class_name OfficeOpening
extends Node
## De eerste vijf minuten (PLAN 2.7d; spec 2026-10-16-first-five-minutes §2):
## a new game's first day as one scene. B2 the ontvangst (Yvonne, the badge),
## B3 Ruud's walk to Aansluitingen (he leads, waits, introduces Sanne, Marco,
## Joost and Anouk, hands over the paper floor plan), B4 his whiteboard
## (skippable), B5 the El Amrani letter, B6 the rest of the day as the phone,
## B7 Anouk at seven calling out as you pass. The beat lives in the session
## layer (Opening, saved); the HUD reveals itself by Opening.hud.
##
## A cue runner: each beat is a list of cues (callables called every step
## until they say they are done), so tests drive the whole scene with step(dt).
##
## A scene that behaves like a scene (PLAN 2.13 A, Merijn 2026-10-19): while a
## line, a choice or a paper is up the player stands and the camera frames
## them and the speaker; between lines (Ruud's walk) they walk. Holding Spatie
## skips the beat on screen to its end, the next place where the player acts.

## Who speaks.
const RUUD := "Ruud"
const YVONNE := "Yvonne"
const SANNE := "Sanne"
const MARCO := "Marco"
const JOOST := "Joost"
const ANOUK := "Anouk"
const BADGE_ROLE := "CI-lead · Aansluitingen"
const SKIP_WEEK := "Ik ken Voltana al: sla de inwerkweek over"
const HINT_WALK := "Lopen: WASD of klik op de vloer"
const HINT_LOOK := "Draaien: Z en C  ·  Zoomen: muiswiel"
const HINT_JOURNAL := "J  journaal: wat Anouk je vertelde staat erin"
const TALK_HINT := "Openheid: hoe open Anouk nu met je praat. Kies hoe je reageert; je ziet aan haar wat het doet."
const EXPLAIN := "Leg maar uit"
const KNOW_IT := "Dat verhaal ken ik al, Ruud"
const LETTER := ["Geachte heer Hoekstra,",
	"Op {aanvraag_datum} hebben wij een zwaardere aansluiting aangevraagd voor onze warmtepomp. Inmiddels wachten we al {dossier_weken}. Mijn moeder woont bij ons in en zij heeft het snel koud. Niemand kan ons vertellen wanneer u komt. Ik vraag niet om voorrang. Ik vraag om een datum.",
	"Met vriendelijke groet,", "F. El Amrani, Nova-Oost"]
## The lines of each beat (spec §2): [who, text].
const LINES := {
	"yvonne": [[YVONNE, "Goedemorgen! Jij bent {speler}, toch? Ik herkende je van de foto."]],
	"yvonne_badge": [[YVONNE, "Hier is je pas. Daarmee kom je overal in, behalve in het onderstation. Daarvoor moet je bij Ruud zijn. Hij komt je zo halen, hij zit nog even in het MT."],
		[YVONNE, "Kijk, daar is hij al. Nooit te laat, wel altijd net op tijd."]],
	"leg1": [[RUUD, "Hoi {speler}, ik ben Ruud. Welkom! Ik wilde je om half negen zelf ophalen, maar het MT liep uit. Dat gebeurt vaker, en meestal is dat geen goed teken."],
		[RUUD, "We nemen de trap. Goed voor mijn conditie, zegt mijn vrouw."]],
	"kcc": [[RUUD, "Hier zit het KCC. Iedereen die op ons wacht, belt hierheen. Je komt hier nog vaak."]],
	"wait": [[RUUD, "Kijk gerust even rond. Ik wacht hier wel."]],
	"plan": [[RUUD, "Hier, een plattegrond. Ik werk hier al twintig jaar en ik loop nog steeds weleens de verkeerde gang in."],
		[RUUD, "Aansluitingen is hier rechtsaf. Je ziet het vanzelf: daar liggen de stapels."]],
	"sanne": [[RUUD, "Dit is Sanne Bakker, teamleider Intake. Elke aanvraag komt eerst bij haar team binnen."],
		[SANNE, "Hoi, welkom! Ik zit net aan de telefoon, maar ik kom straks echt even kennismaken."],
		[RUUD, "Na het weekend staat de telefoon hier roodgloeiend."]],
	"marco": [[RUUD, "En dit is Marco, ploegleider van de monteurs. Die komt alleen boven als er iets misgaat."],
		[MARCO, "Dan zie je me nog vaak genoeg. Klaverstraat. Meterkast weer niet klaar, dus voor niks gereden. Derde keer al."],
		[RUUD, "Vertel het {haar_hem_speler} straks maar. Daar is {hij_zij} juist voor."],
		[MARCO, "Dat zeiden ze in 2012 ook. Maar goed. Welkom."]],
	"design": [[RUUD, "Dit is Joost van Dijk, teamleider Werkvoorbereiding. En dit is Anouk de Vries."],
		[JOOST, "Welkom. Je treft het niet: bijna mijn hele team zit deze week op cursus. Alleen Anouk is er."],
		[ANOUK, "Hoi! Sorry, ik moet dit even afmaken. Ik spreek je straks!"],
		[RUUD, "Kijk even goed naar het bureau van Anouk. Daar komen we nog op terug."]],
	"overtaken": [[RUUD, "Je vond het zelf. Dat is een goed teken."]],
	"door": [[RUUD, "Dit is mijn kamer. Voorlopig dan."],
		[RUUD, "Boven heb ik er ook een, met uitzicht op het spoor. Maar daar zit ik te ver van het werk."]],
	"board_ask": [[RUUD, "Iedereen die hier begint, krijgt van mij hetzelfde verhaal. Over spanning. Heb je een minuutje?"]],
	"board_known": [[RUUD, "Prima. Ik laat het op het bord staan, voor als je het toch nog wilt zien."]],
	"board_close": [[RUUD, "Met ons werk is het net zo. De druk is er: iedereen wil een aansluiting. Er kan maar zoveel tegelijk doorheen. En ergens zit weerstand."],
		[RUUD, "Waar precies? Daar ga jij achter komen."]],
	"letter": [[RUUD, "Dit lag vanochtend op mijn bureau."]],
	"after_letter": [[RUUD, "Ik vraag je niet om dit op te lossen. Nog niet. Eerst wil ik dat je gaat kijken. Hoe je dat doet, leer je deze week. Volgende week volg je dit dossier, van de brief tot de meter."],
		[RUUD, "En als je met mensen praat: vraag eerst hoe het met ze gaat. En meen het ook."],
		[RUUD, "De rest van de dag ben je van IT en HR. Laptop, account, wachtwoorden. Sterkte."]],
}
## The rest of the first day, as the phone (B6): [from, at, text].
const PHONE := [["IT Servicedesk", "10:40", "Je laptop staat klaar. Bij de eerste keer inloggen moet je je wachtwoord wijzigen."],
	["IT Servicedesk", "11:20", "Je wachtwoord is gewijzigd. Je wachtwoord is gewijzigd. Je account is tijdelijk geblokkeerd."],
	["Leerplatform", "16:50", "Je hebt de e-learning Veilig werken bij Voltana afgerond. Resultaat: geslaagd."]]
## The scene's evening (B6): the clock after the skip.
const EVENING_MINUTE := 19 * 60 + 2
## Where things happen (office space, x and z): fallbacks when a floor's own marker is missing.
const RECEPTION_DESK := Vector2(-4.6, -4.7)
const RECEPTION_CHAIR := Vector2(-5.4, -4.6)
const LANDING := Vector2(-2.6, -9.4)
const AT_INTAKE := Vector2(2.4, -3.8)
const AT_AISLE := Vector2(5.8, -5.6)
const AT_DESIGN := Vector2(9.0, -5.4)
## In the evening the player stands in the corridor east of Werkvoorbereiding, the exit west.
const EVENING_AT := Vector2(13.0, -8.2)
## How near (m) counts as "with Ruud", "at a stop", or within Anouk's call.
const NEAR := 3.0
const CALL_DISTANCE := 6.0
## Ruud says his waiting line once per stop after this long.
const WAIT_LINE_S := 20.0
const MOVED_FOR_HINT := 3.0
const GUIDE_PACE := 1.4
## A speaker this near (m) is framed with the player; farther (a call down the corridor) the view stays.
const FRAME_DISTANCE := 8.0
## The speaker's face this share of the screen's height above the middle (the subtitle is below).
const FRAME_LIFT := 0.12
## Where the player stands when the walk is skipped: this far from Ruud's door, back along the corridor.
const DOOR_GAP := 1.6
## What the walk counts as at a place (an observe goal's use).
const TOUR := "tour"

var office: Office
var layer: SessionLayer
var lines: SceneLines
## Ruud leading the walk (B2–B4), a person of the opening's own.
var guide: OfficePerson
var yvonne: OfficePerson
var _cues: Array[Callable] = []
var _guide_route := PackedVector3Array()
var _start := Vector3.ZERO
var _walk_hint_shown := false
var _look_hint_shown := false
var _skip_link: Button
## A line, a choice or a paper holds the player now (Office.hold_for_scene).
var _holding := false
## Who the camera frames now ("" for none).
var _framed := ""


## The opening over `of_office` at the beat its session layer is at.
static func create(of_office: Office) -> OfficeOpening:
	var o := OfficeOpening.new()
	o.name = "Opening"
	o.office = of_office
	o.layer = of_office.ui.session_layer
	o.lines = SceneLines.new()
	o.lines.auto = SceneLines.auto_setting()
	o.lines.skip_requested.connect(o.skip)
	of_office.ui.hud.add_child(o.lines)
	return o


func _ready() -> void:
	start()


## Begin at the saved beat (a resumed game picks up where it was).
func start() -> void:
	if not _cues.is_empty() or not Opening.running(layer):
		return
	match layer.opening_beat:
		Opening.ARRIVAL:
			_arrival()
		Opening.WALK:
			_walk()
		Opening.BOARD:
			_board()
		Opening.LETTER:
			_letter()
		Opening.EVENING:
			_evening()
		Opening.ANOUK:
			_anouk()


func _process(delta: float) -> void:
	step(delta)


## One frame of the scene (tests call it with their own dt).
func step(dt: float) -> void:
	lines.step(dt)
	_move_guide(dt)
	_hints()
	if yvonne != null:
		yvonne.visible = office.floors.floor_id == "ground"
	_run_cues(dt)
	_hold_player()


func _run_cues(dt: float) -> void:
	while not _cues.is_empty():
		var cues := _cues
		var head: Callable = cues[0]
		if not head.call(dt):
			return
		if is_same(cues, _cues) and not _cues.is_empty() and _cues[0] == head:
			_cues.pop_front()   # a cue that started a new beat has replaced the list


## While a line, a choice or a paper is up the player stands and the camera
## frames them and whoever speaks; when it goes, both are free again.
func _hold_player() -> void:
	var holds := lines.holds()
	if holds != _holding:
		_holding = holds
		_framed = ""
		office.hold_for_scene(holds)
	if not holds:
		return
	var who := str(lines.current().get("who", ""))
	if who == _framed:
		return
	_framed = who
	var speaker := _speaker(who)
	if speaker != null and speaker.visible and _near(speaker.position, office.player.position, FRAME_DISTANCE):
		office.frame_scene(speaker, FRAME_LIFT)


## The person who says a line: the opening's own Ruud and Yvonne, else the office's.
func _speaker(who: String) -> OfficePerson:
	match who:
		RUUD:
			return guide if guide != null and guide.visible else office.people.person("ruud")
		YVONNE:
			return yvonne
	return office.people.person(who.to_lower()) if not who.is_empty() else null


## Every cue still to run is done (tests): lines shown, walks arrived.
func running() -> bool:
	return not _cues.is_empty()


# ── B2: De ontvangst ───────────────────────────────────────────────────────

func _arrival() -> void:
	office.floors.go_to("ground", "entrance", true)
	var desk := _point("reception_desk", RECEPTION_DESK)
	var entrance := office.player.position
	var stand := desk + (entrance - desk).normalized() * 1.3
	office.player.position = stand
	office.player.face(Basis.looking_at((desk - stand) * Vector3(1, 0, 1)))
	office.rig.yaw = office.player.rotation.y
	office.rig.snap()
	yvonne = _person("kim", "Yvonne Kramer", "Receptie")   # a stand-in look until Yvonne joins the cast (2.7d §4.3)
	var chair := _point("reception_chair", RECEPTION_CHAIR)
	yvonne.place(chair + (desk - chair) * 0.45, stand - desk)   # standing behind the counter, by her chair
	office.frame_scene(yvonne, FRAME_LIFT)
	_skip_link = UiPanel.button(tr(SKIP_WEEK), skip_week)
	_skip_link.flat = true
	_skip_link.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_skip_link.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_skip_link.offset_left = 16
	_skip_link.offset_top = 56
	lines.add_child(_skip_link)
	lines.skip_hint(true)   # the first scene says how to skip (Merijn 2026-10-19)
	_run([_wait(1.0), _say("yvonne"), _badge(), _say("yvonne_badge"), _do(_ruud_arrives), _do(_walk)])


## The badge on the counter: your photo, your first name, your role.
func _badge() -> Callable:
	var state := {"shown": false}
	return func(_dt: float) -> bool:
		if not state["shown"]:
			state["shown"] = true
			var photo := SaveList.Portrait.new(false, office.session.player.portrait)
			photo.custom_minimum_size = Vector2(PlayerProfile.PORTRAIT_SIZE) * 0.7
			photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var logo := UiPanel.label("VOLTANA NETBEHEER", UiTheme.SMALL, Palette.VOLTANA_GREEN)
			logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var who := UiPanel.label(office.session.player.display_name(), UiTheme.HEADING, Palette.VOLTANA_BLUE)
			who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var role := UiPanel.label(tr(BADGE_ROLE), UiTheme.SMALL, Palette.MUTED)
			role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lines.paper(Color.WHITE, [logo, photo, who, role])
			return false
		return not lines.paper_up()


func _ruud_arrives() -> void:
	office.rig.release()
	guide = _person("ruud", "Ruud Hoekstra", "")
	guide.place(_marker("arrive:lift", Vector2(-1.4, -4.2)), office.player.position - guide.position)
	if _skip_link != null:
		_skip_link.queue_free()
		_skip_link = null


## "Ik ken Voltana al" (a returning player, spec rule 6): the week skipped, the
## full HUD, at your desk's floor.
func skip_week() -> void:
	office.session.skip_training()
	layer.opening_beat = ""
	layer.has_floor_plan = true
	lines.clear()   # Yvonne's line goes with the week: nothing holds the player
	lines.skip_hint(false)
	_end()
	office.floors.go_to("first", "lift", true)
	office.ui.after_action()


# ── Skipping (PLAN 2.13 A) ─────────────────────────────────────────────────

## Spatie held: the beat on screen jumps to its end, where the player acts
## next (the ontvangst to Ruud's walk, the walk to his question at his door,
## his answer to the letter, the letter to the rest of the day, the day to the
## evening). A choice and a talk are the player's: never skipped. The
## explainer on his board skips itself (held Spatie there closes it).
func skip() -> void:
	lines.skip_hint(false)
	if lines.asking() or office.explainer != null or office.ui.dialog_panel.visible:
		return
	match layer.opening_beat:
		Opening.ARRIVAL:
			lines.clear()
			_walk()
		Opening.WALK:
			lines.clear()
			_skip_walk()
		Opening.BOARD:
			_run_cues(0.0)   # an answer just given takes its turn first
			if lines.asking():
				return
			lines.clear()
			_letter()
		Opening.LETTER:
			lines.clear()
			_evening()
		Opening.EVENING:
			_to_evening()
		_:
			return
	step(0.0)


## The walk's end without the walk: upstairs, the plan handed over, both
## teams passed, Ruud at his door and the player in front of him.
func _skip_walk() -> void:
	lines.clear_hint()
	if guide == null:
		_ruud_arrives()
	if office.floors.floor_id != "first":
		office.floors.go_to("first", "stairs_up", true)
	_hand_over_plan()
	_hide_seated_ruud(true)
	_guide_route = PackedVector3Array()
	guide.visible = true
	var door := _coach_door()
	var stand := door + (_v(AT_DESIGN) - door).normalized() * DOOR_GAP
	guide.place(door, stand - door)
	office.player.position = stand
	office.player.face(Basis.looking_at((door - stand).normalized()))
	office.rig.yaw = office.player.rotation.y
	office.rig.snap()
	for place in ["connections.intake", "connections.design"]:
		_seen(place)
	_board()


# ── B3: Ruud haalt je op ───────────────────────────────────────────────────

func _walk() -> void:
	Opening.advance(layer, Opening.WALK)
	lines.skip_hint(false)
	if guide == null:
		_ruud_arrives()
	_start = office.player.position
	if office.floors.floor_id == "ground":
		lines.hint(tr(HINT_WALK), 600.0)
		_walk_hint_shown = true
		var stairs := _interactable_at("stairs_up", Vector2(-5.3, -10.75))
		_run([_say("leg1"), _do(func() -> void: _guide_to(stairs + Vector3(0.9, 0, 0.8))),
			_wait(2.5), _say("kcc"), _until_with_ruud(), _do(_ruud_goes_up), _until_floor("first"), _do(_upstairs)])
	else:
		_upstairs()


func _ruud_goes_up() -> void:
	guide.visible = false
	if not _look_hint_shown:
		_look_hint_shown = true
		lines.hint(tr(HINT_LOOK), SceneLines.HINT_SECONDS)


## On the 1e verdieping: the plan on the landing, then Intake, Marco, Werkvoorbereiding, his door.
func _upstairs() -> void:
	if guide == null:
		_ruud_arrives()
	guide.visible = true
	_hide_seated_ruud(true)
	guide.place(_v(LANDING), office.player.position - _v(LANDING))
	_run([_say("plan"), _do(_hand_over_plan),
		_stop_at(_v(AT_INTAKE), "sanne"), _do(_seen.bind("connections.intake")), _stop_at(_v(AT_AISLE), "marco"),
		_stop_at(_v(AT_DESIGN), "design"), _do(_seen.bind("connections.design")),
		_stop_at(_coach_door(), "door"), _do(_board)])


## Ruud's walk past a team is the arrival day's look at it (training_mon's
## observe goal is met by the walk, spec §4.1).
func _seen(place: String) -> void:
	office.session.missions.note_use(place, TOUR)
	office.session.pass_time(0)


func _hand_over_plan() -> void:
	layer.has_floor_plan = true
	office.ui.after_action()


## Ruud walks to `at`, waits for the player (his waiting line once after a while),
## then says `key`'s lines. A player already at his door overtakes the walk.
func _stop_at(at: Vector3, key: String) -> Callable:
	var state := {"phase": 0, "waited": 0.0, "said_wait": false}
	return func(dt: float) -> bool:
		if state["phase"] < 3 and key != "door" and _near(office.player.position, _coach_door(), NEAR + 0.5):
			_overtaken()
			return false
		match state["phase"]:
			0:
				_guide_to(at)
				state["phase"] = 1
			1:
				if _guide_route.is_empty():
					state["phase"] = 2
			2:
				if _near(office.player.position, guide.position, NEAR + 1.0):
					lines.say(_lines(key))
					state["phase"] = 3
				else:
					state["waited"] += dt
					if state["waited"] >= WAIT_LINE_S and not state["said_wait"] and not lines.speaking():
						state["said_wait"] = true
						lines.say(_lines("wait", true))
			3:
				return not lines.speaking()
		return false


## The player walked ahead to Ruud's room: he catches up there.
func _overtaken() -> void:
	_guide_route = PackedVector3Array()
	guide.place(_coach_door(), office.player.position - _coach_door())
	lines.finish()
	for place in ["connections.intake", "connections.design"]:   # you walked through both to get here
		_seen(place)
	_run([_say("overtaken"), _say("door"), _do(_board)])


# ── B4: Het bord van Ruud ──────────────────────────────────────────────────

func _board() -> void:
	Opening.advance(layer, Opening.BOARD)
	_hide_seated_ruud(true)
	if guide == null:
		_ruud_arrives()
		guide.place(_coach_door(), office.player.position - _coach_door())
	_run([_ask_board()])


## "Weet je waarom dit vak spanning heet?" [Leg maar uit] · [Ik ken het, Ruud]:
## the explainer and his close, or the board left for later; then the letter.
func _ask_board() -> Callable:
	var state := {"asked": false, "answer": -1}
	return func(_dt: float) -> bool:
		if not state["asked"]:
			state["asked"] = true
			var said: Array = LINES["board_ask"][0]
			lines.ask(said[0], fill(said[1]), [tr(EXPLAIN), tr(KNOW_IT)])
			lines.chosen.connect(func(i: int) -> void: state["answer"] = i, CONNECT_ONE_SHOT)
		if state["answer"] < 0:
			return false
		if state["answer"] == 0:
			_run([_explainer(), _say("board_close"), _do(_letter)])
		else:
			_run([_say("board_known"), _do(_letter)])
		return true


## The whiteboard's explainer (2.7c); done when it closes (Klaar or a held Spatie skips it).
func _explainer() -> Callable:
	var state := {"opened": false}
	return func(_dt: float) -> bool:
		if not state["opened"]:
			state["opened"] = true
			office.open_whiteboard()
			return office.explainer == null
		return office.explainer == null


# ── B5: De brief ───────────────────────────────────────────────────────────

func _letter() -> void:
	Opening.advance(layer, Opening.LETTER)
	_run([_say("letter"), _paper_letter(), _say("after_letter"), _do(_evening)])


func _paper_letter() -> Callable:
	var state := {"shown": false}
	return func(_dt: float) -> bool:
		if not state["shown"]:
			state["shown"] = true
			var content: Array[Control] = []
			for i in LETTER.size():
				var p := UiPanel.paragraph(letter_line(i), Palette.INK, 21)
				p.custom_minimum_size.x = 640
				content.append(p)
			lines.paper(Palette.MANILA, content)
			return false
		return not lines.paper_up()


## A line of the El Amrani letter, its date and weeks from the followed order (1.8).
func letter_line(i: int) -> String:
	var age: float = office.session.followed_order()["age_days"]
	return office.session.fill_tokens(LETTER[i]).replace("{dossier_weken}", FollowedOrder.weeks_text(age))


# ── B6: De rest van je eerste dag ──────────────────────────────────────────

func _evening() -> void:
	Opening.advance(layer, Opening.EVENING)
	var cues: Array[Callable] = []
	for n: Array in PHONE:
		cues.append(_do(func() -> void: lines.phone(n[0], n[1], n[2])))
		cues.append(_wait(1.6))
	cues.append(_do(_to_evening))
	_run(cues)


## Time passes to 19:02; the office empties but for one lamp; the clock appears.
func _to_evening() -> void:
	var minutes := EVENING_MINUTE - office.session.minute_of_day()
	if minutes > 0:
		office.session.pass_time(minutes)
	if guide != null:
		guide.visible = false
	_hide_seated_ruud(false)
	if office.floors.floor_id != "first":
		office.floors.go_to("first", "stairs_up", true)
	office.player.position = _v(EVENING_AT)
	office.player.face(Basis.looking_at(Vector3(-1, 0, 0)))
	office.rig.yaw = office.player.rotation.y
	office.rig.snap()
	_anouk()


# ── B7: Anouk om zeven uur ─────────────────────────────────────────────────

func _anouk() -> void:
	Opening.advance(layer, Opening.ANOUK)
	_evening_people()
	office.ui.after_action()
	var state := {"called": false}
	_run([func(_dt: float) -> bool:
		var anouk := office.people.person("anouk")
		if office.ui.dialog_panel.visible:
			state["called"] = true
		elif anouk != null and _near(office.player.position, anouk.position, CALL_DISTANCE) and not office.busy():
			call_out()
		return state["called"] or office.ui.dialog_panel.visible,
		func(_dt: float) -> bool: return not office.ui.dialog_panel.visible,
		_do(_after_talk)])


## Anouk calls out as you pass (the exit passes her desk): her talk opens.
func call_out() -> void:
	office.ui.dialog_panel.first_hint = tr(TALK_HINT)
	var anouk := office.people.person("anouk")
	if anouk != null:
		office.talk_to(anouk)


## Only Anouk is still in; the rest have gone home (OfficePeople.stay_in): one desk lamp
## burns, hers at Werkvoorbereiding (OfficeDaylight).
func _evening_people() -> void:
	office.people.stay_in = ["anouk"]
	office.people.refresh(office.session)
	office.daylight.update(office.session)


func _after_talk() -> void:
	var talked: bool = office.session.people.talk_log.get("anouk", []).any(
		func(t: Dictionary) -> bool: return t.get("dialog") == "anouk_seven")
	if office.session.dialog_meter().is_empty() and talked:
		Opening.advance(layer, Opening.DONE)
		lines.hint(tr(HINT_JOURNAL), 8.0)
		_end()
		if office.session.minute_of_day() >= EVENING_MINUTE:   # the screen goes to Tuesday morning
			office.session.pass_time(SimCalendar.MINUTES_PER_DAY - office.session.minute_of_day() + GameSession.START_MINUTE)
		office.ui.after_action()
	else:
		_anouk()   # closed before it began: she is still there


func _end() -> void:
	office.people.stay_in = []
	_hide_seated_ruud(false)
	for n: Node in [guide, yvonne, _skip_link]:
		if n != null:
			n.queue_free()
	guide = null
	yvonne = null
	_skip_link = null
	_cues.clear()


# ── Ruud as the guide ──────────────────────────────────────────────────────

func _guide_to(at: Vector3) -> void:
	var route := office.nav().path(guide.position, at)
	_guide_route = route if not route.is_empty() else PackedVector3Array([at])
	_play(guide, "walk")


func _move_guide(dt: float) -> void:
	if guide == null or _guide_route.is_empty():
		return
	var to := _guide_route[0] - guide.position
	to.y = 0
	var step := GUIDE_PACE * dt
	if to.length() <= step:
		guide.position = _guide_route[0]
		_guide_route.remove_at(0)
		if _guide_route.is_empty():
			_play(guide, "idle")
			guide.place(guide.position, office.player.position - guide.position)
		return
	guide.place(guide.position + to.normalized() * step, to)


## The walk hint goes once the player has walked a few metres.
func _hints() -> void:
	if _walk_hint_shown and office.player.position.distance_to(_start) >= MOVED_FOR_HINT \
			and lines.hint_text() == tr(HINT_WALK):
		lines.clear_hint()


func _hide_seated_ruud(on: bool) -> void:
	var seated := office.people.person("ruud")
	if seated == null:
		return
	office.people.set_process(not on)
	seated.visible = not on


# ── Cues ────────────────────────────────────────────────────────────────────

func _run(cues: Array[Callable]) -> void:
	_cues = cues


func _do(fn: Callable) -> Callable:
	return func(_dt: float) -> bool:
		fn.call()
		return true


func _wait(seconds: float) -> Callable:
	var state := {"left": seconds}
	return func(dt: float) -> bool:
		state["left"] -= dt
		return state["left"] <= 0.0


func _say(key: String) -> Callable:
	var state := {"started": false}
	return func(_dt: float) -> bool:
		if not state["started"]:
			state["started"] = true
			lines.say(_lines(key))
		return not lines.speaking()


func _until_with_ruud() -> Callable:
	return func(_dt: float) -> bool:
		return _guide_route.is_empty() and _near(office.player.position, guide.position, NEAR)


func _until_floor(id: String) -> Callable:
	return func(_dt: float) -> bool: return office.floors.floor_id == id


## `key`'s lines; an aside (a call-out from afar) moves on by itself and holds no one.
func _lines(key: String, aside := false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: Array in LINES[key]:
		out.append({"who": line[0], "text": fill(line[1]), "aside": aside})
	return out


## A line with the player's tokens ({speler}, the body's words).
func fill(text: String) -> String:
	return office.session.fill_tokens(tr(text))


# ── Places ──────────────────────────────────────────────────────────────────

func _person(model_id: String, display: String, role: String) -> OfficePerson:
	var p := OfficePerson.create({"id": model_id, "name": display, "role": role, "office": {"pose": "idle"}})
	p.name = "Opening" + model_id.capitalize()
	p.tag.visible = false
	p.bar.visible = false
	p.mark.visible = false
	office.add_child(p)
	return p


static func _play(p: OfficePerson, animation: String) -> void:
	var player := CharacterModel.animations(p.model)
	if player != null and player.has_animation(animation):
		player.play(animation, 0.25)


func _point(node: String, fallback: Vector2) -> Vector3:
	var found := office.find_marker(node)
	return office.in_office(found).origin * Vector3(1, 0, 1) if found != null else _v(fallback)


func _marker(id: String, fallback: Vector2) -> Vector3:
	var found: Node3D = OfficeBuilding.markers(office.geometry).get(id)
	return office.in_office(found).origin * Vector3(1, 0, 1) if found != null else _v(fallback)


func _interactable_at(id: String, fallback: Vector2) -> Vector3:
	var i := office.interactable(id)
	return i.position * Vector3(1, 0, 1) if i != null else _v(fallback)


## Where Ruud waits at his room: in front of the coach's marker.
func _coach_door() -> Vector3:
	return _interactable_at("coach", Vector2(22.4, -13.0))


static func _v(xz: Vector2) -> Vector3:
	return Vector3(xz.x, 0, xz.y)


static func _near(a: Vector3, b: Vector3, distance: float) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() <= distance
