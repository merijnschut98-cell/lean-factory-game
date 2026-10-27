extends TestCase
## The player made in the character creator (PLAN 2.7b; spec
## 2026-10-16-creator-and-minimap §1.4–§1.7, tests §4.1 2–4, 10, 11): the
## first name's validator, the tokens in dialog text, the portrait's checks
## and the look, name and portrait in the save (validated on load, an old
## save gets the default look).

const PNG_SIZE := PlayerProfile.PORTRAIT_SIZE

var dir := TestCase.scratch("profile_saves")


func _cleanup() -> void:
	SaveSlots.new(dir).wipe()
	DirAccess.remove_absolute(dir)


## A PNG of `size` (the portrait's by default).
static func _png(size := PNG_SIZE) -> PackedByteArray:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	image.fill(Color(0.6, 0.62, 0.65))
	return image.save_png_to_buffer()


static func _profile(name := "Sanne", body := "vrouw") -> PlayerProfile:
	var p := PlayerProfile.new()
	p.name = name
	p.look = CreatorLook.normalized({"lichaam": body, "kapsel": "lob", "haarkleur": "koperrood", "bril": "groot_rond"})
	return p


# ── The first name (§1.4; §4.1 test 2) ─────────────────────────────────────

func test_names_that_are_accepted_as_typed() -> void:
	for name: String in ["Sanne", "Jan-Willem", "Anne Marie", "D'Angelo", "Şeyma", "Zoë", "Bo", "Maximiliaan"]:
		assert_eq(PlayerProfile.clean_name(name), name, name)


func test_names_are_normalised_on_confirm() -> void:
	assert_eq(PlayerProfile.clean_name("  jan  "), "Jan")
	assert_eq(PlayerProfile.clean_name("anne  marie"), "Anne marie")
	assert_eq(PlayerProfile.clean_name("deVries"), "deVries", "the player's own casing stands")
	assert_eq(PlayerProfile.clean_name("D’Angelo"), "D'Angelo", "the typographic apostrophe")
	assert_eq(PlayerProfile.clean_name("Jan  "), "Jan", "trailing spaces are trimmed")


func test_names_that_are_refused() -> void:
	var refused: Array[String] = ["", "   ", "Abcdefghijklmnopq", "R2D2", "{speler}", "[b]Jan[/b]", "-Jan", "Jan-",
		"Jan--Piet", "Jan\nPiet", "Jan\tPiet", "😀", "Jan" + char(0x202E) + "naJ", "Jan!", "Jan_Piet"]
	for name in refused:
		assert_eq(PlayerProfile.clean_name(name), "", "refused: %s" % name.c_escape())
	assert_eq(PlayerProfile.clean_name("Abcdefghijklmnop"), "Abcdefghijklmnop", "16 letters fit")


func test_typing_drops_what_can_never_be_in_a_name_and_stops_at_sixteen() -> void:
	assert_eq(PlayerProfile.typed("Jan{2}[b]"), "Janb")
	assert_eq(PlayerProfile.typed("D’Ang"), "D'Ang")
	assert_eq(PlayerProfile.typed("Jan-"), "Jan-", "a hyphen may be typed before the next letter")
	assert_eq(PlayerProfile.typed("Abcdefghijklmnopqrst").length(), PlayerProfile.MAX_NAME)
	assert_eq(PlayerProfile.typed("Zo" + char(0x202E) + "ë😀"), "Zoë")


# ── Tokens (§1.6; §4.1 tests 3–4) ──────────────────────────────────────────

func test_the_pronoun_follows_the_body() -> void:
	var line := "{speler}: {hij_zij}, {Zij_Hij_speler}, {haar_hem_speler}, {jongen_meid}."
	assert_eq(_profile("Bo", "man").fill(line), "Bo: hij, Hij, hem, jongen.")
	assert_eq(_profile("Bo", "vrouw").fill(line), "Bo: zij, Zij, haar, meid.")
	var p := _profile("Bo", "vrouw")
	p.look["lichaam"] = "man"
	assert_eq(p.fill("{hij_zij}"), "hij", "a body change changes the next line rendered")


