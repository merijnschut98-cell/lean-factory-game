extends SceneTree
## The route test on a tier that is not in content yet (PLAN 1.6c; four-tier
## audit §4.4, T6), on the real rules:
##   python tools/dialog_drafts.py <draft.md> <tier.json>
##   godot --headless --path game --script res://tools/route_check.gd -- <tier.json> [width]
## Without a file it measures content/dialogs.yaml; with `tier1` it measures
## what test_dialog_routes.gd measures (content, plus the Acts 0–II scripts'
## talks not in content yet: tests/data/tier1_scripts.json). Prints the best fixed route
## found (DialogRoutes) and how many talks it wins, then per talk whether it
## can be won and how many different routes win it (T7: three at least).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var bank: Dictionary = JsonFile.read_dict("res://data/dialogs.json")["data"]["bank"]
	var tier1 := not args.is_empty() and args[0] == "tier1"
	var talks := DialogRoutes.content_talks(Catalog.load_from()) if args.is_empty() or tier1 \
		else DialogRoutes.draft_talks(JSON.parse_string(FileAccess.get_file_as_string(args[0])), bank)
	if tier1:
		var ids := talks.map(func(t: Dialog) -> String: return t.def.id)
		talks.append_array(DialogRoutes.draft_talks(JsonFile.read_dict("res://tests/data/tier1_scripts.json")["data"],
			bank, ids))
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
		var distinct := DialogRoutes.distinct(own["winners"])
		print("  %-26s %-14s %-11s start %2d  %s, %d distinct routes" % [talk.def.id, talk.who.archetype,
			talk.who.need, talk.openness, "winnable" if own["wins"] > 0 else "NOT WINNABLE", distinct.size()])
	quit()
