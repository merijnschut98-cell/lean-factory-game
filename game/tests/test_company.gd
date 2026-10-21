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
	var app := PeopleApp.new()
	app.session = GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(app._head_name({"id": "frank", "title": "manager"}), "Frank Hulshof", "a head in the cast, by name")
	assert_eq(app._head_name({"name": "Ingrid Bos", "title": "assetmanager"}), "Ingrid Bos", "a head named here")
	assert_eq(app._head_name(null), "")
	var heads: Array = app.company()["departments"].map(func(d: Dictionary) -> String: return app._head_name(d["head"]))
	assert_false(heads.has(""), "every department has a head to show: %s" % [heads])
	app.free()


func test_the_name_tag_reads_the_company_title() -> void:
	var entry: Dictionary = CharacterModel.cast().filter(func(e: Dictionary) -> bool: return e["id"] == "anouk")[0]
	var p := OfficePerson.create(entry.merged({"role": "iets anders"}, true))
	assert_eq(p.role, "werkvoorbereider", "the company file wins over a stale role")
	assert_true(p.tag.text.ends_with("\nwerkvoorbereider"), p.tag.text)
	p.free()