func test_tokens_fill_in_one_pass_and_unknown_tokens_stay() -> void:
	var p := _profile("Hij", "vrouw")
	assert_eq(p.fill("{speler} zegt dat {hij_zij} komt."), "Hij zegt dat zij komt.")
	assert_eq(p.fill("{dossier_weken} en {onbekend}"), "{dossier_weken} en {onbekend}", "not ours: left alone")
	assert_eq(p.fill("{speler"), "{speler")
	assert_eq(p.fill(""), "")


## A player without a name is never greeted by a job title (UX audit #1): a greeting drops
## the name with its comma, and elsewhere a colleague says "de nieuwe".
func test_a_nameless_player_is_greeted_without_a_name() -> void:
	var p := PlayerProfile.new()
	assert_eq(p.fill("O, hoi {speler}!"), "O, hoi!")
	assert_eq(p.fill("Hoi {speler}, ik ben Ruud."), "Hoi, ik ben Ruud.")
	assert_eq(p.fill("Goedendag, {speler}. Veertig jaar."), "Goedendag. Veertig jaar.")
	assert_eq(p.fill("Hé {speler}. Zoek je wat?"), "Hé. Zoek je wat?")
	assert_eq(p.fill("Nou, daar is {speler}."), "Nou, daar is de nieuwe.")
	assert_eq(p.fill("Goedemorgen! Jij bent {speler}, toch?"), "Goedemorgen! Jij bent de nieuwe, toch?")
	assert_eq(p.fill("Beste {speler},\n\nDank u."), "Beste collega,\n\nDank u.", "a letter: never a bare Beste")
	assert_eq(p.fill("{hij_zij}"), "hij", "the default look's body")
	assert_eq(_profile("Bo").fill("Hoi {speler}, ik ben Ruud."), "Hoi Bo, ik ben Ruud.", "a name stays")


## Every line in the content that names the player still reads as Dutch without a name.
func test_no_content_line_says_the_job_title_for_a_nameless_player() -> void:
	var p := PlayerProfile.new()
	var bad := RegEx.create_from_string("CI-lead|\\{speler\\}| [,.!?]|^[,.!? ]|(?i)beste,")
	var checked := 0
	for file: String in ["dialogs.json", "missions.json"]:
		var text := FileAccess.get_file_as_string(Catalog.DATA_DIR.path_join(file))
		for line: String in text.split("\n"):
			if line.contains("{speler}"):
				checked += 1
				var said := p.fill(line.strip_edges())
				assert_true(bad.search(said) == null, said)
	assert_true(checked > 50, "the greetings were found (%d)" % checked)


func test_fill_all_reaches_every_string_in_a_result() -> void:
	var p := _profile("Sanne", "vrouw")
	var filled: Variant = p.fill_all({"a": "Hoi {speler}", "b": ["{hij_zij}", 3, {"c": "{jongen_meid}"}], "n": 4})
	assert_eq(filled, {"a": "Hoi Sanne", "b": ["zij", 3, {"c": "meid"}], "n": 4})


func test_dialog_text_and_briefings_carry_the_players_name() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.missions.done_once["fix_unused_capacity"] = true
	assert_eq(s.accept("fix_silo_kpis"), "")
	s.region.found["silo_kpis:4"] = true
	s.player = _profile("Sanne", "vrouw")
	for d: DialogDef in s.people.dialogs.values():
		if d.person == "joost":
			d.opening = "Hoi {speler}. Ze zei dat {hij_zij} kwam."
	var opened := s.start_dialog("joost")
	assert_eq(opened.get("opening"), "Hoi Sanne. Ze zei dat zij kwam.")
	s.missions.defs["fix_silo_kpis"].briefing = "{speler}, de {jongen_meid} van {dossier_weken}."
	assert_false(s.mission_briefing("fix_silo_kpis").contains("{"), s.mission_briefing("fix_silo_kpis"))
	assert_true(s.mission_briefing("fix_silo_kpis").begins_with("Sanne, de meid van "))


# ── The portrait (§1.7; §4.1 test 10) ──────────────────────────────────────

