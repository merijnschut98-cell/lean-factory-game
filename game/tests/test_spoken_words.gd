extends TestCase
## No spoken line names the game (PLAN 2.13 E; style guide
## docs/superpowers/specs/2026-10-19-dutch-style-guide.md §4). The content
## build checks the YAML; this scans the string constants of the opening scene
## and its line box, with the build's banned list from vocabulary.json.

const SCRIPTS := ["res://src/world/office/office_opening.gd", "res://src/ui/scene_lines.gd"]


func _banned() -> Dictionary:
	return JsonFile.read_dict("res://data/vocabulary.json")["data"]["banned_spoken"]


## The first banned word in `text` (whole words, outside {tokens}, the allowed idioms removed), or "".
static func banned_word(text: String, banned: Dictionary) -> String:
	var low := RegEx.create_from_string("\\{[^{}]*\\}").sub(text.to_lower(), " ", true)
	for phrase: String in banned["allowed"]:
		low = low.replace(phrase, " ")
	var words := RegEx.create_from_string("\\b(" + "|".join(PackedStringArray(banned["words"])) + ")\\b")
	var hit := words.search(low)
	return hit.get_string(1) if hit != null else ""


## Every string inside a constant (nested arrays and dictionaries included).
static func strings_in(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is String:
		out.append(value)
	elif value is Array:
		for v: Variant in value:
			out.append_array(strings_in(v))
	elif value is Dictionary:
		for v: Variant in value.values():
			out.append_array(strings_in(v))
	return out


func test_the_scan_finds_whole_words_only() -> void:
	var banned := _banned()
	assert_eq(banned_word("Weet je waarom dit spel… sorry.", banned), "spel")
	assert_eq(banned_word("Je eerste MISSIE.", banned), "missie")
	assert_eq(banned_word("Pak de andere haspel.", banned), "")
	assert_eq(banned_word("Er staat veel op het spel.", banned), "")
	assert_eq(banned_word("Vertel het {haar_hem_speler} maar, {speler}.", banned), "")


func test_the_opening_and_its_line_box_never_name_the_game() -> void:
	var banned := _banned()
	for path: String in SCRIPTS:
		var consts: Dictionary = (load(path) as Script).get_script_constant_map()
		assert_true(not consts.is_empty(), path)
		for name: String in consts:
			for text in strings_in(consts[name]):
				assert_eq(banned_word(text, banned), "", "%s %s: %s" % [path.get_file(), name, text])
