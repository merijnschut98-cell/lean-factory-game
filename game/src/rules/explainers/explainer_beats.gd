class_name ExplainerBeats
extends RefCounted
## Ruud's beats at the whiteboard (spec 2026-10-16-explainer-spanning-stroom-
## weerstand §4), as a pure machine the view drives: which beat plays, which
## controls are on, and when to move on. Nothing here is a quiz: the player
## answers with the valves and switches, or not at all. A beat moves on on
## Spatie (the first press shows what waits behind a silence, the second goes
## on) or when its wait is met; ← plays the beat before again (PLAN 2.13 A).
## Only with `auto` ("Tekst loopt vanzelf door", off by default) does a beat
## also move on by itself, after its reading time or its wait's timeout.
##
## Main beats play in content order. An alt beat (`alt_of`) replaces its main
## beat when its `when` holds as the beat starts; it then goes to `then` (that
## main beat, played as is) or past its main beat. `skip_when` drops a main
## beat. The state carries over the cross-fade: what was open in the garden
## is switched on in the meterkast.

## Reading time of a beat: a base plus per character (estimate: about 20
## characters a second, a slow reader's pace, since Ruud's lines are short).
const READ_BASE_S := 1.5
const READ_PER_CHAR_S := 0.05
## Ruud's silence after a question (spec §4: "two seconds of silence").
const SILENCE_S := 2.0
## The cross-fade's own time on top of its line (§6.3: about 1.4 s).
const CROSS_S := 1.6
const LOADS: Array[String] = ["lamp", "kettle", "heater"]

var def: ExplainerDef
var on := {"lamp": false, "kettle": false, "heater": false}
## The reel in use: 1 (thin) or 2 (thick).
var haspel := 1
var haspel_unlocked := false
## The kettle ran without the heater in the meterkast (R7's variant).
var kettle_alone_seen := false
var done := false
var closed_early := false
## "Tekst loopt vanzelf door": beats move on after their reading time.
var auto := false

var _beat := {}
var _elapsed := 0.0
var _haspel_at_start := 1
## Main beats in content order.
var _mains: Array[String] = []
## The beats played before this one, oldest first (← goes back through them).
var _history: Array[Dictionary] = []


func _init(explainer: ExplainerDef) -> void:
	def = explainer
	for b: Dictionary in def.beats:
		if not b.has("alt_of"):
			_mains.append(b["id"])


func start() -> void:
	_enter(_mains[0], true)


func beat_id() -> String:
	return _beat.get("id", "")


func beat() -> Dictionary:
	return _beat


func phase() -> String:
	return _beat.get("phase", "meterkast")


## Seconds into the current beat.
func elapsed() -> float:
	return _elapsed


## The beat's place among the main beats, from 1 (an alt beat counts as its main beat).
func number() -> int:
	return _mains.find(_beat.get("alt_of", beat_id())) + 1


## How many main beats there are (the counter's "3/13").
func count() -> int:
	return _mains.size()


## Ruud's lines so far: after a silence the rest waits two seconds (or Spatie).
func lines_shown() -> Array:
	var lines: Array = _beat.get("lines", [])
	var silences: Array = _beat.get("silence_after", [])
	if silences.is_empty() or _elapsed >= _full_at():
		return lines
	return lines.slice(0, int(silences[0]) + 1)


## Seconds into the beat when every line shows (after the first silence).
func _full_at() -> float:
	var silences: Array = _beat.get("silence_after", [])
	if silences.is_empty():
		return 0.0
	var chars := 0
	var lines: Array = _beat.get("lines", [])
	for i in int(silences[0]) + 1:
		chars += String(lines[i]).length()
	return READ_BASE_S + chars * READ_PER_CHAR_S + SILENCE_S


## How long the current beat plays before it moves on by itself (with `auto`).
func duration() -> float:
	if _beat.has("wait_for"):
		return float(_beat.get("timeout_s", 10))
	var chars := 0
	for line: String in _beat.get("lines", []):
		chars += line.length()
	var silences: Array = _beat.get("silence_after", [])
	var t := READ_BASE_S + chars * READ_PER_CHAR_S + SILENCE_S * silences.size()
	return t + (CROSS_S if phase() == "cross" else 0.0)


## Flip a control (lamp, kettle, heater) or swap the reel (haspel). False
## when refused: the reel stays until R8 opens it, nothing moves once done.
func toggle(control: String) -> bool:
	if done:
		return false
	if control == "haspel":
		if not haspel_unlocked:
			return false
		haspel = 3 - haspel
	elif on.has(control):
		on[control] = not on[control]
	else:
		return false
	_note_state()
	if _beat.has("wait_for") and _met(_beat["wait_for"]):
		_leave()
	return true


## Spatie: the rest of the beat's lines if a silence holds them, else on to the next beat.
func next() -> void:
	if done:
		return
	if _elapsed < _full_at():
		_elapsed = _full_at()
	else:
		_leave()


## ← or Backspace: the beat before this one again, all its lines at once.
## The switches stay as they are.
func back() -> void:
	if done or _history.is_empty():
		return
	_beat = _history.pop_back()
	_elapsed = _full_at()
	_haspel_at_start = haspel


func tick(dt: float) -> void:
	if done:
		return
	_elapsed += dt
	if auto and _elapsed >= duration():
		_leave()


## Esc or [Klaar]: closed at once.
func close() -> void:
	if not done:
		closed_early = true
		done = true


func _count() -> int:
	return on.values().count(true)


func _note_state() -> void:
	if phase() != "tuin" and on["kettle"] and not on["heater"]:
		kettle_alone_seen = true


func _holds(condition: String) -> bool:
	match condition:
		"only_lamp":
			return on["lamp"] and _count() == 1
		"kettle_on":
			return on["kettle"]
		"heater_on":
			return on["heater"]
		"never_kettle_alone":
			return not kettle_alone_seen
	return false


func _met(wait: String) -> bool:
	match wait:
		"any_on":
			return _count() >= 1
		"two_on":
			return _count() >= 2
		"kettle_on":
			return on["kettle"]
		"heater_on":
			return on["heater"]
		"heater_again":
			return kettle_alone_seen and on["heater"]
		"haspel":
			return haspel != _haspel_at_start
	return false


## Start a main beat: its alt if one holds, or past it if it is skipped.
## `as_is` plays the main beat itself (an alt's `then`).
func _enter(main_id: String, as_is: bool = false) -> void:
	var main := def.beat(main_id)
	if not as_is:
		if main.has("skip_when") and _holds(main["skip_when"]):
			_after(main_id)
			return
		for b: Dictionary in def.beats:
			if b.get("alt_of") == main_id and _holds(b["when"]):
				_play(b)
				return
	_play(main)


func _play(b: Dictionary) -> void:
	if not _beat.is_empty():
		_history.append(_beat)
	_beat = b
	_elapsed = 0.0
	_haspel_at_start = haspel
	if "haspel" in b.get("unlocks", []):
		haspel_unlocked = true
	_note_state()


func _leave() -> void:
	if _beat.has("then"):
		_enter(_beat["then"], true)
	else:
		_after(_beat.get("alt_of", beat_id()))


## The main beat after `main_id`, or done after the last.
func _after(main_id: String) -> void:
	var at := _mains.find(main_id)
	if at < 0 or at + 1 >= _mains.size():
		done = true
		return
	_enter(_mains[at + 1])
