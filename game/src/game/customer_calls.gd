class_name CustomerCalls
## Customers ring the player's phone (PLAN 2.4, phase 2 design §2.5): when a
## customer's talk is due (GameSession.customer_calls), their call rings once a
## day, in the KCC's opening hours, when the player is free. Answering opens the
## talk as a call; letting it go costs nothing (respect the player's time): it
## leaves a voicemail in Berichten and the talk waits, at the KCC's headset or
## for tomorrow's call. What rang when is kept in the session layer (saved).

## The hours a customer calls (minutes of the day; an ESTIMATE: the contact
## centre's ordinary opening hours, nine to five).
const FROM := 9 * 60
const UNTIL := 17 * 60
## A missed call's message id in the inbox: MISSED + "<dialog>:<day>".
const MISSED := "missed:"


## The call that rings now ({person, dialog, name}), or {}: the first customer
## whose talk is due, in office hours, that has not rung today.
static func ringing(s: GameSession, layer: SessionLayer) -> Dictionary:
	var minute := s.minute_of_day()
	if minute < FROM or minute >= UNTIL:
		return {}
	var today := SimCalendar.day_of(s.region.net.time)
	for call: Dictionary in s.customer_calls():
		if int(layer.rang.get(call["dialog"], -1)) != today:
			return call
	return {}


## `call` rang today: it does not ring again until tomorrow.
static func rang(s: GameSession, layer: SessionLayer, call: Dictionary) -> void:
	layer.rang[call["dialog"]] = SimCalendar.day_of(s.region.net.time)


## The player let `call` go: their voicemail waits in Berichten. Nothing else
## changes.
static func missed(s: GameSession, layer: SessionLayer, call: Dictionary) -> void:
	PhoneMessages.push(layer, "%s%s:%d" % [MISSED, call["dialog"], SimCalendar.day_of(s.region.net.time)],
		s.region.net.time)
