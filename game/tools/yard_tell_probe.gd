extends SceneTree
## The yard's tells (PLAN 2.6, S3-Y): what each yard tell reads in the base region and with each
## field problem active from the first day: min/median/max of the daily readings after day 9,
## the numbers behind OfficeTells.THRESHOLDS for the yard.
##   godot --headless --path game --script res://tools/yard_tell_probe.gd -- [seeds] [days]

const PROBLEMS: Array[String] = ["", "wrong_joint_in_van", "not_at_home", "double_visits", "installer_not_ready",
	"digging_damage", "knowledge_drain", "inverters_tripping", "revision_backlog"]
const YARD: Array[String] = ["van_kanban", "magazijn_rack", "van_returns", "storingsbord", "measurement_tray"]
## Readings before this day are the problem still settling in.
const SETTLE_DAYS := 9


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: PackedStringArray = (args[0] if args.size() > 0 else "11,12").split(",")
	var days := int(args[1]) if args.size() > 1 else 60
	for p in PROBLEMS:
		for seed_text in seeds:
			var s := GameSession.new_game(int(seed_text), Catalog.DATA_DIR, false)
			if not s.error.is_empty():
				printerr(s.error)
				quit(1)
				return
			if not p.is_empty():
				s.region.activate(p)
			var rows := {}
			for tell in YARD:
				rows[tell] = []
			for d in days:
				s.region.advance_days(1)
				if d < SETTLE_DAYS:
					continue
				var read := OfficeTells.readings(s.region.net)
				for tell in YARD:
					rows[tell].append(read[tell])
			var out := []
			for tell in YARD:
				var v: Array = rows[tell]
				v.sort()
				out.append("%s %d/%d/%d" % [tell, v[0], v[v.size() / 2], v[-1]])
			print("%-20s seed %s  %s" % [p if not p.is_empty() else "base", seed_text, "  ".join(out)])
	quit(0)
