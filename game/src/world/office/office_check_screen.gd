class_name OfficeCheckScreen
## The Check at Petra's screen (PLAN 2.10): Meetdata keeps the stream's numbers, so a
## Check is read on her monitor, standing beside her at her desk. The place is there only
## while a Check waits (CheckPanel.due: ready, or checked and waiting for the Act); E
## there and the camera moves onto her screen and the Check opens, drawn as her monitor
## (MonitorScreen). Before that, nothing at her desk but Petra herself. Her desk is in the
## floor's model (build_office.py's Meetdata), so the place is added here.

## The interaction point's id (an Interactable kind of its own).
const ID := "check_screen"
## Petra's desk (cast.json: her seat).
const DESK := "meetdata"
## Where the player stands: at her right shoulder, a little behind her chair (m, in the
## seat's frame: +x her right, +z behind her).
const RIGHT := 0.62
const BACK := 0.35
const PROMPT := "E — Scherm van Petra: de Check"
const LABEL := "Scherm van Petra"


## The place beside her chair, facing her screens; null when her desk is not on the
## loaded floor or Meetdata is shut. Shown only while a Check waits (refresh).
static func place(office: Office) -> Interactable:
	var at := OfficeDesk.place_at(office, ID, DESK, stand(office))
	if at != null:
		at.visible = waiting(office)
	return at


static func stand(office: Office) -> Transform3D:
	var seat := OfficeDesk.seat(office, DESK)
	return Transform3D(seat.basis, seat.origin + seat.basis.x * RIGHT + seat.basis.z * BACK)


## Whether a Check waits at her screen.
static func waiting(office: Office) -> bool:
	return office.session.error.is_empty() and not CheckPanel.due(office.session).is_empty()


## Show the place while a Check waits, hide it after the Act (each frame; cheap).
static func refresh(office: Office) -> void:
	var at := office.interactable(ID)
	if at != null:
		at.visible = waiting(office)
