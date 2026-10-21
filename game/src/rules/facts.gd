class_name Facts
extends RefCounted
## Path dependence (Merijn, 2026-10-15; mission-system spec §2.15): what the
## player did, skipped or chose, as facts ("chose:transformer_wait:
## framework_contracts", "flag:mt_trusts_you"), and one `needs` expression
## that missions, countermeasures and (later) strategic options are gated by:
##   {all: [atom, ...], any: [atom, ...], none: [atom, ...]}
## An atom is a fact, or a live measure: "maturity>=3", "reputation>=60".
## What you can decide depends on what you did before; a missing preparation
## locks an option, and another route back always remains (the validator
## checks that, tools/build_content.py).
##
## This class keeps the facts that are recorded; Missions adds the ones it
## derives live (done:, failed:) and the measures (see Missions.knows).

## Fact kinds content may name (mirrored in build_content.py as FACT_KINDS):
## done:<mission>, failed:<mission>, chose:<problem>:<cm>,
## standardised:<problem>, poor_fix:<problem>, repaired:<problem>,
## fork_first:<group>:<mission>, flag:<name>; the dialog system's
## heard:/committed:/complied:/partial:/blocked:<dialog>; checked:<problem>
## (its Check passed) and accepted:<mission> (taken on, maybe done since),
## both derived live by Missions.knows; forecast_positive:<kpi_board | a
## Check KPI> (a quarterly review's forecast beat the habit, or a Check's
## forecast moved its predicted KPI; GameSession records it); the story's
## (phase-2 design §3.2): agreed:<dialog>:<proposal> (a proposal agreed),
## delivered:<story> (a followed order connected), left:<person> (someone who left;
## GameSession records these three), promise_kept:/promise_broken:<dialog> (a
## promised date checked, Missions), and holds:<problem> (its fix in use and not
## slipped, derived live by Missions.knows).
const KINDS: Array[String] = ["done", "failed", "chose", "standardised", "poor_fix", "repaired", "fork_first", "flag",
	"heard", "committed", "complied", "partial", "blocked", "checked", "accepted", "forecast_positive", "agreed",
	"delivered", "left", "promise_kept", "promise_broken", "holds"]
const FORECAST_POSITIVE := "forecast_positive:"
## Live measures an atom can compare with ">=".
const MEASURES: Array[String] = ["maturity", "reputation"]

var _facts: Dictionary[String, bool] = {}


func add(fact: String) -> void:
	_facts[fact] = true


func remove(fact: String) -> void:
	_facts.erase(fact)


func has(fact: String) -> bool:
	return _facts.has(fact)


## Remove every fact starting with `prefix` (e.g. the earlier choice for a
## problem, "chose:custom_design:").
func remove_prefix(prefix: String) -> void:
	for fact: String in _facts.keys():
		if fact.begins_with(prefix):
			_facts.erase(fact)


func with_prefix(prefix: String) -> Array[String]:
	var out: Array[String] = []
	for fact: String in _facts:
		if fact.begins_with(prefix):
			out.append(fact)
	return out


func to_list() -> Array[String]:
	var out: Array[String] = []
	out.assign(_facts.keys())
	out.sort()
	return out


## Restore to_list() output; anything that is not a known kind of fact is
## dropped (and returned).
func load_list(saved: Variant) -> Array[String]:
	_facts.clear()
	var dropped: Array[String] = []
	for fact: Variant in saved if saved is Array else []:
		if str(fact).get_slice(":", 0) in KINDS and str(fact).contains(":"):
			_facts[str(fact)] = true
		else:
			dropped.append(str(fact))
	return dropped


## Whether `needs` holds, asking `knows` (atom → bool) for each atom. Empty
## needs always hold.
static func met(needs: Dictionary, knows: Callable) -> bool:
	for atom: Variant in needs.get("all", []):
		if not knows.call(str(atom)):
			return false
	var any: Array = needs.get("any", [])
	if not any.is_empty() and not any.any(func(atom: Variant) -> bool: return knows.call(str(atom))):
		return false
	for atom: Variant in needs.get("none", []):
		if knows.call(str(atom)):
			return false
	return true


## A measure atom ("maturity>=3") as [measure, at least], or [] when the atom
## is a fact.
static func measure(atom: String) -> Array:
	var parts := atom.split(">=")
	if parts.size() != 2 or not parts[0] in MEASURES or not parts[1].is_valid_int():
		return []
	return [parts[0], parts[1].to_int()]
