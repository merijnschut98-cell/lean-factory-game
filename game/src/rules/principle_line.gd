class_name PrincipleLine
## The principle line (phase-2 design §3.7): one sentence after a main mission's debrief,
## Ruud's note on which of the three principles (CLAUDE.md §2: long term over short term,
## respect for people, always improve) paid or cost, chosen from what the play left. The
## lines are content (missions.yaml `principles`); this picks the code and the line. Pure.

## In the order they win: the first that holds is named.
const CODES: Array[String] = ["long_term_cost", "respect_blamed", "respect_complied", "improve_cost",
	"respect_committed", "improve_paid", "long_term_paid"]


## The code for `facts`: {poor_fix, fading (a fix chosen to fade while a lasting one fit
## as well), blamed, complied (who only complied, or ""), committed (who committed, or
## ""), standardised, failed_checks}.
static func code(facts: Dictionary) -> String:
	if facts.get("poor_fix", false) or facts.get("fading", false):
		return "long_term_cost"
	if facts.get("blamed", false):
		return "respect_blamed"
	var committed := str(facts.get("committed", ""))
	if not str(facts.get("complied", "")).is_empty() and committed.is_empty():
		return "respect_complied"
	if not facts.get("standardised", false):
		return "improve_cost"
	if not committed.is_empty():
		return "respect_committed"
	return "improve_paid" if int(facts.get("failed_checks", 0)) > 0 else "long_term_paid"


## `code`'s line in `bank` for `mission_id` (the same one each time), with {wie} as
## `who`; "" when the bank has none.
static func line(bank: Dictionary, code_id: String, mission_id: String, who: String) -> String:
	var lines: Array = bank.get(code_id, [])
	if lines.is_empty():
		return ""
	return str(lines[absi(hash(mission_id)) % lines.size()]).replace("{wie}", who)
