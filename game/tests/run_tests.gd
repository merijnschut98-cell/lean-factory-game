extends SceneTree
## Headless test runner. Finds every res://tests/test_*.gd (helpers live in
## tests/lib/, outside that pattern), runs each test_*
## method on a fresh instance, prints a summary and exits non-zero on failure.
##   godot --headless --path game --script res://tests/run_tests.gd
## Optional filter: append `-- <substring>` to run only matching test files
## (matched on the path: `-- /test_x.gd` is exactly one). The whole suite runs
## one file per process through tools/run_godot_tests.py. SPANNING_TEST_MEM=1
## prints memory and object counts after each file, SPANNING_TEST_TIMES=1 each
## test's time.

const TEST_DIR := "res://tests"


## Collects engine errors (e.g. a null access inside a test), which GDScript
## cannot catch: without this a test that crashes halfway would count as passed.
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


func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		filter = args[0]
	var files := _test_files(filter)
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var passed := 0
	var failed: PackedStringArray = []
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed.append("%s: could not load (syntax error?)" % path)
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var case: TestCase = script.new()
			catcher.take()
			var started := Time.get_ticks_msec()
			case.call(name)
			if OS.has_environment("SPANNING_TEST_TIMES"):
				print("[time] %6d ms %s::%s" % [Time.get_ticks_msec() - started, path.get_file(), name])
			# One frame, so what the test queue_free'd is deleted now (errors
			# while deleting count against it), not piled up until quit.
			await process_frame
			for err in catcher.take():
				if not case.is_expected_error(err):
					case.failures.append("runtime error: " + err)
			if case.failures.is_empty():
				passed += 1
			else:
				for f in case.failures:
					failed.append("%s::%s — %s" % [path.get_file(), name, f])
		if OS.has_environment("SPANNING_TEST_MEM"):
			print("[mem] %s static=%dMB objects=%d nodes=%d orphans=%d resources=%d" % [path.get_file(),
				OS.get_static_memory_usage() / 1048576, Performance.get_monitor(Performance.OBJECT_COUNT),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
				Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)])
	for line in failed:
		printerr("FAIL ", line)
	OS.remove_logger(catcher)
	print("%d passed, %d failed (%d files)" % [passed, failed.size(), files.size()])
	quit(1 if not failed.is_empty() or files.is_empty() else 0)


func _test_files(filter: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		var path := TEST_DIR.path_join(file)
		# Matched on the path, so `-- /test_x.gd` names exactly one file.
		if file.begins_with("test_") and file.ends_with(".gd") and (filter.is_empty() or filter in path):
			out.append(path)
	out.sort()
	return out
