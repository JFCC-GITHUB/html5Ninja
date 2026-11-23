# Pure style helpers shared by the menu/HUD code.
class_name UIStyle

const GOLD := Color("#d4a237")
const DIFF_COLORS := {
	"GOD": Color("#f1c40f"), "VERY_EASY": Color("#58d68d"), "EASY": Color("#5dade2"),
	"NORMAL": Color("#f39c12"), "HARD": Color("#e74c3c"), "NIGHTMARE": Color("#af7ac5"),
}

static func box(bg: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	return sb

static func set_btn_styles(btn: Button, normal_sb: StyleBox, hover_sb: StyleBox, pressed_sb: StyleBox):
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", normal_sb)
