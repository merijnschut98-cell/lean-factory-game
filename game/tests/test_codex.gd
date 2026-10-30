extends TestCase
## The codex (K): the glossary in the game. Learned concepts are readable,
## the others are only counted under their category; learning one toasts once.

const SCENE := "res://src/world/office/office.tscn"


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false  # a returning player: straight to the campaign
	office.build()
	return office


func _text(office: Office) -> String:
	return "\n".join(office.ui.codex.shown_texts())


func test_k_opens_and_closes_the_codex() -> void:
	var office := _office()
	office.player.phone_pressed.emit(Phone.CODEX)
	assert_true(office.ui.phone.visible and office.ui.phone.current == Phone.CODEX, "K opens it on the phone")
	assert_true(office.ui.is_busy())
	office.player.phone_pressed.emit(Phone.CODEX)
	assert_false(office.ui.phone.visible, "K lowers it")
	office.free()


func test_a_learned_concept_is_readable_and_an_unlearned_one_is_not() -> void:
	var office := _office()
	var concepts := office.session.catalog.concepts
	var kata: ConceptDef = concepts["PDCA"]
	var other: ConceptDef = concepts["flow"]
	office.session.region.profile.learn(["PDCA"])
	office.ui.toggle_phone(Phone.CODEX)
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
	office.ui.toggle_phone(Phone.CODEX)
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
	var estimated := ConceptDef.new()  # the glossary may have no estimates left once all are sourced
	estimated.estimate = "aanname"
	assert_true(CodexPanel.source_line(estimated).begins_with("Schatting: "))
	assert_eq(CodexPanel.source_line(c.concepts["PDCA"]), "", "lean entries need no source")


## A concept learned badges Begrippen on the phone once (no toast over the world).
func test_a_new_concept_badges_begrippen_once() -> void:
	var office := _office()
	var profile := office.session.region.profile
	var before := office.ui.phone.badge(Phone.CODEX)
	var buzzes := {"n": 0}
	office.ui.phone.buzz.connect(func() -> void: buzzes["n"] += 1)
	profile.learn(["PDCA"])
	office.ui.after_action()
	office.ui.after_action()
	assert_eq(office.ui.phone.badge(Phone.CODEX), before + 1, "one more on the badge")
	assert_eq(buzzes["n"], 1, "one buzz")
	assert_false(office.ui.hud.toast_texts().any(func(t: String) -> bool: return t.begins_with("Nieuw begrip")), "no toast")
	office.ui.toggle_phone(Phone.CODEX)
	assert_eq(office.ui.phone.badge(Phone.CODEX), 0, "seen once opened")
	office.free()


func test_the_controls_hint_names_the_phone() -> void:
	var hud := Hud.new()
	assert_true(hud.controls_text().contains("Tab telefoon"))
	hud.free()
