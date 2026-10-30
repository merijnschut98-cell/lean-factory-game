extends SceneTree
## The route test on a tier that is not in content yet (PLAN 1.6c; four-tier
## audit §4.4, T6), on the real rules:
##   python tools/dialog_drafts.py <draft.md> <tier.json>
##   godot --headless --path game --script res://tools/route_check.gd -- <tier.json> [width]
## Without a file it measures content/dialogs.yaml; with `tier1` it measures
## what test_dialog_routes.gd measures (the Acts 0–II scripts' talks, each from
## content once it is there: DialogRoutes.tier1_talks). Prints the best fixed route
## found (DialogRoutes, playing only what each turn offers: PLAN 2.13 B) and
## how many talks it wins, how many always taking the same button wins (no
## position may win more than half), then per talk whether it can be won
## through its offers and how many different routes win it on the whole
## palette (T7: three at least).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var c := Catalog.load_from()
	var talks: Array[Dialog]
	if args.is_empty():
		talks = DialogRoutes.content_talks(c)
	elif args[0] == "tier1":
		talks = DialogRoutes.tier1_talks(c)
	else:
		talks = DialogRoutes.draft_talks(JSON.parse_string(FileAccess.get_file_as_string(args[0])), c.dialog_bank)
	var width := int(args[1]) if args.size() > 1 else DialogRoutes.WIDTH
	var t0 := Time.get_ticks_msec()
	var best := DialogRoutes.best_route(talks, width)
	print("%s: %d of %d persuasion talks (%d %%) won by one route, width %d, %.0f s" % [
		"content" if args.is_empty() else args[0].get_file(), best["wins"], talks.size(),
		roundi(100.0 * best["wins"] / maxi(talks.size(), 1)), width, (Time.get_ticks_msec() - t0) / 1000.0])
	print("  route: ", " ".join(best["route"]))
	print("  wins: ", ", ".join(best["won"]))
	for position in Dialog.OFFERED:
		print("  always button %d: %d of %d" % [position + 1, DialogRoutes.position_wins(talks, position).size(), talks.size()])
	for talk: Dialog in talks:
		var own := DialogRoutes.best_route([talk], width, [], false)
		var distinct := DialogRoutes.distinct(DialogRoutes.best_route([talk], width, [], true, false)["winners"])
		print("  %-26s %-14s %-11s start %2d  %s, %d distinct routes" % [talk.def.id, talk.who.archetype,
			talk.who.need, talk.openness, "winnable" if own["wins"] > 0 else "NOT WINNABLE", distinct.size()])
	quit()
