class_name SessionLayer
extends RefCounted
## The session layer (engagement loop §2, PLAN 1.4): what a play session
## needs around the rules, never a change to them. It reads the GameSession:
## - the terugblik when the game opens: what changed in the last session,
##   who waits, what comes (`terugblik`, `open_session`);
## - the dagstart, where the game suggests stopping after half an hour
##   (`update`, `stop_note_due`);
## - the Intussen view of a running Check and a time skip that names what it
##   skips and stops at beats with people (`intussen`, `skip_to_check`);
## - at most one discovery toast a day, the rest for the next terugblik;
## - at most two new side offers a week; older ones stay open, never lost.
## Results are codes and numbers; the UI words them in Dutch. Respect for
## the player's time: nothing here counts real time against the player.

## New side offers per in-game week (engagement loop §5.2 rule 5).
const NEW_SIDES_PER_WEEK := 2
## Real minutes after which the dagstart suggests stopping (Q2: ~30).
const STOP_NOTE_MINUTES := 30.0
## Lines under Ruud's: one each of changed, waiting, coming.
const MAX_LINES := 3
## A number "moved" when it changed by at least this share (an estimate:
## below it the weekly noise of the simulation dominates).
const CHANGE_MIN := 0.05
## A stream needs this many finished orders in the window for its numbers to
## count (as KpiBoard.MIN_COMPLETED).
const MIN_COMPLETED := 10
## The window the numbers are measured over (days).
const WINDOW_DAYS := 28
## The measures compared (which way is better: Pdca.direction).
const MEASURES: Array[String] = ["lead_days_p50", "on_time", "first_time_right", "throughput_per_week"]
## Built side quests (a slipping fix's check-in, a poor fix's repair) are the
## player's own work coming back: they are never held back.
const BUILT_PREFIXES: Array[String] = [Missions.CHECKIN_PREFIX, Repairs.PREFIX]
const DAY := SimCalendar.MINUTES_PER_DAY

## The snapshot at the start of this session; {} in a new game.
var start := {}
## Side missions offered so far → the in-game day they were offered.
var offered: Dictionary[String, int] = {}
## The in-game day of the last discovery toast.
var toast_day := -1
## Discoveries found after the day's toast: shown at the next terugblik.
var queued: Array[String] = []
## The head office's floor the player was on (PLAN 2.1; "" for the start floor):
## a resumed game opens there.
var floor_id := ""
## Whether Ruud has handed the player the paper floor plan (the minimap, PLAN 2.1b): the
## opening's first walk (2.7d B3) will clear it at the start and set it on the walk;
## until then a new game has it, as do old saves and a skipped training week.
var has_floor_plan := true
## Training days whose glossary card was shown (once a game, also after a
## resume: review N2).
var carded: Array[String] = []
## Where a new game's opening is (Opening.BEATS, PLAN 2.7d); "" for a game
## without one (a returning player, an old save).
var opening_beat := ""
## The phone's Berichten (PLAN 2.14 S1-F, PhoneMessages): each message once,
## in arrival order: {id, at (game minutes), read, and its wording's extras}.
var inbox: Array[Dictionary] = []
## The concepts the player has looked at in the phone's Begrippen (its badge).
var concepts_seen: Array[String] = []
## What new the phone has buzzed for ("<app>:<id>", Phone.announce): once, reload or not.
var announced: Array[String] = []
## Customers' calls (CustomerCalls): dialog id → the day it last rang the phone.
var rang: Dictionary[String, int] = {}
## False for a save from before the phone: GameUI then counts what it holds as read.
var phone_saved := true
## The card shown when this session opened ({} when none): the journal
## reopens it.
var last_card := {}
## The last in-game day seen (dagstart detection; not saved: a loaded game
## starts on its own day).
var _day := -1


## The state a terugblik compares with: the time, the missions done, the
## numbers of every stream, the Checks waiting and the check-ins open.
static func snapshot(s: GameSession) -> Dictionary:
	var measures := {}
	for stream in s.region.net.streams:
		var k := stream.kpis(s.region.net.time, WINDOW_DAYS)
		var m := {"completed": float(k["completed"])}
		for id: String in MEASURES:
			m[id] = float(k[id])
		measures[stream.id] = m
	var done: Array[String] = []
	for id: String in s.missions.defs:
		if s.missions.status(id) == "completed":
			done.append(id)
	return {"t": s.region.net.time, "completed": done, "measures": measures}


