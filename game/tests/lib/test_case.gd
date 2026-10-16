class_name TestCase
extends RefCounted
## Base class for headless logic tests. Subclass it in tests/test_*.gd and add
## methods named test_*. The runner (tests/run_tests.gd) calls each one on a
## fresh instance and reports every failed assertion with its message.

var failures: PackedStringArray = []


## A path under user:// that is this test run's own: every worktree's run
## shares user://, so a fixed name lets one run overwrite or delete another's
## file mid-test.
static func scratch(file_name: String) -> String:
	return "user://test_%d_%s" % [OS.get_process_id(), file_name.replace("/", "_")]


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%sexpected %s, got %s" % [_prefix(message), var_to_str(expected), var_to_str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if actual == unexpected:
		failures.append("%sdid not expect %s" % [_prefix(message), var_to_str(actual)])


func assert_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%sexpected %s ± %s, got %s" % [_prefix(message), expected, tolerance, actual])


func assert_between(actual: float, low: float, high: float, message: String = "") -> void:
	if actual < low or actual > high:
		failures.append("%sexpected %s in [%s, %s]" % [_prefix(message), actual, low, high])


## Every text under `root` (a panel), nested labels and buttons included.
func texts_in(root: Node) -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label or n is Button:
			out.append(n.text)
		stack.append_array(n.get_children())
	return out


## Whether any text under `root` contains `part`.
func shows(root: Node, part: String) -> bool:
	return texts_in(root).any(func(t: String) -> bool: return t.contains(part))


func _prefix(message: String) -> String:
	return "" if message.is_empty() else message + ": "

