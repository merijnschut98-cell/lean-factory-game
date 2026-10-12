extends SceneTree
## Headless test runner. Finds every res://tests/test_*.gd, runs each test_*
## method on a fresh instance, prints a summary and exits non-zero on failure.
##   godot --headless --path game --script res://tests/run_tests.gd
## Optional filter: append `-- <substring>` to run only matching test files.

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
			case.call(name)
			for err in catcher.take():
				case.failures.append("runtime error: " + err)
			if case.failures.is_empty():
				passed += 1
			else:
				for f in case.failures:
					failed.append("%s::%s — %s" % [path.get_file(), name, f])
	for line in failed:
		printerr("FAIL ", line)
	OS.remove_logger(catcher)
	print("%d passed, %d failed (%d files)" % [passed, failed.size(), files.size()])
	quit(1 if not failed.is_empty() or files.is_empty() else 0)


func _test_files(filter: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd" and (filter.is_empty() or filter in file):
			out.append(TEST_DIR.path_join(file))
	out.sort()
	return out
