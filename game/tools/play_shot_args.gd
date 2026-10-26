class_name PlayShotArgs
extends RefCounted
## The screenshot tool's command line (play_shot.gd): `<state> <out.png> [frames]`, then
## named arguments `--at HH:MM` (the office clock) and `--season <name>` (a later slice).
## Flags it does not know (--designer, read by Designer itself) are left alone.

const DEFAULT_FRAMES := 20
const NAMED := ["--at", "--season"]


## {state, out, frames, at (minute of day, -1 when absent or not a time of day), season ("" when absent)}.
static func parse(args: PackedStringArray) -> Dictionary:
	var positional: Array[String] = []
	var named := {}
	var i := 0
	while i < args.size():
		var arg := args[i]
		if arg in NAMED:
			named[arg] = args[i + 1] if i + 1 < args.size() else ""
			i += 1
		elif not arg.begins_with("--"):
			positional.append(arg)
		i += 1
	return {
		"state": positional[0] if positional.size() > 0 else "",
		"out": positional[1] if positional.size() > 1 else "",
		"frames": int(positional[2]) if positional.size() > 2 else DEFAULT_FRAMES,
		"at": minute_of(str(named.get("--at", ""))),
		"season": str(named.get("--season", "")),
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
