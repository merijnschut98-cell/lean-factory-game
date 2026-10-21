class_name OfficeTells
extends Node
## The world shows the work (PLAN 2.6, design §1.5): props on the 1e that read the region.
## Each tell is a node `tell_<id>` in the floor's model (tools/blender/build_office.py) with
## three variants `tell_<id>_low`, `_mid` and `_high`; this shows one, by a number from the
## simulation, and looks again when time has passed. A child of the Office while a floor
## with tells is loaded.
##
## The tells are ambiguous on purpose: a tall stack can be a normal busy week, and the
## same pile shows whatever fills it. They never say what is wrong; the player still has
## to go and look (content/problems_tier1.yaml `tells:` lists which problem can show where).

const LOW := 0
const MID := 1
const HIGH := 2
const VARIANTS: Array[String] = ["low", "mid", "high"]
## Per tell: the reading from which it shows mid and high. ESTIMATES from a probe
## (2026-10-21; GameSession, 2 seeds x 30 days, sampled daily after day 9; medians):
## - intake_stack (applications in Intake's queue plus those back with the customer for
##   missing details): base 14 and 25, incomplete_application 31 and 36. Base seed 2
##   reads mid and peaks high: a tall stack can be a normal week.
## - prep_tray (Werkvoorbereiding's queue plus finished designs held for their project's
##   permit batch): base 5 and 6, custom_design 10 and 13, training_tray 9 and 10,
##   permits_in_batches 16 and 17.
## - planning_board (jobs moved in the last 5 days: execution sent back to planning,
##   for a meterkast not ready or a monteur pulled away to an outage): base 4 and 9,
##   planning_reshuffle 17 and 18, installer_not_ready 18 and 20.
## - revision_cabinet (sketches of finished jobs waiting at Revisie & GIS): base 1 (peaks
##   12), revision_backlog 9 (peaks 19). A quiet stretch can still leave a high pile.
## - close_out_cabinet (finished connections waiting for the close-out, on the wait and at
##   Meetdata's desk): base 9 (peaks 18), done_but_not_closed 52 (the monthly batch).
## - meter_board (new meters that sent no reading in the last METER_DAYS: a failed
##   registration): base 6 (peaks 9), silent_meter 11 (peaks 16).
##   (Probe 2026-10-21, same method; not_at_home leaves all three at base.)
const THRESHOLDS := {"intake_stack": [15, 30], "prep_tray": [6, 12], "planning_board": [8, 16],
	"revision_cabinet": [6, 12], "close_out_cabinet": [15, 35], "meter_board": [8, 12]}
## The window the planning board counts moved jobs over (a working week).
const MOVED_DAYS := 5
## The window Meetdata's whiteboard lists silent meters over (two weeks: five days hold too
## few to tell a bad week from a normal one).
const METER_DAYS := 10
## Seconds between looks at the clock.
const POLL_SECONDS := 1.0

var office: Office
var _seen_time := -1
var _since := INF


## The tells on the office's floor, or null when its model has none.
static func create(of_office: Office) -> OfficeTells:
	if THRESHOLDS.keys().all(func(tell: String) -> bool: return node(of_office.geometry, tell) == null):
		return null
	var tells := OfficeTells.new()
	tells.name = "Tells"
	tells.office = of_office
	return tells


## The node `tell_<id>` in `geometry` (null if there is none).
static func node(geometry: Node, id: String) -> Node3D:
	var name := "tell_" + id
	return Office._find_marker(geometry, name, Office._loose(name))


## Each tell's band (LOW, MID or HIGH) for the network as it is now.
static func bands(net: Network) -> Dictionary:
	var read := readings(net)
	var out := {}
	for tell: String in read:
		out[tell] = band(tell, read[tell])
	return out


## Each tell's number now (see THRESHOLDS); a step the network lacks reads 0.
static func readings(net: Network) -> Dictionary:
	return {"intake_stack": _intake_stack(net), "prep_tray": _prep_tray(net), "planning_board": _moved_jobs(net),
		"revision_cabinet": _waiting(net, ["connections.revision"]),
		"close_out_cabinet": _waiting(net, ["connections.close_out_wait", "connections.close_out"]),
		"meter_board": _silent_meters(net)}


static func band(tell: String, value: int) -> int:
	var at: Array = THRESHOLDS[tell]
	return HIGH if value >= at[1] else (MID if value >= at[0] else LOW)


## Show one variant per tell in `bands` (tell → band); the number of tells found.
static func show(geometry: Node, tell_bands: Dictionary) -> int:
	var found := 0
	for tell: String in tell_bands:
		if node(geometry, tell) == null:
			continue
		found += 1
		for v in VARIANTS.size():
			var variant := node(geometry, "%s_%s" % [tell, VARIANTS[v]])
			if variant != null:
				variant.visible = v == tell_bands[tell]
	return found


## Show the bands for the session's network now.
func refresh() -> void:
	var net := office.session.region.net
	_seen_time = net.time
	show(office.geometry, bands(net))


func _process(delta: float) -> void:
	_since += delta
	if office == null or _since < POLL_SECONDS or not office.session.error.is_empty():
		return
	_since = 0.0
	if office.session.region.net.time != _seen_time:
		refresh()


static func _intake_stack(net: Network) -> int:
	var intake := net.step_at("connections.intake")
	return 0 if intake == null else net.waiting_at(intake) + net.returning_to(intake)


static func _prep_tray(net: Network) -> int:
	var design := net.step_at("connections.design")
	var permit := net.step_at("connections.permit")
	var held := 0
	if permit != null and permit.batch_minutes > 0:
		# Designs finished since the last batch went out wait for the rest of the project.
		var last_batch := int(net.time / float(permit.batch_minutes)) * permit.batch_minutes
		held = permit.stats_since(SimCalendar.day_of(last_batch))["entered"]
	return (0 if design == null else net.waiting_at(design)) + held


static func _moved_jobs(net: Network) -> int:
	var execution := net.step_at("connections.execution")
	if execution == null:
		return 0
	var recent := execution.stats_since(SimCalendar.day_of(net.time) - MOVED_DAYS)
	return recent["reworked"] + recent["interrupted"]


## How many orders wait at these places now (a place the network lacks counts 0).
static func _waiting(net: Network, places: Array[String]) -> int:
	var n := 0
	for place in places:
		var step := net.step_at(place)
		n += 0 if step == null else net.waiting_at(step)
	return n


static func _silent_meters(net: Network) -> int:
	var registration := net.step_at("meters.registration")
	if registration == null:
		return 0
	return registration.stats_since(SimCalendar.day_of(net.time) - METER_DAYS)["reworked"]