## Start a new session's snapshot.
func begin(s: GameSession) -> void:
	start = snapshot(s)
	_day = SimCalendar.day_of(s.region.net.time)


## The game opened on a saved game: the card for what happened since the
## last session started (kept for the journal), the queue cleared, and this
## session's snapshot begun.
func open_session(s: GameSession) -> Dictionary:
	last_card = terugblik(s)
	queued.clear()
	begin(s)
	return last_card


# ── The terugblik ───────────────────────────────────────────────────────────

## {} in a new game; else {ruud: {kind, ...}, lines: [{kind: changed |
## waiting | coming, what, ...}] (at most one of each), discoveries (ids
## found after their day's toast)}. Ruud's kind, most important first:
## completed {mission} | check_ready {problem} | checkin {mission} | changed
## (the changed line) | quiet.
func terugblik(s: GameSession) -> Dictionary:
	if start.is_empty():
		return {}
	var lines: Array[Dictionary] = []
	for line in [_changed(s), _waiting(s), _coming(s)]:
		if not line.is_empty():
			lines.append(line)
	return {"ruud": _ruud(s, lines), "lines": lines, "discoveries": queued.duplicate()}


func _ruud(s: GameSession, lines: Array[Dictionary]) -> Dictionary:
	var before: Array = start.get("completed", [])
	for id: String in s.missions.defs:
		if s.missions.status(id) == "completed" and not before.has(id) and s.missions.defs[id].kind != "training":
			return {"kind": "completed", "mission": id}
	for line in lines:
		if line["kind"] == "waiting" and line["what"] in ["check_ready", "checkin"]:
			return {"kind": line["what"], "problem": line.get("problem", ""), "mission": line.get("mission", "")}
	for line in lines:
		if line["kind"] == "changed":
			return {"kind": "changed"}
	return {"kind": "quiet"}


## The number that moved most since the snapshot: {kind: changed, what:
## measure, stream, measure, before, after, better}; {} when none moved
## enough. The streams the player worked in come first (a consequence of
## their own work, the Gevolg hook); the others only when none of those moved.
func _changed(s: GameSession) -> Dictionary:
	var now: Dictionary = snapshot(s)["measures"]
	var then: Dictionary = start.get("measures", {})
	var worked := {}
	for st: ProblemState in s.region.state.values():
		if st.phase != ProblemState.Phase.DORMANT:
			worked[s.region.problems[st.id].step.get_slice(".", 0)] = true
	var net := s.region.net
	var own := _most_moved(then, now, then.keys().filter(func(id: String) -> bool: return worked.has(id)), net)
	return own if not own.is_empty() else _most_moved(then, now, then.keys(), net)


## `net` says which way each stream's throughput is better (fewer outages is).
static func _most_moved(then: Dictionary, now: Dictionary, streams: Array, net: Network) -> Dictionary:
	var best := {}
	var most := CHANGE_MIN
	for stream: String in streams:
		var b: Dictionary = then[stream]
		var a: Dictionary = now.get(stream, {})
		if a.is_empty() or b.get("completed", 0.0) < MIN_COMPLETED or a["completed"] < MIN_COMPLETED:
			continue
		for id: String in MEASURES:
			var was: float = b.get(id, 0.0)
			if is_zero_approx(was):
				continue
			var share := absf(a[id] - was) / absf(was)
			if share >= most:
				most = share
				best = {"kind": "changed", "what": "measure", "stream": stream, "measure": id, "before": was,
					"after": a[id],
					"better": Pdca.direction(id, KpiBoard.throughput_direction(net, stream)) * (a[id] - was) > 0.0}
	return best


## Who waits, most pressing first: a Check ready {problem, place}; a person
## whose check-in talk is due {person, name, line (their dagstart line)}; a
## check-in or a repair {mission, problem, place}; a main mission on the
## board {mission}.
func _waiting(s: GameSession) -> Dictionary:
	for st: ProblemState in s.region.state.values():
		if st.phase == ProblemState.Phase.CHECK_READY:
			return {"kind": "waiting", "what": "check_ready", "problem": st.id, "place": s.region.problems[st.id].step}
	for p in s.checkin_prompts():   # a person, by name (PLAN 1.4b)
		return {"kind": "waiting", "what": "talk", "person": p["person"], "name": p["name"], "line": p["line"]}
	for m in s.available_missions():
		if held_back(m):
			continue
		if is_built(m):
			return {"kind": "waiting", "what": "checkin" if m.id.begins_with(Missions.CHECKIN_PREFIX) else "repair",
				"mission": m.id, "problem": m.goal_problem, "place": s.region.problems[m.goal_problem].step}
	if s.missions.active("main").is_empty() and not s.in_training():
		for m in s.available_missions():
			if m.kind == "main":
				return {"kind": "waiting", "what": "main", "mission": m.id}
	return {}


