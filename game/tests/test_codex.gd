extends TestCase
## The codex (K): the glossary in the game. Learned concepts are readable,
## the others are only counted under their category; learning one toasts once.

const SCENE := "res://src/world/office/office.tscn"


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.build()
	return office


func _text(office: Office) -> String:
	return "\n".join(office.ui.codex.shown_texts())


func test_k_opens_and_closes_the_codex() -> void:
	var office := _office()
	office.player.codex_pressed.emit()
	assert_true(office.ui.codex.visible, "K opens it")
	assert_true(office.ui.is_busy())
	office.player.codex_pressed.emit()
	assert_false(office.ui.codex.visible, "K closes it")
	office.free()


func test_a_learned_concept_is_readable_and_an_unlearned_one_is_not() -> void:
	var office := _office()
	var concepts := office.session.catalog.concepts
	var kata: ConceptDef = concepts["PDCA"]
	var other: ConceptDef = concepts["flow"]
	office.session.region.profile.learn(["PDCA"])
	office.ui.toggle_codex()
	var text := _text(office)
	for part in [kata.name, kata.short, kata.text, kata.example]:
		assert_true(text.contains(part), part)
	assert_false(text.contains(other.name), "unlearned: no name")
	assert_false(text.contains(other.text), "unlearned: no text")
	assert_false(text.contains("???"), "no ??? grid")
	assert_true(text.contains("Nog te ontdekken: "), "unlearned ones are only counted")
	office.free()


func test_a_category_counts_what_is_left() -> void:
	var office := _office()
	office.session.region.profile.learn(["PDCA"])
	office.ui.toggle_codex()
	var groups := CodexPanel.groups(office.session.catalog.concepts, office.session.region.profile.concepts)
	var left: int = groups[0]["entries"].size() - 1
	assert_true(office.ui.codex.shown_texts().has(CodexPanel.undiscovered_line(left)), "lean: count of the rest")
	assert_eq(CodexPanel.undiscovered_line(1), "Nog te ontdekken: 1 begrip")
	office.free()


func test_groups_follow_the_categories_and_count_what_is_known() -> void:
	var c := Catalog.load_from()
	var groups := CodexPanel.groups(c.concepts, PackedStringArray(["PDCA"]))
	assert_eq(groups.map(func(g: Dictionary) -> String: return g["title"]),
		["Lean", "Kata", "Meten", "Energiesector"])
	var total := 0
	for g in groups:
		total += g["entries"].size()
	assert_eq(total, c.concepts.size(), "every concept sits in a group")
	assert_eq(groups[0]["known"], 1)


func test_sources_and_estimates_are_shown_for_sector_entries() -> void:
	var c := Catalog.load_from()
	var sourced: ConceptDef = c.concepts["netbeheerder"]
	assert_true(CodexPanel.source_line(sourced).begins_with("Bron: "), "a source")
	assert_true(CodexPanel.source_line(sourced).contains(sourced.source_title))
	var estimated := c.concepts.values().filter(func(x: ConceptDef) -> bool: return not x.estimate.is_empty())
	assert_false(estimated.is_empty(), "the glossary has an estimate")
	assert_true(CodexPanel.source_line(estimated[0]).begins_with("Schatting: "))
	assert_eq(CodexPanel.source_line(c.concepts["PDCA"]), "", "lean entries need no source")


func test_a_new_concept_toasts_once() -> void:
	var office := _office()
	var profile := office.session.region.profile
	var name: String = office.session.catalog.concepts["PDCA"].name
	profile.learn(["PDCA"])
	office.ui.after_action()
	office.ui.after_action()
	var toasts := office.ui.hud.toast_texts().filter(func(t: String) -> bool: return t.begins_with("Nieuw begrip"))
	assert_eq(toasts, ["Nieuw begrip: %s (K)" % name])
	profile.learn(["PDCA"])
	office.ui.after_action()
	assert_eq(office.ui.hud.toast_texts().size(), 1, "known concepts do not toast again")
	office.free()


func test_the_controls_hint_names_k() -> void:
	var hud := Hud.new()
	assert_true(hud.controls_text().contains("K begrippen"))
	hud.free()
