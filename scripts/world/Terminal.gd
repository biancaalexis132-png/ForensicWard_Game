class_name Terminal
extends Node3D
## Terminal: a workstation that opens a read-only info panel.
##
## Modes:
##   PATIENT_ROSTER  lists admitted patients (opens each record once per day)
##   CLUE_DOCUMENT   shows a clue's document and acquires it for the player
##   SYSTEM_STATUS   content validation report (useful during development)
## EHR terminals open the EHR screen.

enum Mode { PATIENT_ROSTER, CLUE_DOCUMENT, SYSTEM_STATUS }

@export var terminal_id: String = ""
@export var title: String = "Terminal"
@export var mode: Mode = Mode.PATIENT_ROSTER
## For CLUE_DOCUMENT: the clue this terminal reveals.
@export var clue_id: String = ""

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interactable_id = terminal_id
	_interactable.prompt = "Use " + title
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(_interactor: Node) -> void:
	match mode:
		Mode.PATIENT_ROSTER:
			WorldActions.open_ehr(title)
		Mode.CLUE_DOCUMENT:
			WorldActions.reveal_clue(clue_id, "terminal:" + terminal_id)
		Mode.SYSTEM_STATUS:
			WorldActions.show_system_status(title)
