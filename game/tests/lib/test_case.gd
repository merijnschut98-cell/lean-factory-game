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


## Deep equality for data that went through JSON: numbers compare by value
## (5 and 5.0 are equal), dictionaries by keys, arrays by order.
func assert_data_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	var difference := _data_difference(actual, expected, "")
	if not difference.is_empty():
		failures.append("%sdata differs at %s" % [_prefix(message), difference])


static func _data_difference(a: Variant, b: Variant, path: String) -> String:
	if (a is int or a is float) and (b is int or b is float):
		return "" if absf(float(a) - float(b)) <= 1e-9 * maxf(1.0, absf(float(b))) else "%s: %s vs %s" % [path, a, b]
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return "%s: keys %s vs %s" % [path, a.keys(), b.keys()]
		for k: Variant in b:
			if not a.has(k):
				return "%s: missing %s" % [path, k]
			var d := _data_difference(a[k], b[k], "%s.%s" % [path, k])
			if not d.is_empty():
				return d
		return ""
	if (a is Array or a is PackedStringArray) and (b is Array or b is PackedStringArray):
		if a.size() != b.size():
			return "%s: %d vs %d items" % [path, a.size(), b.size()]
		for i in b.size():
			var d := _data_difference(a[i], b[i], "%s[%d]" % [path, i])
			if not d.is_empty():
				return d
		return ""
	return "" if a == b else "%s: %s vs %s" % [path, a, b]
