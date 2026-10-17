class_name Opening
## De eerste vijf minuten (PLAN 2.7d; spec 2026-10-16-first-five-minutes): the
## beats of a new game's first day, kept in the session layer (saved), and
## which HUD element shows when (spec §3). It reads the session; it changes no
## rule. A game without an opening (a returning player, an old save, the
## tests) has `opening_beat` "" and the full HUD.

const ARRIVAL := "arrival"     # B2: the ontvangst, Yvonne and the badge
const WALK := "walk"           # B3: Ruud's walk to Aansluitingen
const BOARD := "board"         # B4: Ruud's whiteboard, skippable
const LETTER := "letter"       # B5: the El Amrani letter
const EVENING := "evening"     # B6: the rest of the day, skipped to 19:00
const ANOUK := "anouk"         # B7: Anouk at seven
const DONE := "done"           # the opening is over (the week goes on)
const BEATS: Array[String] = [ARRIVAL, WALK, BOARD, LETTER, EVENING, ANOUK, DONE]

## The HUD elements that wait for their moment.
const ELEMENTS: Array[String] = ["clock", "controls", "journal", "codex", "map", "mission", "board", "budget", "xp"]


## Move the opening on to `beat` (never back). False when it is not ahead.
static func advance(layer: SessionLayer, beat: String) -> bool:
	if not beat in BEATS or BEATS.find(beat) <= BEATS.find(layer.opening_beat):
		return false
	layer.opening_beat = beat
	return true


## Whether the opening has reached `beat` (or is past it). No opening: true.
static func reached(layer: SessionLayer, beat: String) -> bool:
	return layer.opening_beat.is_empty() or BEATS.find(layer.opening_beat) >= BEATS.find(beat)


## Whether the opening is running now (a beat before DONE).
static func running(layer: SessionLayer) -> bool:
	return not layer.opening_beat.is_empty() and layer.opening_beat != DONE


## Which HUD element shows now (spec §3), {element: bool}: each comes when it
## is first needed and stays; all of them without an opening or once the
## training week is over.
static func hud(s: GameSession, layer: SessionLayer) -> Dictionary:
	var out := {}
	var all := layer.opening_beat.is_empty() or not s.in_training()
	var tuesday := day_reached(s, "training_tue")
	var shown := {
		"clock": reached(layer, ANOUK) or tuesday,
		"journal": reached(layer, DONE),
		"controls": tuesday,
		"codex": tuesday or s.explainers.seen.size() > 0,
		"map": tuesday,
		"mission": tuesday,
		"board": tuesday,
		"budget": day_reached(s, "training_thu"),
		"xp": day_reached(s, "training_fri"),
	}
	for element: String in ELEMENTS:
		out[element] = all or shown[element]
	return out


static func day_reached(s: GameSession, mission_id: String) -> bool:
	return s.missions.done_once.has(mission_id) or s.missions.status(mission_id) in ["active", "completed"]
