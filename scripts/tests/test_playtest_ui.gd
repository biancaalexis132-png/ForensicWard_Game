extends TestCase
## Playtest UI pass: the EHR's Next step bar (derived from the current
## objective) points at Orders once the note is saved, and the document viewer
## shows the paper image of a clue when it is picked up or read from the
## evidence board, falling back to its text when no image exists.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"
const TRANSFER: String = "clue_transfer"
const TRANSFER_IMAGE: String = "res://assets/documents/clue_transfer.png"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	super.after_each()
	if is_instance_valid(_main):
		_main.free()


# --- EHR next step ------------------------------------------------------------------

func test_next_step_points_at_orders_when_objective_is_obj_act() -> void:
	_reach_obj_act()
	check_eq(_director().get_current_objective().get("id", ""), "obj_act", "objective is obj_act")
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	var step: Dictionary = _ehr().get_next_step()
	check(step["visible"], "Next step bar shown")
	check_eq(step["text"], _director().get_current_objective()["text"], "shows the objective's own text")
	check_eq(step["tab"], "Orders", "points at Orders")
	check_eq(_ehr().get_highlighted_tab(), "Orders", "Orders tab highlighted")
	check("Place" in step["hint"], "hint says to press Place, got '%s'" % step["hint"])
	check("Ready now" in step["hint"], "hint names the order ready now")
	var button: Button = _ehr().find_child("GoToNextStep", true, false) as Button
	_ehr().show_tab("Summary")
	check(button != null and button.visible, "Go to Orders button shown")
	button.pressed.emit()
	check_eq(_tabs().get_tab_title(_tabs().current_tab).begins_with("Orders"), true, "button opens Orders")
	check(not button.visible, "button hides once Orders is open")
	check(_ehr().find_child("Place_ord_medical_team_review", true, false) != null, "medical review has a Place button on its row")
	check("Available" in _ehr().get_tab_text("Orders"), "each order shows its status")
	await _release_audio()


func test_next_step_follows_the_objective() -> void:
	await runner.get_tree().process_frame
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	check_eq(_director().get_current_objective().get("id", ""), "obj_meet_bennett", "starts before the EHR objectives")
	check_eq(_ehr().get_highlighted_tab(), "", "no tab highlighted for an objective outside the chart")
	check(not (_ehr().find_child("GoToNextStep", true, false) as Button).visible, "no Go to button")
	_ehr().close()
	_talk_to_bennett()
	PatientManager.record_observation(ELIAS, "obs_mutism", "test")
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	check_eq(_director().get_current_objective().get("id", ""), "obj_document", "documenting is next")
	check_eq(_ehr().get_highlighted_tab(), "Notes", "Notes highlighted for obj_document")
	_ehr().set_note_selection(["obs_mutism"] as Array[String], [] as Array[String], "Plan.")
	_ehr().submit_note()
	check_eq(_ehr().get_highlighted_tab(), "Orders", "Orders highlighted as soon as the note is saved")
	_ehr().request_place("ord_medical_team_review")
	_ehr().confirm_order()
	check(_ehr().get_highlighted_tab() != "Orders", "highlight moves on once an order is placed")
	await _release_audio()


func test_chart_header_shows_patient_data_without_review_labels() -> void:
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	var header: String = _labels_text(_ehr().find_child("ChartHeader", true, false))
	check("Elias Ward" in header, "name in header")
	check("Legal status: Competency Restoration Transfer" in header, "legal status chip")
	check("Alert: no automatic transfer if medically unstable" in header, "transfer hold alert from the patient data")
	check(not "APPROVED" in header, "no review-status label in the header")
	var orders: String = _ehr().get_tab_text("Orders")
	check("Medication orders" in orders and "No medication logic has clinical approval" in orders,
			"medication still listed as unavailable with its reason")
	check("Laboratory tests" in orders, "laboratory still listed as unavailable")
	await _release_audio()


# --- Document viewer -----------------------------------------------------------------

