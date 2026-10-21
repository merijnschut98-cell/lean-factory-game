extends SceneTree
## Automated playtester: plays the campaign through GameSession as three
## personas over several seeds and reports what a real player would hit.
##   godot --headless --path game --script res://tools/autoplay.gd -- [out_dir] [seeds] [personas]
## e.g. `-- ../docs/qa 11,12,13 expert,average`. Writes autoplay-report.json and
## autoplay-report.md into out_dir (default ../docs/qa, next to game/).
##
## Personas (Persona):
##   expert    does the training week, takes missions in content order, finds
##             the key clues with the tools that reveal them, writes the right
##             A3 with the best-fitting countermeasure, standardises.
##   average   does the training week, takes missions in a shuffled order,
##             searches the problem's step and its neighbours tool by tool,
##             sometimes names a wrong cause first (with a countermeasure for
##             that wrong cause, so the Check fails and it retries), picks the
##             cheapest fitting countermeasure, standardises half the time.
##   careless  skips the training week, uses random tools and questions (blame
##             included), random A3 choices, never standardises.
##   talker    plays the gemba and the A3 as the expert does, and talks to
##             everyone who has a talk for it (check-ins first), listening
##             first: it answers the person's last words with the move that
##             fits them, steers only once the concern is out, never pressures.
##   never-talks  plays as the expert does and never opens a talk: a fix
##             nobody asked its owner about is compliance (Sustain.BUY_IN ×0.6).
##             Only a talk a mission cannot end without is had: Monday's
##             (ends_with_talk) said hello and closed, logged as forced; a talk
##             a mission needs (talk_to goals) pressed for a yes (_push).
## Every persona has the talk a mission ends with; the others only say hello.
## A talk a mission needs (MissionDef.talk_goals) is had when the objective
## names it, once a day: never-talks and careless press, the others listen.
## A run that ends with the campaign done plays an epilogue: EPILOGUE_DAYS
## more with no new work, the persona's audits only, to see which fixes hold.
## A persona that cannot get anywhere on a problem is helped by the expert's
## next step (logged as "assisted"), so one lost player does not end the
## campaign; a state no persona can leave is a dead end.
##
## It only plays through GameSession's actions; session.region and
## session.missions are read to decide and to measure (and Missions.abandon
## clears a mission nobody can finish: GameSession has no abandon action).

const PERSONAS: Array[String] = ["expert", "average", "careless", "talker", "never-talks"]
## Personas who play the gemba, the A3, the Act and the audits as the expert does.
const EXPERT_PLAY: Array[String] = ["expert", "talker", "never-talks"]
const SEEDS: Array[int] = [11, 12, 13]
const DEFAULT_OUT := "res://../docs/qa"
const SEVERITIES: Array[String] = ["critical", "high", "medium", "low"]
## Findings that explain others come first within a severity (key prefixes).
const ROOTS: Array[String] = ["error:", "dead_end:", "orphan", "refused:", "check_window", "treadmill", "debt_spiral",
	"seed_invariant", "flag:trend_hides_gain"]


func _initialize() -> void:
	quit(_run())


func _run() -> int:
	var args := OS.get_cmdline_user_args()
	if args.size() > 1 and args[0] == "--merge":
		return _merge(args[1], args.slice(2))
	var out_dir := ProjectSettings.globalize_path(args[0] if args.size() > 0 else DEFAULT_OUT).simplify_path()
	var seeds: Array[int] = SEEDS
	if args.size() > 1:
		seeds = []
		for part in args[1].split(",", false):
			seeds.append(int(part))
	var personas: Array[String] = PERSONAS.duplicate()
	if args.size() > 2:
		personas.assign(Array(args[2].split(",", false)).filter(func(p: String) -> bool: return p in PERSONAS))
	var runs: Array[Dictionary] = []
	for persona in personas:
		for seed_value in seeds:
			var started := Time.get_ticks_msec()
			var run := Persona.new(persona, seed_value).play()
			run["wall_seconds"] = (Time.get_ticks_msec() - started) / 1000.0
			printerr("played %s seed %d: %s after %.0f days, %d missions (%.1f s)" % [
				persona, seed_value, run["end"], run["days"], run["completed"], run["wall_seconds"]])
			runs.append(run)
	return _report(out_dir, runs)


## `-- --merge <out_dir> <a.json> <b.json> …`: one report from the runs of
## earlier reports (persona-seeds played in parallel processes).
func _merge(out: String, paths: Array) -> int:
	var runs: Array[Dictionary] = []
	for path: String in paths:
		var f := FileAccess.open(path, FileAccess.READ)
		var data: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		if not (data is Dictionary and data.get("runs") is Array):
			printerr("cannot read runs from ", path)
			return 1
		for run: Dictionary in data["runs"]:
			run["seed"] = int(run["seed"])
			runs.append(run)
	runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return [PERSONAS.find(a["persona"]), a["seed"]] < [PERSONAS.find(b["persona"]), b["seed"]])
	return _report(ProjectSettings.globalize_path(out).simplify_path(), runs)


func _report(out_dir: String, runs: Array[Dictionary]) -> int:
	var seeds: Array[int] = []
	var personas: Array[String] = []
	for run in runs:
		if not int(run["seed"]) in seeds:
			seeds.append(int(run["seed"]))
		if not run["persona"] in personas:
			personas.append(run["persona"])
	var catalog := Catalog.load_from()
	var findings := PlayReport.findings(runs, catalog)
	var report := {"generated": Time.get_datetime_string_from_system(true), "seeds": seeds, "personas": personas,
		"findings": findings, "runs": runs}
	if DirAccess.make_dir_recursive_absolute(out_dir) != OK:
		printerr("cannot create ", out_dir)
		return 1
	var ok := _write(out_dir.path_join("autoplay-report.json"), JSON.stringify(report))
	ok = _write(out_dir.path_join("autoplay-report.md"), PlayReport.markdown(report, catalog)) and ok
	return 0 if ok else 1


