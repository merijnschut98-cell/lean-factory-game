class_name Soundscape
extends Node
## A thin sound layer (design §1.3, S1-B; no music): the office bed (an air-handling hum,
## voices across the floor, keyboards, now and then a phone further off) that follows the
## hour and how many people are in, footsteps on the player's walk, and one-shots for
## doors, the lift, the camera shutter and the vans in the yard. A child of the Office
## (the project has no autoloads); a one-shot anywhere else (the creator's shutter) goes
## through play_at. Settings `[audio] master` (default low) and `[audio] muted` through
## Settings. Every file is CC0 and listed in game/assets/audio/SOURCES.md.

const DIR := "res://assets/audio/"
## Sound id → its files (one is picked at random); [] is a hook with no sound yet.
const SOUNDS := {
	"bed_room": ["office_room_tone.ogg"], "bed_murmur": ["office_murmur.ogg"], "bed_keys": ["office_keys.ogg"],
	"phone_far": ["phone_far.ogg"],
	"step_carpet": ["step_carpet_1.ogg", "step_carpet_2.ogg", "step_carpet_3.ogg", "step_carpet_4.ogg"],
	"step_tile": ["step_tile_1.ogg", "step_tile_2.ogg", "step_tile_3.ogg", "step_tile_4.ogg"],
	"door_open": ["door_open.ogg"], "door_close": ["door_close.ogg"],
	"lift_ding": ["lift_ding.ogg"], "lift_door": ["lift_door.ogg"],
	"shutter": ["shutter.ogg"], "van_start": ["van_start.ogg"], "van_drive": ["van_drive.ogg"],
	"phone_buzz": [],   # no CC0 vibration found on the approved sites (SOURCES.md)
}
const SECTION := "audio"
const MASTER_DEFAULT := 0.6
const MUTE_LABEL := "Geluid uit"
const VOLUME_LABEL := "Volume"
## The bed's layers: the sound and its loudness at a full office at 10:00 (linear, before
## the master). The room tone hums whenever the building is open, people or not.
const LAYERS := {"room": ["bed_room", 0.18], "murmur": ["bed_murmur", 0.3], "keys": ["bed_keys", 0.22]}
## The building's day, minutes since midnight → how busy it sounds (0..1), straight lines
## between. ESTIMATE, from an ordinary office day: in from 07:30, full by 10:00 (coffee
## round), a dip at lunch, the afternoon a little lower, most gone by 17:30, near silent
## at 18:30 (design §1.3).
const DAY := [[0, 0.0], [7 * 60, 0.0], [8 * 60, 0.35], [9 * 60, 0.75], [10 * 60, 1.0], [11 * 60 + 30, 0.95],
	[12 * 60 + 15, 0.6], [13 * 60, 0.9], [15 * 60, 0.85], [16 * 60 + 30, 0.6], [17 * 60 + 30, 0.25],
	[18 * 60 + 30, 0.05], [19 * 60, 0.02], [20 * 60, 0.0], [24 * 60, 0.0]]
## The hum runs while the building is open (07:00–19:00), quieter outside those hours.
const OPEN_HOURS := Vector2i(7 * 60, 19 * 60)
## Metres between footsteps at a walk (the walk clip's stride).
const STRIDE := 0.75
const STEP_DB := -10.0
## The core of every floor (stairs, lift, hall) has a tiled floor: x between these (office space).
const CORE_X := Vector2(-6.0, 0.0)
## A far phone rings now and then: seconds between rings at a full office.
const PHONE_EVERY := 45.0
const POLL_SECONDS := 1.0

var settings_path := Settings.PATH
var office: Office
## Layer id → its looping player.
var layers := {}
var _since := POLL_SECONDS   # the first frame looks at the clock
var _phone_in := PHONE_EVERY
var _walked := 0.0
var _last_at := Vector3.INF
var _last_minute := -1


func _init() -> void:
	name = "Soundscape"
	for id: String in LAYERS:
		var player := AudioStreamPlayer.new()
		player.name = id
		player.stream = _looping(LAYERS[id][0])
		player.volume_db = -80.0
		add_child(player)
		layers[id] = player


# ── Settings ────────────────────────────────────────────────────────────────

static func master(path: String = Settings.PATH) -> float:
	return clampf(Settings.get_float(SECTION, "master", MASTER_DEFAULT, path), 0.0, 1.0)


static func muted(path: String = Settings.PATH) -> bool:
	return Settings.get_bool(SECTION, "muted", false, path)


## "" or what went wrong.
static func set_master(value: float, path: String = Settings.PATH) -> String:
	return Settings.set_value(SECTION, "master", clampf(value, 0.0, 1.0), path)


static func set_muted(on: bool, path: String = Settings.PATH) -> String:
	return Settings.set_value(SECTION, "muted", on, path)


