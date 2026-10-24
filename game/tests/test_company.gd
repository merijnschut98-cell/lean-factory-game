extends TestCase
## The company file (phase-2 design §1.6, S1-E): one source for titles, and the name
## tags read them.


func test_titles_come_from_the_company_file() -> void:
	assert_eq(Company.title("joost"), "teamleider Werkvoorbereiding")
	assert_eq(Company.title("anouk"), "werkvoorbereider")
	assert_eq(Company.title("ruud"), "Directeur Netbeheer regio Zuidmark", "a department's head")
	assert_eq(Company.title("gert"), "uitvoerder, Grondwerk Peeters", "an external")
	assert_eq(Company.title("nobody", "x"), "x", "unknown: the caller's own text")


func test_a_broken_company_file_leaves_the_fallback() -> void:
	assert_eq(Company.titles_from({"data": {}, "error": "cannot read"}), {})
	assert_eq(Company.titles_from({"data": {"departments": "nonsense"}, "error": ""}), {})


func test_every_cast_title_agrees_with_the_company_file() -> void:
	for entry: Dictionary in CharacterModel.cast():
		if entry.get("id") != "player":
			assert_eq(Company.title(entry["id"]), str(entry.get("role", "")), entry["id"])


func test_wie_is_wie_names_each_departments_head() -> void:
	assert_eq(Company.name_of({"id": "frank", "title": "manager"}), "Frank Hulshof", "a head in the cast, by name")
	assert_eq(Company.name_of({"name": "Karin Hoekman", "title": "teamleider"}), "Karin Hoekman", "a head named here")
	assert_eq(Company.name_of(null), "")
	assert_eq(Company.name_of("head"), "", "a team its head leads")
	var heads: Array = Company.doc()["departments"].map(func(d: Dictionary) -> String: return Company.name_of(d["head"]))
	assert_false(heads.has(""), "every department has a head to show: %s" % [heads])


func test_the_name_tag_reads_the_company_title() -> void:
	var entry: Dictionary = CharacterModel.cast().filter(func(e: Dictionary) -> bool: return e["id"] == "anouk")[0]
	var p := OfficePerson.create(entry.merged({"role": "iets anders"}, true))
	assert_eq(p.role, "werkvoorbereider", "the company file wins over a stale role")
	assert_true(p.tag.text.ends_with("\nwerkvoorbereider"), p.tag.text)
	p.free()


func test_a_person_has_a_place_and_a_manager() -> void:
	assert_eq(Company.person("anouk")["manager"], "Joost van Dijk")
	assert_eq(Company.place_line("anouk"), "Werkvoorbereiding · Aansluitingen & Netverzwaring · leidinggevende: Joost van Dijk")
	assert_eq(Company.place_line("joost"), "Aansluitingen & Netverzwaring · leidinggevende: Frank Hulshof",
		"the title already names his team")
	assert_eq(Company.place_line("esra"), "Klantcontactcentrum · leidinggevende: Ruud Hoekstra",
		"a head: the department once, and whom they report to")
	assert_eq(Company.place_line("ruud"), "Directie regio Zuidmark", "the directeur: no one above in the region")
	assert_eq(Company.place_line("gert"), "", "an external: the title says it")
	assert_eq(Company.place_line("nobody"), "")
	assert_eq(Company.place_line_of({"department": 3}), "3", "a wrong type is still text, never a crash")


func test_every_cast_member_has_a_department_and_a_manager() -> void:
	for entry: Dictionary in CharacterModel.cast():
		var id: String = entry["id"]
		var p := Company.person(id)
		assert_false(p.is_empty(), id)
		if p.has("organisation"):
			continue
		assert_false(str(p["department"]).is_empty(), id)
		assert_true(id == "ruud" or not str(p["manager"]).is_empty(), id)


func test_numbers_read_as_dutch() -> void:
	assert_eq(Company.number_text(15498), "15.498")
	assert_eq(Company.number_text(707000), "707.000")
	assert_eq(Company.number_text(18), "18")
	assert_eq(Company.number_text(1000000), "1.000.000")


func test_wie_is_wie_shows_each_team_with_its_headcount_and_lead() -> void:
	var app := PeopleApp.new()
	app.session = GameSession.new_game(11, Catalog.DATA_DIR, false)
	var box := VBoxContainer.new()
	app._list = box
	app._org_chart()
	var text := "\n".join(_labels(box))
	assert_true(text.contains("Werkvoorbereiding (4) · Joost van Dijk"), "a team: its headcount and its lead")
	assert_true(text.contains("Projecten netverzwaring (3) · Bas Willems"), "a lead named in the company file")
	assert_true(text.contains("• Planning (2)\n"), "a team its head leads: no second name")
	box.free()
	app.free()


func test_the_codex_has_a_company_page() -> void:
	var codex := CodexPanel.new()
	codex.session = GameSession.new_game(11, Catalog.DATA_DIR, false)
	codex.show_tab(CodexPanel.COMPANY)
	var text := "\n".join(codex.shown_texts())
	assert_true(text.contains("Hoofdgebouw Nova"), "the sites")
	assert_true(text.contains("Voltana Vooruit (2012)"), "the 2012 programme")
	assert_true(text.contains("15.498 aanvragen"), "a number in Dutch, with its unit")
	assert_true(text.contains("Bron: CBS, Monitor Warmtepompen 2025"), "a number's source")
	assert_true(text.contains("Schatting: "), "an estimate says it is one")
	assert_false(text.contains("heard:"), "who led 2012 is for the talks, never the page")
	codex.free()


func _labels(root: Node) -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label:
			out.append(n.text)
		stack.append_array(n.get_children())
	return out
