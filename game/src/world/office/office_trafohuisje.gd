class_name OfficeTrafohuisje
## The trafohuisje mock-up on the opleidingsterrein (PLAN 2.3 and 2.7c; spec 2026-10-24-
## explainer-transformator §6): standing at its doors (E, or a click on the ring) opens
## "Hoe werkt het? 2: de transformator" with Ruud's beats, the camera on the little house
## (Office.open_trafohuisje). The mock-up is in the yard's model already (build_yard.py
## opleidingsterrein()), so the place is added in Godot and the yard needs no rebuild; it
## is there once the opleidingsterrein is open.

## The interaction point's id (an Interactable kind of its own).
const ID := "trafohuisje"
## The explainer it opens.
const EXPLAINER := "transformator"
## The room it stands in, and the yard model's node the mock-up is part of.
const ROOM := "opleidingsterrein"
const NODE := "opleidingsterrein"
## The mock-up in that node's own space (glTF: Blender x, z up, −y; build_yard.py hx, hy =
## −28.4, −16.4, its doors on the north side, 2.3 m high): the middle of its doors' face.
const DOORS := Vector3(-28.4, 0.0, 15.4)
## Out of the doors, in the node's space (Blender +y is glTF −z).
const OUTWARD := Vector3(0, 0, -1)
## The player stands this far in front of the doors; the camera looks at this height.
const STAND := 0.9
const LOOK_HEIGHT := 1.2
const PROMPT := "E — Trafohuisje: hoe werkt een trafo?"
const LABEL := "Trafohuisje (opleidingsterrein)"


## The ring in front of the doors, facing them; null when the yard is not loaded or the
## opleidingsterrein is still shut.
static func place(office: Office) -> Interactable:
	var node := office.find_marker(NODE)
	if node == null or not ROOM in office.floors.open:
		return null
	return Interactable.create(ID, stand(office))


## Where the player stands to use it: in front of the doors, facing them.
static func stand(office: Office) -> Transform3D:
	var t := office.in_office(office.find_marker(NODE))
	var out := (t.basis * OUTWARD).normalized()
	var at := t * DOORS + out * STAND
	return Transform3D(Basis.looking_at(-out, Vector3.UP), at)


## The point the camera looks at: the doors, at about chest height.
static func look_point(office: Office) -> Vector3:
	return office.in_office(office.find_marker(NODE)) * DOORS + Vector3.UP * LOOK_HEIGHT
