class_name PlayShotArgs
extends RefCounted
## The screenshot tool's command line (play_shot.gd): `<state> <out.png> [frames]`, then
## named arguments `--at HH:MM` (the office clock) and `--season <name>` (a later slice).
## Flags it does not know (--designer, read by Designer itself) are left alone.

const DEFAULT_FRAMES := 20
const NAMED := ["--at", "--season"]
## Said when a menu state is given `--at`: the menus have no office clock.
const MENU_AT_NOTE := "--at has no effect on a menu state (there is no office clock)"


## {state, out, frames, at (minute of day, -1 when absent or bad), season ("" when absent),
## error ("" or what is wrong with a flag: a missing or bad value)}. A flag's value never
## starts with `--`: that is the next flag, and the value is missing.
static func parse(args: PackedStringArray) -> Dictionary:
	var positional: Array[String] = []
	var named := {}
	var errors: Array[String] = []
	var i := 0
	while i < args.size():
		var arg := args[i]
		if arg in NAMED:
			if i + 1 < args.size() and not args[i + 1].begins_with("--"):
				named[arg] = args[i + 1]
				i += 1
			else:
				errors.append("%s wants a value" % arg)
		elif not arg.begins_with("--"):
			positional.append(arg)
		i += 1
	var at := minute_of(str(named.get("--at", "")))
	if "--at" in named and at < 0:
		errors.append("--at wants a time of day like 18:30, not '%s'" % named["--at"])
	return {
		"state": positional[0] if positional.size() > 0 else "",
		"out": positional[1] if positional.size() > 1 else "",
		"frames": int(positional[2]) if positional.size() > 2 else DEFAULT_FRAMES,
		"at": at,
		"season": str(named.get("--season", "")),
		"error": "; ".join(errors),
	}


## "18:30" as minutes since midnight; -1 when it is no time of day.
static func minute_of(text: String) -> int:
	var parts := text.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or parts[1].length() != 2:
		return -1
	var hour := int(parts[0])
	var minute := int(parts[1])
	if parts[0].begins_with("-") or hour > 23 or minute > 59:
		return -1
	return hour * 60 + minute
