class_name OfficeTells
extends Node
## The world shows the work (PLAN 2.6, design §1.5): props on the 1e, the 2e and the yard that
## read the region.
## Each tell is a node `tell_<id>` in the floor's model (tools/blender/build_office.py, the
## yard's build_yard.py) with three variants `tell_<id>_low`, `_mid` and `_high`; this shows
## one, by a number from the simulation, and looks again when time has passed. A child of the
## Office while a floor with tells is loaded.
##
## The tells are ambiguous on purpose: a tall stack can be a normal busy week, and the
## same pile shows whatever fills it. They never say what is wrong; the player still has
## to go and look (content/problems_tier1.yaml `tells:` lists which problem can show where).
##
## Looking closer (PLAN 2.15): E beside a tell, or a click on it, moves the camera in and one
## line over it says what anyone would see (`text`); the line is noted once in Notities as a
## "Waarneming". Walking on, or the line's time, gives the camera back.

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
## The 2e (PLAN 2.16; probe 2026-10-23: GameSession, seeds 11 and 12, daily over 60 days and
## weekly over 240 days, each problem active from the first day):
## - obeya_board (the value streams late on their norm, KPI cards in red): base 1 to 5 of 6,
##   median 3 (seeds 11-13, weekly over 150 days), every problem alike: the board reads the
##   region, not one problem.
## - grid_study_tray (studies waiting for the grid analysts, connections and congestion):
##   base median 0 and 2 (peaks 11), grid_study_queue 12 and 21 (peaks 27).
## - reinforcement_board (streets waiting for their reinforcement): base 53 to 86,
##   transformer_wait climbs to 104 and 115 by week 30 (a wait of months fills slowly).
## - congestion_list (requests waiting for capacity): base 21 to 45, unused_capacity 43 and
##   63 after half a year, transformer_wait up to 51.
## The yard (PLAN 2.6, S3-Y; probe 2026-10-24: tools/yard_tell_probe.gd, GameSession, seeds 11
## and 12, daily over 60 days after day 9, each problem active from the first day; min/median/max).
## No job waits for material there: the stock covers every week (0 in every run), so the
## field tells read what the field work uses and brings back.
## - van_kanban (the joints the storingsbussen took this week: a card each in the kanban
##   wall's "bestellen" column): base 3/7/11 and 3/8/12, digging_damage 5/12/18 and 6/10/16.
##   wrong_joint_in_van takes no more joints (its harm is the drive to fetch one), so the wall
##   shows it only in a busy week, as it would.
## - magazijn_rack (the share of the joint shelf that is empty, % of reorder point plus an
##   order): base 16/51/83 and 13/44/79 (it empties and refills with each delivery: a low
##   shelf can be the day before the truck), digging_damage 27/60/92 and 15/60/89.
## - van_returns (meters and connection kits back on the pallet from a failed visit in the last
##   MOVED_DAYS: no one home, the meterkast not ready): base 6/12/20 and 7/13/23, not_at_home
##   and double_visits 7/21/35 and 10/22/38, installer_not_ready 11/23/34 and 13/25/43.
## - storingsbord (this week's callouts, plus those searched for again and those past the
##   norm, plus each "materiaal halen"): base 11/18/27 and 7/19/37, digging_damage 13/25/35
##   and 15/26/35, knowledge_drain 13/28/43 and 10/27/66, wrong_joint_in_van 14/27/36 and
##   8/28/44 (probe 2026-10-24, S3 G-A: the trips; before them 11/19/29 and 8/20/42).
## - measurement_tray (voltage complaints waiting for a measurement or with a logger out):
##   base 2/6/11 and 1/6/12, inverters_tripping 12/22/33 and 9/16/30.
const THRESHOLDS := {"intake_stack": [15, 30], "prep_tray": [6, 12], "planning_board": [8, 16],
	"revision_cabinet": [6, 12], "close_out_cabinet": [15, 35], "meter_board": [8, 12],
	"obeya_board": [3, 5], "grid_study_tray": [6, 15], "reinforcement_board": [90, 105], "congestion_list": [40, 55],
	"van_kanban": [10, 14], "magazijn_rack": [55, 80], "van_returns": [18, 28], "storingsbord": [24, 32],
	"measurement_tray": [10, 18]}
