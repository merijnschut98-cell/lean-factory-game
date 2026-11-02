class_name Reputation
extends RefCounted
## How the management team (MT) of the region sees the CI lead, 0..100: a
## measure of its own, next to trust (per team) and the budget (Merijn,
## 2026-10-15). It gates the region-wide and strategic work later on, and it
## never locks the game: small missions can always rebuild it.
##
## It follows the three deep-thinking principles (CLAUDE.md §2): it pays for
## improvements that last (a fix still holding half a year later) and for
## owning a regression, it costs when people are blamed, and it never pays a
## quick win more than a lasting one. All numbers are ESTIMATES (mission-
## system spec §2.7, audit R6).

const START := 30
const MAX := 100
const MAIN_MISSION := 5
const SIDE_MISSION := 2
## A mission done again after its fix faded: owning the regression.
const REOPENED := 2
## A solved problem whose fix moved the stream's flow (score impact ≥ 4).
const FLOW_GAIN := 3
const FLOW_IMPACT := 4
## A fix still holding (health ≥ HELD_HEALTH) HELD_DAYS after its Act:
## long term over short term, proven by time (audit R6).
const HELD_FIX := 2
const HELD_DAYS := 180
const HELD_HEALTH := 0.9
## Respect for people comes first.
const BLAME := -1
const DEADLINE_MISSED := -10
const BAD_PERIOD := -5

var value := START


## Change by `delta` (bounded); the {type: reputation, ...} event, or {} when
## nothing changed.
func change(delta: int, reason: String) -> Dictionary:
	var before := value
	value = clampi(value + delta, 0, MAX)
	if value == before:
		return {}
	return {"type": "reputation", "change": value - before, "reason": reason, "value": value}
