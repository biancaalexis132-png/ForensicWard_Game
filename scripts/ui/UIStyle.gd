class_name UIStyle
extends RefCounted
## UIStyle: shared look for code-built screens (EHR, Interview), matching
## the InfoPanel scene: dark green-grey panels with a teal border.

const BACKGROUND: Color = Color(0.06, 0.08, 0.08, 0.97)
const BORDER: Color = Color(0.3, 0.55, 0.48, 1.0)
const TEXT: Color = Color(0.86, 0.93, 0.9)
const MUTED: Color = Color(0.6, 0.68, 0.66)
const WARNING: Color = Color(0.95, 0.75, 0.35)
## Raised surfaces (cards, chips) and the highlight for "do this next".
const CARD: Color = Color(0.1, 0.13, 0.13, 1.0)
const ACCENT: Color = Color(0.45, 0.85, 0.72)
const GOOD: Color = Color(0.55, 0.85, 0.55)


static func panel_style(alpha: float = 0.97) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(BACKGROUND, alpha)
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	return style


## A raised card inside a panel; `accent` colours its left edge.
static func card_style(accent: Color = BORDER, background: Color = CARD) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(accent, 0.55)
	style.set_border_width_all(1)
	style.border_width_left = 5
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


## A small rounded tag (status, legal status, alerts).
static func chip(text: String, color: Color = MUTED, size: int = 17) -> PanelContainer:
	var result: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color, 0.14)
	style.border_color = Color(color, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	result.add_theme_stylebox_override("panel", style)
	var text_label: Label = label(text, size, color.lightened(0.15))
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.add_child(text_label)
	return result


## A filled call-to-action button.
static func primary_button(text: String, size: int = 19) -> Button:
	var result: Button = button(text)
	result.add_theme_font_size_override("font_size", size)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.42, 0.36) if state != "hover" else Color(0.2, 0.52, 0.44)
		style.border_color = ACCENT
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		result.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.add_theme_color_override(state, Color(0.95, 1.0, 0.97))
	return result


## A bordered secondary button that reads as a button on dark cards.
static func secondary_button(text: String, size: int = 18) -> Button:
	var result: Button = button(text)
	result.add_theme_font_size_override("font_size", size)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.2, 0.2) if state != "hover" else Color(0.22, 0.28, 0.27)
		style.border_color = Color(MUTED, 0.4 if state == "disabled" else 0.8)
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		result.add_theme_stylebox_override(state, style)
	result.add_theme_color_override("font_color", TEXT)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	return result


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


## fit = true: grows to its text (for headers and lists inside a scroll box);
## otherwise it fills the remaining space and scrolls itself.
static func rich_text(fit: bool = false) -> RichTextLabel:
	var result: RichTextLabel = RichTextLabel.new()
	result.bbcode_enabled = true
	result.fit_content = fit
	result.scroll_active = not fit
	result.scroll_following = false
	result.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if fit else Control.SIZE_EXPAND_FILL
	result.add_theme_font_size_override("normal_font_size", 17)
	result.add_theme_font_size_override("bold_font_size", 17)
	result.add_theme_font_size_override("italics_font_size", 17)
	result.add_theme_color_override("default_color", TEXT)
	return result


static func button(text: String) -> Button:
	var result: Button = Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", 17)
	return result


## Full-screen root Control with a dim backdrop, for a CanvasLayer screen.
static func make_root(layer: CanvasLayer, dim: float) -> Control:
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP if dim > 0.0 else Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	if dim > 0.0:
		var backdrop: ColorRect = ColorRect.new()
		backdrop.color = Color(0, 0, 0, dim)
		backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(backdrop)
	return root


static func humanize(id: String) -> String:
	return id.replace("_", " ")
