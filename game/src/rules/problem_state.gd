class_name ProblemState
extends RefCounted
## Where one problem stands in the PDCA loop:
## dormant → active (hurting the simulation) → spotted (the player knows) →
## doing (experiment running) → check_ready → checked → resolved, and back
## to active if an unstandardised fix fades.

var id: String
var phase := "dormant"
var tools_used := PackedStringArray()
## A blaming question was asked of the team while it was open.
var blamed := false
## {waste, cause, evidence, cm, prediction}; empty until submitted.
var a3: Dictionary = {}
var eff := 0.0
var level := ""
var tried := PackedStringArray()
var failed_checks := 0
var check_at := 0
## Snapshot before the experiment (see Region.snapshot).
var baseline: Dictionary = {}
var standardised := false
## When an unstandardised fix fades; -1: never.
var recur_at := -1
var score: Dictionary = {}


func _init(problem_id: String) -> void:
	id = problem_id


func is_open() -> bool:
	return phase in ["active", "spotted", "doing", "check_ready", "checked"]


## The player knows about it and it is not solved yet.
func is_known() -> bool:
	return is_open() and phase != "active"