## The nearest date ahead: a Check, a deadline or the KPI review.
func _coming(s: GameSession) -> Dictionary:
	var dates := _dates(s, s.region.net.time, INF)
	if dates.is_empty():
		return {}
	var first: Dictionary = dates[0].duplicate()
	first["kind"] = "coming"
	return first


## The dates between `from` (excluded) and `until` (included), soonest
## first: [{what: check | deadline | review, t, id, person}]. A deadline and
## the review are beats with people; another Check is a number.
func _dates(s: GameSession, from: int, until: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for st: ProblemState in s.region.state.values():
		if st.phase == ProblemState.Phase.DOING and st.check_at > from and st.check_at <= until:
			out.append({"what": "check", "t": st.check_at, "id": st.id, "person": false})
	for id: String in _clocks(s):
		var t: int = s.missions.opened_at[id] + SimCalendar.days(s.missions.defs[id].deadline_days)
		if t > from and t <= until:
			out.append({"what": "deadline", "t": t, "id": id, "person": true})
	var board := s.region.board
	if board.unlocked and board.next_review_at > from and board.next_review_at <= until:
		out.append({"what": "review", "t": board.next_review_at, "id": "", "person": true})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	return out


## Missions whose deadline clock runs (Missions.update's rule).
func _clocks(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	var m := s.missions
	for id: String in m.opened_at:
		var def: MissionDef = m.defs.get(id)
		if def != null and def.deadline_days >= 0 and not (m.done_once.has(id) or m.failed_once.has(id)
				or m.deadline_kept.has(id)) and m.status(id) in ["available", "active"]:
			out.append(id)
	return out


# ── The dagstart ────────────────────────────────────────────────────────────

## Call after every action: offers new sides (at most two a week) and
## returns true once when a new in-game day has started (the dagstart).
func update(s: GameSession) -> bool:
	_offer(s)
	var day := SimCalendar.day_of(s.region.net.time)
	if _day < 0:
		_day = day
	if day <= _day:
		return false
	_day = day
	return true


## Whether the dagstart suggests stopping, after this many real minutes of
## play. Only a suggestion: nothing is lost by playing on or stopping.
static func stop_note_due(real_minutes: float) -> bool:
	return real_minutes >= STOP_NOTE_MINUTES


# ── Discoveries ─────────────────────────────────────────────────────────────

## Whether a discovery found now gets a toast: the first of the in-game day
## does; the rest wait for the next terugblik.
func discovery_toast(s: GameSession, id: String) -> bool:
	var day := SimCalendar.day_of(s.region.net.time)
	if day != toast_day:
		toast_day = day
		return true
	if not queued.has(id):
		queued.append(id)
	return false


# ── Side offers ─────────────────────────────────────────────────────────────

## Whether the board holds a mission back until it is offered: authored side
## missions without a clock. A main mission, a side with a deadline (its
## clock runs from when it opens), a built side quest and a routine never wait.
func held_back(m: MissionDef) -> bool:
	return _paced(m) and m.deadline_days < 0 and not offered.has(m.id)


## A side the weekly pacing counts: authored, not a routine (the weekly round is
## on the board every week it is due, and never "Nog open").
static func _paced(m: MissionDef) -> bool:
	return m.kind == "side" and not is_built(m) and not m.is_routine()


## A side quest the rules build (a check-in or a repair), not content.
static func is_built(m: MissionDef) -> bool:
	return BUILT_PREFIXES.any(func(prefix: String) -> bool: return m.id.begins_with(prefix))


## Offer waiting sides, in content order, while this week has room; a side
## with a deadline is offered at once and counts.
func _offer(s: GameSession) -> void:
	var today := SimCalendar.day_of(s.region.net.time)
	var week := _week(today)
	var this_week := offered.values().filter(func(d: int) -> bool: return _week(d) == week).size()
	for m in s.available_missions():
		if not _paced(m) or offered.has(m.id):
			continue
		if m.deadline_days >= 0 or this_week < NEW_SIDES_PER_WEEK:
			offered[m.id] = today
			this_week += 1


## What the board offers as new: main and training missions, built side
## quests, sides with a clock and the sides offered in the last seven days.
func new_offers(s: GameSession) -> Array[MissionDef]:
	var today := SimCalendar.day_of(s.region.net.time)
	return s.available_missions().filter(func(m: MissionDef) -> bool:
		return not held_back(m) and (not _paced(m) or not offered.has(m.id) or today - offered[m.id] < 7))


## Sides offered more than a week ago and still open ("Nog open").
func older_offers(s: GameSession) -> Array[MissionDef]:
	var today := SimCalendar.day_of(s.region.net.time)
	return s.available_missions().filter(func(m: MissionDef) -> bool:
		return _paced(m) and offered.has(m.id) and today - offered[m.id] >= 7)


## The sim's weeks start on Monday (SimCalendar.weekday).
static func _week(day: int) -> int:
	return floori(day / 7.0)


# ── Intussen and the time skip ──────────────────────────────────────────────

## While an experiment runs: {problem, check_at, days (to the Check, whole
## days up), beats (_dates before the Check), people (waiting lines),
## sides (offered side missions that need no Check of their own)}, or
## {error: unknown_problem | not_doing}.
func intussen(s: GameSession, problem_id: String) -> Dictionary:
	var st: ProblemState = s.region.state.get(problem_id)
	if st == null:
		return {"error": "unknown_problem"}
	if st.phase != ProblemState.Phase.DOING:
		return {"error": "not_doing"}
	var now := s.region.net.time
	var beats := _dates(s, now, st.check_at - 1)
	var people: Array[Dictionary] = []
	var waiting := _waiting(s)
	if not waiting.is_empty():
		people.append(waiting)
	var sides := new_offers(s).filter(func(m: MissionDef) -> bool: return m.kind == "side" and m.goal_type != "solve")
	return {"problem": problem_id, "check_at": st.check_at, "days": ceili((st.check_at - now) / float(DAY)),
		"beats": beats, "people": people, "sides": sides}


## The problems whose experiment runs (a Check window is open).
static func running(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for st: ProblemState in s.region.state.values():
		if st.phase == ProblemState.Phase.DOING:
			out.append(st.id)
	return out


## Let the experiment run to its Check, a morning at a time, and stop early
## at a beat with a person: a check-in or repair that opens, or a deadline
## coming within a day (one already that close when the skip starts does not
## stop it again), or a person's check-in talk that comes due (PLAN 1.4b).
## Returns {stopped: "" (the Check is due) | checkin | talk (id: the person) |
## deadline | review, id, days (skipped)}, or {error: unknown_problem |
## not_doing}.
func skip_to_check(s: GameSession, problem_id: String) -> Dictionary:
	var st: ProblemState = s.region.state.get(problem_id)
	if st == null:
		return {"error": "unknown_problem"}
	if st.phase != ProblemState.Phase.DOING:
		return {"error": "not_doing"}
	var from := s.region.net.time
	var near := {}
	for beat in _dates(s, from, from + DAY):
		near[beat["what"] + ":" + beat["id"]] = true
	var built := _built_ids(s)
	var talks := _talk_ids(s)
	while st.phase == ProblemState.Phase.DOING:
		var now := s.region.net.time
		var morning := SimCalendar.days(SimCalendar.day_of(now) + 1) + GameSession.START_MINUTE
		s.pass_time(mini(st.check_at, morning) - now)
		var stop := _stop(s, near, built, talks)
		if not stop.is_empty():
			stop["days"] = _days(s.region.net.time - from)
			return stop
	return {"stopped": "", "id": "", "days": _days(s.region.net.time - from)}


func _stop(s: GameSession, near: Dictionary, built: Array[String], talks: Array[String]) -> Dictionary:
	for id in _built_ids(s):
		if not built.has(id):
			return {"stopped": "checkin", "id": id}
	for id in _talk_ids(s):
		if not talks.has(id):
			return {"stopped": "talk", "id": id}
	var now := s.region.net.time
	for beat in _dates(s, now, now + DAY):
		if beat["person"] and not near.has(beat["what"] + ":" + beat["id"]):
			return {"stopped": beat["what"], "id": beat["id"]}
	return {}


## The people whose check-in talk is due now.
static func _talk_ids(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for p in s.checkin_prompts():
		out.append(p["person"])
	return out


func _built_ids(s: GameSession) -> Array[String]:
	var out: Array[String] = []
	for m in s.available_missions():
		if is_built(m):
			out.append(m.id)
	return out


static func _days(minutes: int) -> int:
	return roundi(minutes / float(DAY))


# ── Saved state ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {"start": start.duplicate(true), "offered": offered.duplicate(), "toast_day": toast_day,
		"queued": queued.duplicate(), "floor_id": floor_id, "carded": carded.duplicate(),
		"has_floor_plan": has_floor_plan, "opening_beat": opening_beat,
		"inbox": inbox.duplicate(true), "concepts_seen": concepts_seen.duplicate(), "announced": announced.duplicate(),
		"rang": rang.duplicate()}


## Restore to_dict() output, untrusted: anything of the wrong shape is
## dropped (a junk snapshot reads as a new game: no terugblik).
func load_dict(d: Dictionary) -> void:
	start = _clean_snapshot(d.get("start"))
	offered.clear()
	var saved := JsonFile.dict_or_empty(d.get("offered"))
	for id: Variant in saved:
		if saved[id] is int:
			offered[str(id)] = saved[id]
	toast_day = d["toast_day"] if d.get("toast_day") is int else -1
	floor_id = d["floor_id"] if d.get("floor_id") is String else ""
	has_floor_plan = d["has_floor_plan"] if d.get("has_floor_plan") is bool else true
	var beat: Variant = d.get("opening_beat")
	opening_beat = beat if beat is String and beat in Opening.BEATS else ""
	queued.clear()
	var ids: Variant = d.get("queued", [])
	for id: Variant in ids if ids is Array else []:
		if id is String:
			queued.append(id)
	carded.clear()
	var days: Variant = d.get("carded", [])
	for id: Variant in days if days is Array else []:
		if id is String:
			carded.append(id)
	phone_saved = d.get("inbox") is Array
	inbox.clear()
	for e: Variant in d["inbox"] if phone_saved else []:
		var entry := _clean_message(e)
		if not entry.is_empty():
			inbox.append(entry)
	concepts_seen.assign(_names(d.get("concepts_seen")))
	announced.assign(_names(d.get("announced")))
	rang.clear()
	var calls := JsonFile.dict_or_empty(d.get("rang"))
	for id: Variant in calls:
		if calls[id] is int or calls[id] is float:   # JSON gives whole numbers back as floats
			rang[str(id)] = int(calls[id])


## The strings of a saved list, untrusted: anything else is dropped.
static func _names(v: Variant) -> Array[String]:
	var out: Array[String] = []
	for id: Variant in v if v is Array else []:
		if id is String:
			out.append(id)
	return out


## A saved inbox message, untrusted: {} unless it has its id, time and read
## flag; a debrief's measured queues kept only as place -> number.
static func _clean_message(e: Variant) -> Dictionary:
	if not (e is Dictionary and e.get("id") is String and (e.get("at") is int or e.get("at") is float) \
			and e.get("read") is bool):
		return {}
	var out := {"id": e["id"], "at": int(e["at"]), "read": e["read"]}
	var queues := JsonFile.dict_or_empty(e.get("queues"))
	var clean := {}
	for place: Variant in queues:
		if queues[place] is int or queues[place] is float:
			clean[str(place)] = queues[place]
	if not clean.is_empty():
		out["queues"] = clean
	return out


static func _clean_snapshot(v: Variant) -> Dictionary:
	if not (v is Dictionary and v.get("t") is int):
		return {}
	var measures := {}
	var saved := JsonFile.dict_or_empty(v.get("measures"))
	for stream: Variant in saved:
		if not saved[stream] is Dictionary:
			continue
		var m := {}
		for id: String in ["completed"] + MEASURES:
			var value: Variant = saved[stream].get(id)
			if value is float or value is int:
				m[id] = float(value)
		if m.size() == MEASURES.size() + 1:
			measures[str(stream)] = m
	var done: Array[String] = []
	var ids: Variant = v.get("completed", [])
	for id: Variant in ids if ids is Array else []:
		if id is String:
			done.append(id)
	return {"t": v["t"], "completed": done, "measures": measures}
