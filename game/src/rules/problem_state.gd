class_name ProblemState
extends RefCounted
## Where one problem stands in the PDCA loop:
## dormant → active (hurting the simulation) → spotted (the player knows) →
## doing (experiment running) → check_ready → checked → resolved, and back
## to dormant when the fix wears out (Sustain; its mission brings it back).

enum Phase { DORMANT, ACTIVE, SPOTTED, DOING, CHECK_READY, CHECKED, RESOLVED }

var id: String
var phase := Phase.DORMANT
## A blaming question was asked of the team while it was open.
var blamed := false
## {waste, cause, evidence, cm, prediction}; empty until submitted.
var a3: Dictionary = {}
## Verdicts on the A3, fixed when it is submitted.
var cause_correct := false
var waste_right := false
var eff := 0.0
var level := ""
var failed_checks := 0
var check_at := 0
## Snapshot before the experiment (see Region.snapshot).
var baseline: Dictionary = {}
## The Act standardised the fix (the main sustaining habit, see Sustain).
var standardised := false
## How worn the resolved fix is (Sustain): health 0.5^wear, it recurs at 1.
var wear := 0.0
## Days since anything was done to sustain the fix (the Act, an audit, a
## routine): the longer, the faster it wears.
var neglect := 0.0
var score: Dictionary = {}


func _init(problem_id: String) -> void:
	id = problem_id


## For save files (the phase by name).
func to_dict() -> Dictionary:
	return {
		"phase": Phase.keys()[phase], "blamed": blamed, "a3": a3, "cause_correct": cause_correct,
		"waste_right": waste_right, "eff": eff, "level": level, "failed_checks": failed_checks,
		"check_at": check_at, "baseline": baseline, "standardised": standardised, "wear": wear,
		"neglect": neglect,
		"score": score,
	}


## Restore to_dict() output; false (and nothing changed) if the phase is unknown.
func load_dict(d: Dictionary) -> bool:
	var saved_phase := Phase.keys().find(d.get("phase", ""))
	if saved_phase < 0:
		return false
	phase = saved_phase
	blamed = bool(d.get("blamed", false))
	a3 = d.get("a3", {}) if d.get("a3") is Dictionary else {}
	cause_correct = bool(d.get("cause_correct", false))
	waste_right = bool(d.get("waste_right", false))
	eff = float(d.get("eff", 0.0))
	level = str(d.get("level", ""))
	failed_checks = int(d.get("failed_checks", 0))
	check_at = int(d.get("check_at", 0))
	baseline = d.get("baseline", {}) if d.get("baseline") is Dictionary else {}
	# Saves from before graded sustainment: a fix that never faded was standardised.
	standardised = bool(d.get("standardised", phase == Phase.RESOLVED and int(d.get("recur_at", 0)) < 0))
	wear = maxf(0.0, float(d.get("wear", 0.0)))
	neglect = maxf(0.0, float(d.get("neglect", 0.0)))
	score = d.get("score", {}) if d.get("score") is Dictionary else {}
	return true


func is_open() -> bool:
	return phase != Phase.DORMANT and phase != Phase.RESOLVED


## The player knows about it and it is not solved yet.
func is_known() -> bool:
	return is_open() and phase != Phase.ACTIVE
