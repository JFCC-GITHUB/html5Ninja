# GameRenderer.gd
# Read-only drawing of the play field. Owns no game state: everything comes from Main (`g`).
class_name GameRenderer
extends Node2D

var g # Main

func _draw() -> void:
	var f: Font = g.custom_font if g.custom_font else ThemeDB.fallback_font
	draw_texture_rect(g.tex_background, Rect2(0, 0, g.view_width, g.view_height), false)
	if g.state == g.GameState.MENU:
		draw_rect(Rect2(0, 0, g.view_width, g.view_height), Color(0.02, 0.02, 0.06, 0.5))
		return

	if g.selected_mode == "DEFENSE" and not g.tower.is_empty():
		draw_texture_rect(g.tex_tower, Rect2(g.tower["x"], g.tower["y"], g.tower["width"], g.tower["height"]), false)

	if not g.is_player_dead_in_defense and not g.player.is_empty():
		var p_tex = g.tex_ninja_run_r if g.player["moving"] and g.player["facing"] == "right" else (
			g.tex_ninja_run_l if g.player["moving"] and g.player["facing"] == "left" else (
				g.tex_ninja_idle_r if g.player["facing"] == "right" else g.tex_ninja_idle_l
			)
		)
		var is_inv = (g.player["invincibleTimer"] > 0.0 and fmod(g.player["invincibleTimer"] * 10.0, 1.0) > 0.5)
		if not is_inv:
			draw_texture_rect(p_tex, Rect2(g.player["x"], g.player["y"], g.player["width"], g.player["height"]), false)

		if g.is_sword_attacking:
			var s_range = g._get_sword_range()
			var p_center_x = g.player["x"] + g.player["width"] / 2.0
			var p_center_y = g.player["y"] + g.player["height"] / 2.0
			if g.selected_difficulty == "GOD":
				draw_circle(Vector2(p_center_x, p_center_y), s_range, Color(1, 0.8, 0.2, 0.35))
			else:
				var start_a = -PI / 3.0 if g.player["facing"] == "right" else PI - PI / 3.0
				var end_a = PI / 3.0 if g.player["facing"] == "right" else PI + PI / 3.0
				draw_arc(Vector2(p_center_x, p_center_y), s_range, start_a, end_a, 16, Color(1, 0.85, 0.3, 0.9), 6.0)

	for e in g.enemies:
		var side_str = "right" if e["vx"] > 0 else "left"
		var tex = g.enemy_textures[e["type"]][side_str]
		draw_texture_rect(tex, Rect2(e["x"], e["y"], e["width"], e["height"]), false)
		if e["maxHp"] > 1:
			var hp_pct = clamp(float(e["hp"]) / float(e["maxHp"]), 0.0, 1.0)
			draw_rect(Rect2(e["x"], e["y"] - 8, e["width"], 4), Color("#000000"))
			draw_rect(Rect2(e["x"], e["y"] - 8, e["width"] * hp_pct, 4), Color("#2ecc71"))

	for s in g.shurikens:
		draw_texture_rect(g.tex_shuriken, Rect2(s["x"], s["y"], s["size"], s["size"]), false)

	for a in g.tower_arrows:
		draw_set_transform(Vector2(a["x"], a["y"]), Vector2(a["vx"], a["vy"]).angle(), Vector2.ONE)
		draw_texture_rect(g.tex_arrow, Rect2(-18, -4.5, 36, 9), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for p in g.particles:
		draw_rect(Rect2(p["x"], p["y"], 4, 4), p["color"])

	for ft in g.floating_texts:
		var c = ft["color"]
		c.a = clamp(ft["life"], 0.0, 1.0)
		draw_string(f, Vector2(ft["x"] - 60, ft["y"]), ft["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 14, c)

	if g.state == g.GameState.PLAYING:
		_draw_touch_controls(f)

func _draw_touch_controls(f: Font):
	var u = Config.UI_TEXT[g.current_lang]
	var c = g._touch_circle_center()
	var r = g._sword_radius()
	var pad_r = clamp(g.view_width * 0.13, 40.0, 60.0)
	var lc = Vector2(g.view_width * 0.2, c.y)
	var rc = Vector2(g.view_width * 0.8, c.y)
	var label_col = Color(0.8, 0.83, 0.85, 0.9)

	for pad in [[lc, g.key_left, -1.0, u["touch_left"]], [rc, g.key_right, 1.0, u["touch_right"]]]:
		var pc: Vector2 = pad[0]
		var on: bool = pad[1]
		var dir: float = pad[2]
		draw_circle(pc, pad_r, Color(0.16, 0.5, 0.73, 0.55 if on else 0.28))
		draw_arc(pc, pad_r, 0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
		draw_colored_polygon(PackedVector2Array([
			pc + Vector2(dir * pad_r * 0.3, 0),
			pc + Vector2(-dir * pad_r * 0.25, -pad_r * 0.35),
			pc + Vector2(-dir * pad_r * 0.25, pad_r * 0.35)]), Color(1, 1, 1, 0.92))
		draw_string(f, pc + Vector2(-100, pad_r + 26), pad[3], HORIZONTAL_ALIGNMENT_CENTER, 200, 16, label_col)

	draw_circle(c, r, Color(0.75, 0.22, 0.17, 0.75 if g.sword_held else 0.5))
	draw_arc(c, r, 0, TAU, 48, Color(1, 0.6, 0.55, 0.7), 3.0)
	draw_string(f, c + Vector2(-r, 7), u["touch_sword"], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 18, Color.WHITE)
