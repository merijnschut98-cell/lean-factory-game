extends TestCase
## Where "Hoe werkt het? 2: de transformator" lives in the world (spec 2026-10-24-
## explainer-transformator §6): the trafohuisje mock-up on the opleidingsterrein, once
## that is open, opens it with Ruud's beats; Femke's topic about the middenspanningsruimte
## opens it the codex's way over her talk.

const SCENE := "res://src/world/office/office.tscn"


func _office() -> Office:
	var office: Office = load(SCENE).instantiate()
	office.seed_value = 11
	office.training = false
	office.build()
	return office


func _on_yard(office: Office, missions: Array[String]) -> void:
	for m in missions:
		office.session.missions.progress[m] = {"status": "active", "asks": {}, "seen": {}}
	office.floors.go_to("yard", "exit", true)


func test_the_trafohuisje_waits_for_the_opleidingsterrein() -> void:
	var office := _office()
	_on_yard(office, ["fix_wrong_joint"])
	assert_eq(office.interactable(OfficeTrafohuisje.ID), null, "the ground is still shut")
	office.free()


func test_at_the_trafohuisje_ruud_explains_the_transformer() -> void:
	var office := _office()
	_on_yard(office, ["save_henks_knowledge"])
	var at := office.interactable(OfficeTrafohuisje.ID)
	assert_true(at != null, "a place at the mock-up's doors")
	if at == null:
		office.free()
		return
	var ground := OfficeFloors.room_rect(office.floors.markers()["room:opleidingsterrein"])
	assert_true(ground.has_point(Vector2(at.position.x, at.position.z)), "on the opleidingsterrein")
	assert_eq(office.prompt_for(at), tr(OfficeTrafohuisje.PROMPT))
	assert_true(office.prompt_for(at).contains("hoe werkt een trafo?"))
	office.interact(at)
	assert_true(office.explainer != null, "the explainer opens")
	assert_eq(office.explainer.def.id, OfficeTrafohuisje.EXPLAINER)
	assert_true(office.explainer.beats != null and office.explainer.def.speaker == "Ruud", "with Ruud's beats")
	assert_true(office.busy(), "the world waits")
	office.explainer.close()
	assert_eq(office.explainer, null, "closing gives the world back")
	assert_true(office.session.explainers.has_seen(OfficeTrafohuisje.EXPLAINER), "filed in the codex")
	office.free()


func test_femkes_topic_about_the_msr_opens_it() -> void:
	var read := JsonFile.read_dict("res://data/dialogs.json")
	var found := {}
	for d: Dictionary in read["data"]["dialogs"]:
		if d["id"] == "femke_expert":
			for t: Dictionary in d["topics"]:
				if t["id"] == "msr":
					found = t
	assert_eq(found.get("unlocks", {}).get("explainer", ""), OfficeTrafohuisje.EXPLAINER)
	var office := _office()
	office.open_talk_explainer(OfficeTrafohuisje.EXPLAINER)
	assert_true(office.explainer != null and office.explainer.codex, "over her talk, the codex's way")
	office.explainer.close()
	office.free()
