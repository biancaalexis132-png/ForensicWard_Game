class_name CluePickup
extends Node3D
## CluePickup: a physical document the player can collect (e.g. a ward roster).
## Hidden once the clue is acquired; reappears correctly after loading a save
## because visibility is derived from EvidenceManager, not stored separately.

@export var clue_id: String = ""

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interactable_id = "pickup:" + clue_id
	var clue: Dictionary = ContentRegistry.get_clue(clue_id)
	_interactable.prompt = "Take " + (clue.get("title", "document") as String)
	_interactable.interacted.connect(_on_interacted)
	EventBus.game_loaded.connect(func(_slot: int) -> void: _refresh())
	_refresh()


func _on_interacted(_interactor: Node) -> void:
	WorldActions.reveal_clue(clue_id, "pickup:" + name)
	_refresh()


func _refresh() -> void:
	var taken: bool = EvidenceManager.has_clue(clue_id)
	visible = not taken
	_interactable.enabled = not taken
	_interactable.monitorable = not taken
