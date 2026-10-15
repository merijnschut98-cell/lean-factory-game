class_name CheckForecast
## The Check's counterfactual (the pattern of KpiBoard.forecast): the coming
## `days` run twice on copies of the network, "with" the fix as it stands and
## "without" it (the problem at full strength, no countermeasure). Both
## continue the same random sequences, so they differ only in the fix, and
## the stream's own trend lands on both. The game itself does not move on.
##
## Lagging KPIs (lead time, on time, first time right) measure orders that
## started long before the fix; the caller picks `window`, the last days of
## the run over which the KPIs are measured, so that those orders started
## after the fix.


## {error, days, window, with, without (Region.measures at the end), gains
## (every Investigation.KPIS → Pdca.kpi_gain from without to with)}, or
## {error} when a copy fails. `net` is only read.
static func run(net: Network, problem: ProblemDef, days: int, window: int) -> Dictionary:
	var with_fix := NetworkState.copy(net)
	var without := NetworkState.copy(net)
	var error := with_fix.error if not with_fix.error.is_empty() else without.error
	if error.is_empty():
		without.clear_effects("cm:" + problem.id)
		error = without.set_effects("problem:" + problem.id, problem.effects)
	if not error.is_empty():
		return {"error": error}
	var out := {"error": "", "days": days, "window": window, "gains": {}}
	for run: String in ["with", "without"]:
		var twin: Network = with_fix if run == "with" else without
		twin.advance_days(days)
		out[run] = Region.measures(twin, problem.step, window)
	for kpi: String in Investigation.KPIS:
		out["gains"][kpi] = Pdca.kpi_gain(kpi, out["without"], out["with"])
	return out
