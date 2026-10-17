class_name UIStyle
extends RefCounted
## UIStyle: shared look for code-built screens (EHR, Interview), matching
## the InfoPanel scene: dark green-grey panels with a teal border.

const BACKGROUND: Color = Color(0.06, 0.08, 0.08, 0.97)
const BORDER: Color = Color(0.3, 0.55, 0.48, 1.0)
const TEXT: Color = Color(0.86, 0.93, 0.9)
const MUTED: Color = Color(0.6, 0.68, 0.66)
const WARNING: Color = Color(0.95, 0.75, 0.35)


static func panel_style(alpha: float = 0.97) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(BACKGROUND, alpha)
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	return style


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