## The settings' controls (title menu Instellingen, pause menu): "Geluid uit" and a volume
## slider, each writing its setting as it changes.
static func settings_controls(path: String = Settings.PATH) -> Array[Control]:
	var box := CheckBox.new()
	box.text = MUTE_LABEL   # a Button translates its own text
	box.button_pressed = muted(path)
	box.toggled.connect(func(on: bool) -> void: _warn(set_muted(on, path)))
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = VOLUME_LABEL
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = master(path)
	slider.custom_minimum_size.x = 200
	slider.value_changed.connect(func(v: float) -> void: _warn(set_master(v, path)))
	row.add_child(slider)
	return [box, row]


# ── The bed ─────────────────────────────────────────────────────────────────

## How busy the office sounds (0..1) at `minute` with this share of its people in.
static func bed_level(minute: int, occupancy: float) -> float:
	var day := 0.0
	for i in range(1, DAY.size()):
		if minute <= DAY[i][0]:
			var a: Array = DAY[i - 1]
			var b: Array = DAY[i]
			day = lerpf(a[1], b[1], inverse_lerp(a[0], b[0], minute))
			break
	return day * (0.25 + 0.75 * clampf(occupancy, 0.0, 1.0))


## Set the bed's layers for this hour and occupancy (muted: all stopped).
func apply_bed(minute: int, occupancy: float) -> void:
	var off := muted(settings_path)
	var gain := master(settings_path)
	var busy := bed_level(minute, occupancy)
	var open := minute >= OPEN_HOURS.x and minute < OPEN_HOURS.y
	for id: String in layers:
		var player: AudioStreamPlayer = layers[id]
		var level: float = (1.0 if open else 0.3) if id == "room" else busy
		var linear: float = level * LAYERS[id][1] * gain
		if off or linear <= 0.001 or player.stream == null:
			player.stop()
			continue
		player.volume_db = linear_to_db(linear)
		if not player.playing and player.is_inside_tree():
			player.play(randf() * player.stream.get_length())


# ── One-shots ───────────────────────────────────────────────────────────────

## Play a sound once under `parent` (the player frees itself when done). Null when muted,
## for a hook with no sound, or when the file is missing.
static func play_at(parent: Node, id: String, path: String = Settings.PATH, volume_db := 0.0) -> AudioStreamPlayer:
	var files: Array = SOUNDS.get(id, [])
	if files.is_empty() or muted(path) or not is_instance_valid(parent):
		return null
	var stream := _stream(files.pick_random())
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(maxf(master(path), 0.001))
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	if player.is_inside_tree():
		player.play()
	return player


func play(id: String, volume_db := 0.0) -> AudioStreamPlayer:
	return play_at(self, id, settings_path, volume_db)


## Arriving on a floor: the lift's ding and doors, or the yard's back door behind you.
func arrive(how: String) -> void:
	match how:
		"lift":
			play("lift_ding", -4.0)
			play("lift_door", -8.0)
		"exit":
			play("door_open", -6.0)
			if is_inside_tree():
				get_tree().create_timer(0.8).timeout.connect(play.bind("door_close", -6.0))


## A footstep where the player stands on `floor_id`.
func step(at: Vector3, floor_id: String) -> AudioStreamPlayer:
	return play("step_" + surface_at(at, floor_id), STEP_DB)


static func surface_at(at: Vector3, floor_id: String) -> String:
	if floor_id == "yard" or (at.x > CORE_X.x and at.x < CORE_X.y):
		return "tile"
	return "carpet"


# ── The office's clock ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if office == null or office.session == null or not office.session.error.is_empty():
		return
	_footsteps()
	_since += delta
	if _since < POLL_SECONDS:
		return
	var minute := office.session.minute_of_day()
	var occupied := occupancy()
	apply_bed(minute, occupied)
	_phone_in -= _since * bed_level(minute, occupied)
	if _phone_in <= 0.0:
		_phone_in = PHONE_EVERY * randf_range(0.6, 1.6)
		play("phone_far", -6.0)
	if office.yard != null and _last_minute >= 0:
		for at in [OfficeYard.OUT, OfficeYard.BACK]:
			if _last_minute < at and minute >= at:
				play("van_start")
				play("van_drive", -4.0)
	_last_minute = minute
	_since = 0.0


## The share of this floor's people who are in now (0..1).
func occupancy() -> float:
	if office.people == null or office.people.people.is_empty():
		return 0.0
	var visible := office.people.people.filter(func(p: OfficePerson) -> bool: return p.visible).size()
	return visible / float(office.people.people.size())


func _footsteps() -> void:
	var player := office.player
	if player == null:
		return
	var at := player.position
	var moved := Vector2(at.x - _last_at.x, at.z - _last_at.z).length() if _last_at != Vector3.INF else 0.0
	if moved < 1.0:   # a longer jump is a floor change or a placed player, not a walk
		_walked += moved
	_last_at = at
	if _walked >= STRIDE:
		_walked = 0.0
		step(at, office.floors.floor_id if office.floors != null else "")


static func _stream(file: String) -> AudioStream:
	var path := DIR + file
	if not ResourceLoader.exists(path):
		push_warning("soundscape: missing " + path)
		return null
	return load(path)


static func _looping(id: String) -> AudioStream:
	var stream := _stream(SOUNDS[id][0])
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		stream.loop = true
	return stream


static func _warn(error: String) -> void:
	if not error.is_empty():
		push_warning(error)