## A value stream's KPI card is red when fewer than this share of the orders finished over
## the last KPI_DAYS met its norm: the healthy base meets the norm about nine times in ten
## (value_streams.yaml, connections). A card shows no colour with fewer than
## KPI_MIN_FINISHED finished (KpiBoard's rule: chance moves a few orders more than the work).
const ON_TIME_BAR := 0.9
const KPI_DAYS := 28
const KPI_MIN_FINISHED := KpiBoard.MIN_COMPLETED
## The window the planning board counts moved jobs over (a working week).
const MOVED_DAYS := 5
## The window Meetdata's whiteboard lists silent meters over (two weeks: five days hold too
## few to tell a bad week from a normal one).
const METER_DAYS := 10
## The window the yard's week tells count over (the kanban wall's cards, the storingsbord).
const WEEK_DAYS := 7
## Seconds between looks at the clock.
const POLL_SECONDS := 1.0
## The prompt beside a tell: it says you can look, never what is there.
const PROMPT := "E — Van dichtbij bekijken"
## A look ends when the player has walked this far (m) from where they stood.
const LEAVE := 0.5
## The line floats this high (m) over the tell's top.
const LINE_LIFT := 0.1
## The camera looks a little past the player's shoulder (rad), so they do not hide the tell.
const LOOK_ANGLE := 0.5
## The most (s) one frame takes off a line's time.
const MAX_STEP := 0.1

var office: Office
## What each tell looks like: OfficeBuilding.tells.
var looks: Dictionary = {}
## The line over the tell looked at (OfficePerson's subtitle style), hidden between looks.
var line: Label3D
var _seen_time := -1
var _since := INF
## The tell looked at now ("" for none), how long its line still shows, where the player stood.
var _looking := ""
var _look_left := 0.0
var _look_from := Vector3.ZERO
## tell → its bounds in the office's space (all variants), filled on first use.
var _boxes: Dictionary = {}
## tell → its root node in the floor's model (only the tells this floor has).
var roots: Dictionary = {}


## The tells on the office's floor, or null when its model has none.
static func create(of_office: Office) -> OfficeTells:
	var found := {}
	for tell: String in THRESHOLDS:
		var root := node(of_office.geometry, tell)
		if root != null:
			found[tell] = root
	if found.is_empty():
		return null
	var tells := OfficeTells.new()
	tells.roots = found
	tells.name = "Tells"
	tells.office = of_office
	tells.looks = of_office.floors.building.tells if of_office.floors != null else {}
	tells.line = OfficePerson._subtitle()
	tells.add_child(tells.line)
	return tells


## What the player sees of `tell` at `band`: from mid up, the own words of an open problem
## that shows there (`open`); else the tell's look at that height (`looks`, world.yaml).
static func text(tell: String, band: int, tell_looks: Dictionary, open: Array[ProblemDef]) -> String:
	if band >= MID:
		for p in open:
			for t: Dictionary in p.tells:
				if t["tell"] == tell:
					return t["text"]
	return str(tell_looks.get(tell, {}).get(VARIANTS[band], ""))


## Look closer at `tell`: the camera moves in, its line shows over it and is noted once in
## the journal at the tell's place. Returns the line ("" when the tell has no words).
func look(tell: String) -> String:
	var region := office.session.region
	var open: Array[ProblemDef] = []
	open.assign(region.problem_list().filter(func(p: ProblemDef) -> bool: return region.state[p.id].is_open()))
	var said := text(tell, bands(region.net)[tell], looks, open)
	if said.is_empty():
		return ""
	var box := bounds(tell)
	var ahead := (box.get_center() - office.player.position) * Vector3(1, 0, 1)
	office.rig.inspect(box.get_center(), atan2(-ahead.x, -ahead.z) + LOOK_ANGLE)
	line.text = said
	line.position = box.get_center() + Vector3.UP * (box.size.y / 2.0 + LINE_LIFT)
	line.visible = true
	_looking = tell
	_look_left = OfficePerson.say_time(said)
	_look_from = office.player.position
	office.session.gemba.note(looks[tell]["place"], said,
		SimCalendar.day_of(region.net.time) - GameSession.WARMUP_DAYS)
	return said


## The tell looked at now ("" for none).
func looking() -> String:
	return _looking


## The tell `n` is the root of ("" when it is none).
func id_of(n: Node) -> String:
	for tell: String in roots:
		if n != null and n == roots[tell]:
			return tell
	return ""


## The nearest tell with words whose footprint lies within `reach` of `at` (office space;
## "" for none).
func nearest(at: Vector3, reach: float) -> String:
	var best := ""
	for tell in _lookable():
		var d := distance(tell, at)
		if d <= reach:
			best = tell
			reach = d
	return best


