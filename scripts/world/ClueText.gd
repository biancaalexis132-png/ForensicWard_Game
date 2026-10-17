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
