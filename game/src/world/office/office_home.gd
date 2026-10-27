class_name OfficeHome
extends Node
## Going home (PLAN 2.14 S1-A follow-up): the office keeps time, so the day must be able
## to end inside the world. After five the begane grond's front door offers "Naar huis":
## E there ends the day on the next working morning (a weekend skipped) through the
## session's own clock (GameSession.pass_time) and the UI's own dagstart
## (GameUI.after_action: autosave, Ruud's note, the people's day), behind a short fade
## with the date; you come in by the front door. Nothing forces it: you may stay late, and
## the HUD's objective line suggests home over the same window (Objective.home_time: the
## evening and the night), no toast besides.
##
## A colleague an active mission needs (MinimapTargets) who is not at their desk leaves
## it answering for them: E there says where they are ("Sanne is al naar huis. Morgen
## weer."), and the minimap keeps pointing at it. Not during the first day's scene
## (Opening): its evening is scripted (B6, B7). A child of the Office, which routes its
## interaction points here (use, prompt, label) as it does the floors' seams.

const HOME := "home"
const ABSENT := "absent"
## The front door's arrival marker (the begane grond).
const ENTRANCE := "arrive:entrance"
## From this minute the front door offers going home (design: after 17:00), through the
## night (Objective.home_time); the objective line says so over the same window.
const HOME_FROM := Objective.HOME_FROM
## Seconds between looks at the clock (as OfficePeople.REFRESH_SECONDS).
const POLL_SECONDS := 0.5
## The fade: black with the new day's date, clearing over this many seconds.
const FADE_SECONDS := 1.8
const FADE_HOLD := 0.6

const PROMPT := "E — Naar huis"
const DOOR_LABEL := "Voordeur"
const DESK_PROMPT := "E — Bureau van %s"
const DESK_LABEL := "Bureau van %s"
const GONE_HOME := "%s is al naar huis. Morgen weer."
const NOT_IN_YET := "%s is er nog niet."
const AT_LUNCH := "%s zit in de kantine."
const AWAY := "%s is even weg."

var office: Office
var _since := 0.0
var _fade: CanvasLayer
var _fade_label: Label
var _fade_left := 0.0


static func create(of_office: Office) -> OfficeHome:
	var h := OfficeHome.new()
	h.name = "Home"
	h.office = of_office
	return h


## The interaction points as the clock and the missions have them now: the front door
## in home time, the empty desks of the colleagues the missions need.
func poll() -> void:
	var s := office.session
	if s == null or not s.error.is_empty() or office.people == null:
		return
	var minute := s.minute_of_day()
	var scripted := Opening.running(office.ui.session_layer)
	var markers := office.floors.markers()
	var want := {}
	if Objective.home_time(minute) and not scripted and markers.has(ENTRANCE):
		want[HOME] = office.in_office(markers[ENTRANCE])
	if not scripted:
		for id in _needed(s):
			var p := office.people.person(id)
			if p != null and not p.visible and not p.desk.is_empty():
				want["%s:%s" % [ABSENT, id]] = Transform3D(Basis.IDENTITY, p.desk["at"])
	_keep(want)


