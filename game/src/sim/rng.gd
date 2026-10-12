class_name Rng
extends RefCounted
## The simulation's only source of randomness. Seeded and saveable, so a run
## replays exactly — which is what makes the simulation testable.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value


## Uniform float in [0, 1).
func next() -> float:
	return _rng.randf()


## Exponentially distributed sample with the given mean (e.g. time to failure).
func exp_mean(mean: float) -> float:
	return -log(1.0 - _rng.randf()) * mean


## Uniform in [mean·(1−spread), mean·(1+spread)].
func around(mean: float, spread: float) -> float:
	return _rng.randf_range(mean * (1.0 - spread), mean * (1.0 + spread))


## Poisson-distributed count with the given mean (e.g. requests per day).
func poisson(mean: float) -> int:
	var limit := exp(-mean)
	var k := 0
	var p := _rng.randf()
	while p > limit:
		k += 1
		p *= _rng.randf()
	return k


## Uniform integer in [low, high].
func int_range(low: int, high: int) -> int:
	return _rng.randi_range(low, high)


## True with the given probability.
func chance(probability: float) -> bool:
	return _rng.randf() < probability


func pick(items: Array) -> Variant:
	return items[int_range(0, items.size() - 1)] if not items.is_empty() else null


## Internal state, for save files. Restoring it continues the same sequence.
func get_state() -> int:
	return _rng.state


func set_state(value: int) -> void:
	_rng.state = value
