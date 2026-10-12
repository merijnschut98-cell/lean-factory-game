class_name TestCase
extends RefCounted
## Base class for headless logic tests. Subclass it in tests/test_*.gd and add
## methods named test_*. The runner (tests/run_tests.gd) calls each one on a
## fresh instance and reports every failed assertion with its message.

var failures: PackedStringArray = []


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


func _prefix(message: String) -> String:
	return "" if message.is_empty() else message + ": "