## The people the active missions point at (their next step is a talk with them).
func _needed(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for t in MinimapTargets.all(s, office.floors.building, CharacterModel.cast()):
		if t["kind"] == "person":
			out.append(t["person"])
	return out


## This node's interaction points exactly `want` (id → transform in the office).
func _keep(want: Dictionary) -> void:
	for i in office.interactables.duplicate():
		if i.kind in [HOME, ABSENT] and not want.has(i.id):
			office.interactables.erase(i)
			office.remove_child(i)
			i.free()
	for id: String in want:
		var found := office.interactables.any(func(i: Interactable) -> bool: return i.id == id)
		if not found:
			var i := Interactable.create(id, want[id])
			i.show_ring(i.kind == HOME)
			office.interactables.append(i)
			office.add_child(i)


## Use one of this node's points; false for any other (the office handles it).
func use(target: Interactable) -> bool:
	if target == null or not target.kind in [HOME, ABSENT]:
		return false
	if target.kind == HOME:
		go_home()
	else:
		office.ui.hud.toast(tr(where_line(target.id.get_slice(":", 1))))
	return true


func prompt(target: Interactable) -> String:
	if target == null or not target.kind in [HOME, ABSENT]:
		return ""
	return tr(PROMPT) if target.kind == HOME else tr(DESK_PROMPT) % _first_name(target.id.get_slice(":", 1))


func label(target: Interactable) -> String:
	if target == null or not target.kind in [HOME, ABSENT]:
		return ""
	return tr(DOOR_LABEL) if target.kind == HOME else tr(DESK_LABEL) % _first_name(target.id.get_slice(":", 1))


## Where someone not at their desk is, in one line: gone home, not in yet, at lunch, away.
func where_line(id: String) -> String:
	var p := office.people.person(id)
	if p == null:
		return ""
	var minute := office.session.minute_of_day()
	var day := office.people.day_of(id)
	var line := AWAY
	match office.people.place_for(p, minute):
		OfficeDay.OUT:
			line = NOT_IN_YET if minute < day.arrive else GONE_HOME
		OfficeDay.LUNCH:
			line = AT_LUNCH
	return line % _first_name(id)


func _first_name(id: String) -> String:
	var p := office.people.person(id)
	return p.display_name.get_slice(" ", 0) if p != null else id


## End the day: the clock to the next working morning, the dagstart, in by the front
## door; a short fade with the new date.
func go_home() -> void:
	var s := office.session
	if office.sound != null:   # the front door, the street; the office fades out behind you
		office.sound.go_home()
	s.pass_time(next_morning(s.region.net.time) - s.region.net.time)
	if office.floors.floor_id != "ground":
		office.floors.go_to("ground", "entrance", true)
	var markers := office.floors.markers()
	if markers.has(ENTRANCE):
		var at := office.in_office(markers[ENTRANCE])
		office.player.position = at.origin
		office.player.face(at.basis)
		office.rig.yaw = office.player.rotation.y
		office.rig.snap()
	office.ui.after_action()
	office.people.refresh(s)
	office.daylight.update(s)
	poll()
	_show_fade(GameSession.day_text(s.region.net.time))
	if office.sound != null:   # the morning office fades in as the black clears
		office.sound.wake_after(FADE_HOLD + FADE_SECONDS * 0.5)


## The next working day's START_MINUTE after `t` (Saturday and Sunday skipped).
static func next_morning(t: int) -> int:
	var day := SimCalendar.day_of(t) + 1
	while SimCalendar.weekday(SimCalendar.days(day) - SimCalendar.days(GameSession.WARMUP_DAYS)) >= 5:
		day += 1
	return SimCalendar.days(day) + GameSession.START_MINUTE


func fading() -> bool:
	return _fade_left > 0.0


func fade_text() -> String:
	return _fade_label.text if _fade_label != null else ""


func _show_fade(date: String) -> void:
	if _fade == null:
		_fade = CanvasLayer.new()
		_fade.name = "HomeFade"
		_fade.layer = 90
		var black := ColorRect.new()
		black.color = Color.BLACK
		black.set_anchors_preset(Control.PRESET_FULL_RECT)
		black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.add_child(black)
		_fade_label = Label.new()
		_fade_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_fade_label.add_theme_font_size_override("font_size", 40)
		_fade_label.add_theme_color_override("font_color", Palette.NOTE_PAPER)
		black.add_child(_fade_label)
		add_child(_fade)
	_fade_label.text = date
	_fade_left = FADE_SECONDS + FADE_HOLD
	_fade.visible = true
	(_fade.get_child(0) as ColorRect).modulate.a = 1.0


func _process(delta: float) -> void:
	if _fade_left > 0.0:
		_fade_left = maxf(0.0, _fade_left - delta)
		(_fade.get_child(0) as ColorRect).modulate.a = clampf(_fade_left / FADE_SECONDS, 0.0, 1.0)
		_fade.visible = _fade_left > 0.0
	_since += delta
	if _since >= POLL_SECONDS:
		_since = 0.0
		poll()
