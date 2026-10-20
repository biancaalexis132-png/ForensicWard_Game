class_name MapScreen
extends CanvasLayer
## Simple in-game floor map/directory

const PANEL_ID: String = "map"

var is_open: bool = false

@onready var _close_button: Button = $Root/Panel/Margin/VBox/Close
@onready var _text: RichTextLabel = $Root/Panel/Margin/VBox/Text

func _ready() -> void:
	layer = 9
	visible = false
	if has_node("Root/Panel/Margin/VBox/Close"):
		_close_button.pressed.connect(close)


func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	if _text:
		_text.text = "[b]Ashcroft State Forensic Hospital - Clinical Wing[/b]\n\n[b]Key Locations:[/b]\n- Nursing Station - Handover, sign-out\n- Interview Room A - Patient interviews\n- EHR Workstation - Chart review & orders\n- Records Archive - Transfer summaries & documentation\n- Corridor - Navigation between areas\n- Psychiatrist Office - Staff consultations\n\n[b]Controls:[/b]\n[E] Interact  |  [Tab/Journal] Evidence Board  |  [I/EHR] Electronic Health Record  |  [Esc] Pause/Menu\n\nClinical duties are separate from institutional investigation objectives."
	if has_node("Root/Panel/Margin/VBox/Close"):
		_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)
