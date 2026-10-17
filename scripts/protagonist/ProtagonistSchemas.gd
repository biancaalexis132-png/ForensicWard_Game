class_name ProtagonistSchemas
extends RefCounted
## P1 creation-draft contracts only. No shipped options, save provider or runtime hooks.
## Compatible with ContentValidator's schema vocabulary; extra fields are rejected
## by ProtagonistValidator rather than changing existing content validation policy.

const VERSION: int = 1
const OPTION_PREFIX: String = "popt_"
const NAME_MAX_CHARS: int = 64
const PRONOUN_MAX_CHARS: int = 32
const FORMATIVE_MAX_ITEMS: int = 3
const RELATIONSHIP_MAX_ITEMS: int = 2

const APPEARANCE_GROUPS: Dictionary = {
	"body_preset_id": "body_presets", "face_preset_id": "face_presets",
	"skin_tone_id": "skin_tones", "hair_style_id": "hair_styles",
	"hair_texture_id": "hair_textures", "hair_color_id": "hair_colors",
	"outfit_id": "outfits", "voice_id": "voices",
}
const BACKGROUND_GROUPS: Dictionary = {
	"professional_interest_id": "professional_interests", "acceptance_reason_id": "acceptance_reasons",
	"formative_experience_ids": "formative_experiences", "relationship_ids": "relationships",
	"outside_life_ids": "outside_life",
}
const _TEXT: Dictionary = {"type": "string", "allow_empty": true}
const _SELECTIONS: Dictionary = {"type": "array", "items": {"type": "id"}}
const PRONOUN_FORMS: Dictionary = {
	"type": "object", "required": {"subject": _TEXT, "object": _TEXT, "possessive": _TEXT},
}
const OPTION: Dictionary = {
	"type": "object", "required": {"id": {"type": "id"}, "label": {"type": "string"}},
}
const _OPTIONS: Dictionary = {"type": "array", "items": OPTION}
const GROUPS: Dictionary = {
	"type": "object", "required": {
		"pronouns": {"type": "array", "items": {"type": "object", "required": {
			"id": {"type": "id"}, "label": {"type": "string"}, "forms": PRONOUN_FORMS,
		}}},
		"body_presets": _OPTIONS, "face_presets": _OPTIONS, "skin_tones": _OPTIONS,
		"hair_styles": _OPTIONS, "hair_textures": _OPTIONS, "hair_colors": _OPTIONS,
		"outfits": _OPTIONS, "accessories": _OPTIONS, "voices": _OPTIONS,
		"professional_interests": _OPTIONS, "acceptance_reasons": _OPTIONS,
		"formative_experiences": _OPTIONS, "relationships": _OPTIONS, "outside_life": _OPTIONS,
	},
}
const CATALOG: Dictionary = {
	"type": "object", "required": {"catalog_version": {"type": "int"}, "groups": GROUPS},
}
const PROFILE: Dictionary = {
	"type": "object", "required": {
		"profile_version": {"type": "int"},
		"creation_state": {"type": "enum", "values": ["unconfigured", "configured"]},
		"identity": {"type": "object", "required": {
			"name": _TEXT,
			"professional_role": {"type": "enum", "values": ["psychiatrist"]},
			"pronouns": {"type": "object", "required": {
				"preset_id": _TEXT, "subject": _TEXT, "object": _TEXT, "possessive": _TEXT,
			}},
		}},
		"appearance": {"type": "object", "required": {
			"body_preset_id": _TEXT, "face_preset_id": _TEXT, "skin_tone_id": _TEXT,
			"hair_style_id": _TEXT, "hair_texture_id": _TEXT, "hair_color_id": _TEXT,
			"outfit_id": _TEXT, "voice_id": _TEXT, "accessory_ids": _SELECTIONS,
		}},
		"background": {"type": "object", "required": {
			"professional_interest_id": _TEXT, "acceptance_reason_id": _TEXT,
			"formative_experience_ids": _SELECTIONS, "relationship_ids": _SELECTIONS,
			"outside_life_ids": _SELECTIONS,
		}},
	},
}
