class_name Designer
## The designer's switch (Merijn's playtest tools): on in the editor or with `--designer`
## after `--` on the command line. The player build has neither.

static var _forced: Variant = null


static func enabled() -> bool:
	if _forced != null:
		return _forced
	return OS.has_feature("editor") or OS.get_cmdline_user_args().has("--designer")


## A test hook: true or false overrides enabled(), null clears the override.
static func force(value: Variant) -> void:
	_forced = value
