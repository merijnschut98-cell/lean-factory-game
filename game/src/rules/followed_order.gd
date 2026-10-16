class_name FollowedOrder
extends RefCounted
## One customer's dossier followed through the stream (Merijn, 2026-10-15;
## audit §3.0): the El Amrani family's connection is a real work order in the
## simulation, so how long it waits, how many hours are worked on it and when
## it is delivered are computed, never scripted. It makes lead time personal.

const STREAM := "connections"
## Where the family's dossier lies when play starts: early in the stream
## (Anouk's tray in the training week).
const START_STEPS := ["intake", "design"]

## Week counts in words, for the briefings (index = weeks).
const WEEK_WORDS := ["één", "één", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien", "elf", "twaalf",
	"dertien", "veertien", "vijftien", "zestien", "zeventien", "achttien", "negentien", "twintig"]

var order_id := -1
var born := 0
## When it was delivered (minutes); -1 while it is under way.
var delivered_at := -1
## Its last known step and touch hours (kept once it is delivered).
var _step := ""
var _touch_hours := 0.0


## Follow the oldest open order waiting early in the stream.
func pick(net: Network) -> void:
	var oldest: WorkOrder = null
	for o in net.open_orders(net.stream(STREAM)):
		if o.current_step().id in START_STEPS and (oldest == null or o.born < oldest.born):
			oldest = o
	if oldest != null:
		order_id = oldest.id
		born = oldest.born
		_note(oldest)


## Where it is now; delivered once it is no longer open.
func update(net: Network) -> void:
	if order_id < 0 or delivered_at >= 0:
		return
	for o in net.open_orders(net.stream(STREAM)):
		if o.id == order_id:
			_note(o)
			return
	delivered_at = net.time
	_step = ""


## The hours of work it has had: every work step before its current one,
## and what is done of the current one.
func _note(o: WorkOrder) -> void:
	_step = o.current_step().id
	var minutes := 0
	for i in o.step_index:
		var step: SimStep = o.stream.steps[i]
		if step.kind == SimStep.Kind.WORK:
			minutes += step.touch_minutes
	if o.started and o.current_step().kind == SimStep.Kind.WORK:
		minutes += maxi(0, o.current_step().touch_minutes - o.remaining)
	_touch_hours = minutes / 60.0


## {age_days (born to now or delivery), touch_hours, step ("" once
## delivered), delivered_days (-1 while under way)}.
func view(net: Network) -> Dictionary:
	var end := delivered_at if delivered_at >= 0 else net.time
	return {
		"age_days": (end - born) / float(SimCalendar.MINUTES_PER_DAY), "touch_hours": _touch_hours, "step": _step,
		"delivered_days": (delivered_at - born) / float(SimCalendar.MINUTES_PER_DAY) if delivered_at >= 0 else -1.0,
	}


## A wait in whole weeks as a briefing says it: "één week", "elf weken",
## "31 weken" (at least one week).
static func weeks_text(days: float) -> String:
	var weeks := maxi(1, int(days / 7.0))
	var word: String = WEEK_WORDS[weeks] if weeks < WEEK_WORDS.size() else str(weeks)
	return word + (" week" if weeks == 1 else " weken")


func to_dict() -> Dictionary:
	return {"order": order_id, "born": born, "delivered_at": delivered_at, "step": _step, "touch_hours": _touch_hours}


func load_dict(d: Dictionary) -> void:
	order_id = int(d.get("order", -1))
	born = int(d.get("born", 0))
	delivered_at = int(d.get("delivered_at", -1))
	_step = str(d.get("step", ""))
	_touch_hours = float(d.get("touch_hours", 0.0))
