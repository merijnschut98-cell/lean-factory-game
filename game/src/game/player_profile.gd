class_name PlayerProfile
extends RefCounted
## The player as made in the character creator (PLAN 2.7b; spec
## 2026-10-16-creator-and-minimap §1.4–§1.7): the first name, the look (trait
## id -> option id, CreatorLook) and the badge photo (a PNG). The save keeps
## them (GameSave: the name and look under "player", the name and photo in the
## meta, so the title menu shows them without loading the game); everything
## read back is validated here, and a bad value falls back, never a crash.
##
## The name is substituted into dialog text with {speler} and shown in rich
## text, so the set of characters it may hold is narrow: letters, and one
## space, hyphen or apostrophe between two letters. Braces and square brackets
## can never enter it, so it can never become a token or BBCode; fill() is
## single-pass besides (a substituted value is never scanned again).

## What the save cards and {speler} show for a player without a valid name.
const NAMELESS := "Nieuwe CI-lead"
const MAX_NAME := 16
## The badge photo: passport ratio 35:45 (estimate: sharp on a card and a badge).
const PORTRAIT_SIZE := Vector2i(252, 324)
const PORTRAIT_MAX_BYTES := 256 * 1024
const _NAME := "^\\p{L}+(?:[ '\\-]\\p{L}+)*$"
## One character that may be typed into the name field (the rest of the rule,
## "between two letters", is checked on confirm).
const _TYPEABLE := "^[\\p{L} '\\-]$"
const _PNG_MAGIC := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
const _TOKEN := "\\{([A-Za-z_]+)\\}"
## The body's words for third-person lines about the player (§1.6): token ->
## [man, vrouw].
const _BODY_WORDS := {
	"hij_zij": ["hij", "zij"],
	"Zij_Hij_speler": ["Hij", "Zij"],
	"haar_hem_speler": ["hem", "haar"],
	"jongen_meid": ["jongen", "meid"],
}

static var _name_re := RegEx.create_from_string(_NAME)
static var _typeable_re := RegEx.create_from_string(_TYPEABLE)
static var _token_re := RegEx.create_from_string(_TOKEN)

## The valid first name, or "" (shown as NAMELESS).
var name := ""
## Every trait mapped to a valid option (CreatorLook.normalized).
var look: Dictionary = CreatorLook.normalized({})
## The badge photo as PNG bytes; empty for the drawn placeholder.
var portrait := PackedByteArray()


func copy() -> PlayerProfile:
	var p := PlayerProfile.new()
	p.name = name
	p.look = look.duplicate()
	p.portrait = portrait.duplicate()
	return p


func display_name() -> String:
	return name if not name.is_empty() else NAMELESS


## {name, look}: what the save keeps beside the meta.
func to_dict() -> Dictionary:
	return {"name": name, "look": look.duplicate()}


## A profile from a save's "player" entry and the meta's portrait, both
## untrusted: an invalid name is "", an unknown option the trait's first, a bad
## photo the placeholder.
static func from_dict(data: Variant, photo: Variant) -> PlayerProfile:
	var p := PlayerProfile.new()
	var d := JsonFile.dict_or_empty(data)
	p.name = stored_name(d.get("name"))
	p.look = CreatorLook.normalized(JsonFile.dict_or_empty(d.get("look")))
	p.portrait = valid_portrait(photo)
	return p


## A stored name as it may be shown: valid and already normal, else "".
static func stored_name(value: Variant) -> String:
	return value if value is String and clean_name(value) == value else ""


## The first name as confirmed (§1.4): trimmed, runs of spaces made one, the
## typographic apostrophe made plain, a name typed all in lower case given a
## capital; "" when it is not 1–16 letters with a single space, hyphen or
## apostrophe between two letters.
static func clean_name(raw: String) -> String:
	var name := raw.strip_edges().replace("’", "'")
	while name.contains("  "):
		name = name.replace("  ", " ")
	if name.is_empty() or name.length() > MAX_NAME or _name_re.search(name) == null:
		return ""
	if name == name.to_lower():
		name = name.left(1).to_upper() + name.substr(1)
	return name


## What the name field keeps of typed text: only letters, spaces, hyphens and
## apostrophes (’ as '), at most MAX_NAME characters.
static func typed(text: String) -> String:
	var out := ""
	for ch in text.replace("’", "'"):
		if out.length() < MAX_NAME and _typeable_re.search(ch) != null:
			out += ch
	return out


## The bytes when they are a PNG of PORTRAIT_SIZE under PORTRAIT_MAX_BYTES,
## else empty (the placeholder).
static func valid_portrait(value: Variant) -> PackedByteArray:
	if not value is PackedByteArray or value.is_empty() or value.size() > PORTRAIT_MAX_BYTES:
		return PackedByteArray()
	var bytes: PackedByteArray = value
	if bytes.size() < _PNG_MAGIC.size() or Array(bytes.slice(0, _PNG_MAGIC.size())) != _PNG_MAGIC:
		return PackedByteArray()
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK or Vector2i(image.get_size()) != PORTRAIT_SIZE:
		return PackedByteArray()
	return bytes


## A photo (PNG bytes) as a texture, or null for the placeholder.
static func texture_of(bytes: PackedByteArray) -> Texture2D:
	if bytes.is_empty():
		return null
	var image := Image.new()
	return ImageTexture.create_from_image(image) if image.load_png_from_buffer(bytes) == OK else null


## The player's tokens: {speler} and the body's words.
func tokens() -> Dictionary:
	var woman := CreatorLook.body_of(look) == "f"
	var out := {"speler": display_name()}
	for token: String in _BODY_WORDS:
		out[token] = _BODY_WORDS[token][1 if woman else 0]
	return out


## `text` with the player's tokens filled, in one pass; any other {token} is
## left for its own filler (e.g. {dossier_weken}).
func fill(text: String) -> String:
	if not text.contains("{"):
		return text
	var values := tokens()
	var out := ""
	var at := 0
	for m in _token_re.search_all(text):
		var key := m.get_string(1)
		if values.has(key):
			out += text.substr(at, m.get_start() - at) + str(values[key])
			at = m.get_end()
	return out + text.substr(at)


## fill() on every string in `value` (a result of dictionaries and arrays).
func fill_all(value: Variant) -> Variant:
	if value is String:
		return fill(value)
	if value is Array:
		var list: Array = value.duplicate()
		for i in list.size():
			list[i] = fill_all(list[i])
		return list
	if value is Dictionary:
		var out: Dictionary = value.duplicate()
		for key: Variant in out:
			out[key] = fill_all(out[key])
		return out
	return value
