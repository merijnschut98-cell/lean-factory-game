class_name ExplainerRig
extends RefCounted
## The controls and the model behind one "Hoe werkt het?" explainer (PLAN
## 2.7c): what the player has switched or turned, what the beats wait for,
## and what the drawing shows for it (layers by state, needles, wheels, LEDs,
## the LCD faces, the card's readout, the reveal's live numbers, the heat).
## ExplainerBeats and ExplainerView drive any explainer through this one
## interface; each model has its own rig (OhmRig for #1, TrafoRig for #2),
## picked by the content's `model`. Pure: no scene access, tested headless.
##
## A control named in a beat's `unlocks` is locked until that beat (or for
## good in the codex: unlock_all).

var def: ExplainerDef
var locked: Array[String] = []
## The state as the current beat began (waits that ask "changed since").
var at_start := {}


static func create(explainer: ExplainerDef) -> ExplainerRig:
	if explainer.model == TrafoRig.MODEL:
		return TrafoRig.new(explainer)
	return OhmRig.new(explainer)


func _init(explainer: ExplainerDef) -> void:
	def = explainer
	for b: Dictionary in def.beats:
		for control: String in b.get("unlocks", []):
			if not locked.has(control):
				locked.append(control)


func unlock(control: String) -> void:
	locked.erase(control)


func unlock_all() -> void:
	locked.clear()


func is_locked(control: String) -> bool:
	return locked.has(control)


## Flip a switch or turn a stepped control by `step` (+1 or -1). False when
## refused: locked, unknown, or already at its end.
func toggle(control: String, step: int = 1) -> bool:
	if is_locked(control):
		return false
	return _apply(control, step)


## A beat begins (or is played again): remember the state its waits compare against.
func mark() -> void:
	at_start = snapshot()


# ── For each model to fill in ───────────────────────────────────────────────

func _apply(_control: String, _step: int) -> bool:
	return false


## The controls' state as plain values.
func snapshot() -> Dictionary:
	return {}


## The state changed in this phase (a rig may remember what it saw).
func note(_phase: String) -> void:
	pass


## A beat's `when` or `skip_when`.
func holds(_condition: String) -> bool:
	return false


## A beat's `wait_for`.
func met(_wait: String) -> bool:
	return false


## Time passes: temperatures ease, wheels turn (reduced motion: no easing, no turning).
func step(_dt: float, _reduced_motion: bool) -> void:
	pass


## Whether a layer's `when` (from the manifest) holds now.
func shows(_when: Dictionary) -> bool:
	return true


## 0..1: how warm a heat layer looks.
func heat(_layer_id: String) -> float:
	return heat_level()


## 0..1: the warmth the analogy and the real thing share.
func heat_level() -> float:
	return 0.0


## 0..1 along a needle's sweep.
func needle(_id: String) -> float:
	return 0.0


## A wheel's turn, 0..1.
func turn(_id: String) -> float:
	return 0.0


func led(_id: String) -> bool:
	return false


func lcd_text(_id: String) -> String:
	return ""


## The card's readout (the real skin), from the content's labels.
func readout(_labels: Dictionary) -> String:
	return ""


## The values the reveal's `live` lines fill in.
func reveal_values() -> Dictionary:
	return {}


## Dutch number: a decimal comma, a thousands dot.
static func nl(x: float, decimals: int) -> String:
	var text := ("%." + str(decimals) + "f") % x if decimals > 0 else str(roundi(x))
	var parts := text.split(".")
	var whole := parts[0]
	var grouped := ""
	while whole.lstrip("-").length() > 3:
		grouped = "." + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	return whole + grouped + ("," + parts[1] if parts.size() > 1 else "")
