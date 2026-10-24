class_name OfficeDesk
extends Node3D
## Your desk at Aansluitingen (phase-2 design §1.8, PLAN 2.10): the free desk on
## Werkvoorbereiding's bench, beside Joost and Anouk. On it: a name plate with your first
## name, your badge photo (the creator's portrait) in a small frame, the El Amrani letter
## once Ruud has handed it over (the opening's letter beat), her thank-you letter beside it
## once a kept promise sent one (a mission's `payoff` by letter: winter_el_amrani; design
## §3.2), and your clipboard with the A3. Standing behind its chair (E, or a click on the ring) the camera drops to the desk
## and the A3 opens, drawn as the sheet on that clipboard. The desk is in the floor's
## model already (build_office.py's design bench), so its things are added here and the
## floor needs no rebuild; they follow the profile ("Uiterlijk") and the opening as they change.

## The interaction point's id (an Interactable kind of its own).
const ID := "desk"
## The free desk: no cast member sits there (test_player_desk checks it).
const DESK := "design1"
## How far behind the chair the player stands to use it (m).
const BEHIND := 0.7
const PROMPT := "E — Je bureau: je A3"
const LABEL := "Je bureau"
## The desk top's height (build_office.py kit_desk), and the things' places on it in the
## desk's own frame: x to the right of the one sitting there, -z towards the screens.
const TOP := 0.75
const PLATE_AT := Vector3(0.02, TOP, -0.01)
const PHOTO_AT := Vector3(0.66, TOP, -0.24)
const LETTER_AT := Vector3(0.56, TOP + 0.001, 0.06)
## A letter that came later lies half over the first, a little nearer the chair.
const THANKS_AT := Vector3(0.42, TOP + 0.002, 0.16)
const CLIPBOARD_AT := Vector3(-0.44, TOP, 0.12)
## The photo's frame: passport ratio (PlayerProfile.PORTRAIT_SIZE), 12 cm wide.
const PHOTO_SIZE := Vector2(0.12, 0.154)
## The badge's colours while no photo was taken (the creator's placeholder).
const NO_PHOTO := Color("#c9d6e3")
## The letter's ink lines between its greeting and its close (OfficeOpening.LETTER), too
## small to read from the chair.
const INK_LINES := ["——————————————", "—————————————", "——————————————", "—————————", "",
	"—————————————", "——————————————", "———————————"]

var office: Office
var _plate: Label3D
var _photo: MeshInstance3D
var _letter: Node3D
## The letter a kept promise sent (null until one did), and the text it shows.
var _thanks: Node3D
var _thanks_text := ""
## The missions done when the thank-you letter was last looked for (-1: not yet).
var _done_seen := -1
## The profile the plate and the photo show (a new one comes with "Uiterlijk").
var _shown: PlayerProfile


## Your desk's things on the loaded floor, or null when the desk is not on it.
static func create(of_office: Office) -> OfficeDesk:
	var desk := of_office.find_marker(DESK + "_desk")
	if desk == null:
		return null
	var d := OfficeDesk.new()
	d.name = "PlayerDesk"
	d.office = of_office
	d.transform = of_office.in_office(desk)
	d._build()
	d.refresh()
	return d


## The ring behind the desk's chair, facing the desk; null when the desk is not on the
## loaded floor or its room is shut.
static func place(of_office: Office) -> Interactable:
	return place_at(of_office, ID, DESK, stand(of_office))


## An interaction point `id` at `at`, by desk `desk`; null when that desk is not on the
## loaded floor or its room is shut.
static func place_at(of_office: Office, id: String, desk: String, at: Transform3D) -> Interactable:
	if of_office.find_marker(desk + "_desk") == null or of_office.find_marker(desk + "_chair") == null:
		return null
	var shut := of_office.floors.shut_rects(of_office.floors.markers())
	if shut.any(func(r: Rect2) -> bool: return r.has_point(Vector2(at.origin.x, at.origin.z))):
		return null
	return Interactable.create(id, at)


## Where the player stands to use it: behind the chair, facing the desk.
static func stand(of_office: Office) -> Transform3D:
	var at := seat(of_office, DESK)
	return Transform3D(at.basis, at.origin + at.basis.z * BEHIND)


## Desk `desk`'s chair on the floor, facing the desk (the desk's -Z, as a seated person
## faces it): -Z ahead, +X to the sitter's right. Identity when it is not on the floor.
static func seat(of_office: Office, desk: String) -> Transform3D:
	var chair := of_office.find_marker(desk + "_chair")
	var top := of_office.find_marker(desk + "_desk")
	if chair == null or top == null:
		return Transform3D.IDENTITY
	var forward := -of_office.in_office(top).basis.z * Vector3(1, 0, 1)
	return Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), of_office.in_office(chair).origin * Vector3(1, 0, 1))


func _process(_delta: float) -> void:
	refresh()


## Follow the player's profile (name, photo), the opening (the letter) and the missions
## done (a thank-you letter). Cheap: the plate and the photo change only with a new
## profile, the thank-you only with a mission done.
func refresh() -> void:
	var me := office.session.player
	if me != _shown:
		_shown = me
		_done_seen = -1   # the thank-you letter greets you by the new name
		_plate.text = me.display_name()
		var photo := PlayerProfile.texture_of(me.portrait)
		var look := _photo.material_override as StandardMaterial3D
		look.albedo_texture = photo
		look.albedo_color = Color.WHITE if photo != null else NO_PHOTO
	var layer := office.ui.session_layer if office.ui != null else null
	_letter.visible = layer == null or Opening.reached(layer, Opening.EVENING)
	if office.session.missions == null:   # the content did not load: no missions, no letters
		return
	var done := office.session.missions.done_once.size()
	if done == _done_seen:
		return
	_done_seen = done
	var thanks := payoff_letter(office.session)
	if thanks != _thanks_text:
		_thanks_text = thanks
		if _thanks != null:
			_thanks.free()
		_thanks = null if thanks.is_empty() else _letter_sheet("Thanks", thanks.split("\n\n"), THANKS_AT, 8.0)
		if _thanks != null:
			add_child(_thanks)


