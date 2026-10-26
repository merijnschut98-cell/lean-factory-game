class_name MakeSaves
extends SceneTree
## The designer's jump-to-day saves (DesignerSaves.SAVES): the autoplay bot plays to the stop
## and the game is written to user://saves/designer/<slot>.save. The main menu (with --designer)
## loads one into the autosave.
##   godot --headless --path game --script res://tools/make_saves.gd -- [slot|all] [persona] [seed]
## Default `all expert 11`. Prints each slot and the play day it stopped on; exits 1 on any error.
## In tools, not src: the player build leaves tools out (export_presets.cfg).

const Autoplay := preload("res://tools/autoplay.gd")
const DEFAULT_PERSONA := "expert"
const DEFAULT_SEED := 11


const STOPS: Array[String] = ["stop_day", "stop_act"]


## Play to the spec's stop (`stop_day` or `stop_act`), on to the next working morning, and
## write its slot into `dir`; the meta says how (persona, seed, stop, content hash).
## "" or what went wrong.
static func write(spec: Dictionary, persona: String, seed_value: int, dir: String = DesignerSaves.DIR) -> String:
	if not STOPS.any(func(stop: String) -> bool: return spec.has(stop)):
		return "%s: no stop_day or stop_act" % spec.get("slot", "")
	var bot := Autoplay.Persona.new(persona, seed_value)
	bot.stop_day = spec.get("stop_day", -1.0)
	bot.stop_act = spec.get("stop_act", -1)
	var ended: String = bot.play()["end"]
	if not ended in STOPS:
		return "%s: the run ended on %s before its stop" % [spec["slot"], ended]
	var s := bot.s
	s.pass_time(working_morning(s.region.net.time) - s.region.net.time)
	var designer := {"persona": persona, "seed": seed_value, "content_hash": DesignerSaves.content_hash()}
	for stop: String in STOPS:
		if spec.has(stop):
			designer[stop] = spec[stop]
	return GameSave.write(spec["slot"], s, SessionLayer.new(), dir, Time.get_unix_time_from_system(),
		{"designer": designer})


## Where a save resumes after a run stopped at `t`: the way a day starts in play, 08:30 on the
## first working day at or after `t` (OfficeHome.next_morning). A run stops in the night, and a
## save there opens on a dark office with no way home.
static func working_morning(t: int) -> int:
	var morning := OfficeHome.next_morning(t - SimCalendar.days(1))
	return morning if morning >= t else OfficeHome.next_morning(t)


func _initialize() -> void:
	quit(_run(OS.get_cmdline_user_args()))


func _run(args: PackedStringArray) -> int:
	var which := args[0] if args.size() > 0 else "all"
	var persona := args[1] if args.size() > 1 else DEFAULT_PERSONA
	var seed_value := int(args[2]) if args.size() > 2 else DEFAULT_SEED
	var specs := DesignerSaves.SAVES.filter(func(spec: Dictionary) -> bool: return which == "all" or spec["slot"] == which)
	if specs.is_empty():
		printerr("no designer save %s (%s)" % [which, ", ".join(DesignerSaves.SAVES.map(func(spec: Dictionary) -> String: return spec["slot"]))])
		return 1
	var failed := false
	for spec: Dictionary in specs:
		var error := write(spec, persona, seed_value)
		if error.is_empty():
			var back: GameSession = GameSave.read(spec["slot"], Catalog.DATA_DIR, DesignerSaves.DIR)["session"]
			var minute := back.minute_of_day()
			print("%s: play day %d at %02d:%02d, act %d" % [spec["slot"], back.missions.play_day(), minute / 60,
				minute % 60, back.missions.current_act()])
		else:
			printerr(error)
			failed = true
	return 1 if failed else 0
