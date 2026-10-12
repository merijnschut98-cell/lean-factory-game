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


## True with the given probability.
func chance(probability: float) -> bool:
	return _rng.randf() < probability


func pick(items: Array) -> Variant:
	return items[_rng.randi_range(0, items.size() - 1)] if not items.is_empty() else null


## Internal state, for save files. Restoring it continues the same sequence.
func get_state() -> int:
	return _rng.state


func set_state(value: int) -> void:
	_rng.state = value
