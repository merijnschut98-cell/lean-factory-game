class_name SustainView
## What the UI shows of sustain or decay (CLAUDE.md §2): the resolved fixes
## and how each one is holding up. It reads GameSession.sustain_of and shows
## the measure only (health, days since anyone checked the standard), never
## the mechanisms that would hand over the remedy.


## The resolved fixes, in content order; at `place` only when given. The
## training week's practice problem is retired, so it is left out.
static func fixes(s: GameSession, place: String = "") -> Array[String]:
	var out: Array[String] = []
	for p in s.region.problem_list():
		if (place.is_empty() or p.step == place) and not s.is_practice(p.id) and not s.sustain_of(p.id).is_empty():
			out.append(p.id)
	return out


## Green while the fix holds, orange once it slips (the `slipping` line).
static func color(health: float) -> Color:
	return Palette.GREEN_DARK if health >= Sustain.SLIPPING_HEALTH else Palette.SAFETY_ORANGE


## A fix as two lines in `parent`: its name (and place), then its health.
static func add_fix(parent: Node, s: GameSession, problem_id: String, with_place: bool) -> void:
	var p: ProblemDef = s.region.problems[problem_id]
	var step := s.region.net.step_at(p.step)
	var name := "%s  —  %s" % [p.name, step.name] if with_place and step != null else p.name
	parent.add_child(UiPanel.label(name, UiTheme.SMALL, Palette.VOLTANA_BLUE))
	var sustain := s.sustain_of(problem_id)
	parent.add_child(UiPanel.paragraph(UiText.fix_health(sustain), color(sustain["health"]), UiTheme.SMALL))
