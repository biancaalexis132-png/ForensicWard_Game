class_name ClueText
extends RefCounted
## Formats a clue for display. Provenance and verification status are always
## shown, so the player never confuses a source's claim with a verified fact.


static func describe(clue: Dictionary) -> String:
	return "%s\n\n[color=#9aa]Source: %s · Provenance: %s · %s[/color]" % [
		clue["description"],
		str(clue["source"]).replace("_", " "),
		str(clue["provenance"]).replace("_", " "),
		"Independently verified" if clue["verified"] else "Not independently verified",
	]


## InfoPanel data for reading a clue: its title, text and id, so the panel
## shows the paper document beside the text when an image exists.
static func panel_data(clue_id: String) -> Dictionary:
	var clue: Dictionary = ContentRegistry.get_clue(clue_id)
	if clue.is_empty():
		return {}
	return {"title": clue["title"], "body": describe(clue), "clue_id": clue_id}