func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("cannot write ", path, ": ", error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	printerr("wrote ", path)
	return true


# ── One persona playing one seed ───────────────────────────────────────────

## Engine errors (a null access in the rules) do not stop GDScript; the
## playtester collects them and blames the action that was running.
class ErrorCatcher extends Logger:
	var errors: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		errors.append("%s (%s:%d in %s)" % [rationale if not rationale.is_empty() else code, file.get_file(), line, function])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var out := errors.duplicate()
		errors.clear()
		_mutex.unlock()
		return out


class Persona extends RefCounted:
	const P := ProblemState.Phase
	## The horizon: three years of play.
	const MAX_PLAY_DAYS := 1095.0
	const MAX_ACTIONS := 4000
	## Failed Checks on one problem before the run calls it a dead end.
	const MAX_ATTEMPTS := 8
	## Gemba actions on one problem before a lost persona gets the expert's help.
	const MAX_SEARCH := 30
	## The same place and tool finding nothing new this often: it never will.
	const BARREN_USES := 2
	## Careless reads the mismatch note after this many failed Checks (a
	## fitting countermeasure), and follows the coach after CARELESS_LISTENS_AFTER
	## (the best one).
	const CARELESS_LEARNS_AFTER := 3
	const CARELESS_LISTENS_AFTER := 5
	## A KPI moved "the wrong way" beyond this relative change (14-day windows are noisy).
	const NOISE := 0.05
	const AVERAGE_TOOLS: Array[String] = ["shadow", "documents", "data", "conversation", "time_study", "listen_in",
		"queue_count", "material_check"]
	const OBSERVE_TOOLS: Array[String] = ["documents", "time_study", "shadow", "data", "conversation", "queue_count"]
	const SAMPLE_DAYS := 7.0
	## The talker's limits: a persuasion is tried this often in all (it wants a
	## commitment), a check-in this often while it is open, each at most once a day.
	const TALK_TRIES := 3
	const CHECKIN_TRIES := 6
	const MAX_MOVES := 40
	## Who presses for a yes when a mission needs a talk (_have_needed_talk), and how
	## often before it listens instead.
	const PUSHERS: Array[String] = ["never-talks", "careless"]
	const PUSH_TRIES := 5
	## A needed talk not won in this many talks is a dead end (a talk nobody can win).
	const NEEDED_TRIES := 20
	## Everyone's morale is recorded once this day is reached (record morale_day_100).
	const MORALE_CHECK_DAY := 100.0
	## The listening move for a person's last words (Dialog.ANSWERS), in order.
	const ANSWER := {"feeling": "reflect", "admission": "empathy", "hesitation": "silence", "claim": "paraphrase",
		"doubt": "experience"}
	const FALLBACK_LISTEN: Array[String] = ["open_question", "inquiry", "empathy", "paraphrase", "mood"]
	## After the campaign: days with no new work, to see which fixes hold.
	const EPILOGUE_DAYS := 182
	const EPILOGUE_STEP_DAYS := 7.0

	var persona: String
	## How it plays the gemba, the A3, the Act and the audits (EXPERT_PLAY).
	var style: String
	var seed_value: int
	## Stop once this many main missions are completed; -1: play the campaign out.
	var stop_after_main := -1
	var s: GameSession
	var record: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	var _runs: Dictionary = {}  # mission id → its open run record
	var _search: Dictionary = {}  # problem id → {actions, plan, next, barren: {pair: n}, dead: {pair: true}, assisted}
	var _tried: Dictionary = {}  # problem id → countermeasure ids tried
	var _ruled_out: Dictionary = {}  # problem id → countermeasure ids the A3 refused (a repair needs another)
	var _coached: Dictionary = {}  # "mission|stage" → true
	var _refused: Dictionary = {}  # "mission|code" → true
	var _given_up: Dictionary = {}  # mission ids nobody can finish
	var _catcher := ErrorCatcher.new()
	var _doing := "new_game"  # the action running, to blame engine errors on
	var _audits: Array[String] = []
	var _sustain_tries: Dictionary = {}  # check-in mission id → audits done for it
	var _actions := 0
	var _last_sample := -INF
	var _talk_tries: Dictionary = {}  # dialog id → talks the talker opened
	var _talk_day: Dictionary = {}  # dialog id → the day (int) of its last talk
	var _ever_resolved: Dictionary = {}  # problem id → true, every problem a solve mission fixed

	func _init(persona_name: String, seed_number: int, stop_after_main_missions: int = -1) -> void:
		persona = persona_name
		style = "expert" if persona_name in EXPERT_PLAY else persona_name
		seed_value = seed_number
		stop_after_main = stop_after_main_missions
		rng.seed = hash("%s:%d" % [persona_name, seed_number])

	## Play until the campaign ends, gets stuck or hits the horizon.
	func play() -> Dictionary:
		record = {"persona": persona, "seed": seed_value, "end": "", "days": 0.0, "completed": 0, "xp": 0,
			"budget": 0, "belt": "", "maturity": 0, "missions": [], "checks": [], "curve": [], "dead_ends": [],
			"assisted": [], "refusals": [], "coach": [], "bad_periods": [], "belts": [], "failed": [],
			"reopened": [], "kpi_reviews": [], "standardise_refused": [], "slipping": [], "audits": [], "errors": [], "actions": 0,
			"talks": [], "ends_with_talk": [], "recurred": [], "left": [], "discoveries": [], "people": {}, "fixes": [],
			"min_budget": 0, "epilogue": {}}
		OS.add_logger(_catcher)
		s = GameSession.new_game(seed_value, Catalog.DATA_DIR, style != "careless")
		if not s.error.is_empty():
			_dead_end("content_error", "", s.error)
			record["end"] = "content_error"
			return record
		while (record["end"] as String).is_empty():
			_step()
			_blame_errors()
		_finish()
		if record["end"] == "campaign_done":
			_epilogue()
			_blame_errors()
		OS.remove_logger(_catcher)
		return record

	## Engine errors since the last step, with the action that raised them
	## (each message once).
	func _blame_errors() -> void:
		for message in _catcher.take():
			if not (record["errors"] as Array).any(func(e: Dictionary) -> bool: return e["message"] == message):
				record["errors"].append({"message": message, "action": _doing, "day": snappedf(day(), 0.1)})

	func day() -> float:
		return (s.region.net.time - SimCalendar.days(GameSession.WARMUP_DAYS)) / float(SimCalendar.MINUTES_PER_DAY)

	# ── The loop ────────────────────────────────────────────────────────────

	func _step() -> void:
		_note_events()
		_sample()
		if day() > MAX_PLAY_DAYS:
			_end("horizon")
			return
		if _actions >= MAX_ACTIONS:
			_end("action_cap")
			return
		if stop_after_main >= 0 and _completed_main() >= stop_after_main:
			_end("stop_after")
			return
		if s.missions.defs.keys().all(func(id: String) -> bool:
				return s.missions.done_once.has(id) or s.missions.status(id) == "failed" or _given_up.has(id)):
			_end("campaign_done")
			return
		if _audit():
			_actions += 1
			return
		_take_missions()
		for m in s.active_missions():
			if not _runs.has(m.id):
				_open_run(m)  # handed out by the coach (the training week)
		if persona == "talker" and _talk_round():
			_actions += 1
			return
		var actives := s.active_missions().filter(func(m: MissionDef) -> bool: return not _given_up.has(m.id))
		if actives.is_empty():
			_nothing_active()
			return
		for m: MissionDef in actives:
			if _act_on(m):
				_actions += 1
				return
		_wait(actives)

	func _end(reason: String) -> void:
		record["end"] = reason

	func _finish() -> void:
		_note_events()
		_last_sample = -INF
		_sample()
		for id: String in _runs:
			_runs[id]["outcome"] = "unfinished"
		record["days"] = snappedf(day(), 0.01)
		record["xp"] = s.xp()
		record["budget"] = s.budget()
		record["belt"] = s.belt()
		record["maturity"] = s.region.maturity()
		record["actions"] = _actions
		var covered := s.active_missions().map(func(m: MissionDef) -> String: return m.goal_problem)
		record["orphans"] = []
		for id: String in s.region.state:
			if s.region.state[id].is_open() and not id in covered:
				var why := s.missions.defs.values().filter(func(m: MissionDef) -> bool: return m.goal_problem == id) \
					.map(func(m: MissionDef) -> String: return "%s %s" % [m.id, s.missions.status(m.id)])
				record["orphans"].append({"problem": id, "phase": s.phase_of(id), "missions": why})
		record["completed"] = (record["missions"] as Array).filter(
			func(r: Dictionary) -> bool: return r["outcome"] == "completed").size()
		record["min_budget"] = (record["curve"] as Array).reduce(
			func(low: int, c: Dictionary) -> int: return mini(low, c["budget"]), s.budget())
		record["discoveries"] = s.discoveries.found.keys()
		record["people"] = _people_now()
		record["fixes"] = _fixes_now()

	## Every person's trust and morale, at the start and now: {id: {trust,
	## morale, trust_start, morale_start, left, talks}}.
	func _people_now() -> Dictionary:
		var out := {}
		for p: PersonDef in s.people.persons.values():
			out[p.id] = {"trust": s.people.trust[p.id], "morale": s.people.morale[p.id], "trust_start": p.trust,
				"morale_start": p.morale, "left": s.people.has_left(p.id),
				"talks": (record["talks"] as Array).filter(func(t: Dictionary) -> bool: return t["person"] == p.id).size()}
		return out

	## Every problem a solve mission fixed: [{problem, phase, held (resolved
	## now), recurred (times), buy_in, standardised, life_days, health}].
	func _fixes_now() -> Array:
		var out := []
		for id: String in _ever_resolved:
			var st: ProblemState = s.region.state[id]
			var resolved := st.phase == P.RESOLVED
			out.append({"problem": id, "phase": s.phase_of(id), "held": resolved,
				"recurred": (record["recurred"] as Array).filter(func(r: Dictionary) -> bool: return r["problem"] == id).size(),
				"buy_in": st.buy_in if resolved else "", "standardised": resolved and st.standardised,
				"life_days": snappedf(s.region.life_days(id), 0.1), "health": snappedf(s.region.health(id), 0.01)})
		return out

	## After the campaign: time passes with no new work; the persona audits
	## where it would. What wears, recurs and reopens shows which fixes hold.
	func _epilogue() -> void:
		var start := day()
		var counts := func(key: String) -> int:
			return (record[key] as Array).filter(func(e: Dictionary) -> bool: return e["day"] > start).size()
		_doing = "epilogue"
		while day() - start < EPILOGUE_DAYS:
			s.wait_days(EPILOGUE_STEP_DAYS)
			_note_events()
			while _audit():
				pass
		record["epilogue"] = {"days": snappedf(day() - start, 0.1), "slipping": counts.call("slipping"),
			"recurred": counts.call("recurred"), "reopened": counts.call("reopened"), "audits": counts.call("audits"),
			"left": counts.call("left"), "budget": s.budget(), "people": _people_now(), "fixes": _fixes_now()}

	func _completed_main() -> int:
		return (record["missions"] as Array).filter(func(r: Dictionary) -> bool:
			return r["kind"] == "main" and r["outcome"] == "completed").size()

	## Nothing active: the campaign is over, or something keeps the player out.
	func _nothing_active() -> void:
		var open := _open_missions()
		if not open.is_empty():
			var codes := []
			for m: MissionDef in open:
				var code := s.accept(m.id)
				if code.is_empty():
					_open_run(m)
					return
				codes.append("%s: %s" % [m.id, code])
			_dead_end("accept_refused", "", "available but refused: %s" % ", ".join(codes))
			_end("stuck")
			return
		var gated := []
		var blocked := []
		for m: MissionDef in s.missions.defs.values():
			if s.missions.status(m.id) != "locked":
				continue
			var needs_done := Array(m.requires_missions).filter(func(id: String) -> bool:
				return not s.missions.done_once.has(id))
			if needs_done.is_empty():
				gated.append("%s needs %s (%d XP), has %d XP" % [m.id, Progression.BELTS[m.requires_belt]["id"],
					Progression.BELTS[m.requires_belt]["xp"], s.xp()])
			elif needs_done.any(func(id: String) -> bool: return s.missions.status(id) == "failed"):
				blocked.append("%s behind failed %s" % [m.id, needs_done])
		if not gated.is_empty():
			_dead_end("belt_gate", "", "; ".join(gated))
			_end("stuck")
		elif not blocked.is_empty():
			_dead_end("locked_behind_failed", "", "; ".join(blocked))
			_end("stuck")
		else:
			_end("campaign_done")

	## Every active mission waits for its Check: wait for the first one due.
	func _wait(actives: Array) -> void:
		var due := -1
		var problem := ""
		for m: MissionDef in actives:
			var st: ProblemState = s.region.state.get(m.goal_problem)
			if st != null and st.phase == P.DOING and (due < 0 or st.check_at < due):
				due = st.check_at
				problem = m.goal_problem
		if not problem.is_empty():
			s.wait_for_check(problem)
			return
		if actives.any(func(m: MissionDef) -> bool: return not s.missions.pending_talk(m).is_empty()):
			s.wait_days(1.0)  # a needed talk tomorrow (once a day, or after a ruined one)
			return
		for m: MissionDef in actives:
			_dead_end("no_action", m.id, "active, nothing to do and nothing to wait for (phase %s)" % _phase(m))
			_give_up(m)

	# ── Missions ────────────────────────────────────────────────────────────

	## The board, without the missions this run gave up on.
	func _open_missions() -> Array:
		return s.available_missions().filter(func(m: MissionDef) -> bool: return not _given_up.has(m.id))

	func _take_missions() -> void:
		var open := _open_missions()
		if style != "expert":
			_shuffle(open)
		for m: MissionDef in open:
			if m.kind == "main" and s.missions.active("main").is_empty():
				_accept(m)
			elif m.kind == "side" and s.missions.active("side").size() < _side_slots():
				_accept(m)

	func _side_slots() -> int:
		return 2 if style == "average" else Missions.MAX_SIDE

	func _accept(m: MissionDef) -> void:
		var code := s.accept(m.id)
		if code.is_empty():
			_open_run(m)
			return
		var key := "%s|%s" % [m.id, code]
		if not _refused.has(key):
			_refused[key] = true
			record["refusals"].append({"action": "accept", "mission": m.id, "code": code, "day": snappedf(day(), 0.1)})

	func _open_run(m: MissionDef) -> void:
		var reopened := (record["missions"] as Array).filter(func(r: Dictionary) -> bool: return r["id"] == m.id).size()
		var run := {"id": m.id, "kind": m.kind, "goal": m.goal_type, "problem": m.goal_problem,
			"accepted_day": snappedf(day(), 0.01), "completed_day": -1.0, "days": -1.0, "outcome": "active",
			"run": reopened + 1, "actions": 0, "gemba_hours": 0.0, "checks": 0, "failed_checks": 0,
			"a3_refusals": [], "score": {}, "standardise_asked": false, "standardised": false, "cm_spent": 0,
			"xp_at_accept": s.xp(), "budget_at_accept": s.budget(), "reward_xp": m.reward_xp,
			"reward_budget": m.reward_budget, "problem_xp": 0, "problem_budget": 0, "deadline_days": m.deadline_days,
			"wait_step": _at_wait(m.goal_problem)}
		_runs[m.id] = run
		record["missions"].append(run)
		_search.erase(m.goal_problem)
		_tried.erase(m.goal_problem)

	## The problem shows at a step without a team (a wait or a material step).
	func _at_wait(problem_id: String) -> bool:
		var p: ProblemDef = s.region.problems.get(problem_id)
		return p != null and s.region.net.step_at(p.step).kind != SimStep.Kind.WORK

	func _close_run(id: String, outcome: String) -> void:
		var run: Dictionary = _runs.get(id, {})
		if run.is_empty():
			return
		run["outcome"] = outcome
		run["completed_day"] = snappedf(day(), 0.01)
		run["days"] = snappedf(day() - run["accepted_day"], 0.01)
		run["xp_gain"] = s.xp() - run["xp_at_accept"]
		run["budget_change"] = s.budget() - run["budget_at_accept"]
		_runs.erase(id)

	## Nobody can finish it: clear it so the rest of the campaign can be played.
	func _give_up(m: MissionDef) -> void:
		_given_up[m.id] = true
		s.missions.abandon(m.id)
		_close_run(m.id, "given_up")

	func _note_events() -> void:
		for e in s.drain_events():
			var d := snappedf(day(), 0.1)
			match e["type"]:
				"completed":
					_close_run(e["mission"], "completed")
					_sustain_tries.erase(e["mission"])
					_sample(true)
					_note_closing_talk(e["mission"], d)
				"recurred":
					record["recurred"].append({"problem": e["problem"], "day": d})
				"left":
					record["left"].append({"person": e["person"], "day": d})
				"failed":
					var failed_def: MissionDef = s.missions.defs[e["mission"]]
					record["failed"].append({"mission": e["mission"], "day": d, "closes": Array(failed_def.fail_closes),
						"taken": _runs.has(e["mission"]), "phase": s.phase_of(failed_def.goal_problem)})
					_close_run(e["mission"], "failed")
				"reopened":
					record["reopened"].append({"mission": e["mission"], "day": d})
				"belt":
					record["belts"].append({"belt": Progression.BELTS[e["belt"]]["id"], "day": d, "xp": s.xp()})
				"bad_period":
					if e["started"]:
						record["bad_periods"].append({"start": d, "end": -1.0, "budget": s.budget()})
					elif not (record["bad_periods"] as Array).is_empty():
						record["bad_periods"].back()["end"] = d
				"kpi_review":
					record["kpi_reviews"].append(d)
				"slipping":
					record["slipping"].append({"problem": e["problem"], "day": d})
					if style == "expert" or (style == "average" and rng.randf() < 0.5):
						_audits.append(s.region.problems[e["problem"]].step)

	## A mission that ends with a talk completed: whether the talk was had by
	## then (a talker may have had it before its goal was met, unasked).
	func _note_closing_talk(mission_id: String, d: float) -> void:
		var m: MissionDef = s.missions.defs.get(mission_id)
		if m == null or m.ends_with_talk.is_empty():
			return
		var entries := (record["ends_with_talk"] as Array).filter(func(x: Dictionary) -> bool: return x["mission"] == mission_id)
		var entry: Dictionary = entries.back() if not entries.is_empty() else {}
		if entry.is_empty():
			entry = {"mission": mission_id, "dialog": m.ends_with_talk, "day": -1.0, "held_open": false,
				"outcome": s.talk_outcome(m.ends_with_talk)}
			record["ends_with_talk"].append(entry)
		entry["completed_after_talk"] = s.talked(m.ends_with_talk)
		entry["completed_day"] = d

	func _sample(force: bool = false) -> void:
		if not force and day() - _last_sample < SAMPLE_DAYS:
			return
		_last_sample = day()
		if day() >= MORALE_CHECK_DAY and not record.has("morale_day_100"):
			record["morale_day_100"] = s.people.morale.duplicate()  # QA 2.12 (b): someone under 40 by day 100?
		var point := {"day": snappedf(day(), 0.1), "xp": s.xp(), "budget": s.budget(), "belt": s.belt()}
		if s.has_method("drift"):
			point["drift"] = snappedf(s.call("drift")["level"], 0.001)
		record["curve"].append(point)

	## The leader routine, where the rules have it (GameSession.audit): a fix
	## that is slipping gets its standard checked at its place.
	func _audit() -> bool:
		if _audits.is_empty() or not s.has_method("audit"):
			return false
		var place: String = _audits.pop_front()
		_doing = "audit at " + place
		var result: Dictionary = s.call("audit", place)
		record["audits"].append({"place": place, "day": snappedf(day(), 0.1), "result": result})
		return true

	func _dead_end(kind: String, mission: String, detail: String) -> void:
		record["dead_ends"].append({"kind": kind, "mission": mission, "detail": detail,
			"day": snappedf(day(), 0.1) if s != null and s.region != null else 0.0})

	func _phase(m: MissionDef) -> String:
		return s.phase_of(m.goal_problem) if not m.goal_problem.is_empty() else "-"

	# ── Acting on one mission ───────────────────────────────────────────────

	## One action on the mission; false when it can only wait.
	func _act_on(m: MissionDef) -> bool:
		_coach(m)
		var needed := s.missions.pending_talk(m)
		if not needed.is_empty() and Objective.step(m, s).get("step") == "talk" and _talk_day.get(needed, -1) != floori(day()):
			return _have_needed_talk(m, s.people.dialogs[needed])
		if not m.ends_with_talk.is_empty() and not s.talked(m.ends_with_talk) \
				and (persona == "talker" or _goal_met_but_talk(m)):
			return _have_talk(m)
		match m.goal_type:
			"observe":
				return _observe(m)
			"walk":
				return _walk(m)
			"investigate":
				return _investigate_goal(m)
			"solve", "check", "rework_fix":
				return _solve(m)  # a repair quest's accept took the fix back to the A3
			"sustain":
				return _sustain(m)
		_dead_end("unknown_goal", m.id, m.goal_type)
		_give_up(m)
		return true

	## Whether the mission's own goal is met and only its closing talk is left
	## (Missions reads the talk through its `talked` Callable).
	func _goal_met_but_talk(m: MissionDef) -> bool:
		var talked := s.missions.talked
		s.missions.talked = func(_dialog_id: String) -> bool: return true
		var met: bool = s.missions.call("_goal_met", m)
		s.missions.talked = talked
		return met

	## The mission ends with a talk: have it (the talker as it talks, the
	## others say hello and go), and note whether the mission waited for it.
	func _have_talk(m: MissionDef) -> bool:
		var d: DialogDef = s.people.dialogs[m.ends_with_talk]
		var entry := {"mission": m.id, "dialog": d.id, "day": snappedf(day(), 0.1), "held_open": _goal_met_but_talk(m),
			"completed_after_talk": false, "completed_day": -1.0, "outcome": ""}
		record["ends_with_talk"].append(entry)
		var outcome := _converse(d, persona != "talker")
		if outcome.begins_with("error:"):
			_dead_end("talk_unavailable", m.id, "%s: %s" % [d.id, outcome])
			_give_up(m)
		entry["outcome"] = outcome
		return true

	## A talk the mission needs (MissionDef.talk_goals), when the objective names it: the
	## pushers (never-talks, careless) press for a yes, the others listen first. A pusher
	## that got nowhere PUSH_TRIES times listens instead (logged as assisted).
	func _have_needed_talk(m: MissionDef, d: DialogDef) -> bool:
		if s.people.cooling_down(d.person, s.region.net.time):
			_talk_day[d.id] = floori(day())  # after a ruined talk: tomorrow morning
			return true
		var tries := (record["talks"] as Array).filter(func(t: Dictionary) -> bool: return t["dialog"] == d.id)
		if tries.size() >= NEEDED_TRIES:
			_dead_end("talk_never_won", m.id, "%s: %d talks, still %s" % [d.id, tries.size(), s.talk_outcome(d.id)])
			_give_up(m)
			return true
		var pushes := tries.filter(func(t: Dictionary) -> bool: return t.get("pushed", false)).size()
		if persona in PUSHERS and pushes < PUSH_TRIES:
			_push(d)
		else:
			if persona in PUSHERS:
				record["assisted"].append({"mission": m.id, "problem": m.goal_problem, "day": snappedf(day(), 0.1),
					"why": "talk %s: pushed %d times" % [d.id, pushes]})
			_converse(d)
		return true

	## Press for a yes, as a player who does not listen: a hello, a proposal on the table,
	## pressure, the ask (Dialog: compliance while openness holds). Returns the outcome.
	func _push(d: DialogDef) -> String:
		_doing = "push " + d.id
		_talk_tries[d.id] = int(_talk_tries.get(d.id, 0)) + 1
		_talk_day[d.id] = floori(day())
		var opened := s.start_dialog(d.person)
		if opened.get("dialog") != d.id:
			if not opened.has("error"):
				s.end_dialog()
			return "error:" + str(opened.get("error", opened.get("dialog")))
		var proposals: Array = s.dialog_moves().filter(func(mv: Dictionary) -> bool: return mv["id"] == "propose")[0]["picks"]
		var made: Array[String] = []
		var result := {}
		for move: Array in [["mood", ""], ["propose", proposals[0]["id"] if not proposals.is_empty() else ""], ["pressure", ""],
				["ask_commitment", ""]]:
			result = s.choose_move(move[0], move[1])
			if result.has("error"):
				break
			made.append(move[0])
			if result["ended"]:
				break
		if not result.get("ended", false):
			result = s.end_dialog()
		var summary: Dictionary = result.get("summary", {})
		var outcome := str(summary.get("outcome", result.get("outcome", "")))
		record["talks"].append({"dialog": d.id, "person": d.person, "kind": d.kind, "mission": d.mission,
			"day": snappedf(day(), 0.1), "outcome": outcome, "moves": made, "forced": false, "pushed": true,
			"trust": summary.get("trust", -1), "morale": summary.get("morale", -1)})
		return outcome

	# ── Talks ───────────────────────────────────────────────────────────────

	## The talker has the talk it can now: an open check-in prompt first, then
	## any check-in, the main mission's talk, then the others. False when there
	## is none it has not tried enough (or today already).
	func _talk_round() -> bool:
		var best: DialogDef = null
		var best_rank := 99
		var today := floori(day())
		for p: PersonDef in s.people.persons.values():
			if s.people.has_left(p.id) or s.people.cooling_down(p.id, s.region.net.time):
				continue
			var d := s.people.dialog_for(p.id, s.call("_world", p))
			if d == null or _talk_day.get(d.id, -1) == today \
					or int(_talk_tries.get(d.id, 0)) >= (CHECKIN_TRIES if d.kind == "checkin" else TALK_TRIES):
				continue
			var rank := 3
			if d.kind == "checkin":
				rank = 0 if s.people.prompts.has(d.id) else 1
			elif s.missions.active("main").any(func(m: MissionDef) -> bool: return m.id == d.mission):
				rank = 2
			if rank < best_rank:
				best = d
				best_rank = rank
		if best == null:
			return false
		_converse(best)
		return true

	## Have a talk with `d`'s person: listening first (_talker_move), or, when
	## `hello`, open and close at once. Returns the outcome, or "error:<code>".
	func _converse(d: DialogDef, hello: bool = false) -> String:
		_doing = "talk " + d.id
		_talk_tries[d.id] = int(_talk_tries.get(d.id, 0)) + 1
		_talk_day[d.id] = floori(day())
		var opened := s.start_dialog(d.person)
		if opened.get("dialog") != d.id:
			if not opened.has("error"):
				s.end_dialog()
			return "error:" + str(opened.get("error", opened.get("dialog")))
		var tags: Array = opened["position"].get("tags", [])
		var talk := {"proposed": false, "shown_data": false, "co": "", "last": "", "uses": {}, "result": {}}
		var made: Array[String] = []
		var result := {}
		while not hello and made.size() < MAX_MOVES:
			var pick := _from_offers(_talker_move(d, tags, talk), tags, talk)
			result = s.choose_move(pick[0], pick[1])
			if result.has("error"):
				record["refusals"].append({"action": "talk:" + pick[0], "mission": d.mission, "code": result["error"],
					"day": snappedf(day(), 0.1)})
				break
			made.append(pick[0])
			talk["last"] = pick[0]
			talk["uses"][pick[0]] = int(talk["uses"].get(pick[0], 0)) + 1
			talk["result"] = result
			if pick[0] in ["propose", "propose_experiment"]:
				talk["proposed"] = true
			elif pick[0] == "ask_commitment":
				talk["proposed"] = false  # refused: listen on, then put it on the table again
			talk["shown_data"] = talk["shown_data"] or pick[0] == "show_data"
			if not (result["co_proposal"] as Dictionary).is_empty():
				talk["co"] = result["co_proposal"]["id"]
			if result["ended"]:
				break
			tags = result["tags"]
		if not result.get("ended", false):
			result = s.end_dialog()
		var summary: Dictionary = result.get("summary", {})
		var outcome := str(summary.get("outcome", result.get("outcome", "")))
		record["talks"].append({"dialog": d.id, "person": d.person, "kind": d.kind, "mission": d.mission,
			"day": snappedf(day(), 0.1), "outcome": outcome, "moves": made, "forced": hello,
			"trust": summary.get("trust", -1), "morale": summary.get("morale", -1)})
		return outcome

	## The talker's next move: [move, pick]. A check-in listens until the
	## concern is out and the person is open, then closes (lifted). A
	## persuasion listens, shows its data once when heard, and puts a proposal
	## that answers the concern on the table only once the concern is out and
	## the meter reads commitment (or patience runs low), then asks.
	func _talker_move(d: DialogDef, tags: Array, talk: Dictionary) -> Array:
		var last: Dictionary = talk["result"]
		var openness: int = s.dialog_meter()["openness"]
		var concern := s.dialog_layers().any(func(l: Dictionary) -> bool: return l["id"] == "concern" and l["heard"])
		var patience_low: bool = last.get("patience_low", false)
		if d.kind == "checkin":
			if (concern and openness >= Dialog.LIFTED_AT) or patience_low:
				return ["close", ""]
			return [_listen_move(tags, talk), ""]
		if talk["proposed"]:
			return ["ask_commitment", ""]
		if (concern and openness >= Dialog.COMMIT_AT) or patience_low:
			var proposal := _proposal(d, talk["co"], concern)
			if not proposal.is_empty():
				return proposal
			return ["close", ""] if patience_low else [_listen_move(tags, talk), ""]  # no proposal offered yet: listen on
		if last.get("heard", false) and not talk["shown_data"] and openness >= Dialog.SHOW_DATA["at"]:
			var data := Array(d.data).filter(func(id: String) -> bool: return s.region.found.has(id))
			if not data.is_empty():
				return ["show_data", data[0]]
		return [_listen_move(tags, talk), ""]

	## The listening move that answers the person's last words, never the same
	## move twice in a row and never a worn one (the first move asks the mood).
	func _listen_move(tags: Array, talk: Dictionary) -> String:
		return _listen_order(tags, talk)[0]

	## The listening moves in the order the talker would make them now.
	func _listen_order(tags: Array, talk: Dictionary) -> Array[String]:
		var uses: Dictionary = talk["uses"]
		var order: Array[String] = []
		if uses.is_empty():
			order.append("mood")
		for tag: String in tags:
			if ANSWER.has(tag):
				order.append(ANSWER[tag])
		order.append_array(FALLBACK_LISTEN)
		var fresh := order.filter(func(move: String) -> bool:
			return move != talk["last"] and int(uses.get(move, 0)) < Dialog.USE_DECAY.size())
		var out: Array[String] = []
		out.assign(fresh)
		out.append("silence" if talk["last"] != "silence" else "empathy")
		return out

	## The talker says only what the turn offers (PLAN 2.13 B, four sentences):
	## its own move when offered (a proposal with another offered pick), else
	## the first offered listening move in the order it would listen, else the
	## first offer that is no pressure or blame. Closing is always there (Esc).
	func _from_offers(want: Array, tags: Array, talk: Dictionary) -> Array:
		var offers := s.dialog_offers()
		if want[0] == "close" or offers.is_empty():
			return ["close", ""]
		for o: Dictionary in offers:
			if o["move"] == want[0] and (o["pick"] == want[1] or want[0] in ["propose", "propose_experiment"]):
				return [o["move"], o["pick"]]
		for move: String in _listen_order(tags, talk):
			for o: Dictionary in offers:
				if o["move"] == move:
					return [move, ""]
		for o: Dictionary in offers:
			if not o["move"] in ["pressure", "confront"]:
				return [o["move"], o["pick"]]
		return [offers[0]["move"], offers[0]["pick"]]

	## The proposal to put on the table, among this turn's offers: the person's
	## own idea, else one that answers the concern (a hidden one it unlocked
	## first), else the first offered; [] when there is none.
	func _proposal(d: DialogDef, co: String, concern: bool) -> Array:
		var offered := {}
		for o: Dictionary in s.dialog_offers():
			if o["move"] in ["propose", "propose_experiment"]:
				offered[o["pick"]] = o["move"]
		if offered.has(co):
			return [offered[co], co]
		var first: Array = []
		for id: String in offered:
			if first.is_empty():
				first = [offered[id], id]
			if concern and "concern" in d.item(id).get("addresses", []):
				return [offered[id], id]
		return first

	func _observe(m: MissionDef) -> bool:
		var seen: Dictionary = s.missions.progress[m.id]["seen"]
		for place in m.goal_places:
			if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
				return _use(m, place, _observe_tools(m, place)[0])
		for place in m.goal_places:
			for tool in _observe_tools(m, place):
				if not seen.has(place + "|" + tool):
					return _use(m, place, tool)
		_dead_end("observe_exhausted", m.id, "every place and tool used, goal not met")
		_give_up(m)
		return true

	## The goal's tool, or the usual ones the place's menu offers now.
	func _observe_tools(m: MissionDef, place: String) -> Array[String]:
		if not m.goal_tool.is_empty():
			return [m.goal_tool]
		var offered := _offered(place)
		var tools: Array[String] = OBSERVE_TOOLS.filter(func(t: String) -> bool: return t in offered)
		return tools if not tools.is_empty() else offered

	## What the place menu offers (PLAN 2.12): the known tools that fit, and
	## "conversation" where someone can be asked.
	func _offered(place: String) -> Array[String]:
		var out := s.place_tools(place)
		if not s.place_questions(place).is_empty() or not s.gemba.has_place(place):
			out.append("conversation")
		return out

	## A check-in (a standardised fix slipping): audit its place, where the
	## rules have the audit; twice without effect is a dead end.
	func _sustain(m: MissionDef) -> bool:
		var tries: int = _sustain_tries.get(m.id, 0)
		if not s.has_method("audit") or tries >= 2:
			_dead_end("sustain_stuck", m.id, "no audit in GameSession" if tries == 0 else "audited twice, check-in not done")
			_give_up(m)
			return true
		_sustain_tries[m.id] = tries + 1
		_audits.append(s.region.problems[m.goal_problem].step)
		var run: Dictionary = _runs.get(m.id, {})
		if not run.is_empty():
			run["actions"] += 1
		return _audit()

	func _walk(m: MissionDef) -> bool:
		for step in s.region.net.stream(m.goal_stream).steps:
			var place := m.goal_stream + "." + step.id
			if step.kind == SimStep.Kind.WORK and not s.region.observed.has(place):
				var offered := _offered(place)
				return _use(m, place, "shadow" if "shadow" in offered or offered.is_empty() else offered[0])
		_dead_end("walk_exhausted", m.id, "every work step walked, goal not met")
		_give_up(m)
		return true

	func _investigate_goal(m: MissionDef) -> bool:
		var p: ProblemDef = s.region.problems[m.goal_problem]
		if _investigate(m, p):
			return true
		_dead_end("investigate_stuck", m.id, "%d of %d key clues found, nothing left to try" % [
			s.region.key_clues_found(p.id), m.goal_clues])
		_give_up(m)
		return true

	func _solve(m: MissionDef) -> bool:
		var p: ProblemDef = s.region.problems[m.goal_problem]
		var st: ProblemState = s.region.state[p.id]
		match st.phase:
			P.ACTIVE:
				if _investigate(m, p):
					return true
				_dead_end("cannot_spot", m.id, "the problem never showed (%s, %s)" % [p.step, p.visibility])
				_give_up(m)
				return true
			P.SPOTTED:
				if _wants_more(p) and _investigate(m, p, false):
					return true
				return _submit(m, p)
			P.DOING:
				return false
			P.RESOLVED when not s.missions.pending_talk(m).is_empty():
				return false  # only a needed talk is left (tomorrow)
			P.CHECK_READY:
				return _check(m, p)
			P.CHECKED:
				return _act(m, p)
		_dead_end("bad_phase", m.id, "mission active while its problem is %s" % s.phase_of(p.id))
		_give_up(m)
		return true

	# ── Investigation ───────────────────────────────────────────────────────

	func _search_of(p: ProblemDef) -> Dictionary:
		if not _search.has(p.id):
			_search[p.id] = {"actions": 0, "plan": [], "next": 0, "barren": {}, "dead": {}, "assisted": false}
		return _search[p.id]

	## One gemba action on the problem the persona's way; false when the
	## persona (and, for a lost one, the expert's help) has nothing left.
	func _investigate(m: MissionDef, p: ProblemDef, allow_help: bool = true) -> bool:
		var sr := _search_of(p)
		if sr["actions"] < MAX_SEARCH or style == "expert":
			var acted := false
			match style:
				"expert":
					acted = _expert_step(m, p)
				"average":
					acted = _average_step(m, p)
				_:
					acted = _careless_step(m, p)
			if acted:
				return true
		if style == "expert" or not allow_help:
			return false
		if not sr["assisted"]:
			sr["assisted"] = true
			record["assisted"].append({"mission": m.id, "problem": p.id, "day": snappedf(day(), 0.1),
				"actions": sr["actions"], "phase": s.phase_of(p.id), "clues": s.clues_found(p.id).size()})
		return _expert_step(m, p)

	## Whether the persona looks further before writing the A3.
	func _wants_more(p: ProblemDef) -> bool:
		var found := s.clues_found(p.id).size()
		var sr := _search_of(p)
		match style:
			"expert":
				return _next_key_clue(p) != null or not _scouted(p)
			"average":
				return found < 3 and sr["next"] < _average_plan(p).size() and sr["actions"] < MAX_SEARCH
		return found == 0 or sr["actions"] < 3

	func _expert_step(m: MissionDef, p: ProblemDef) -> bool:
		if s.region.state[p.id].phase == P.ACTIVE:
			var tool := _spotting_tool(p)
			return false if _search_of(p)["dead"].has(p.step + "|" + tool) else _use(m, p.step, tool, p)
		var next := _next_key_clue(p)
		if next != null:
			return _use(m, next.at, next.tool, p)
		if not _scouted(p):
			var place := _neighbour(p)
			return not place.is_empty() and _use(m, place, "queue_count", p)
		return false

	## A tool at the problem's step that shows it: the first key clue's there
	## when it can, else a deep look (data) or a walk along (shadow).
	func _spotting_tool(p: ProblemDef) -> String:
		for c in p.clues:
			if c.key and c.depth == 0 and c.at == p.step and c.tool != "conversation" \
					and (p.visibility != "hidden" or Investigation.TOOLS[c.tool]["deep"]):
				return c.tool
		return "data" if p.visibility == "hidden" else "shadow"

	## The shallowest key clue that can be found now (and has not proved barren).
	func _next_key_clue(p: ProblemDef) -> Clue:
		var dead: Dictionary = _search_of(p)["dead"]
		var best: Clue = null
		for c in p.clues:
			if c.key and Investigation.revealable(c, p, s.region.found) and not dead.has(c.at + "|" + c.tool) \
					and (best == null or c.depth < best.depth):
				best = c
		return best

	func _scouted(p: ProblemDef) -> bool:
		return s.region.observed.keys().any(func(place: String) -> bool:
			return place != p.step and place.get_slice(".", 0) == p.stream_id())

	## The nearest other work step of the problem's stream.
	func _neighbour(p: ProblemDef) -> String:
		var places := _stream_places(p, true)
		places.erase(p.step)
		return places[0] if not places.is_empty() else ""

	## The problem's stream's places, nearest to the problem's step first.
	func _stream_places(p: ProblemDef, work_only: bool) -> Array[String]:
		var stream := s.region.net.stream(p.stream_id())
		var at := 0
		var places: Array[String] = []
		for i in stream.steps.size():
			if stream.id + "." + stream.steps[i].id == p.step:
				at = i
		var order := range(stream.steps.size())
		order.sort_custom(func(a: int, b: int) -> bool: return absi(a - at) < absi(b - at) or (absi(a - at) == absi(b - at) and a < b))
		for i: int in order:
			if not work_only or stream.steps[i].kind == SimStep.Kind.WORK:
				places.append(stream.id + "." + stream.steps[i].id)
		return places

	## Average: every tool at the problem's step, then the four common ones at
	## the two nearest other work steps, then once more where something was found.
	func _average_plan(p: ProblemDef) -> Array:
		var sr := _search_of(p)
		if not (sr["plan"] as Array).is_empty():
			return sr["plan"]
		var plan := []
		for tool in AVERAGE_TOOLS:
			plan.append([p.step, tool])
		var others := _stream_places(p, true)
		others.erase(p.step)
		for place in others.slice(0, 2):
			for tool in AVERAGE_TOOLS.slice(0, 4):
				plan.append([place, tool])
		sr["plan"] = plan
		return plan

	func _average_step(m: MissionDef, p: ProblemDef) -> bool:
		var sr := _search_of(p)
		var plan := _average_plan(p)
		while sr["next"] < plan.size():
			var pair: Array = plan[sr["next"]]
			sr["next"] += 1
			if not sr["dead"].has(pair[0] + "|" + pair[1]) and pair[1] in _offered(pair[0]):
				return _use(m, pair[0], pair[1], p)
		return false

	func _careless_step(m: MissionDef, p: ProblemDef) -> bool:
		var places := _stream_places(p, false)
		var place: String = p.step if rng.randf() < 0.5 else places[rng.randi() % places.size()]
		var tools := _offered(place)
		return not tools.is_empty() and _use(m, place, tools[rng.randi() % tools.size()], p)

	## Use a tool (or, for "conversation", ask a question) at a place.
	func _use(m: MissionDef, place: String, tool: String, p: ProblemDef = null) -> bool:
		var before_time := s.region.net.time
		var before_found := s.region.found.size()
		var before_phase := s.phase_of(p.id) if p != null else ""
		var result: Dictionary
		_doing = "%s at %s (mission %s)" % [tool, place, m.id]
		if tool == "conversation":
			result = s.ask(place, _question(place))
		else:
			result = s.use_tool(place, tool)
		if result.has("error"):
			record["refusals"].append({"action": tool, "mission": m.id, "place": place, "code": result["error"],
				"day": snappedf(day(), 0.1)})
		var run: Dictionary = _runs.get(m.id, {})
		if not run.is_empty():
			run["actions"] += 1
			run["gemba_hours"] += (s.region.net.time - before_time) / 60.0
		if p != null:
			var sr := _search_of(p)
			sr["actions"] += 1
			var pair := place + "|" + tool
			if s.region.found.size() == before_found and s.phase_of(p.id) == before_phase:
				sr["barren"][pair] = int(sr["barren"].get(pair, 0)) + 1
				if sr["barren"][pair] >= BARREN_USES:
					sr["dead"][pair] = true
		return true

	## A question the place's menu offers: any for the careless persona, else
	## an open one (all of Investigation.QUESTIONS where the place has none listed).
	func _question(place: String) -> String:
		var ids: Array = s.place_questions(place).map(func(q: Dictionary) -> String: return q["id"])
		if ids.is_empty():
			ids = Investigation.QUESTIONS.keys()
		if style == "careless":
			return ids[rng.randi() % ids.size()]
		var open := ids.filter(func(id: String) -> bool: return Investigation.QUESTIONS[id] == "open")
		return open[0] if not open.is_empty() else ids[0]

	# ── The A3, the Check and the Act ───────────────────────────────────────

	func _submit(m: MissionDef, p: ProblemDef) -> bool:
		var a3 := _compose_a3(p)
		var cost: int = s.region.countermeasures[a3["cm"]].budget if s.region.countermeasures.has(a3["cm"]) else 0
		var code := s.submit_a3(p.id, a3)
		var run: Dictionary = _runs.get(m.id, {})
		if code.is_empty():
			(_tried.get_or_add(p.id, []) as Array).append(a3["cm"])
			if not run.is_empty():
				run["cm_spent"] += cost
			return true
		if not run.is_empty():
			run["a3_refusals"].append(code)
		if code == "same_countermeasure" and not a3["cm"] in _ruled_out.get(p.id, []):
			(_ruled_out.get_or_add(p.id, []) as Array).append(a3["cm"])
			return true  # the next A3 puts another countermeasure on it
		if code == "evidence" and _investigate(m, p):
			return true
		_dead_end("a3_refused", m.id, "%s (A3 %s)" % [code, a3])
		_give_up(m)
		return true

	func _compose_a3(p: ProblemDef) -> Dictionary:
		var st: ProblemState = s.region.state[p.id]
		var options := s.cause_options(p.id)
		var correct := options.find(p.root_cause)
		var found := s.clues_found(p.id).map(func(c: Clue) -> String: return c.id)
		var keys := s.clues_found(p.id).filter(func(c: Clue) -> bool: return c.key).map(func(c: Clue) -> String: return c.id)
		var ruled_out: Array = _ruled_out.get(p.id, [])
		var available: Array[CountermeasureDef] = []
		available.assign(s.countermeasures().filter(func(c: CountermeasureDef) -> bool: return not c.id in ruled_out))
		var fitting := available.filter(func(c: CountermeasureDef) -> bool: return p.countermeasures.has(c.id))
		fitting.sort_custom(func(a: CountermeasureDef, b: CountermeasureDef) -> bool: return a.budget < b.budget)
		var tried: Array = _tried.get(p.id, [])
		var a3 := {"waste": p.waste, "cause": correct, "evidence": keys if not keys.is_empty() else found,
			"cm": _best_cm(p, available), "prediction": p.kpi}
		match style:
			"average":
				var wrong_first := st.failed_checks == 0 and tried.is_empty() and rng.randf() < 0.4
				if rng.randf() >= 0.7:
					a3["waste"] = _pick(Investigation.WASTES)
				a3["evidence"] = found
				if rng.randf() >= 0.6:
					a3["prediction"] = _pick(Investigation.KPIS)
				if wrong_first:
					a3["cause"] = _wrong_index(options.size(), correct)
					var others := available.filter(func(c: CountermeasureDef) -> bool: return not p.countermeasures.has(c.id))
					if not others.is_empty():
						a3["cm"] = others[rng.randi() % others.size()].id
				else:
					var untried := fitting.filter(func(c: CountermeasureDef) -> bool: return not c.id in tried)
					if not untried.is_empty():
						a3["cm"] = untried[0].id
			"careless":
				a3["waste"] = _pick(Investigation.WASTES)
				a3["cause"] = rng.randi() % maxi(1, options.size())
				a3["prediction"] = _pick(Investigation.KPIS)
				var pool := fitting if st.failed_checks >= CARELESS_LEARNS_AFTER and not fitting.is_empty() else available
				a3["cm"] = pool[rng.randi() % pool.size()].id
				if st.failed_checks >= CARELESS_LISTENS_AFTER:
					a3["cm"] = _best_cm(p, available)
				var evidence := found.duplicate()
				_shuffle(evidence)
				a3["evidence"] = evidence.slice(0, 1 + rng.randi() % maxi(1, evidence.size()))
		return a3

	## The countermeasure that works best here now (cheapest on a tie).
	func _best_cm(p: ProblemDef, available: Array[CountermeasureDef]) -> String:
		var best := ""
		var best_eff := -1.0
		var best_cost := 0
		for c in available:
			var eff: float = Pdca.effectiveness(p, c, s.region.maturity())["eff"]
			if eff > best_eff or (is_equal_approx(eff, best_eff) and c.budget < best_cost):
				best = c.id
				best_eff = eff
				best_cost = c.budget
		return best

	func _check(m: MissionDef, p: ProblemDef) -> bool:
		var st: ProblemState = s.region.state[p.id]
		var eff := st.eff
		var a3 := st.a3.duplicate()
		var r := s.check(p.id)
		if r.has("error"):
			_dead_end("check_refused", m.id, r["error"])
			_give_up(m)
			return true
		var entry := {"mission": m.id, "problem": p.id, "day": snappedf(day(), 0.1), "attempt": st.failed_checks + (1 if r["passed"] else 0),
			"cm": a3["cm"], "cm_tier": s.region.countermeasures[a3["cm"]].tier, "eff": snappedf(eff, 0.001),
			"level": r["level"], "passed": r["passed"], "lesson": r["lesson"], "not_constraint": r["not_constraint"],
			"at_constraint": r["before"]["at_constraint"], "constraint_before": r["before"]["constraint_pool"],
			"constraint_after": r["after"]["constraint_pool"], "prediction": a3["prediction"], "kpi": p.kpi,
			"cause_correct": r["cause_correct"], "waste_right": r["waste_right"],
			"wait_step": _at_wait(p.id),
			"before": _rows(r["before"]), "after": _rows(r["after"]),
			# The Check's own counterfactual (Region.check): the fix's effect.
			"with": _rows(r["forecast"]["with"]), "without": _rows(r["forecast"]["without"]),
			"gains": _rows(r["forecast"]["gains"])}
		entry["flags"] = _flags(entry)
		record["checks"].append(entry)
		var run: Dictionary = _runs.get(m.id, {})
		if not run.is_empty():
			run["checks"] += 1
			if not r["passed"]:
				run["failed_checks"] += 1
		if not r["passed"] and st.failed_checks >= MAX_ATTEMPTS:
			_dead_end("too_many_failed_checks", m.id, "%d failed Checks on %s" % [st.failed_checks, p.id])
			_give_up(m)
		return true

	func _act(m: MissionDef, p: ProblemDef) -> bool:
		var want := style == "expert" or (style == "average" and rng.randf() < 0.5)
		var budget_before := s.budget()
		var score := s.act(p.id, want)
		var standardised := want and budget_before >= Region.STANDARDISE_BUDGET
		if want and not standardised:
			record["standardise_refused"].append({"mission": m.id, "day": snappedf(day(), 0.1), "budget": budget_before})
		var run: Dictionary = _runs.get(m.id, {})
		if score.has("error"):
			_dead_end("act_refused", m.id, score["error"])
			_give_up(m)
			return true
		if s.region.state[p.id].phase == P.RESOLVED and not s.is_practice(p.id):
			_ever_resolved[p.id] = true
		if not run.is_empty():
			run["score"] = score
			run["standardise_asked"] = want
			run["standardised"] = standardised
			run["problem_xp"] = Pdca.xp_for(score, p.tier)
			run["problem_budget"] = Pdca.budget_for(score, p.severity)
		return true

	static func _rows(snapshot: Dictionary) -> Dictionary:
		var out := {}
		for row: String in CheckPanel.ROWS:
			out[row] = snappedf(float(snapshot.get(row, 0.0)), 0.001)
		return out

	## Signed relative change of a KPI, positive when better.
	static func better_by(row: String, before: Dictionary, after: Dictionary) -> float:
		var b: float = before.get(row, 0.0)
		var a: float = after.get(row, 0.0)
		var change := (a - b) / absf(b) if absf(b) > 0.0001 else (a - b)
		return -change if row in Pdca.LOWER_IS_BETTER else change

	## What would read as contradictory: the verdict against the Check's own
	## counterfactual (the fix's effect, `gains`), and the panel's before/after
	## table against it.
	static func _flags(e: Dictionary) -> Array[String]:
		var flags: Array[String] = []
		var pred: float = e["gains"][e["prediction"]]
		var own: float = e["gains"][e["kpi"]]
		if e["passed"]:
			if pred < -Pdca.CHECK_NOISE:
				flags.append("passed_leading_kpi_worse" if CheckPanel.kind(e["prediction"]) == CheckPanel.LEADING
					else "passed_lagging_kpi_worse")
			if e["kpi"] != e["prediction"] and own < -Pdca.CHECK_NOISE:
				flags.append("passed_problem_kpi_worse")
			if absf(pred) <= Pdca.CHECK_NOISE and absf(own) <= Pdca.CHECK_NOISE:
				flags.append("passed_no_visible_change")
			if not e["cause_correct"]:
				flags.append("passed_with_wrong_cause")
			if e["at_constraint"] and e["gains"]["capacity"] < 0.005:
				flags.append("constraint_fixed_no_capacity_gain")
			if better_by(e["kpi"], e["before"], e["after"]) < -NOISE and own > Pdca.CHECK_NOISE:
				flags.append("trend_hides_gain")
		else:
			if pred > Pdca.CHECK_NOISE:
				flags.append("failed_but_kpi_improved")
			if e["lesson"] == "too_early" and e["level"] == "full":
				flags.append("too_early_but_region_ready")
		if e["not_constraint"] and e["wait_step"]:
			flags.append("not_constraint_on_wait_step")
		return flags

	# ── The coach ───────────────────────────────────────────────────────────

	## Ask the coach at each new stage (the expert three times, to see an
	## insight; careless only tries it on a side mission).
	func _coach(m: MissionDef) -> void:
		if m.kind == "side":
			if not _coached.has(m.id):
				_coached[m.id] = true
				var reply := s.ask_coach(m.id)
				record["coach"].append({"mission": m.id, "mission_kind": m.kind, "stage": "", "kind": reply["kind"],
					"text": reply.get("text", ""), "day": snappedf(day(), 0.1)})
			return
		if style == "careless":
			return
		var stage := s.missions.stage_of(m)
		var key := m.id + "|" + stage
		if _coached.has(key):
			return
		_coached[key] = true
		for i in (3 if style == "expert" else 1):
			var reply := s.ask_coach()
			record["coach"].append({"mission": m.id, "mission_kind": m.kind, "stage": reply.get("stage", ""),
				"kind": reply["kind"], "text": reply.get("text", ""), "day": snappedf(day(), 0.1)})

	# ── Chance ──────────────────────────────────────────────────────────────

	func _pick(from: Array) -> String:
		return from[rng.randi() % from.size()]

	func _wrong_index(size: int, correct: int) -> int:
		if size < 2:
			return correct
		var i := rng.randi() % (size - 1)
		return i + 1 if i >= correct else i

	func _shuffle(a: Array) -> void:
		for i in range(a.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var t: Variant = a[i]
			a[i] = a[j]
			a[j] = t


# ── The report ─────────────────────────────────────────────────────────────

class PlayReport extends RefCounted:
	## A Check flag's severity, title and proposed fix.
	const FLAGS := {
		"trend_hides_gain": ["high", "The Check panel's before/after table shows the problem's KPI worse although the fix helped",
			"The verdict now uses the Check's counterfactual (Region.check's forecast: the coming lead time with and without the fix), but CheckPanel still shows before/after, two different 14-day windows, so the stream's own trend lands on the player's fix. Show forecast.without ('zonder jouw maatregel') and forecast.with as the columns, and say how far ahead the Check looks (forecast.days)."],
		"passed_leading_kpi_worse": ["high", "Check passes while the predicted leading KPI got worse",
			"The pass rule is the countermeasure's fit (eff >= 0.5), not the numbers; a leading indicator (capacity, throughput, WIP age) is supposed to move inside the Check. Judge the pass on the measured change against a no-fix twin, or have the panel say 'geslaagd, maar je voorspelde KPI is nog niet bewogen'."],
		"passed_lagging_kpi_worse": ["medium", "Check passes while the predicted lagging KPI got worse",
			"The panel's LAGGING_NOTE explains lag in general, but not when the predicted KPI moved the wrong way. Name it in the verdict ('je voorspelde KPI is een volgindicator: kijk naar de stuurindicatoren') or let the A3 ask for a leading indicator as the prediction."],
		"passed_problem_kpi_worse": ["high", "Check passes while the problem's own KPI got worse (prediction named another KPI)",
			"Show the problem's KPI as the headline row; word a pass with a worse headline as 'de maatregel werkt, maar het effect is nog niet zichtbaar'."],
		"passed_no_visible_change": ["medium", "Check passes with no visible change in the predicted or the problem KPI",
			"Make the countermeasure's effect large enough to move its KPI inside 14 days, or let the panel name the indicator that did move."],
		"passed_with_wrong_cause": ["medium", "A wrong root cause still passes the Check",
			"By design the fit decides the pass and the lesson says cause_wrong, so a lucky countermeasure passes. Lower eff when the cause is wrong (e.g. x0.6), or make the root-cause dimension of the score cost more."],
		"constraint_fixed_no_capacity_gain": ["medium", "A fix at the constraint passes but stream capacity does not rise",
			"Check that the countermeasure's effects touch the constraint's touch time or availability; otherwise the 'bottleneck first' lesson reads false."],
		"failed_but_kpi_improved": ["high", "Check fails while the fix moved the predicted KPI",
			"A too-early countermeasure weakens the problem, but below Pdca.CHECK_PASS it does not work: the verdict and the numbers disagree. Word the too_early lesson with the numbers ('het helpt een beetje, maar werkt maar half')."],
		"too_early_but_region_ready": ["high", "'Too early' verdict while the region's maturity was ready (level full)",
			"Region.check words every non-mismatch failure as too_early; a low-fit countermeasure at full level needs its own lesson code (e.g. 'weak_fit')."],
		"not_constraint_on_wait_step": ["low", "'Not the bottleneck' warning on a problem at a wait step",
			"A wait step has no team, so at_constraint is always false and the panel says 'het werk wacht nog op een ander team'. Skip the warning (or word it for waits) when the problem's step is a wait."],
	}

	static func findings(runs: Array[Dictionary], catalog: Catalog) -> Array[Dictionary]:
		var out := {}
		var unstick := RegEx.create_from_string("#-?\\d+")
		for run in runs:
			var who := {"persona": run["persona"], "seed": run["seed"]}
			var expert: bool = run["persona"] == "expert"
			for d: Dictionary in run["dead_ends"]:
				var persona_limit: bool = d["kind"] == "too_many_failed_checks" and not expert
				_add(out, "dead_end:" + d["kind"] + (":persona" if persona_limit else ""), "medium" if persona_limit else "critical",
					"balance" if persona_limit else "stuck",
					"A player can fail the Check %d times in a row without a way out" % Persona.MAX_ATTEMPTS if persona_limit
						else "Dead end: %s" % d["kind"],
					d["detail"], who, d["mission"], d["day"],
					"After two mismatches the coach (or the Check panel) should point at the clues that rule the countermeasure out; today the only feedback is the mismatch note." if persona_limit
						else _dead_end_fix(d["kind"]), d["mission"])
			for e: Dictionary in run["errors"]:
				var message := unstick.sub(e["message"], "", true)
				_add(out, "error:" + message, "critical", "stuck", "Engine error: " + message, "raised by " + e["action"], who, "",
					e["day"], "Region.queue_at (and use_tool's queue_count) read Network.queue_of for any step, but a wait or material step has no queue: guard it as Region.measures does (count 0), and add a test that counts the queue at connections.permit.",
					(e["action"] as String).get_slice(" (", 0))
			for o: Dictionary in run.get("orphans", []):
				_add(out, "orphan", "high", "stuck", "Problems stay open (and hurting) with no mission to solve them",
					"open problems no active mission covers at the end of the run; they hold one of Region.MAX_OPEN (4) slots, so missions get refused with problem_unavailable",
					who, "", run["days"], "When a mission fails or completes without solving its problem (deadline missed, an investigate goal), put the problem back to sleep (Region.deactivate) or keep a mission open for it. A failed save_henks_knowledge can never be accepted again (status failed), so its problem stays open for good, against 'the problem can still be solved another way'.",
					"%s (%s; %s)" % [o["problem"], o["phase"], ", ".join(o["missions"])])
			if run["end"] in ["horizon", "action_cap"]:
				_add(out, "end:" + run["end"], "high", "stuck", "Campaign not finished within the horizon",
					"%d missions after %.0f days" % [run["completed"], run["days"]], who, "", run["days"],
					"See the slowest missions; shorten Checks or let the player run missions in parallel.", run["end"])
			for c: Dictionary in run["checks"]:
				for flag: String in c["flags"]:
					var f: Array = FLAGS[flag]
					var detail := "cm %s, predicted %s %+.1f %% (fix), problem KPI %s %+.1f %% (fix), %+.1f %% (before/after), capacity %+.1f %% (fix), eff %.2f, lesson %s" % [
						c["cm"], c["prediction"], 100.0 * c["gains"][c["prediction"]], c["kpi"], 100.0 * c["gains"][c["kpi"]],
						100.0 * Persona.better_by(c["kpi"], c["before"], c["after"]), 100.0 * c["gains"]["capacity"], c["eff"], c["lesson"]]
					_add(out, "flag:" + flag, f[0], "contradiction", f[1], detail, who, c["mission"], c["day"], f[2], c["problem"])
				if expert and not c["passed"]:
					_add(out, "expert_fail", "high", "balance", "The expert's best countermeasure fails the Check",
						"cm %s (tier %d) eff %.2f, level %s" % [c["cm"], c["cm_tier"], c["eff"], c["level"]], who, c["mission"], c["day"],
						"Give the problem a tier-1 countermeasure whose fit x full multiplier reaches 0.5, or raise the fit.", c["problem"])
			for f: Dictionary in run["failed"]:
				_add(out, "deadline:" + f["mission"] + (":expert" if expert else ""), "high" if expert else "low", "deadline",
					"Deadline missed: %s%s" % [f["mission"], " (even by the expert)" if expert else ""],
					"failed on day %.0f (taken on: %s), closes %s" % [f["day"], f["taken"], f["closes"]], who, f["mission"], f["day"],
					"The expert missing it means the deadline is too tight for the slots and the Check length." if expert
						else "Working as designed (a missed deadline closes a door); see the orphan finding for what happens to its problem.",
					run["persona"])
			if not (run["reopened"] as Array).is_empty():
				_add(out, "reopened:" + ("expert" if expert else "other"), "medium" if expert else "low", "fade",
					"Fixes fade and missions reopen%s" % (" even for the expert, who standardises and audits" if expert else ""),
					"reopenings per run (the expert standardises every fix and audits on every 'slipping' event)", who, "", 0.0,
					"With the sustain rules a standardised fix still wears (half-life 2.2 x decay_days); if the expert, who audits, still sees reopenings the audit cadence the game needs is not discoverable. Show 'slipping' on the HUD with the place to audit." if expert
						else "Working as designed for players who do not standardise; check the reopened mission tells why it is back.",
					"%s/%d: %d" % [run["persona"], run["seed"], (run["reopened"] as Array).size()])
			for a: Dictionary in run["assisted"]:
				if a.has("why"):  # a needed talk the persona could not push through (_have_needed_talk)
					_add(out, "assisted_talk:" + run["persona"], "low", "people",
						"%s could not press a needed talk to a yes" % run["persona"],
						"after Persona.PUSH_TRIES pushes it listened instead", who, a["mission"], a["day"],
						"Working as designed: pressure fails with someone already closed (openness under 10 ruins the talk); listening is the way through.",
						a["why"])
					continue
				_add(out, "assisted:" + run["persona"], "medium", "balance", "%s play gets lost searching for clues" % run["persona"],
					"after the persona's own search (%s) the problem was still unspotted or without evidence" % (
						"every tool at the step, four at its two neighbours" if run["persona"] == "average" else "30 random gemba actions"),
					who, a["mission"], a["day"],
					"Key clues sit at another step or stream than the problem (status_callers: intake/design; grid_study_queue: depth chain). Add a hidden_signal hint or a coach insight that names the place of the first key clue.",
					"%s (%d actions, %s, %d clues)" % [a["problem"], a["actions"], a["phase"], a["clues"]])
			for r: Dictionary in run["refusals"]:
				if r["action"] == "accept" and r["code"] == "problem_unavailable":
					_add(out, "refused:problem_unavailable", "high", "stuck", "Missions on the board cannot be accepted (problem_unavailable)",
						"Region.MAX_OPEN problems are open, mostly problems without a mission (see the orphan finding)", who, r["mission"], r["day"],
						"Count only problems with an active mission towards MAX_OPEN, or hide such missions from the board with the reason.", r["mission"])
			for x: Dictionary in run["standardise_refused"]:
				_add(out, "std_refused", "medium", "balance", "Standardising is silently refused below €3.000",
					"asked with budget %d" % x["budget"], who, x["mission"], x["day"],
					"Region.act drops the wish without an error; return a code (e.g. 'no_budget') so the UI can say why, or allow it into debt like the experiment.", x["mission"])
		_balance(out, runs)
		_check_window(out, runs)
		_progress_findings(out, runs)
		_treadmill(out, runs)
		_coach_findings(out, runs)
		_text_findings(out, runs, catalog)
		_promises(out, runs)
		_closing_talks(out, runs)
		var list: Array[Dictionary] = []
		list.assign(out.values())
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var sa := SEVERITIES.find(a["severity"])
			var sb := SEVERITIES.find(b["severity"])
			if sa != sb:
				return sa < sb
			var ra := _root_rank(a["id"])
			var rb := _root_rank(b["id"])
			return ra < rb if ra != rb else a["count"] > b["count"])
		return list

	static func _root_rank(id: String) -> int:
		for i in ROOTS.size():
			if id.begins_with(ROOTS[i]):
				return i
		return ROOTS.size()

	## Add an occurrence to the finding `key` (made on its first occurrence):
	## `item` counts what it affects (a problem, a mission).
	static func _add(out: Dictionary, key: String, severity: String, category: String, title: String, detail: String,
			who: Dictionary, mission: String, day: float, fix: String, item: String = "") -> void:
		if not out.has(key):
			out[key] = {"id": key, "severity": severity, "category": category, "title": title, "detail": detail, "count": 0,
				"repro": {"persona": who.get("persona", ""), "seed": who.get("seed", 0), "mission": mission, "day": day},
				"seen_in": [], "affects": {}, "fix": fix}
		var f: Dictionary = out[key]
		f["count"] += 1
		if who.has("persona"):
			var tag := "%s/%d" % [who["persona"], who["seed"]]
			if not tag in f["seen_in"]:
				f["seen_in"].append(tag)
			# Prefer the expert's run as the reproduction: the fewest random choices.
			if who["persona"] == "expert" and f["repro"]["persona"] != "expert":
				f["repro"] = {"persona": "expert", "seed": who["seed"], "mission": mission, "day": day}
				f["detail"] = detail
		if not item.is_empty():
			f["affects"][item] = int(f["affects"].get(item, 0)) + 1

	static func _dead_end_fix(kind: String) -> String:
		match kind:
			"belt_gate":
				return "The XP the reachable missions give is below the belt the next main mission needs. Lower requires.belt, raise rewards, or make sure enough side missions are open before the gate."
			"accept_refused":
				return "Missions are on the board but cannot be taken (see the codes): make the board hide what cannot be accepted, or free the slot / problem."
			"locked_behind_failed":
				return "A failed mission locks what follows; per CLAUDE.md a failed mission closes a door but the problem must stay solvable: unlock on failure too."
			"cannot_spot", "investigate_stuck":
				return "No tool reachable to the player reveals the problem or its key clues; check clue `at`/tool/depth chains and visibility."
			"too_many_failed_checks":
				return "No available countermeasure passes the Check at this maturity; add a tier-1 option or lower the tier."
			"no_action":
				return "A mission is active with nothing to do and nothing to wait for: its problem is in a state the mission does not expect."
		return "Investigate the detail; it should not happen."

	## Balance: campaign length, rewards, debt, how much the personas differ.
	static func _balance(out: Dictionary, runs: Array[Dictionary]) -> void:
		var by := _by_persona(runs)
		var expert: Array = by.get("expert", [])
		var careless: Array = by.get("careless", [])
		var none := {}
		if not expert.is_empty() and not careless.is_empty():
			var ex := _mean(expert.map(func(r: Dictionary) -> float: return float(r["xp"])))
			var cx := _mean(careless.map(func(r: Dictionary) -> float: return float(r["xp"])))
			var es := _mean_score(expert)
			var cs := _mean_score(careless)
			if ex > 0 and cx / ex >= 0.8:
				_add(out, "easy:xp", "medium", "balance", "Careless play earns nearly the expert's XP",
					"careless %.0f XP vs expert %.0f XP (%.0f %%); mean score %.1f vs %.1f of 25" % [cx, ex, 100 * cx / ex, cs, es],
					{"persona": "careless", "seed": careless[0]["seed"]}, "", 0.0,
					"Mission rewards are flat and dominate the problem XP; scale mission XP by the score, or reward the score more steeply (e.g. xp_for = total^2 * tier / 2).")
			if es - cs < 5.0:
				_add(out, "easy:score", "medium", "balance", "The score barely separates careless from expert play",
					"mean score careless %.1f vs expert %.1f of 25" % [cs, es], none, "", 0.0,
					"Widen the score: the floor of each dimension is 1-2 points, so random play still collects ~10.")
		for persona: String in by:
			var debts := 0
			var debt_days := 0.0
			var low := INF
			for r: Dictionary in by[persona]:
				for b: Dictionary in r["bad_periods"]:
					debts += 1
					debt_days += (b["end"] if b["end"] >= 0 else r["days"]) - b["start"]
				for c: Dictionary in r["curve"]:
					low = minf(low, c["budget"])
			if persona == "expert" and debts > 0:
				_add(out, "debt:expert", "medium", "balance", "The expert goes into debt",
					"%d bad period(s), %.0f days in all" % [debts, debt_days], {"persona": "expert", "seed": by[persona][0]["seed"]}, "", 0.0,
					"Budget too tight for best play: lower countermeasure budgets or raise mission budget rewards.")
			if persona == "careless" and debts == 0:
				_add(out, "debt:never", "low", "balance", "Debt never threatens, even careless play",
					"lowest budget seen by careless play: €%.0f" % low, {"persona": "careless", "seed": by[persona][0]["seed"]}, "", 0.0,
					"Only two problems have a weekly cost; give more problems a cost_per_week (claims, overtime, compensation for late connections) so neglect is felt.")
		# Luck: does the simulation's randomness ever change an outcome?
		if expert.size() > 1 and expert.all(func(r: Dictionary) -> bool:
				return r["xp"] == expert[0]["xp"] and r["budget"] == expert[0]["budget"] and r["days"] == expert[0]["days"]):
			_add(out, "seed_invariant", "medium", "balance", "The simulation never changes an outcome: the expert's result is identical on every seed",
				"%d seeds: %d XP, budget %s, %.0f days each, although the Check numbers differ per seed" % [expert.size(), expert[0]["xp"],
					UiText.money(expert[0]["budget"]), expert[0]["days"]], {"persona": "expert", "seed": expert[0]["seed"]}, "", 0.0,
				"Pass, score and rewards come from fit, maturity and planned capacity (Capacity.analyse), never from the measured flow. Let the impact dimension (and a bonus) use the measured change against a no-fix twin so that what the player sees in the numbers is what they are rewarded for.")
		# Rewards out of proportion: end budget far above anything there is to spend it on.
		for r: Dictionary in expert:
			var spent := 0
			for m: Dictionary in r["missions"]:
				spent += int(m["cm_spent"])
			if r["budget"] > 4 * maxi(spent, 1) and r["budget"] > 100000:
				_add(out, "rich", "medium", "balance", "Budget piles up: rewards far exceed what there is to spend",
					"expert ends with €%d after spending €%d on countermeasures" % [r["budget"], spent],
					{"persona": "expert", "seed": r["seed"]}, "", r["days"],
					"Pdca.budget_for (up to €18.000 per problem) plus mission budgets outrun countermeasure costs; lower BUDGET_BASE or make budget buy something (extra staff, training) so it matters.")
				break
		# Slow missions: more than twice the median for that persona, and over 30 days.
		for persona: String in by:
			var days := []
			for r: Dictionary in by[persona]:
				for m: Dictionary in r["missions"]:
					if m["outcome"] == "completed" and m["kind"] != "training":
						days.append(m["days"])
			if days.is_empty():
				continue
			days.sort()
			var median: float = days[int(days.size() / 2.0)]
			for r: Dictionary in by[persona]:
				for m: Dictionary in r["missions"]:
					if m["outcome"] == "completed" and m["days"] > maxf(30.0, 2.0 * median):
						_add(out, "slow:" + persona, "low", "balance", "Slow missions for %s play (over 30 days and twice the median of %.0f)" % [persona, median],
							"%s took %.0f days, %d Checks, %d gemba actions" % [m["id"], m["days"], m["checks"], m["actions"]],
							{"persona": persona, "seed": r["seed"]}, m["id"], m["accepted_day"],
							"Each failed Check costs another 14 days; offer a shorter re-run after a failed Check (7 days), or a hint after the first mismatch.",
							"%s (%.0f d)" % [m["id"], m["days"]])

	## The expert's Checks: does the Check show the best fix in the problem's
	## own KPI (its counterfactual gain, mean over seeds)?
	static func _check_window(out: Dictionary, runs: Array[Dictionary]) -> void:
		var effects := {}  # problem/kpi → [the fix's gain per Check]
		var who := {}
		for run in runs:
			if run["persona"] != "expert":
				continue
			if who.is_empty():
				who = {"persona": "expert", "seed": run["seed"]}
			for c: Dictionary in run["checks"]:
				if c["prediction"] == c["kpi"]:
					(effects.get_or_add("%s/%s" % [c["problem"], c["kpi"]], []) as Array).append(c["gains"][c["kpi"]])
		var flat := []
		for key: String in effects:
			var mean := _mean(effects[key])
			if mean <= Pdca.CHECK_NOISE:
				flat.append("%s %+.1f %%" % [key, 100.0 * mean])
		if flat.is_empty():
			return
		_add(out, "check_window", "high", "contradiction", "The Check cannot show the best fix in the problem's own KPI",
			"Against the Check's no-fix forecast, the expert's best fix moves the problem's own KPI by no more than the noise (%.0f %%) for %d of %d problems, mean over seeds: %s." % [
				100.0 * Pdca.CHECK_NOISE, flat.size(), effects.size(), ", ".join(flat)],
			who, "", 0.0,
			"The content names a KPI the fix cannot move within the Check's horizon (CheckForecast): name the KPI the fix moves, or make the fix's effect match its description.")

	## Progress: belt pacing, debt that never recovers, the fork, wait steps
	## and deadlines that run out while the experiment runs.
	static func _progress_findings(out: Dictionary, runs: Array[Dictionary]) -> void:
		for run in runs:
			var who := {"persona": run["persona"], "seed": run["seed"]}
			var belts: Array = run["belts"]
			if run["persona"] == "expert" and run["end"] == "campaign_done" and not belts.is_empty() \
					and belts.back()["belt"] == Progression.BELTS.back()["id"] and belts.back()["day"] < 0.7 * run["days"]:
				_add(out, "belts_fast", "medium", "balance", "Belts run out early: the top belt comes long before the campaign ends",
					"master black on day %.0f of a %.0f-day campaign; belts on days %s" % [belts.back()["day"], run["days"],
						", ".join(belts.map(func(b: Dictionary) -> String: return "%s %.0f" % [b["belt"], b["day"]]))], who, "", belts.back()["day"],
					"Total campaign XP (~%d for the expert) is far above Progression's master black (%d). Raise the belt thresholds, scale XP down, or tie the later belts to maturity and the KPI review instead of XP." % [run["xp"], Progression.BELTS.back()["xp"]])
			var curve: Array = run["curve"]
			var at_floor := curve.filter(func(c: Dictionary) -> bool: return c["budget"] <= Region.DEBT_FLOOR + 5000)
			if not at_floor.is_empty():
				_add(out, "debt_floor", "low", "balance", "Play reaches the debt floor",
					"%s spends %.0f %% of the run within €5.000 of the floor (%s) and ends at %s" % [run["persona"],
						100.0 * at_floor.size() / curve.size(), UiText.money(Region.DEBT_FLOOR), UiText.money(run["budget"])],
					who, "", at_floor[0]["day"],
					"Working as designed (recovery is always possible): the directie carries losses beyond the floor; held fixes' savings and solved problems pay the way back. Check the persona ever climbs out.",
					"%s/%d" % [run["persona"], run["seed"]])
			if run["budget"] < 0 and curve.size() > 4:
				var late: Dictionary = curve[maxi(0, curve.size() - 27)]
				var slope: float = (run["budget"] - late["budget"]) / maxf(1.0, run["days"] - late["day"]) * 30.0
				if slope < 0.0:
					_add(out, "debt_spiral", "high", "balance", "Debt spiral: the budget keeps falling and the bad period never ends",
						"%s ends at %s after %.0f days, still falling about %s a month; %d bad periods" % [run["persona"], UiText.money(run["budget"]),
							run["days"], UiText.money(roundi(-slope)), (run["bad_periods"] as Array).size()], who, "", run["days"],
						"CLAUDE.md: recovery must always be possible. Open problems (and worn fixes) keep costing and the bad period cuts capacity, while rewards come only from solved problems. Add a floor (e.g. the board grants a recovery budget, or costs stop at a debt limit), or let a bad period lower costs (no overtime) instead of only capacity.",
						"%s/%d" % [run["persona"], run["seed"]])
			for f: Dictionary in run["failed"]:
				if f.get("phase", "") in ["doing", "check_ready", "checked"]:
					_add(out, "deadline_during_experiment", "medium", "deadline", "A deadline runs out while the player's experiment is already running",
						"%s failed on day %.0f with its problem %s; the problem stays open with no mission" % [f["mission"], f["day"], f["phase"]],
						who, f["mission"], f["day"],
						"Count the deadline as met once the A3 is submitted (the countermeasure is in place), or warn when the Check would end after the deadline.",
						"%s/%d" % [run["persona"], run["seed"]])
			for m: Dictionary in run["missions"]:
				var notes: Array = (m["score"] as Dictionary).get("notes", [])
				if run["persona"] == "expert" and m["wait_step"] and "impact_not_constraint" in notes:
					_add(out, "wait_impact", "medium", "balance", "Fixing a wait step can never score on impact",
						"the impact dimension rewards stream capacity only; a wait (permit, delivery, close-out) has no team, so the expert's right fix scores impact 1-2 and gets the 'not the bottleneck' note",
						who, m["id"], m["accepted_day"],
						"Score impact on the problem's KPI against the no-fix twin (lead time for a wait), not on capacity alone.", m["problem"])

	## Faded fixes reopen their missions: how much of a run is re-runs, and how
	## much longer the campaign's first pass takes than the expert's.
	static func _treadmill(out: Dictionary, runs: Array[Dictionary]) -> void:
		var expert_days := _mean(runs.filter(func(r: Dictionary) -> bool:
			return r["persona"] == "expert" and r["end"] == "campaign_done").map(func(r: Dictionary) -> float: return r["days"]))
		for run in runs:
			var done: Array = (run["missions"] as Array).filter(func(m: Dictionary) -> bool:
				return m["outcome"] == "completed" and m["kind"] != "training")
			var reruns := done.filter(func(m: Dictionary) -> bool: return m["run"] > 1).size()
			if run["persona"] == "expert" or done.is_empty() or reruns < 0.3 * done.size():
				continue
			_add(out, "treadmill", "high", "balance", "Treadmill: players who do not always standardise spend most of the campaign redoing faded fixes",
				"%s/%d: %d of %d completed missions were re-runs of a faded fix; the campaign took %.0f days (%s) against the expert's %.0f" % [
					run["persona"], run["seed"], reruns, done.size(), run["days"], run["end"], expert_days],
				{"persona": run["persona"], "seed": run["seed"]}, "", run["days"],
				"A reopened main mission takes the only main slot for another 14+ days, so new missions wait. Let a reopened mission come back as a side mission (or a short 're-standardise' task without a new Check), and make decay_days longer than the Check so one lapse is not a full redo.",
				"%s/%d: %d/%d" % [run["persona"], run["seed"], reruns, done.size()])

	static func _coach_findings(out: Dictionary, runs: Array[Dictionary]) -> void:
		var texts := {}
		var asks := 0
		var insights := 0
		for run in runs:
			var who := {"persona": run["persona"], "seed": run["seed"]}
			for c: Dictionary in run["coach"]:
				if c["mission_kind"] == "side":
					if c["kind"] != "not_main":
						_add(out, "coach_side", "high", "coach", "The coach answers about a side mission",
							"%s got %s" % [c["mission"], c["kind"]], who, c["mission"], c["day"], "Missions.ask_coach must refuse side missions.")
					continue
				if run["persona"] != "expert":
					continue
				asks += 1
				if c["kind"] == "insight":
					insights += 1
				if c["kind"] == "question" and not (c["text"] as String).strip_edges().ends_with("?"):
					_add(out, "coach_not_q:" + c["text"], "medium", "coach", "Coach 'question' that is not a question",
						"stage %s: \"%s\"" % [c["stage"], c["text"]], who, c["mission"], c["day"], "Rephrase as a question (Toyota Kata).")
				if (c["text"] as String).is_empty() and c["kind"] in ["question", "insight"]:
					_add(out, "coach_empty:" + c["stage"], "high", "coach", "Coach says nothing at stage %s" % c["stage"],
						"", who, c["mission"], c["day"], "Add questions for every stage in content/missions.yaml coach.stages.")
				var seen: Dictionary = texts.get_or_add(c["text"], {})
				seen[c["mission"]] = true
		var repeated := texts.keys().filter(func(t: String) -> bool: return texts[t].size() >= 5)
		if not repeated.is_empty():
			repeated.sort_custom(func(a: String, b: String) -> bool: return texts[a].size() > texts[b].size())
			var top: String = repeated[0]
			_add(out, "coach_repeat", "medium", "coach", "The coach repeats the same questions across missions",
				"%d distinct lines over %d expert asks; %d lines reach 5+ missions, e.g. \"%s\" in %d missions. Insights: %d of %d asks." % [
					texts.size(), asks, repeated.size(), top, texts[top].size(), insights, asks],
				{"persona": "expert", "seed": runs[0]["seed"]}, "", 0.0,
				"The question index restarts at 0 for every mission, so each mission opens with the same line. Rotate by mission (offset by a hash of the id or by missions completed) and add a few mission-specific questions next to the insights.")

	## Missing or non-Dutch text: mission text, insights per stage reached,
	## clue notes, and codes the runs met that UiText has no words for.
	static func _text_findings(out: Dictionary, runs: Array[Dictionary], catalog: Catalog) -> void:
		var none := {}
		var english := RegEx.create_from_string("(?i)\\b(the|and|with|TODO|TBD|FIXME)\\b")
		for m in catalog.missions:
			for field in ["briefing", "debrief"]:
				var text: String = m.get(field)
				if text.strip_edges().is_empty():
					_add(out, "text:%s:%s" % [m.id, field], "low", "text", "Mission %s has no %s" % [m.id, field], "", none, m.id, 0.0,
						"Write the Dutch %s in content/missions.yaml." % field)
				elif english.search(text) != null:
					_add(out, "english:%s:%s" % [m.id, field], "low", "text", "English word in %s of %s" % [field, m.id], text, none, m.id, 0.0, "Translate.")
			if m.deadline_days >= 0 and m.fail_text.is_empty():
				_add(out, "text:%s:fail" % m.id, "low", "text", "Mission %s has a deadline but no fail text" % m.id, "", none, m.id, 0.0,
					"Add `fail:` in content/missions.yaml.")
		var reached := {}
		for run in runs:
			for c: Dictionary in run["coach"]:
				# The talk stage is People.coach_question's bank (dialogs.yaml bank.coach), not a mission insight.
				if c["mission_kind"] != "side" and not (c["stage"] as String) in ["", "talk"]:
					(reached.get_or_add(c["mission"], {}) as Dictionary)[c["stage"]] = true
		var missing := []
		for id: String in reached:
			var m: MissionDef = catalog.missions.filter(func(x: MissionDef) -> bool: return x.id == id).front()
			for stage: String in reached[id]:
				if not m.insights.has(stage):
					missing.append("%s/%s" % [id, stage])
		if not missing.is_empty():
			_add(out, "insights_missing", "low", "text", "No coach insight for stages players reach",
				"%d mission/stage pairs fall back to the generic questions only: %s" % [missing.size(), ", ".join(missing)], none, "", 0.0,
				"Add an `insights` line per reached stage (at least understand and reflect) in content/missions.yaml.")
		var no_note := []
		for p in catalog.problems:
			for c in p.clues:
				if c.text.strip_edges().is_empty():
					_add(out, "clue_text:" + c.id, "high", "text", "Clue without text: %s" % c.id, "", none, "", 0.0, "Write the clue's Dutch text.")
				if c.key and c.note.strip_edges().is_empty():
					no_note.append(c.id)
		if not no_note.is_empty():
			_add(out, "clue_notes", "low", "text", "Key clues without a coach note for the debrief",
				"%d key clues: %s" % [no_note.size(), ", ".join(no_note.slice(0, 12))], none, "", 0.0,
				"Add `note:` to each key clue (the coach's reflection in the debrief).")
		var words := {"lesson": UiText.LESSONS, "score_note": UiText.SCORE_NOTES, "accept": UiText.ACCEPT_ERRORS,
			"a3": UiText.A3_ERRORS, "place": UiText.PLACE_ERRORS}
		for run in runs:
			var who := {"persona": run["persona"], "seed": run["seed"]}
			for c: Dictionary in run["checks"]:
				if not words["lesson"].has(c["lesson"]):
					_add(out, "uitext:lesson:" + c["lesson"], "medium", "text", "No Dutch text for lesson " + c["lesson"], "", who, c["mission"], c["day"], "Add it to UiText.LESSONS.")
			for m: Dictionary in run["missions"]:
				for note: String in m["score"].get("notes", []):
					if not words["score_note"].has(note):
						_add(out, "uitext:note:" + note, "medium", "text", "No Dutch text for score note " + note, "", who, m["id"], m["accepted_day"], "Add it to UiText.SCORE_NOTES.")
				for code: String in m["a3_refusals"]:
					if not words["a3"].has(code):
						_add(out, "uitext:a3:" + code, "medium", "text", "No Dutch text for A3 refusal " + code, "", who, m["id"], m["accepted_day"], "Add it to UiText.A3_ERRORS.")
			for r: Dictionary in run["refusals"]:
				var table: Dictionary = words["accept"] if r["action"] == "accept" else words["place"]
				if not table.has(r["code"]):
					_add(out, "uitext:%s:%s" % [r["action"], r["code"]], "medium", "text", "No Dutch text for refusal " + r["code"], "", who, r["mission"], r["day"], "Add it to UiText.")

	## The design's promises about talking and setbacks (CLAUDE.md §2, the
	## dialog spec §4.2), seed by seed: each contradiction is its own finding.
	static func _promises(out: Dictionary, runs: Array[Dictionary]) -> void:
		var by := _by_persona(runs)
		for t: Dictionary in by.get("talker", []):
			var n := _same_seed(by.get("never-talks", []), t["seed"])
			if n.is_empty():
				continue
			var seed: int = t["seed"]
			var who := {"persona": "talker", "seed": seed}
			var trust := [mean_of_people(t, "trust"), mean_of_people(n, "trust")]
			if trust[0] <= trust[1]:
				_add(out, "promise:trust:%d" % seed, "high", "promise", "The talker does not end with more trust than never-talks",
					"seed %d, day %.0f: mean trust over %d people talker %.1f, never-talks %.1f" % [seed, end_day(t),
						(t["people"] as Dictionary).size(), trust[0], trust[1]], who, "", end_day(t),
					"Trust only moves in talks (People.TRUST); if listening does not raise it, check the outcome table (TRUST) and that talks reach the people who own the fixes.")
			if fixes_of(t).is_empty() or fixes_of(n).is_empty():
				continue
			var life := [mean_life(t), mean_life(n)]
			var decay := [decay_events(t), decay_events(n)]
			if life[0] <= life[1] or decay[0] > decay[1]:
				_add(out, "promise:lasting:%d" % seed, "high", "promise", "The talker's fixes do not last longer than never-talks'",
					"seed %d, day %.0f: mean life of held fixes talker %.0f d, never-talks %.0f d; slipping + recurred talker %d, never-talks %d" % [
						seed, end_day(t), life[0], life[1], decay[0], decay[1]], who, "", end_day(t),
					"Buy-in (Sustain.BUY_IN) multiplies a fix's life only when its problem has an owner dialog (DialogDef.owns); give every fix an owner, or let the talk's outcome reach the fix another way.")
			if float(n["xp"]) > float(t["xp"]):
				_add(out, "promise:decay_pays:%d" % seed, "medium", "promise", "Never-talks earns more XP than the talker: the slips pay",
					"seed %d, day %.0f: XP never-talks %d, talker %d; check-in missions (terugval_) done never-talks %d, talker %d" % [
						seed, n["days"], n["xp"], t["xp"], _checkins_done(n), _checkins_done(t)],
					{"persona": "never-talks", "seed": seed}, "", n["days"],
					"Principle 1 (long term over short term): a check-in for a slipping fix pays Missions.CHECKIN_XP, so faster decay earns more. Pay the check-in nothing, or pay the fix that held (e.g. a bonus per quarter a fix stayed above SLIPPING_HEALTH).")
			var morale := [_people_mean(n["people"], "morale_start"), mean_of_people(n, "morale")]
			if morale[1] >= morale[0] and (n["left"] as Array).is_empty():
				_add(out, "promise:people_flat:%d" % seed, "medium", "promise", "Never talking to people costs their morale nothing",
					"seed %d, day %.0f: never-talks' mean morale %.1f at the start, %.1f at the end; nobody left; trust %.1f → %.1f" % [
						seed, end_day(n), morale[0], morale[1], _people_mean(n["people"], "trust_start"), mean_of_people(n, "trust")],
					{"persona": "never-talks", "seed": seed}, "", end_day(n),
					"Respect for people (principle 2): morale moves only in talks (People.MORALE) and a goodbye needs morale below 20 for 60 days. Let ignored check-in prompts and fixes pushed through without the owner (compliance) cost morale, so neglect shows before anyone leaves.")
			var compliance := (fixes_of(n)).filter(func(f: Dictionary) -> bool: return f["buy_in"] == "compliance").size()
			if decay[1] <= decay[0] and compliance == 0:
				_add(out, "promise:never_decay:%d" % seed, "high", "promise", "Never-talks' fixes do not decay more than the talker's",
					"seed %d, day %.0f: slipping + recurred never-talks %d, talker %d; fixes held by compliance %d" % [
						seed, end_day(n), decay[1], decay[0], compliance], {"persona": "never-talks", "seed": seed}, "", end_day(n),
					"Acting without asking the owner should count as compliance (×0.6); check People.buy_in.")
		for n: Dictionary in by.get("never-talks", []):
			var e := _same_seed(by.get("expert", []), n["seed"])
			if e.get("end") != "campaign_done":
				continue
			if n["end"] != "campaign_done" or float(n["completed"]) < 0.9 * float(e["completed"]):
				_add(out, "promise:never_completes:%d" % n["seed"], "high", "promise", "Never-talks cannot complete the campaign",
					"seed %d, day %.0f: %s with %d missions done, expert %d" % [n["seed"], n["days"], n["end"], n["completed"],
						e["completed"]], {"persona": "never-talks", "seed": n["seed"]}, "", n["days"],
					"A mission must stay finishable by acting alone (compliance at ×0.6, half pay), never require a commitment.")
		for c: Dictionary in by.get("careless", []):
			var who := {"persona": "careless", "seed": c["seed"]}
			if c["end"] in ["stuck", "content_error"] or not (c["errors"] as Array).is_empty():
				_add(out, "promise:game_over:%d" % c["seed"], "critical", "promise", "Careless play ends in a state it cannot leave",
					"seed %d, day %.0f: end %s, %d engine errors" % [c["seed"], c["days"], c["end"], (c["errors"] as Array).size()],
					who, "", c["days"], "Setbacks, never game over (CLAUDE.md §2): see the dead ends and errors of this run.")
			if (c["bad_periods"] as Array).is_empty() and float(c["min_budget"]) >= 0.0 and (c["failed"] as Array).is_empty():
				_add(out, "promise:no_setback:%d" % c["seed"], "medium", "promise", "Careless play never hits a setback",
					"seed %d, day %.0f: no bad period, no missed deadline, lowest budget %s" % [c["seed"], c["days"],
						UiText.money(int(c["min_budget"]))], who, "", c["days"],
					"Neglect must cost: weekly costs of open problems, claims, missed deadlines.")

	## Missions that end with a talk (Monday: anouk_seven): completed without
	## the talk, or held open and never completed.
	static func _closing_talks(out: Dictionary, runs: Array[Dictionary]) -> void:
		for run in runs:
			var who := {"persona": run["persona"], "seed": run["seed"]}
			for e: Dictionary in run.get("ends_with_talk", []):
				if float(e["completed_day"]) >= 0.0 and not e["completed_after_talk"]:
					_add(out, "closing_talk:skipped", "critical", "stuck", "A mission that ends with a talk completed without it",
						"%s completed on day %.1f, %s not had" % [e["mission"], e["completed_day"], e["dialog"]], who, e["mission"],
						e["completed_day"], "Missions._goal_met must wait for MissionDef.ends_with_talk.", e["mission"])
				elif float(e["completed_day"]) < 0.0:
					_add(out, "closing_talk:stuck", "critical", "stuck", "A mission held open for its closing talk never completed",
						"%s waited for %s from day %.1f (talk outcome %s)" % [e["mission"], e["dialog"], e["day"], e["outcome"]], who,
						e["mission"], e["day"], "The talk must stay reachable while its mission waits for it.", e["mission"])

	static func _checkins_done(run: Dictionary) -> int:
		return (run["missions"] as Array).filter(func(m: Dictionary) -> bool:
			return (m["id"] as String).begins_with(Missions.CHECKIN_PREFIX) and m["outcome"] == "completed").size()

	static func _same_seed(list: Array, seed: int) -> Dictionary:
		for r: Dictionary in list:
			if int(r["seed"]) == seed:
				return r
		return {}

	## The last day the run measured (the epilogue's end when it had one).
	static func end_day(run: Dictionary) -> float:
		return float(run["days"]) + float((run["epilogue"] as Dictionary).get("days", 0.0))

	## The people as measured last (after the epilogue when there was one).
	static func people_of(run: Dictionary) -> Dictionary:
		return (run["epilogue"] as Dictionary).get("people", run["people"])

	static func fixes_of(run: Dictionary) -> Array:
		return (run["epilogue"] as Dictionary).get("fixes", run["fixes"])

	static func mean_of_people(run: Dictionary, key: String) -> float:
		return _people_mean(people_of(run), key)

	static func _people_mean(people: Dictionary, key: String) -> float:
		return _mean(people.values().map(func(p: Dictionary) -> float: return float(p[key])))

	## Mean life (days of neglect it lasts) of the fixes that still hold.
	static func mean_life(run: Dictionary) -> float:
		return _held_life(fixes_of(run))

	static func _held_life(fixes: Array) -> float:
		return _mean(fixes.filter(func(f: Dictionary) -> bool: return f["held"]).map(
			func(f: Dictionary) -> float: return float(f["life_days"])))

	## How often a fix slipped or recurred, in the campaign and the epilogue.
	static func decay_events(run: Dictionary) -> int:
		return (run["slipping"] as Array).size() + (run["recurred"] as Array).size()

	static func _by_persona(runs: Array[Dictionary]) -> Dictionary:
		var by := {}
		for r in runs:
			(by.get_or_add(r["persona"], []) as Array).append(r)
		return by

	static func _mean(values: Array) -> float:
		if values.is_empty():
			return 0.0
		var sum := 0.0
		for v: Variant in values:
			sum += float(v)
		return sum / values.size()

	static func _mean_score(runs: Array) -> float:
		var totals := []
		for r: Dictionary in runs:
			for m: Dictionary in r["missions"]:
				if not (m["score"] as Dictionary).is_empty() and m["kind"] != "training":
					totals.append(float(m["score"]["total"]))
		return _mean(totals)

	# ── Markdown ────────────────────────────────────────────────────────────

	static func markdown(report: Dictionary, catalog: Catalog) -> String:
		var runs: Array = report["runs"]
		var md := PackedStringArray()
		md.append("# Autoplay report")
		md.append("")
		md.append("Generated %s by `game/tools/autoplay.gd` (personas %s, seeds %s). Reproduce one run with" % [
			report["generated"], ", ".join(report["personas"]), ", ".join(report["seeds"].map(func(x: int) -> String: return str(x)))])
		md.append("`godot --headless --path game --script res://tools/autoplay.gd -- ../docs/qa <seed> <persona>`.")
		md.append("Raw data (every Check's numbers, the XP/budget curve, coach replies) is in `autoplay-report.json`.")
		md.append("The rules are played as they stand in the working tree; the gemba audit (leader routine) is %s." % (
			"used on every 'slipping' event by the expert, on half of them by the average player" if runs.any(func(r: Dictionary) -> bool:
				return not (r["audits"] as Array).is_empty()) else "not in GameSession, so fixes are left to wear"))
		md.append("")
		md.append("Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 %% of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. **talker** plays the gemba, the A3 and the audits as the expert does and talks to everyone who has a talk for it (check-ins first, each talk at most once a day, a persuasion three times, a check-in six), listening first: it answers the person's last words with the move that fits them, steers only once the concern is out and the meter reads commitment, never pressures. **never-talks** plays as the expert does and never opens a talk; only a talk a mission cannot end without is had: Monday's `anouk_seven` hello and goodbye (logged as forced), and a talk a mission needs (`talk_to`) pressed for a yes (a hello, a proposal, pressure, the ask; listening after 5 pushes, logged as assisted). Every other persona also only says hello on Monday; a needed talk is had when the objective names it, careless pressing like never-talks, the others listening first. A lost persona gets the expert's next step (\"assisted\"). A run that ends with the campaign done plays an epilogue of %d days with no new work (the persona's audits only), to see which fixes hold." % Persona.EPILOGUE_DAYS)
		md.append("")
		var by_severity := PackedStringArray()
		for sev in SEVERITIES:
			by_severity.append("%d %s" % [(report["findings"] as Array).filter(func(f: Dictionary) -> bool: return f["severity"] == sev).size(), sev])
		md.append("**Summary:** %s. Every persona but careless reaches the end of the campaign without a dead end: %s." % [", ".join(by_severity),
			"yes" if runs.all(func(r: Dictionary) -> bool: return r["persona"] == "careless" or ((r["dead_ends"] as Array).is_empty() and r["end"] == "campaign_done")) else "no"])
		md.append("")
		md.append("## Runs")
		md.append("")
		md.append("| persona | seed | end | days | missions done | main done | XP | belt | budget | Checks passed/failed | deadlines missed | reopened | bad periods | assisted |")
		md.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
		for r: Dictionary in runs:
			var checks: Array = r["checks"]
			var passed := checks.filter(func(c: Dictionary) -> bool: return c["passed"]).size()
			var main := (r["missions"] as Array).filter(func(m: Dictionary) -> bool: return m["kind"] == "main" and m["outcome"] == "completed").size()
			md.append("| %s | %d | %s | %.0f | %d | %d | %d | %s | %s | %d/%d | %d | %d | %d | %d |" % [r["persona"], r["seed"], r["end"],
				r["days"], r["completed"], main, r["xp"], r["belt"], UiText.money(r["budget"]), passed, checks.size() - passed,
				(r["failed"] as Array).size(), (r["reopened"] as Array).size(), (r["bad_periods"] as Array).size(), (r["assisted"] as Array).size()])
		md.append("")
		md.append("Days, XP, budget and the counts are the campaign's (the epilogue's are in the next table); reopened counts the epilogue too.")
		md.append("")
		md.append("## People, talks and fixes")
		md.append("")
		md.append_array(_people_table(runs))
		md.append("")
		md.append("## Per persona (mean over seeds)")
		md.append("")
		md.append_array(_persona_table(runs))
		md.append("")
		md.append("## Monday's closing talk (`ends_with_talk`)")
		md.append("")
		md.append_array(_closing_table(runs))
		md.append("")
		var findings: Array = report["findings"]
		md.append("## Findings (%d), ranked by severity" % findings.size())
		md.append("")
		var n := 0
		for f: Dictionary in findings:
			n += 1
			var repro: Dictionary = f["repro"]
			md.append("### %d. [%s] %s" % [n, f["severity"], f["title"]])
			md.append("")
			md.append("- **Category:** %s · **occurrences:** %d · **seen in:** %s" % [f["category"], f["count"], ", ".join(f["seen_in"]) if not f["seen_in"].is_empty() else "content"])
			if not (f["detail"] as String).is_empty():
				md.append("- **Detail:** %s" % f["detail"])
			var affects: Dictionary = f["affects"]
			if not affects.is_empty():
				var items := affects.keys()
				items.sort_custom(func(a: String, b: String) -> bool: return affects[a] > affects[b])
				md.append("- **Affects:** %s" % ", ".join(items.slice(0, 14).map(func(i: String) -> String:
					return i if affects[i] == 1 else "%s ×%d" % [i, affects[i]])) + (" …" if items.size() > 14 else ""))
			if not (repro["persona"] as String).is_empty():
				md.append("- **Reproduce:** persona `%s`, seed %d%s, day %.0f" % [repro["persona"], repro["seed"],
					(", mission `%s`" % repro["mission"]) if not repro["mission"].is_empty() else "", repro["day"]])
			md.append("- **Proposed fix:** %s" % f["fix"])
			md.append("")
		md.append("## Days per mission (mean over seeds, completed runs)")
		md.append("")
		md.append_array(_mission_table(runs, catalog))
		md.append("")
		md.append("## Checks")
		md.append("")
		md.append_array(_check_table(runs))
		md.append("")
		md.append("## The fork (two main missions open at once)")
		md.append("")
		md.append_array(_fork_table(runs, catalog))
		md.append("")
		md.append("## Coach")
		md.append("")
		md.append_array(_coach_table(runs))
		md.append("")
		md.append("## Accessors GameSession lacks (the playtester reads Region/Missions instead)")
		md.append("")
		for line in [
			"`kpi_review_due()`: `kpi_review(choices)` exists, but nothing says when a review is due and no screen calls it (PLAN 2.4c), so the quarterly review is not played here.",
			"`mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.",
			"`stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.",
			"`problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.",
			"`dialog_for(person_id)`: which talk a person has now (the talker reads People.dialog_for with GameSession._world); `people_at(place)` gives only has_dialog.",
			"`goal_met(mission_id)`: whether a mission waits only for its closing talk (the playtester swaps Missions.talked to ask Missions._goal_met).",
			"`act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently; `standardise()` afterwards does say no_budget).",
		]:
			md.append("- " + line)
		md.append("")
		return "\n".join(md)

	## Per run: talks and their outcomes, trust and morale, who left, the
	## fixes (held vs recurred, buy-in, life), discoveries, and the epilogue.
	static func _people_table(runs: Array) -> PackedStringArray:
		var rows := PackedStringArray([
			"| persona | seed | talks (forced) | outcomes | trust start→end (mean) | morale start→end (mean) | lowest morale | left | fixes held/made | recurred | slipping | audits | buy-in c/n/x | life of held fixes (d) | discoveries | lowest budget | epilogue: held, recurred, slipping |",
			"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"])
		for r: Dictionary in runs:
			var talks: Array = r["talks"]
			var outcomes := {}
			for t: Dictionary in talks:
				outcomes[t["outcome"]] = int(outcomes.get(t["outcome"], 0)) + 1
			var people: Dictionary = r["people"]
			var low_id := ""
			for id: String in people:
				if low_id.is_empty() or people[id]["morale"] < people[low_id]["morale"]:
					low_id = id
			var fixes: Array = r["fixes"]
			var buy := func(kind: String) -> int: return fixes.filter(func(f: Dictionary) -> bool: return f["buy_in"] == kind).size()
			var ep: Dictionary = r["epilogue"]
			var ep_cell := "–"
			if not ep.is_empty():
				ep_cell = "%d/%d, %d, %d" % [(ep["fixes"] as Array).filter(func(f: Dictionary) -> bool: return f["held"]).size(),
					(ep["fixes"] as Array).size(), ep["recurred"], ep["slipping"]]
			rows.append("| %s | %d | %d (%d) | %s | %.1f→%.1f | %.1f→%.1f | %s %d | %s | %d/%d | %d | %d | %d | %d/%d/%d | %.0f | %d | %s | %s |" % [
				r["persona"], r["seed"], talks.size(), talks.filter(func(t: Dictionary) -> bool: return t["forced"]).size(),
				", ".join(outcomes.keys().map(func(o: String) -> String: return "%s %d" % [o, outcomes[o]])) if not outcomes.is_empty() else "–",
				_people_mean(people, "trust_start"), _people_mean(people, "trust"),
				_people_mean(people, "morale_start"), _people_mean(people, "morale"),
				low_id, people[low_id]["morale"] if not low_id.is_empty() else 0,
				", ".join((r["left"] as Array).map(func(x: Dictionary) -> String: return "%s (d%.0f)" % [x["person"], x["day"]])) if not (r["left"] as Array).is_empty() else "–",
				fixes.filter(func(f: Dictionary) -> bool: return f["held"]).size(), fixes.size(), (r["recurred"] as Array).size(),
				(r["slipping"] as Array).size(), (r["audits"] as Array).size(), buy.call("commitment"), buy.call("none"), buy.call("compliance"),
				_held_life(fixes),
				(r["discoveries"] as Array).size(), UiText.money(int(r["min_budget"])), ep_cell])
		rows.append("")
		rows.append("At the campaign's end (careless: the horizon). Trust and morale are means over every person in content (0–100). Recurred, slipping and audits count the epilogue too. Buy-in: of the fixes still held, commitment (life ×1.25) / none (×1.0, also a fix with no owner in content) / compliance (×0.6, Sustain.BUY_IN). Life: days of neglect a held fix lasts at today's habits (Region.life_days).")
		return rows

	static func _persona_table(runs: Array) -> PackedStringArray:
		var rows := PackedStringArray(["| persona | runs | missions done | failed | days | budget at end | lowest budget | trust (end) | morale (end) | people left | fixes held after epilogue | slipping + recurred | life of held fixes (d) | discoveries | talks |",
			"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"])
		var by := _by_persona(runs)
		for persona: String in by:
			var list: Array = by[persona]
			var m := func(f: Callable) -> float: return _mean(list.map(f))
			rows.append("| %s | %d | %.1f | %.1f | %.0f | %s | %s | %.1f | %.1f | %.1f | %s | %.1f | %.0f | %.1f | %.1f |" % [persona, list.size(),
				m.call(func(r: Dictionary) -> float: return float(r["completed"])),
				m.call(func(r: Dictionary) -> float: return float((r["failed"] as Array).size())),
				m.call(func(r: Dictionary) -> float: return float(r["days"])),
				UiText.money(roundi(m.call(func(r: Dictionary) -> float: return float(r["budget"])))),
				UiText.money(roundi(m.call(func(r: Dictionary) -> float: return float(r["min_budget"])))),
				m.call(func(r: Dictionary) -> float: return mean_of_people(r, "trust")),
				m.call(func(r: Dictionary) -> float: return mean_of_people(r, "morale")),
				m.call(func(r: Dictionary) -> float: return float((r["left"] as Array).size())),
				"%.1f/%.1f" % [m.call(func(r: Dictionary) -> float: return float(fixes_of(r).filter(func(f: Dictionary) -> bool: return f["held"]).size())),
					m.call(func(r: Dictionary) -> float: return float(fixes_of(r).size()))],
				m.call(func(r: Dictionary) -> float: return float(decay_events(r))),
				m.call(func(r: Dictionary) -> float: return mean_life(r)),
				m.call(func(r: Dictionary) -> float: return float((r["discoveries"] as Array).size())),
				m.call(func(r: Dictionary) -> float: return float((r["talks"] as Array).size()))])
		rows.append("")
		rows.append("Trust, morale, fixes and life after the epilogue where the run had one (careless: at the horizon).")
		return rows

	static func _closing_table(runs: Array) -> PackedStringArray:
		var rows := PackedStringArray(["| persona | seed | mission | talk | had on day | goal met, day held open | completed on day | completed after the talk | outcome |",
			"|---|---|---|---|---|---|---|---|---|"])
		for r: Dictionary in runs:
			for e: Dictionary in r.get("ends_with_talk", []):
				rows.append("| %s | %d | %s | %s | %s | %s | %.1f | %s | %s |" % [r["persona"], r["seed"], e["mission"], e["dialog"],
					"%.1f" % e["day"] if float(e["day"]) >= 0.0 else "before the goal (talk round)", "yes" if e["held_open"] else "no",
					e["completed_day"], "yes" if e["completed_after_talk"] else "**no**", e["outcome"]])
		rows.append("")
		rows.append("Careless skips the training week, so it has no Monday. 'Goal met, day held open': the walk was done and the day stayed open until the talk.")
		return rows

	static func _mission_table(runs: Array, catalog: Catalog) -> PackedStringArray:
		var rows := PackedStringArray(["| mission | kind | expert | average | careless |", "|---|---|---|---|---|"])
		for m in catalog.missions:
			var cells := []
			for persona in PERSONAS:
				var days := []
				for r: Dictionary in runs:
					if r["persona"] != persona:
						continue
					for x: Dictionary in r["missions"]:
						if x["id"] == m.id and x["outcome"] == "completed":
							days.append(float(x["days"]))
				cells.append("%.1f (%d)" % [_mean(days), days.size()] if not days.is_empty() else "–")
			rows.append("| %s | %s | %s |" % [m.id, m.kind, " | ".join(cells)])
		rows.append("")
		rows.append("Cells: mean days from accept to completion (number of completed runs). Training days of a careless player are skipped.")
		return rows

	static func _check_table(runs: Array) -> PackedStringArray:
		var rows := PackedStringArray(["| persona | problem | try | cm | eff | passed | lesson | predicted | Δ predicted (fix) | KPI | Δ KPI (fix) | Δ KPI before→after | Δ capacity (fix) | flags |",
			"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"])
		for r: Dictionary in runs:
			if r["seed"] != runs[0]["seed"] or not r["persona"] in ["expert", "average"]:
				continue
			for c: Dictionary in r["checks"]:
				rows.append("| %s | %s | %d | %s | %.2f | %s | %s | %s | %+.1f %% | %s | %+.1f %% | %+.1f %% | %+.1f %% | %s |" % [r["persona"],
					c["problem"], c["attempt"], c["cm"], c["eff"], "yes" if c["passed"] else "no", c["lesson"], c["prediction"],
					100.0 * c["gains"][c["prediction"]], c["kpi"], 100.0 * c["gains"][c["kpi"]],
					100.0 * Persona.better_by(c["kpi"], c["before"], c["after"]), 100.0 * c["gains"]["capacity"], ", ".join(c["flags"])])
		rows.append("")
		var counts := PackedStringArray()
		for persona in PERSONAS:
			var all := []
			for r: Dictionary in runs:
				if r["persona"] == persona:
					all.append_array(r["checks"])
			if not all.is_empty():
				counts.append("%s %d of %d passed" % [persona, all.filter(func(c: Dictionary) -> bool: return c["passed"]).size(), all.size()])
		rows.append("Expert and average, first seed; Δ is the relative change, positive = better. (fix): the Check's own counterfactual, the coming lead time with against without the fix (Region.check's forecast); before→after: the two 14-day windows the Check panel still shows. All Checks (%s) are in the JSON." % "; ".join(counts))
		return rows

	## Main missions that open together (the same requirements): which one
	## each run took first, and what the first passed Check said.
	static func _fork_table(runs: Array, catalog: Catalog) -> PackedStringArray:
		var by_requires := {}
		for m in catalog.missions:
			if m.kind == "main":
				(by_requires.get_or_add(",".join(m.requires_missions), []) as Array).append(m)
		var rows := PackedStringArray(["| persona | seed | first taken | branch | at constraint | 'not the bottleneck' shown | Δ capacity |", "|---|---|---|---|---|---|---|"])
		for fork: Array in by_requires.values():
			if fork.size() < 2:
				continue
			for r: Dictionary in runs:
				var order: Array = (r["missions"] as Array).filter(func(x: Dictionary) -> bool:
					return fork.any(func(m: MissionDef) -> bool: return m.id == x["id"])).map(func(x: Dictionary) -> String: return x["id"])
				if order.is_empty():
					continue
				for m: MissionDef in fork:
					var first: Array = (r["checks"] as Array).filter(func(c: Dictionary) -> bool: return c["mission"] == m.id and c["passed"])
					if first.is_empty():
						continue
					var c: Dictionary = first[0]
					rows.append("| %s | %d | %s | %s | %s | %s | %+.1f %% |" % [r["persona"], r["seed"], order[0], m.id,
						"yes" if c["at_constraint"] else "no", "yes" if c["not_constraint"] else "no",
						100.0 * Persona.better_by("capacity", c["before"], c["after"])])
		rows.append("")
		rows.append("The design wants the non-bottleneck branch, taken first, to show 'not the bottleneck' at its Check.")
		return rows

	static func _coach_table(runs: Array) -> PackedStringArray:
		var rows := PackedStringArray(["| stage | asks (expert) | distinct lines | insights | most repeated line (missions) |", "|---|---|---|---|---|"])
		var stages := {}
		for r: Dictionary in runs:
			if r["persona"] != "expert":
				continue
			for c: Dictionary in r["coach"]:
				if c["mission_kind"] == "side":
					continue
				var st: Dictionary = stages.get_or_add(c["stage"], {"asks": 0, "insights": 0, "texts": {}})
				st["asks"] += 1
				if c["kind"] == "insight":
					st["insights"] += 1
				(st["texts"].get_or_add(c["text"], {}) as Dictionary)[c["mission"]] = true
		for stage: String in stages:
			var st: Dictionary = stages[stage]
			var top := ""
			for t: String in st["texts"]:
				if top.is_empty() or st["texts"][t].size() > st["texts"][top].size():
					top = t
			rows.append("| %s | %d | %d | %d | \"%s\" (%d) |" % [stage, st["asks"], st["texts"].size(), st["insights"], top, st["texts"][top].size()])
		return rows
