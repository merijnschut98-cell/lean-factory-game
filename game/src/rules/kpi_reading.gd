class_name KpiReading
## The real number a KPI stands for, read from the region now (content/kpis.yaml
## `measure` and `at`): what the KPI board writes on a card (PLAN 2.4c). Pure: it only
## reads the network.

## Over the last four weeks, like the obeya wall's numbers.
const WINDOW_DAYS := 28
## Of a stream (`at` a stream id): ValueStream.kpis, and the age of its open work.
const STREAM_MEASURES: Array[String] = ["throughput_per_week", "lead_days_p50", "on_time", "first_time_right", "wip_age"]
## Of a work step (`at` a place): finished per week, its first-time-right rate, its time per job.
const STEP_MEASURES: Array[String] = ["done_per_week", "step_ftr", "touch_minutes"]
## Of the KPI's own team: its planned load over what it has (Capacity).
const POOL_MEASURES: Array[String] = ["utilisation"]
const MEASURES: Array[String] = STREAM_MEASURES + STEP_MEASURES + POOL_MEASURES


## `k`'s number on `net` now; 0 when the content names nothing measurable here.
static func value(net: Network, k: KpiDef) -> float:
	if k.measure in POOL_MEASURES:
		var pool: Dictionary = Capacity.analyse(net)["pools"].get(k.pool, {})
		var load := float(pool.get("utilisation", 0.0))
		return load if is_finite(load) else 0.0
	if k.measure in STEP_MEASURES:
		var step := net.step_at(k.at)
		if step == null:
			return 0.0
		match k.measure:
			"done_per_week":
				var done: int = step.stats_since(SimCalendar.day_of(net.time) - WINDOW_DAYS)["done"]
				return done * 7.0 / WINDOW_DAYS
			"step_ftr":
				return step.ftr
		return float(step.touch_minutes)
	var stream := net.stream(k.at)
	if stream == null or not k.measure in STREAM_MEASURES:
		return 0.0
	if k.measure == "wip_age":
		return net.open_age_days(stream)
	return float(stream.kpis(net.time, WINDOW_DAYS)[k.measure])
