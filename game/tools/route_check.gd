extends SceneTree
## The route test on a tier that is not in content yet (PLAN 1.6c; four-tier
## audit §4.4, T6), on the real rules:
##   python tools/dialog_drafts.py <draft.md> <tier.json>
##   godot --headless --path game --script res://tools/route_check.gd -- <tier.json> [width]
## Without a file it measures content/dialogs.yaml. Prints the best fixed route
## found (DialogRoutes) and how many talks it wins, then per talk whether it
## can be won and how many different routes win it (T7: three at least).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var bank: Dictionary = JsonFile.read_dict("res://data/dialogs.json")["data"]["bank"]
	var talks := _content(bank) if args.is_empty() else _draft(args[0], bank)
	var width := int(args[1]) if args.size() > 1 else DialogRoutes.WIDTH
	var t0 := Time.get_ticks_msec()
	var best := DialogRoutes.best_route(talks, width)
	print("%s: %d of %d persuasion talks (%d %%) won by one route, width %d, %.0f s" % [
		"content" if args.is_empty() else args[0].get_file(), best["wins"], talks.size(),
		roundi(100.0 * best["wins"] / maxi(talks.size(), 1)), width, (Time.get_ticks_msec() - t0) / 1000.0])
	print("  route: ", " ".join(best["route"]))
	print("  wins: ", ", ".join(best["won"]))
	for talk: Dialog in talks:
		var own := DialogRoutes.best_route([talk], width)
		var distinct := []
		for r: Array in own["winners"]:
			if distinct.all(func(o: Array) -> bool: return _differ(o, r) >= 2):
				distinct.append(r)
		print("  %-26s %-14s %-11s start %2d  %s, %d distinct routes" % [talk.def.id, talk.who.archetype,
			str(talk.who.get("need")), talk.openness, "winnable" if own["wins"] > 0 else "NOT WINNABLE", distinct.size()])
	quit()


func _content(bank: Dictionary) -> Array:
	var c := Catalog.load_from()
	var people := People.new(c.persons, c.dialogs, c.dialog_bank)
	var out := []
	for d: DialogDef in c.dialogs:
		if d.kind == "persuade":
			var first := people.start(d, {"main": [d.mission], "active": [d.mission], "found": {}, "facts": {},
				"team_trust": 0, "blamed": false, "now": 0})
			out.append(DialogRoutes.start(d, people.persons[d.person], bank, first.openness))
	return out


func _draft(path: String, bank: Dictionary) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var persons := {}
	for p: Dictionary in data["people"]:
		persons[p["id"]] = PersonDef.from_dict(p.merged({"place": "draft"}))
	var out := []
	for d: Dictionary in data["dialogs"]:
		var def := DialogDef.from_dict(d)
		if not def.error.is_empty():
			push_error(def.error)
			continue
		out.append(DialogRoutes.start(def, persons[def.person], bank, int(d["start"])))
	return out


func _differ(a: Array, b: Array) -> int:
	var n := absi(a.size() - b.size())
	for i in mini(a.size(), b.size()):
		n += 1 if a[i] != b[i] else 0
	return n
