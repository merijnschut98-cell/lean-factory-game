extends SceneTree
## Winter 1's stakes (PLAN 1.8a / D14): when each autoplay persona's El Amrani dossier is
## connected, per seed, against the first frost period (day 70).
##   godot --headless --path game --script res://tools/winter_probe.gd -- [personas] [seeds] [stop_day]
## e.g. `-- expert,never-talks 11,12,13 90`. Prints one row per run: persona, seed, the
## day the dossier was connected (-1: not by stop_day), winter kept | missed | open, and
## the days the Act I mains were done.

const Autoplay := preload("res://tools/autoplay.gd")
const MAINS: Array[String] = ["fix_custom_design", "fix_incomplete_application", "fix_installer_not_ready",
	"fix_status_callers", "fix_done_but_not_closed"]
## The fork after fix_custom_design: the bottleneck branch (her intake) and the other.
const FORK: Array[String] = ["fix_incomplete_application", "fix_installer_not_ready"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var personas: PackedStringArray = (args[0] if args.size() > 0 else ",".join(Autoplay.PERSONAS)).split(",")
	var seeds: PackedStringArray = (args[1] if args.size() > 1 else "11,12,13").split(",")
	var stop := float(args[2]) if args.size() > 2 else 90.0
	print("| persona | seed | branch first | connected (day) | winter | mains done (day) |")
	print("|---|---|---|---|---|---|")
	for p in personas:
		for seed_text in seeds:
			var persona = Autoplay.Persona.new(p, int(seed_text))
			persona.stop_day = stop
			var run: Dictionary = persona.play()
			var mains := []
			var branch := "-"
			for r: Dictionary in run["missions"]:
				if r["id"] in FORK and branch == "-":
					branch = "%s (day %d)" % [r["id"].trim_prefix("fix_"), int(r["accepted_day"])]
				if r["id"] in MAINS and r["outcome"] == "completed":
					mains.append("%s %d" % [r["id"].trim_prefix("fix_"), int(r["completed_day"])])
			print("| %s | %s | %s | %s | %s | %s |" % [p, seed_text, branch, run["followed_day"], run["winter"],
				", ".join(mains)])
	quit(0)