## How far `at` is from the tell's footprint on the floor (0 over it; INF without the tell).
func distance(tell: String, at: Vector3) -> float:
	var box := bounds(tell)
	if box.size == Vector3.ZERO:
		return INF
	var foot := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var p := Vector2(at.x, at.z)
	return p.distance_to(p.clamp(foot.position, foot.end))


## The tell with words under a ray from `origin` along `ray` (office space; "" for none).
func under(origin: Vector3, ray: Vector3) -> String:
	for tell in _lookable():
		if bounds(tell).intersects_ray(origin, ray) != null:
			return tell
	return ""


## The tells on this floor that have words.
func _lookable() -> Array[String]:
	var out: Array[String] = []
	out.assign(roots.keys().filter(func(tell: String) -> bool: return looks.has(tell)))
	return out


## The tell's bounds in the office's space, every variant included (empty without it).
func bounds(tell: String) -> AABB:
	if not _boxes.has(tell):
		var box := AABB()
		var root: Node3D = roots.get(tell)
		for n in root.find_children("*", "MeshInstance3D", true, false) if root != null else []:
			var b: AABB = office.in_office(n) * (n as MeshInstance3D).get_aabb()
			box = b if box.size == Vector3.ZERO else box.merge(b)
		_boxes[tell] = box
	return _boxes[tell]


func _end_look() -> void:
	_looking = ""
	line.visible = false
	if not office.busy():
		office.rig.release()


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
		"meter_board": _counted(net, "meters.registration", METER_DAYS), "obeya_board": _red_cards(net),
		"grid_study_tray": _waiting(net, ["connections.grid_study", "congestion.congestion_study"]),
		"reinforcement_board": _waiting(net, ["connections.grid_reinforcement"]),
		"congestion_list": _waiting(net, ["congestion.capacity_queue"]),
		"van_kanban": _counted(net, "outages.joint", WEEK_DAYS, "entered"), "magazijn_rack": _shelf_empty(net, "cable_joint"),
		"van_returns": _counted(net, "meters.visit", MOVED_DAYS) + _counted(net, "connections.execution", MOVED_DAYS),
		"storingsbord": _callouts(net),
		"measurement_tray": _waiting(net, ["voltage_complaints.measurement", "voltage_complaints.measurement_week"])}


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
	if not _looking.is_empty():
		_look_left -= minf(delta, MAX_STEP)   # a hitch (a shader compiling) does not eat the line
		var moved := (office.player.position - _look_from) * Vector3(1, 0, 1)
		if _look_left <= 0.0 or moved.length() > LEAVE:
			_end_look()
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


## A count (SimStep.stats_since: "reworked", "entered") at `place` over the last `days` (0
## when the network lacks the place). Meetdata's silent meters are the registrations reworked.
static func _counted(net: Network, place: String, days: int, what := "reworked") -> int:
	var step := net.step_at(place)
	return 0 if step == null else step.stats_since(SimCalendar.day_of(net.time) - days)[what]


## How much of a full shelf of `item` (its reorder point plus an order) is empty, in percent.
static func _shelf_empty(net: Network, item: String) -> int:
	var stock: SimStock = net.stock.get(item)
	if stock == null:
		return 0
	var full := stock.reorder_point + stock.order_quantity
	return clampi(roundi(100.0 * (full - stock.level) / full), 0, 100) if full > 0 else 0


## The storingsdienst's board: this week's callouts, plus a mark for each fault searched for
## again, each "materiaal halen" (a monteur back to the magazijn mid-repair) and each outage
## that lasted past its norm.
static func _callouts(net: Network) -> int:
	var outages := net.stream("outages")
	if outages == null:
		return 0
	var k := outages.kpis(net.time, WEEK_DAYS)
	var late := roundi(k["completed"] * (1.0 - k["on_time"])) if k["completed"] > 0 else 0
	return _counted(net, "outages.report", WEEK_DAYS, "entered") + _counted(net, "outages.locate", WEEK_DAYS) + late \
		+ net.material_trips_since(SimCalendar.day_of(net.time) - WEEK_DAYS)


## The value streams whose KPI card is red: too few of their finished orders met the norm.
static func _red_cards(net: Network) -> int:
	return net.streams.filter(func(s: ValueStream) -> bool:
		var k := s.kpis(net.time, KPI_DAYS)
		return k["completed"] >= KPI_MIN_FINISHED and k["on_time"] < ON_TIME_BAR).size()
