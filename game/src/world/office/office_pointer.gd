class_name OfficePointer
extends RefCounted
## The mouse in the office: a move shows the name of the person under the cursor or lights
## up the ring under it; a left click on a person walks up and asks for a talk, on a tell
## looks closer, on the floor walks there (and opens a place whose ring was clicked) on
## arrival. The office owns one (Office.pointer) and hands it its unhandled mouse events.

## A click this close (m) to a ring's centre is a click on the ring.
const RING_CLICK := Interactable.RING_RADIUS + 0.3

var office: Office
## The person under the cursor (their name tag shows), or null.
var hovered: OfficePerson
## The ring, person or tell clicked last: used when the walk there ends.
var _walk_goal: Node3D


func _init(for_office: Office) -> void:
	office = for_office


## The floor changed: nothing is under the cursor or walked to any more.
func forget() -> void:
	_walk_goal = null
	hovered = null


## A left click or a mouse move on the view that no panel took.
func handle(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not clicked and not event is InputEventMouseMotion:
		return
	var camera := office.rig.camera
	var origin := office.to_local(camera.project_ray_origin(event.position))
	var ray := (office.to_local(camera.project_ray_origin(event.position) + camera.project_ray_normal(event.position)) - origin).normalized()
	var person := office.people.person_under(origin, ray) if not office.ui.is_busy() else null
	if clicked and person != null:
		click_person(person)
		return
	if clicked and office.tells != null and click_tell(office.tells.under(origin, ray)):
		return
	if not clicked:
		hover_person(person)
	if ray.y >= -0.01:
		return
	var point := origin + ray * (-origin.y / ray.y)
	if clicked:
		click_floor(point)
	elif person == null:
		hover_floor(point)


## The person under the cursor (null for none): their name tag shows, the rings
## go dark, the cursor becomes a hand.
func hover_person(person: OfficePerson) -> void:
	hovered = person
	if person == null:
		return
	for i in office.interactables:
		i.set_hovered(false)
	if DisplayServer.get_name() != "headless":
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


## Walk up to a clicked person and ask for a talk on arrival. False when the
## click is not for the world or there is no way there.
func click_person(person: OfficePerson) -> bool:
	if office.world_waits() or not office.session.error.is_empty():
		return false
	_walk_goal = person
	return _walk_to(person.position)


## A click on a tell (PLAN 2.15): within reach, look closer; else walk up to it and look on
## arrival. False when the click is not for the world, there is no tell or no way there.
func click_tell(tell: String) -> bool:
	if tell.is_empty() or office.world_waits() or not office.session.error.is_empty():
		return false
	var tells := office.tells
	var root: Node3D = tells.roots[tell]
	if tells.distance(tell, office.player.position) <= Office.REACH:
		office.use(root)
		return true
	_walk_goal = root
	return _walk_to(tells.bounds(tell).get_center() * Vector3(1, 0, 1))


## Light up the ring at a floor point under the cursor (office space), and
## only that one; the cursor becomes a hand over it.
func hover_floor(point: Vector3) -> void:
	var under := office.interactable_near(point, RING_CLICK) if not office.ui.is_busy() else null
	for i in office.interactables:
		i.set_hovered(i == under)
	if DisplayServer.get_name() != "headless":
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if under != null else Input.CURSOR_ARROW)


## Walk to a clicked floor point (office space); a click on a place's ring
## walks there and opens it on arrival. False when the click is not for the
## world (a panel is open, the content failed) or nothing can be reached.
func click_floor(point: Vector3) -> bool:
	if office.world_waits() or not office.session.error.is_empty():
		return false
	_walk_goal = office.interactable_near(point, RING_CLICK)
	return _walk_to(_walk_goal.position if _walk_goal != null else point)


## The player walks to `to` (office space); false when there is no way there.
func _walk_to(to: Vector3) -> bool:
	var route := office.nav().path(office.player.position, to)
	office.player.walk(route)
	return not route.is_empty()


## The walk ended (Player.arrived): what was clicked is used when it is in reach now.
func on_arrived() -> void:
	var goal := _walk_goal
	_walk_goal = null
	if goal == null or office.ui.is_busy():
		return
	var tells := office.tells
	var tell := tells.id_of(goal) if tells != null else ""
	if goal == office.interactable_near(office.player.position) or goal == office.people.person_near(office.player.position, Office.REACH) \
			or (not tell.is_empty() and tells.distance(tell, office.player.position) <= Office.REACH):
		office.use(goal)
