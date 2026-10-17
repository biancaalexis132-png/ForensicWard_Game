class_name Interactable
extends Area3D
## Interactable: a component that makes its parent usable with the E key.
##
## Add as a child of a prop with a CollisionShape3D child. The player's
## interaction ray hits it on physics layer 2 ("interactable"). The owning
## prop connects to `interacted` and may supply a dynamic prompt through
## `prompt_provider` (e.g. "Open door" / "Close door").

signal interacted(interactor: Node)

const INTERACTABLE_LAYER: int = 2

## Stable id for logs and EventBus.interacted, e.g. "door_office".
@export var interactable_id: String = ""
@export var prompt: String = "Interact"
@export var enabled: bool = true

## Optional Callable returning the prompt text; overrides `prompt`.
var prompt_provider: Callable = Callable()


func _ready() -> void:
	collision_layer = 1 << (INTERACTABLE_LAYER - 1)
	collision_mask = 0
	monitoring = false
	monitorable = true


func get_prompt() -> String:
	if prompt_provider.is_valid():
		return prompt_provider.call()
	return prompt


func interact(interactor: Node) -> void:
	if not enabled:
		return
	# Owning props assign the id in their _ready, which runs after ours.
	if interactable_id.is_empty():
		push_warning("Interactable at %s has no interactable_id" % get_path())
	interacted.emit(interactor)
	EventBus.interacted.emit(interactable_id)