func test_picking_up_transfer_summary_shows_its_document_image() -> void:
	WorldActions.reveal_clue(TRANSFER, "pickup:test")
	check(_info().is_open, "panel opened on pickup")
	check(_info().is_showing_document(), "document image shown")
	check_eq(_info().get_document_viewer().shown_path, TRANSFER_IMAGE, "the transfer summary's own image")
	check("references an archived identifier" in _body_text(), "text still shown beside the page")
	_info().close()
	check(not _info().get_document_viewer().has_image(), "texture released on close")
	EventBus.ui_panel_requested.emit("evidence", {})
	_board().view_document(TRANSFER)
	check(_info().is_open and _info().is_showing_document(), "reopened from the evidence board")
	check_eq(_info().get_document_viewer().shown_path, TRANSFER_IMAGE, "same image from the board")
	check(_board().find_child("View_" + TRANSFER, true, false) != null, "board lists a Read button")
	_info().close()
	check(_board().is_open, "closing the document returns to the board")
	_board().close()
	await _release_audio()


func test_viewer_falls_back_to_text_without_an_image() -> void:
	check_eq(DocumentViewer.image_path("clue_not_drawn"), "", "no image for an unknown clue")
	var viewer: DocumentViewer = DocumentViewer.new()
	runner.add_child(viewer)
	check(not viewer.show_document("clue_not_drawn", "Untitled", "Only text."), "no image shown")
	check("Only text." in viewer.get_fallback_text(), "text shown on the paper card")
	check(viewer.show_document(TRANSFER, "Transfer Summary", "x"), "image shown when it exists")
	check_eq(viewer.get_fallback_text(), "", "no fallback with an image")
	viewer.clear()
	viewer.free()
	EventBus.ui_panel_requested.emit("info", {"title": "Notice", "body": "Plain notice.", "clue_id": "clue_not_drawn"})
	check(_info().is_open and not _info().is_showing_document(), "panel shows text only")
	check("Plain notice." in _body_text(), "text body shown")
	_info().close()
	await _release_audio()


func test_every_chapter1_clue_has_a_manifested_fictional_image() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://assets/asset_manifest/document_images_manifest.json"))
	for clue_id: String in ["clue_transfer", "clue_roster", "clue_access"]:
		check(not DocumentViewer.image_path(clue_id).is_empty(), "image imported for " + clue_id)
		var entry: Dictionary = manifest["documents"].get(clue_id, {})
		check_eq(entry.get("fictional", false), true, clue_id + " marked fictional")
		check_eq(entry.get("review_status", ""), "PENDING_OWNER_REVIEW", clue_id + " awaits owner review")
		var texture: Texture2D = load(DocumentViewer.image_path(clue_id))
		check(texture.get_width() <= 1024, clue_id + " is at most 1024 px wide")
	await _release_audio()


# --- Helpers ------------------------------------------------------------------------

func _reach_obj_act() -> void:
	_talk_to_bennett()
	PatientManager.record_observation(ELIAS, "obs_mutism", "test")
	var none: Array[String] = []
	PatientManager.save_note(ELIAS, ["obs_mutism"] as Array[String], none, "Plan.")


func _talk_to_bennett() -> void:
	var character: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	(character.get_node("Interactable") as Interactable).interact(_main.get_node("Player"))
	_info().close()


## Music the scene started must stop before the runner exits.
func _release_audio() -> void:
	AudioDirector.stop_music(0.01)
	await runner.get_tree().create_timer(0.3).timeout


func _labels_text(root: Node) -> String:
	var parts: PackedStringArray = []
	for node: Node in root.find_children("*", "Label", true, false):
		parts.append((node as Label).text)
	return "\n".join(parts)


func _body_text() -> String:
	return (_info().get_node("Root/Panel/Margin/VBox/Body") as RichTextLabel).get_parsed_text()


func _tabs() -> TabContainer:
	return _ehr().find_children("*", "TabContainer", true, false)[0] as TabContainer


func _ehr() -> EHRScreen:
	return _main.get_node("EHRScreen")


func _info() -> InfoPanel:
	return _main.get_node("InfoPanel")


func _board() -> EvidenceBoard:
	return _main.get_node("EvidenceBoard")


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")