func test_a_portrait_must_be_a_small_png_of_the_passport_size() -> void:
	assert_eq(PlayerProfile.valid_portrait(_png()), _png())
	assert_eq(PlayerProfile.valid_portrait(_png(Vector2i(100, 100))), PackedByteArray(), "the wrong size")
	assert_eq(PlayerProfile.valid_portrait("not bytes"), PackedByteArray())
	assert_eq(PlayerProfile.valid_portrait(PackedByteArray([1, 2, 3])), PackedByteArray(), "not a PNG")
	var big := _png()
	big.resize(PlayerProfile.PORTRAIT_MAX_BYTES + 1)
	assert_eq(PlayerProfile.valid_portrait(big), PackedByteArray(), "over 256 KB")
	assert_eq(PlayerProfile.valid_portrait(null), PackedByteArray())


func test_headless_the_photo_is_the_placeholder() -> void:
	assert_false(PortraitPhoto.can_render(), "no renderer in the headless tests")


# ── The save (§4.1 tests 10–11) ────────────────────────────────────────────

func test_look_name_and_portrait_round_trip_through_a_save() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.player = _profile("Şeyma", "vrouw")
	s.player.portrait = _png()
	var slots := SaveSlots.new(dir)
	assert_eq(slots.save(2, s, SessionLayer.new()), "")
	var back: GameSession = slots.resume("slot_2")["session"]
	assert_eq(back.player.name, "Şeyma")
	assert_eq(back.player.look, s.player.look)
	assert_eq(back.player.portrait, _png())
	var e := slots.entry("slot_2")
	assert_eq(e["name"], "Şeyma", "the card's name")
	assert_eq(e["portrait"], _png(), "the card's portrait, without loading the game")
	_cleanup()


func test_a_corrupt_look_and_name_fall_back_never_crash() -> void:
	var p := PlayerProfile.from_dict({"name": "{speler}[b]", "look": {"lichaam": "vrouw", "kapsel": "mohawk",
		"gezicht": "volle_baard", "ogen": 7, "bril": null, "onzin": "x"}}, "garbage")
	assert_eq(p.name, "", "an invalid name: the placeholder")
	assert_eq(p.display_name(), PlayerProfile.NAMELESS)
	assert_eq(p.look["lichaam"], "vrouw")
	assert_eq(p.look["kapsel"], CreatorLook.options("kapsel", "f")[0]["id"], "unknown id: the trait's first option")
	assert_eq(p.look["gezicht"], "geen", "a man's beard is not on a woman's list")
	assert_eq(p.look["ogen"], CreatorLook.options("ogen", "f")[0]["id"])
	assert_false(p.look.has("onzin"))
	assert_eq(p.portrait, PackedByteArray())
	for junk: Variant in [null, 3, "x", [], {"look": "x", "name": 5}]:
		var q := PlayerProfile.from_dict(junk, null)
		assert_eq(q.look, CreatorLook.normalized({}), "junk %s: the default look" % [junk])


func test_an_old_save_without_a_player_loads_with_the_default_look() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	assert_eq(SaveFile.write("slot_1", s.region, {"missions": s.missions.to_dict()}, dir), "")
	var loaded := SaveSlots.new(dir).resume("slot_1")
	assert_eq(loaded["error"], "")
	var back: GameSession = loaded["session"]
	assert_eq(back.player.look, CreatorLook.normalized({}))
	assert_eq(back.player.name, "")
	assert_eq(SaveSlots.new(dir).entry("slot_1")["portrait"], PackedByteArray())
	_cleanup()


func test_a_save_from_a_broken_build_shows_the_placeholder() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	var meta := GameSave.meta(s, 1.0)
	meta["name"] = "[color=red]X"
	meta["portrait"] = _png(Vector2i(10, 10))
	assert_eq(SaveFile.write("slot_3", s.region, {"meta": meta, "player": {"name": 12, "look": "x"}}, dir), "")
	var e := SaveSlots.new(dir).entry("slot_3")
	assert_eq(e["name"], "")
	assert_eq(e["portrait"], PackedByteArray())
	var back: GameSession = SaveSlots.new(dir).resume("slot_3")["session"]
	assert_eq(back.player.look, CreatorLook.normalized({}))
	_cleanup()


func test_the_name_never_reaches_the_playtest_log() -> void:
	var s := GameSession.new_game(11, Catalog.DATA_DIR, false)
	s.player = _profile("Fokke", "man")
	assert_false(SessionLog.ended_at(s, true).contains("Fokke"))
