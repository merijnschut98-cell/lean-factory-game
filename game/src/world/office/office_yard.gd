class_name OfficeYard
extends Node
## The yard by the hour (PLAN 2.2; spec 2026-10-17-the-yard.md §5): the monteurs take their
## vans out in the morning and bring them back in the afternoon. Before 07:45 and from 16:15
## every bay holds a van; in between only the storingsbussen on call stay. A child of the
## Office while the yard is loaded; it reads the session's clock.

## The storingsbussen (van0, van1): on call, they stay in the yard all day.
const ON_CALL: Array[int] = [0, 1]
const VANS := 6
## Out from (minutes since midnight) and back at.
const OUT := 7 * 60 + 45
const BACK := 16 * 60 + 15
## Seconds between looks at the clock.
const POLL_SECONDS := 1.0

var office: Office
var _since := INF


## Park the vans in `geometry` (the yard's model) as they stand at `minute`.
static func park(geometry: Node, minute: int) -> void:
	var out := minute >= OUT and minute < BACK
	for k in VANS:
		var van := Office._find_marker(geometry, "van%d" % k, Office._loose("van%d" % k))
		if van != null:
			van.visible = not out or k in ON_CALL


func _process(delta: float) -> void:
	_since += delta
	if office == null or _since < POLL_SECONDS or not office.session.error.is_empty():
		return
	_since = 0.0
	park(office.geometry, office.session.minute_of_day())