## The text of the letter a kept promise sent you (MissionDef.payoff by letter, its tokens
## filled), "" when none came yet.
static func payoff_letter(s: GameSession) -> String:
	for m: MissionDef in s.missions.defs.values():
		if s.missions.done_once.has(m.id):
			for p: Dictionary in m.payoff:
				if p["by"] == "letter":
					return s.fill_tokens(p["text"])
	return ""


func plate_text() -> String:
	return _plate.text


## The badge photo in the frame; null for the placeholder.
func photo_texture() -> Texture2D:
	return (_photo.material_override as StandardMaterial3D).albedo_texture


func letter_shown() -> bool:
	return _letter.visible


func thanks_shown() -> bool:
	return _thanks != null and _thanks.visible


## The thank-you letter's text ("" when there is none).
func thanks_text() -> String:
	return _thanks_text


func _build() -> void:
	add_child(_name_plate())
	add_child(_photo_frame())
	var letter := OfficeOpening.LETTER
	_letter = _letter_sheet("Letter", PackedStringArray([letter[0], letter[2] + "\n" + letter[3]]), LETTER_AT, -14.0)
	add_child(_letter)
	add_child(_clipboard())


## A letter lying on the desk at `at`, turned `yaw` degrees: its first paragraph (the
## greeting) and its last (the close) readable, ink lines between, too small to read from
## the chair.
static func _letter_sheet(node_name: String, paragraphs: PackedStringArray, at: Vector3, yaw: float) -> Node3D:
	var sheet := _sheet(node_name, Vector2(0.21, 0.297), Color("#fbfaf4"), at, yaw)
	var lines := _text("\n".join([paragraphs[0], ""] + INK_LINES + ["", paragraphs[paragraphs.size() - 1]]), 0.00042,
		Color("#2b3550"))
	lines.rotation_degrees.x = -90
	lines.position = Vector3(0, 0.002, 0)
	sheet.add_child(lines)
	return sheet


## A small wedge of dark wood with your first name in white, facing the chair.
func _name_plate() -> Node3D:
	var plate := Node3D.new()
	plate.name = "NamePlate"
	plate.position = PLATE_AT + Vector3(0, 0.03, 0)
	plate.rotation_degrees.x = -22
	plate.add_child(_box(Vector3(0.22, 0.06, 0.014), Vector3.ZERO, Color("#3a2c22")))
	_plate = _text("", 0.0011, Color("#f3efe4"))
	_plate.position = Vector3(0, 0, 0.0075)
	_plate.font_size = 48
	plate.add_child(_plate)
	return plate


## The badge photo in a thin black frame on a stand, leaning back, facing the chair.
func _photo_frame() -> Node3D:
	var frame := Node3D.new()
	frame.name = "Photo"
	frame.position = PHOTO_AT + Vector3(0, PHOTO_SIZE.y / 2.0 + 0.012, 0)
	frame.rotation_degrees = Vector3(-14, -18, 0)
	frame.add_child(_box(Vector3(PHOTO_SIZE.x + 0.02, PHOTO_SIZE.y + 0.02, 0.01), Vector3.ZERO, Color("#1f1f22")))
	var quad := QuadMesh.new()
	quad.size = PHOTO_SIZE
	_photo = MeshInstance3D.new()
	_photo.mesh = quad
	_photo.position = Vector3(0, 0, 0.0055)
	var look := StandardMaterial3D.new()
	look.roughness = 0.45
	_photo.material_override = look
	frame.add_child(_photo)
	return frame


## Your clipboard: hardboard, a sheet with its ruling, the metal clip.
func _clipboard() -> Node3D:
	var board := Node3D.new()
	board.name = "Clipboard"
	board.position = CLIPBOARD_AT
	board.rotation_degrees.y = 9
	board.add_child(_box(Vector3(0.235, 0.006, 0.33), Vector3(0, 0.003, 0), Color("#8b6a45")))
	var sheet := _sheet("Sheet", Vector2(0.21, 0.28), Color("#f6f3e8"), Vector3(0, 0.0065, 0.015), 0.0)
	var heading := _text("A3", 0.0011, Color("#1f4e8c"))
	heading.rotation_degrees.x = -90
	heading.position = Vector3(-0.06, 0.001, -0.1)
	sheet.add_child(heading)
	board.add_child(sheet)
	board.add_child(_box(Vector3(0.09, 0.016, 0.035), Vector3(0, 0.012, -0.15), Color("#b9bcc2")))
	return board


## A sheet of paper lying flat at `at` (on the desk), turned `yaw` degrees.
static func _sheet(node_name: String, size: Vector2, color: Color, at: Vector3, yaw: float) -> Node3D:
	var sheet := _box(Vector3(size.x, 0.001, size.y), Vector3.ZERO, color)
	sheet.name = node_name
	sheet.position = at
	sheet.rotation_degrees.y = yaw
	return sheet


static func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var look := StandardMaterial3D.new()
	look.albedo_color = color
	look.roughness = 0.6
	box.material = look
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.position = at
	return mesh


static func _text(text: String, pixel: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.shaded = true
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if text.contains("\n") else HORIZONTAL_ALIGNMENT_CENTER
	return label
