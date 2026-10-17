class_name FlickerLight
extends OmniLight3D
## FlickerLight: an unreliable fluorescent tube for atmosphere.
##
## Accessibility (GDD §11): when Settings "flash_effects" is off, the light
## burns steadily. Uses a seeded RNG stream so flicker timing is reproducible.

@export var base_energy: float = 1.0
@export var min_interval: float = 0.05
@export var max_interval: float = 1.6

var _rng: RandomNumberGenerator = null
var _timer: float = 0.0


func _ready() -> void:
	_rng = SaveManager.make_rng("flicker:" + name)
	light_energy = base_energy


func _process(delta: float) -> void:
	if not Settings.get_value("flash_effects"):
		light_energy = base_energy
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _rng.randf_range(min_interval, max_interval)
	# Mostly on, occasionally dropping out.
	light_energy = base_energy if _rng.randf() > 0.25 else base_energy * _rng.randf_range(0.0, 0.3)
