extends Node3D
## Main — temporary boot scene used to verify the project is wired correctly.
##
## Shows a status line proving both autoloads are loaded and that EventBus
## signals reach listeners. Press O / P to drain / restore objectivity and
## watch the bleed stage change. This scene will later be replaced by the
## real ward level once FPSPlayer.gd exists.

@onready var _status_label: Label = $HUD/StatusLabel


func _ready() -> void:
	EventBus.objectivity_changed.connect(_on_objectivity_changed)
	EventBus.bleed_stage_changed.connect(_on_bleed_stage_changed)
	GameState.start_shift(1, "day")
	_refresh_label()
	print("[The Forensic Ward] Boot OK - EventBus and GameState loaded.")


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_O:
			GameState.change_objectivity(-10.0)
		KEY_P:
			GameState.change_objectivity(10.0)


func _on_objectivity_changed(_old_value: float, _new_value: float) -> void:
	_refresh_label()


func _on_bleed_stage_changed(stage: int) -> void:
	print("[Bleed] stage -> %d" % stage)


func _refresh_label() -> void:
	_status_label.text = (
		"THE FORENSIC WARD - systems online\n"
		+ "Day %d (%s shift)\n" % [GameState.day, GameState.shift]
		+ "Objectivity: %.0f / %.0f   Bleed stage: %d\n" % [
			GameState.objectivity, GameState.OBJECTIVITY_MAX, GameState.bleed_stage]
		+ "[O] drain objectivity   [P] restore"
	)
