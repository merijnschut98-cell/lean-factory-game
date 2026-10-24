class_name OfficeHeadset
## The customer call as a place (PLAN 2.4, phase 2 design §1.7): a free desk at
## the Klantcontactcentrum (begane grond) with its headset. Standing behind its
## chair (E, or a click on the ring) the player sits down, puts on the headset
## and takes the next call: a customer whose talk is due (GameSession.
## customer_calls). With nobody waiting the line is quiet: a short note, no
## talk. The desk is in the floor's model already (build_office.py), so the
## place is added in Godot and the floor needs no rebuild.

## The interaction point's id (an Interactable kind of its own).
const ID := "headset"
## The free desk: no cast member sits there (test_customer_calls checks it).
const DESK := "kcc12"
## How far behind the chair the player stands to use it (m).
const BEHIND := 0.7
const PROMPT := "E — Headset opzetten"
const LABEL := "Headset (KCC)"
## Nobody waiting for the player on the line.
const QUIET := "Het is rustig op de lijn. Er hangt niemand voor je in de wacht."


## The ring behind the free desk's chair, facing the desk; null when the desk is
## not on the loaded floor or its room is shut.
static func place(office: Office) -> Interactable:
	if office.find_marker(DESK + "_headset") == null or office.find_marker(DESK + "_chair") == null:
		return null
	var at := stand(office)
	var shut := office.floors.shut_rects(office.floors.markers())
	if shut.any(func(r: Rect2) -> bool: return r.has_point(Vector2(at.origin.x, at.origin.z))):
		return null
	return Interactable.create(ID, at)


## Where the player stands to use it: behind the chair, facing the desk.
static func stand(office: Office) -> Transform3D:
	var seat := seat_at(office)
	return Transform3D(seat.basis, seat.origin + seat.basis.z * BEHIND)


## The chair, facing the desk (the desk's -Z, as a seated person faces it).
static func seat_at(office: Office) -> Transform3D:
	var chair := office.find_marker(DESK + "_chair")
	var desk := office.find_marker(DESK + "_desk")
	if chair == null or desk == null:
		return Transform3D.IDENTITY
	var forward := -office.in_office(desk).basis.z * Vector3(1, 0, 1)
	return Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), office.in_office(chair).origin * Vector3(1, 0, 1))


## Sit down and take the next call; with nobody waiting, a note that the line
## is quiet. True when a call opened.
static func take_call(office: Office) -> bool:
	var calls := office.session.customer_calls()
	if calls.is_empty():
		office.ui.hud.toast(TranslationServer.translate(QUIET))
		return false
	if not office.ui.open_talk(calls[0]["person"], TalkView.HEADSET).is_empty():
		return false
	office.player.sit_at(seat_at(office))
	wear(office, true)
	return true


## The player puts the desk's headset on (`on`) or back on the desk after the call.
static func wear(office: Office, on: bool) -> void:
	office.player.wear_headset(on)
	var on_desk := office.find_marker(DESK + "_headset")
	if on_desk != null:
		on_desk.visible = not on
