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
## A persona that cannot get anywhere on a problem is helped by the expert's
## next step (logged as "assisted"), so one lost player does not end the
## campaign; a state no persona can leave is a dead end.
##
## It only plays through GameSession's actions; session.region and
## session.missions are read to decide and to measure (and Missions.abandon
## clears a mission nobody can finish: GameSession has no abandon action).

const PERSONAS: Array[String] = ["expert", "average", "careless"]
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

	var persona: String
	var seed_value: int
	## Stop once this many main missions are completed; -1: play the campaign out.
	var stop_after_main := -1
	var s: GameSession
	var record: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	var _runs: Dictionary = {}  # mission id → its open run record
	var _search: Dictionary = {}  # problem id → {actions, plan, next, barren: {pair: n}, dead: {pair: true}, assisted}
	var _tried: Dictionary = {}  # problem id → countermeasure ids tried
	var _coached: Dictionary = {}  # "mission|stage" → true
	var _refused: Dictionary = {}  # "mission|code" → true
	var _given_up: Dictionary = {}  # mission ids nobody can finish
	var _catcher := ErrorCatcher.new()
	var _doing := "new_game"  # the action running, to blame engine errors on
	var _audits: Array[String] = []
	var _sustain_tries: Dictionary = {}  # check-in mission id → audits done for it
	var _actions := 0
	var _last_sample := -INF

	func _init(persona_name: String, seed_number: int, stop_after_main_missions: int = -1) -> void:
		persona = persona_name
		seed_value = seed_number
		stop_after_main = stop_after_main_missions
		rng.seed = hash("%s:%d" % [persona_name, seed_number])

	## Play until the campaign ends, gets stuck or hits the horizon.
	func play() -> Dictionary:
		record = {"persona": persona, "seed": seed_value, "end": "", "days": 0.0, "completed": 0, "xp": 0,
			"budget": 0, "belt": "", "maturity": 0, "missions": [], "checks": [], "curve": [], "dead_ends": [],
			"assisted": [], "refusals": [], "coach": [], "bad_periods": [], "belts": [], "failed": [],
			"reopened": [], "kpi_reviews": [], "standardise_refused": [], "slipping": [], "audits": [], "errors": [], "actions": 0}
		OS.add_logger(_catcher)
		s = GameSession.new_game(seed_value, Catalog.DATA_DIR, persona != "careless")
		if not s.error.is_empty():
			_dead_end("content_error", "", s.error)
			record["end"] = "content_error"
			return record
		while (record["end"] as String).is_empty():
			_step()
			_blame_errors()
		_finish()
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
		for m: MissionDef in actives:
			_dead_end("no_action", m.id, "active, nothing to do and nothing to wait for (phase %s)" % _phase(m))
			_give_up(m)

	# ── Missions ────────────────────────────────────────────────────────────

	## The board, without the missions this run gave up on.
	func _open_missions() -> Array:
		return s.available_missions().filter(func(m: MissionDef) -> bool: return not _given_up.has(m.id))

	func _take_missions() -> void:
		var open := _open_missions()
		if persona != "expert":
			_shuffle(open)
		for m: MissionDef in open:
			if m.kind == "main" and s.missions.active("main").is_empty():
				_accept(m)
			elif m.kind == "side" and s.missions.active("side").size() < _side_slots():
				_accept(m)

	func _side_slots() -> int:
		return 2 if persona == "average" else Missions.MAX_SIDE

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
					if persona == "expert" or (persona == "average" and rng.randf() < 0.5):
						_audits.append(s.region.problems[e["problem"]].step)

	func _sample(force: bool = false) -> void:
		if not force and day() - _last_sample < SAMPLE_DAYS:
			return
		_last_sample = day()
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
		if not m.ends_with_talk.is_empty() and not s.people.talks.has(m.ends_with_talk):
			return _have_talk(m)
		match m.goal_type:
			"observe":
				return _observe(m)
			"walk":
				return _walk(m)
			"investigate":
				return _investigate_goal(m)
			"solve", "check":
				return _solve(m)
			"sustain":
				return _sustain(m)
		_dead_end("unknown_goal", m.id, m.goal_type)
		_give_up(m)
		return true

	## The day ends with a talk: have it (the persona says hello and goes).
	func _have_talk(m: MissionDef) -> bool:
		var opened := s.start_dialog(s.people.dialogs[m.ends_with_talk].person)
		if opened.get("dialog") != m.ends_with_talk:
			if not opened.has("error"):
				s.end_dialog()
			_dead_end("talk_unavailable", m.id, "%s: %s" % [m.ends_with_talk, opened.get("error", opened.get("dialog"))])
			_give_up(m)
			return true
		s.end_dialog()
		return true

	func _observe(m: MissionDef) -> bool:
		var seen: Dictionary = s.missions.progress[m.id]["seen"]
		var tools: Array[String] = OBSERVE_TOOLS
		if not m.goal_tool.is_empty():
			tools = [m.goal_tool]
		for place in m.goal_places:
			if not seen.keys().any(func(k: String) -> bool: return k.get_slice("|", 0) == place):
				return _use(m, place, tools[0])
		for tool in tools:
			for place in m.goal_places:
				if not seen.has(place + "|" + tool):
					return _use(m, place, tool)
		_dead_end("observe_exhausted", m.id, "every place and tool used, goal not met")
		_give_up(m)
		return true

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
				return _use(m, place, "shadow")
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
		if sr["actions"] < MAX_SEARCH or persona == "expert":
			var acted := false
			match persona:
				"expert":
					acted = _expert_step(m, p)
				"average":
					acted = _average_step(m, p)
				_:
					acted = _careless_step(m, p)
			if acted:
				return true
		if persona == "expert" or not allow_help:
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
		match persona:
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
			if not sr["dead"].has(pair[0] + "|" + pair[1]):
				return _use(m, pair[0], pair[1], p)
		return false

	func _careless_step(m: MissionDef, p: ProblemDef) -> bool:
		var places := _stream_places(p, false)
		var place: String = p.step if rng.randf() < 0.5 else places[rng.randi() % places.size()]
		var tools := Investigation.TOOLS.keys()
		return _use(m, place, tools[rng.randi() % tools.size()], p)

	## Use a tool (or, for "conversation", ask a question) at a place.
	func _use(m: MissionDef, place: String, tool: String, p: ProblemDef = null) -> bool:
		var before_time := s.region.net.time
		var before_found := s.region.found.size()
		var before_phase := s.phase_of(p.id) if p != null else ""
		var result: Dictionary
		_doing = "%s at %s (mission %s)" % [tool, place, m.id]
		if tool == "conversation":
			var questions := Investigation.QUESTIONS.keys()
			result = s.ask(place, questions[rng.randi() % questions.size()] if persona == "careless" else "walk")
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
		var available := s.countermeasures()
		var fitting := available.filter(func(c: CountermeasureDef) -> bool: return p.countermeasures.has(c.id))
		fitting.sort_custom(func(a: CountermeasureDef, b: CountermeasureDef) -> bool: return a.budget < b.budget)
		var tried: Array = _tried.get(p.id, [])
		var a3 := {"waste": p.waste, "cause": correct, "evidence": keys if not keys.is_empty() else found,
			"cm": _best_cm(p, available), "prediction": p.kpi}
		match persona:
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
		var want := persona == "expert" or (persona == "average" and rng.randf() < 0.5)
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
		if persona == "careless":
			return
		var stage := s.missions.stage_of(m)
		var key := m.id + "|" + stage
		if _coached.has(key):
			return
		_coached[key] = true
		for i in (3 if persona == "expert" else 1):
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
				if c["mission_kind"] != "side" and not (c["stage"] as String).is_empty():
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
		md.append("Personas: **expert** does the training week, takes missions in content order, finds the key clues with the tools that reveal them, writes the right A3 with the best-fitting countermeasure, standardises. **average** searches tool by tool at the step and its neighbours, names a wrong cause (with a countermeasure for it) first 40 % of the time, picks the cheapest fitting countermeasure, standardises half the time. **careless** skips the training week, plays random tools, questions (blame included) and A3 choices, reads the mismatch note after 3 failed Checks and follows the coach after 5, never standardises. A lost persona gets the expert's next step (\"assisted\").")
		md.append("")
		var by_severity := PackedStringArray()
		for sev in SEVERITIES:
			by_severity.append("%d %s" % [(report["findings"] as Array).filter(func(f: Dictionary) -> bool: return f["severity"] == sev).size(), sev])
		md.append("**Summary:** %s. Expert and average reach the end of the campaign without a dead end: %s." % [", ".join(by_severity),
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
			"`abandon(mission_id)`: Missions.abandon exists but the facade has no action; a stuck player cannot drop a mission.",
			"`kpi_review(choices)` and `kpi_review_due()`: Region.kpi_review is not reachable through GameSession, so the quarterly review (and its large reward, KpiBoard.REVIEW_XP/REVIEW_BUDGET) is not played here.",
			"`mission_status(id)` / `mission_progress(id)`: the board needs status, deadline left (opened_at + deadline_days) and observe progress without reaching into session.missions.",
			"`stage_of(mission_id)`: the coach's stage, for a UI hint and for tests.",
			"`problem(id)` / `key_clues_found(id)`: the problem's definition and found key clues are read through session.region.",
			"`wait(minutes)` / `next_day()`: time only passes through tools and Checks; with every mission waiting on a fade or nothing active the player cannot let time pass.",
			"`act()` returning why standardising was refused (budget below Region.STANDARDISE_BUDGET is dropped silently).",
		]:
			md.append("- " + line)
		md.append("")
		return "\n".join(md)

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
			if r["seed"] != runs[0]["seed"] or r["persona"] == "careless":
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
