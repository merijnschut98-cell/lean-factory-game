class_name OfficeDaylight
extends Node3D
## The light follows the clock (PLAN 2.14 S1-A; design 2026-10-21 §1.2): the sun through
## the windows, its colour, the room's ambient light and the sky turn with the hour band
## of the session's minute_of_day (07–09 low and warm, 09–16 neutral, 16–18 low and warm,
## after 18 dark; before 07 dark too). After 17:00 a desk lamp burns at every desk
## where someone still sits at their own workstation (OfficePeople.lamp_spots): the
## opening's evening, with only Anouk in, is one lamp at Werkvoorbereiding.
##
## The evening is a runtime dim, not a second lightmap set (spike, 2026-10-21): the
## office's baked lightmap is imported as a multiply detail layer (office_import.gd), a
## shading of the corners rather than light, so dimming the sun and the ambient darkens
## the baked rooms with them; frame time does not change (no second set of textures).
## Seasons wait for Phase 3.

## Seconds between looks at the clock (as OfficePeople.REFRESH_SECONDS).
const REFRESH_SECONDS := 0.5
## The bands by their first minute.
const BANDS: Array[Array] = [[0, "night"], [7 * 60, "morning"], [9 * 60, "day"], [16 * 60, "evening"], [18 * 60, "night"]]
## Per band: the way the sun shines (Office.SUN_DIRECTION by day; from the east-south-east
## low in the morning, from the west-south-west low in the evening), its colour and
## energy, the ambient light's colour and energy, the sky's top and horizon colours.
## Values by eye on the office's screenshots (estimates); the day is the office's look
## from before the clock (Office.SUN_DIRECTION, office_environment.tres).
const LOOKS := {
	"morning": {"sun": Vector3(-0.62, -0.3, -0.72), "sun_color": Color(1.0, 0.8, 0.6), "sun_energy": 1.1,
		"ambient": Color(1.0, 0.9, 0.8), "ambient_energy": 0.45,
		"sky_top": Color(0.42, 0.52, 0.72), "sky_horizon": Color(0.98, 0.8, 0.62)},
	"day": {"sun": Office.SUN_DIRECTION, "sun_color": Color(1, 0.95, 0.86), "sun_energy": 1.6,
		"ambient": Color(0.93, 0.95, 1), "ambient_energy": 0.55,
		"sky_top": Color(0.36, 0.55, 0.82), "sky_horizon": Color(0.78, 0.85, 0.92)},
	"evening": {"sun": Vector3(0.72, -0.25, -0.65), "sun_color": Color(1.0, 0.7, 0.48), "sun_energy": 0.9,
		"ambient": Color(1.0, 0.85, 0.74), "ambient_energy": 0.4,
		"sky_top": Color(0.33, 0.38, 0.6), "sky_horizon": Color(0.95, 0.62, 0.45)},
	"night": {"sun": Vector3(0.2, -0.6, -0.77), "sun_color": Color(0.55, 0.62, 0.85), "sun_energy": 0.06,
		"ambient": Color(0.5, 0.56, 0.75), "ambient_energy": 0.14,
		"sky_top": Color(0.02, 0.03, 0.07), "sky_horizon": Color(0.06, 0.08, 0.14)},
}
## Desk lamps burn from this minute (design §1.2: after 17:00).
const LAMPS_FROM := 17 * 60
## A desk lamp: a small warm light this high (m) over the desk's marker, this far.
const LAMP_HEIGHT := 1.0
const LAMP_RANGE := 2.6
const LAMP_ENERGY := 1.6
const LAMP_COLOR := Color(1.0, 0.82, 0.58)

var office: Office
var sun: DirectionalLight3D
## The office's environment (a copy: the sky and ambient change), or null without one.
var environment: WorldEnvironment
## The band shown now ("" before the first look).
var band := ""
## The lamps made so far; the first lit_desks() of them burn.
var lamps: Array[OmniLight3D] = []
var _lit := 0
var _since := 0.0


## The office's sun and environment, in the day's look until the clock is read.
static func create(of_office: Office) -> OfficeDaylight:
	var d := OfficeDaylight.new()
	d.name = "Daylight"
	d.office = of_office
	if ResourceLoader.exists(Office.ENVIRONMENT):
		d.environment = WorldEnvironment.new()
		d.environment.environment = (load(Office.ENVIRONMENT) as Environment).duplicate(true)
		d.add_child(d.environment)
	d.sun = DirectionalLight3D.new()
	d.sun.shadow_enabled = true
	d.sun.shadow_blur = 1.5
	d.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	d.sun.directional_shadow_max_distance = 40.0
	d.add_child(d.sun)
	d.apply(12 * 60)
	return d


static func band_at(minute: int) -> String:
	var out := "night"
	for b in BANDS:
		if minute >= int(b[0]):
			out = b[1]
	return out


## The look of the band `minute` falls in (nothing changes inside a band).
func apply(minute: int) -> void:
	var now := band_at(minute)
	if now == band:
		return
	band = now
	var look: Dictionary = LOOKS[band]
	sun.basis = Basis.looking_at((look["sun"] as Vector3).normalized())
	sun.light_color = look["sun_color"]
	sun.light_energy = look["sun_energy"]
	sun.shadow_enabled = band != "night"
	if environment == null:
		return
	var env := environment.environment
	env.ambient_light_color = look["ambient"]
	env.ambient_light_energy = look["ambient_energy"]
	var sky := env.sky.sky_material as ProceduralSkyMaterial if env.sky != null else null
	if sky != null:
		sky.sky_top_color = look["sky_top"]
		sky.sky_horizon_color = look["sky_horizon"]
		sky.ground_horizon_color = (look["sky_horizon"] as Color).darkened(0.1)


## The light for the session's clock now, and the lamps at the desks still in use. A
## session without a clock, or whose content failed to load (it has none), keeps the day.
func update(session: Object) -> void:
	if session == null or not session.has_method("minute_of_day"):
		return
	var failed: Variant = session.get("error")
	if failed is String and not (failed as String).is_empty():
		return
	var minute: int = session.call("minute_of_day")
	apply(minute)
	var spots := office.people.lamp_spots() if minute >= LAMPS_FROM and office.people != null else PackedVector3Array()
	light_desks(spots)


## A lamp over each of `desks` (office space, on the floor); the rest go out.
func light_desks(desks: PackedVector3Array) -> void:
	while lamps.size() < desks.size():
		var lamp := OmniLight3D.new()
		lamp.name = "DeskLamp%d" % lamps.size()
		lamp.light_color = LAMP_COLOR
		lamp.light_energy = LAMP_ENERGY
		lamp.omni_range = LAMP_RANGE
		lamp.shadow_enabled = false
		add_child(lamp)
		lamps.append(lamp)
	for i in lamps.size():
		lamps[i].visible = i < desks.size()
		if i < desks.size():
			lamps[i].position = desks[i] + Vector3.UP * LAMP_HEIGHT
	_lit = desks.size()


## How many desk lamps burn.
func lit_desks() -> int:
	return _lit


func _process(delta: float) -> void:
	_since += delta
	if _since >= REFRESH_SECONDS and office != null:
		_since = 0.0
		update(office.session)
