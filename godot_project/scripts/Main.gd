# Main.gd
extends Node2D

enum GameState { MENU, PLAYING, PAUSED, GAMEOVER }

var state: GameState = GameState.MENU
var selected_mode: String = "CLASSIC"
var selected_difficulty: String = "NORMAL"
var current_lang: String = "zh"

var score: int = 0
var high_score: int = 0
var level: int = 1
var current_wave: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 100

var game_time: float = 0.0
var last_spawn_time: float = 0.0
var current_spawn_interval: float = 1800.0
var last_shoot_time: float = 0.0
var last_sword_time: float = 0.0
var last_tower_shoot_time: float = 0.0

var is_sword_attacking: bool = false
var sword_attack_timer: float = 0.0
var player_respawn_timer: float = 0.0
var is_player_dead_in_defense: bool = false

# Dynamic Virtual Bounds for Responsive Canvas
var view_width: float = 960.0
var view_height: float = 540.0
var is_portrait: bool = false
var ui_scale_factor: float = 1.0

# Game Entities
var player: Dictionary = {}
var tower: Dictionary = {}
var shurikens: Array = []
var tower_arrows: Array = []
var enemies: Array = []
var particles: Array = []
var floating_texts: Array = []

# Textures
var tex_ninja_idle_r: Texture2D
var tex_ninja_idle_l: Texture2D
var tex_ninja_run_r: Texture2D
var tex_ninja_run_l: Texture2D
var tex_heart_filled: Texture2D
var tex_heart_empty: Texture2D
var tex_shuriken: Texture2D
var tex_tower: Texture2D
var tex_arrow: Texture2D
var enemy_textures: Dictionary = {}
var custom_font: FontFile
var tex_background: Texture2D

# Portrait layout (set in _update_layout_for_viewport)
const PLAYFIELD_RATIO := 0.62
var ground_y: float = 523.0
var ctrl_top: float = 607.0
var sword_held: bool = false

# Node References
@onready var sound_system: SoundSystem = $SoundSystem
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD
@onready var menu_screen: Control = $UILayer/MenuScreen
@onready var pause_screen: Control = $UILayer/PauseScreen
@onready var gameover_screen: Control = $UILayer/GameOverScreen
@onready var touch_controls: Control = $UILayer/TouchControls

# HUD UI References
@onready var hp_hearts: HBoxContainer = $UILayer/HUD/TopPanel/MarginContainer/HBox/HpContainer/HpHearts
@onready var tower_hp_container: HBoxContainer = $UILayer/HUD/TopPanel/MarginContainer/HBox/TowerHpContainer
@onready var tower_hp_val: Label = $UILayer/HUD/TopPanel/MarginContainer/HBox/TowerHpContainer/TowerHpVal
@onready var level_val: Label = $UILayer/HUD/TopPanel/MarginContainer/HBox/LevelContainer/LevelVal
@onready var wave_val: Label = $UILayer/HUD/TopPanel/MarginContainer/HBox/WaveContainer/WaveVal
@onready var exp_bar_fill: ColorRect = $UILayer/HUD/TopPanel/MarginContainer/HBox/LevelContainer/ExpBarContainer/ExpBarFill
@onready var score_val: Label = $UILayer/HUD/TopPanel/MarginContainer/HBox/ScoreContainer/ScoreVal
@onready var high_score_val: Label = $UILayer/HUD/TopPanel/MarginContainer/HBox/HighScoreContainer/HighScoreVal

# Menu UI References
@onready var menu_overlay_content: VBoxContainer = $UILayer/MenuScreen/OverlayContent
@onready var menu_box_container: PanelContainer = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer
@onready var title_ninja_left: TextureRect = $UILayer/MenuScreen/OverlayContent/TitleHBox/TitleNinjaLeft
@onready var title_ninja_right: TextureRect = $UILayer/MenuScreen/OverlayContent/TitleHBox/TitleNinjaRight
@onready var diff_title: Label = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DiffDetailPanel/DiffTitle
@onready var diff_desc: Label = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DiffDetailPanel/DiffDesc
@onready var diff_stats: Label = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DiffDetailPanel/DiffStats
@onready var btn_classic: Button = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/ModeButtons/BtnClassic
@onready var btn_defense: Button = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/ModeButtons/BtnDefense
@onready var btn_start: Button = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/BtnStart
@onready var lang_button: Button = $UILayer/MenuScreen/LangButton

# GameOver UI References
@onready var final_score_val: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/ScoreHBox/FinalScoreVal
@onready var final_best_val: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/BestHBox/FinalBestVal
@onready var new_record_tag: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/NewRecordTag

# Touch Control References
@onready var touch_left: ColorRect = $UILayer/TouchControls/TouchLeft
@onready var touch_right: ColorRect = $UILayer/TouchControls/TouchRight
@onready var touch_sword: Button = $UILayer/TouchControls/TouchSword

# Key inputs
var music_on: bool = true
var key_left: bool = false
var key_right: bool = false

var renderer: GameRenderer

func _ready():
	renderer = GameRenderer.new()
	renderer.g = self
	add_child(renderer)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_setup_custom_font()
	_generate_textures()
	_apply_menu_box_styling()
	_load_high_score()
	_update_language_ui()
	_connect_ui_signals()
	_update_layout_for_viewport()
	_set_state(GameState.MENU)

func _apply_menu_box_styling():
	title_ninja_left.texture = tex_ninja_idle_r
	title_ninja_right.texture = tex_ninja_idle_l

	# Transparent menu backdrop so the dusk background shows through
	menu_screen.color = Color(0, 0, 0, 0)

	# Title: bigger, outlined
	var title = $UILayer/MenuScreen/OverlayContent/TitleHBox/Title
	title.set_meta("base_font_sz", 34)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color("#2a0a0a"))
	title.add_theme_color_override("font_color", Color("#ff6b5b"))

	for sub in [$UILayer/MenuScreen/OverlayContent/Subtitle, $UILayer/MenuScreen/OverlayContent/Creators]:
		sub.add_theme_constant_override("outline_size", 6)
		sub.add_theme_color_override("font_outline_color", Color("#0b0a12"))

	# Panel: deep indigo with gold border and drop shadow
	var panel = UIStyle.box(Color(0.07, 0.06, 0.13, 0.9), UIStyle.GOLD, 16, 2)
	panel.shadow_size = 10
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.content_margin_left = 18
	panel.content_margin_top = 16
	panel.content_margin_right = 18
	panel.content_margin_bottom = 18
	menu_box_container.add_theme_stylebox_override("panel", panel)

	for hdr in [$UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/ModeHeader, $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DiffHeader]:
		hdr.set_meta("base_font_sz", 16)
		hdr.add_theme_color_override("font_color", Color("#f7dc6f"))
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	diff_title.add_theme_color_override("font_color", Color("#f7dc6f"))
	diff_title.set_meta("base_font_sz", 17)
	diff_desc.add_theme_color_override("font_color", Color("#e8e0f5"))
	diff_desc.set_meta("base_font_sz", 14)
	diff_stats.add_theme_color_override("font_color", Color("#a9dfbf"))
	diff_stats.set_meta("base_font_sz", 13)

	# Start button: red, gold border, raised shadow
	var start_n = UIStyle.box(Color("#e74c3c"), Color("#ffd27a"), 14, 3)
	start_n.shadow_size = 4
	start_n.shadow_offset = Vector2(0, 5)
	start_n.shadow_color = Color("#6e1d14")
	var start_h = UIStyle.box(Color("#ff6b5b"), Color("#ffe6a0"), 14, 3)
	start_h.shadow_size = 4
	start_h.shadow_offset = Vector2(0, 5)
	start_h.shadow_color = Color("#6e1d14")
	var start_p = UIStyle.box(Color("#c0392b"), Color("#ffd27a"), 14, 3)
	UIStyle.set_btn_styles(btn_start, start_n, start_h, start_p)
	btn_start.set_meta("base_font_sz", 22)
	btn_start.add_theme_color_override("font_color", Color.WHITE)

	# Other buttons (pause/game over/lang): blue rounded
	var default_blue_sb = UIStyle.box(Color("#2980b9"), Color("#3498db"), 8, 2)
	var pause_btn = $UILayer/HUD/BtnPause
	var btn_resume = $UILayer/PauseScreen/OverlayContent/MenuBox/BtnResume
	var btn_restart_p = $UILayer/PauseScreen/OverlayContent/MenuBox/BtnRestartPause
	var btn_menu_p = $UILayer/PauseScreen/OverlayContent/MenuBox/BtnMenuPause
	var btn_restart_g = $UILayer/GameOverScreen/OverlayContent/MenuBox/BtnRestart
	var btn_menu_g = $UILayer/GameOverScreen/OverlayContent/MenuBox/BtnMenuGameover
	var music_btn_menu = $UILayer/MenuScreen/MusicButton
	var music_btn_pause = $UILayer/PauseScreen/OverlayContent/MenuBox/BtnMusicPause
	for btn in [pause_btn, lang_button, music_btn_menu, music_btn_pause, touch_sword, btn_resume, btn_restart_p, btn_menu_p, btn_restart_g, btn_menu_g]:
		if btn:
			UIStyle.set_btn_styles(btn, default_blue_sb, default_blue_sb, default_blue_sb)

func _on_viewport_resized():
	_update_layout_for_viewport()

func _update_layout_for_viewport():
	var vp_size = get_viewport_rect().size
	view_width = vp_size.x
	view_height = vp_size.y
	is_portrait = view_height >= view_width

	ui_scale_factor = clamp(view_width / 390.0, 1.0, 1.5)
	_apply_font_scaling_recursively(ui_layer, ui_scale_factor)

	# Play field occupies the upper part; controls sit below the ground line
	ground_y = view_height * PLAYFIELD_RATIO
	ctrl_top = ground_y + 84.0 * ui_scale_factor

	menu_overlay_content.custom_minimum_size = Vector2(min(view_width - 24.0, 600.0), 0)
	for lbl in [diff_title, diff_desc, diff_stats]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var half_menu = min(300.0, view_width / 2.0 - 12.0)
	menu_overlay_content.offset_left = -half_menu
	menu_overlay_content.offset_right = half_menu

	var half_go = min(200.0, view_width / 2.0 - 12.0)
	var go_box = $UILayer/GameOverScreen/OverlayContent
	go_box.offset_left = -half_go
	go_box.offset_right = half_go
	var half_p = min(160.0, view_width / 2.0 - 12.0)
	var pa_box = $UILayer/PauseScreen/OverlayContent
	pa_box.offset_left = -half_p
	pa_box.offset_right = half_p

	_layout_touch_controls()
	_compact_hud()

	if player.has("y"):
		player["y"] = ground_y - player["height"]
		player["x"] = clamp(player["x"], 0.0, max(0.0, view_width - player["width"]))
	if tower.has("y"):
		tower["y"] = ground_y - tower["height"]
		tower["x"] = view_width / 2.0 - tower["width"] / 2.0
	for en in enemies:
		en["y"] = ground_y - en["height"]

func _compact_hud():
	var margin: MarginContainer = $UILayer/HUD/TopPanel/MarginContainer
	margin.add_theme_constant_override("margin_right", int(54 * ui_scale_factor))
	margin.add_theme_constant_override("margin_left", 8)
	$UILayer/HUD/TopPanel/MarginContainer/HBox.add_theme_constant_override("separation", 8)
	$UILayer/HUD/TopPanel/MarginContainer/HBox/HpContainer/HpLabel.visible = false
	$UILayer/HUD/TopPanel/MarginContainer/HBox/HighScoreContainer.visible = false
	$UILayer/HUD/TopPanel/MarginContainer/HBox/WaveContainer.visible = false
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lbl in $UILayer/HUD/TopPanel.find_children("*", "Label", true, false):
		lbl.add_theme_font_size_override("font_size", int(round(13 * ui_scale_factor)))
	exp_bar_fill.get_parent().custom_minimum_size.x = 36.0
	$UILayer/HUD/BtnPause.text = "II"

func _touch_circle_center() -> Vector2:
	return Vector2(view_width / 2.0, ctrl_top + (view_height - ctrl_top) * 0.5)

func _sword_radius() -> float:
	return clamp(view_width * 0.12, 36.0, 56.0)

func _layout_touch_controls():
	var zone_h = view_height - ctrl_top
	var zone_w = view_width * 0.36
	touch_left.position = Vector2(0, ctrl_top)
	touch_left.size = Vector2(zone_w, zone_h)
	touch_right.position = Vector2(view_width - zone_w, ctrl_top)
	touch_right.size = Vector2(zone_w, zone_h)
	# Zones are invisible hit areas; visuals are drawn in _draw_touch_controls
	for z in [touch_left, touch_right]:
		z.color = Color(0, 0, 0, 0)
		for c in z.get_children():
			c.visible = false
	var c = _touch_circle_center()
	var r = _sword_radius()
	touch_sword.position = Vector2(c.x - r, c.y - r)
	touch_sword.size = Vector2(r * 2.0, r * 2.0)
	var empty = StyleBoxEmpty.new()
	for s_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		touch_sword.add_theme_stylebox_override(s_name, empty)
	touch_sword.text = ""

func _setup_custom_font():
	if ResourceLoader.exists("res://fonts/NotoSansTC-Regular.ttf"):
		custom_font = load("res://fonts/NotoSansTC-Regular.ttf")
		if custom_font:
			_apply_font_recursively(ui_layer, custom_font)

func _apply_font_recursively(node: Node, font: Font):
	if node is Control:
		node.add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font_recursively(child, font)

func _apply_font_scaling_recursively(node: Node, scale_mult: float):
	if node is Label or node is Button:
		var base_sz = node.get_meta("base_font_sz", 16)
		if not node.has_meta("base_font_sz"):
			base_sz = node.get_theme_font_size("font_size")
			if base_sz <= 0: base_sz = 16
			node.set_meta("base_font_sz", base_sz)
		node.add_theme_font_size_override("font_size", int(round(base_sz * scale_mult)))

	for child in node.get_children():
		_apply_font_scaling_recursively(child, scale_mult)

func _generate_textures():
	tex_background = load("res://art/background.png")
	tex_ninja_idle_r = load("res://art/ninja_idle_r.png")
	tex_ninja_idle_l = load("res://art/ninja_idle_l.png")
	tex_ninja_run_r = load("res://art/ninja_run_r.png")
	tex_ninja_run_l = load("res://art/ninja_run_l.png")
	tex_heart_filled = load("res://art/heart_full.png")
	tex_heart_empty = load("res://art/heart_empty.png")
	tex_shuriken = load("res://art/shuriken.png")
	tex_tower = load("res://art/tower.png")
	tex_arrow = load("res://art/tower_arrow.png")
	for k in Config.ENEMY_TYPES.keys():
		var base = "res://art/enemy_%s_" % k.to_lower()
		enemy_textures[k] = {"right": load(base + "r.png"), "left": load(base + "l.png")}

func _load_high_score():
	high_score = 0
	if FileAccess.file_exists("user://highscore.save"):
		var f = FileAccess.open("user://highscore.save", FileAccess.READ)
		if f:
			high_score = f.get_32()
			f.close()
	high_score_val.text = str(high_score)

func _save_high_score():
	var f = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if f:
		f.store_32(high_score)
		f.close()

func _connect_ui_signals():
	btn_classic.pressed.connect(func(): _select_mode("CLASSIC"))
	btn_defense.pressed.connect(func(): _select_mode("DEFENSE"))

	if lang_button:
		lang_button.pressed.connect(_toggle_language)
	$UILayer/MenuScreen/MusicButton.pressed.connect(toggle_music)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnMusicPause.pressed.connect(toggle_music)

	var diff_grid = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DifficultyButtons
	for btn in diff_grid.get_children():
		if btn is Button and btn.has_meta("diff"):
			var d_key = btn.get_meta("diff")
			btn.pressed.connect(func(): _select_difficulty(d_key))

	btn_start.pressed.connect(start_game)
	$UILayer/HUD/BtnPause.pressed.connect(toggle_pause)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnResume.pressed.connect(toggle_pause)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnRestartPause.pressed.connect(start_game)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnMenuPause.pressed.connect(func(): _set_state(GameState.MENU))

	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnRestart.pressed.connect(start_game)
	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnMenuGameover.pressed.connect(func(): _set_state(GameState.MENU))

	# Touch Controls
	touch_left.gui_input.connect(func(event):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			key_left = event.pressed
	)
	touch_right.gui_input.connect(func(event):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			key_right = event.pressed
	)
	touch_sword.pressed.connect(func(): perform_sword_attack())
	touch_sword.button_down.connect(func(): sword_held = true)
	touch_sword.button_up.connect(func(): sword_held = false)

func toggle_music():
	music_on = not music_on
	sound_system.set_music_enabled(music_on)
	sound_system.play_click()
	_update_music_buttons()

func _update_music_buttons():
	var t: String = Config.UI_TEXT[current_lang]["music_on" if music_on else "music_off"]
	$UILayer/MenuScreen/MusicButton.text = t
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnMusicPause.text = t

func _toggle_language():
	current_lang = "en" if current_lang == "zh" else "zh"
	sound_system.play_click()
	_update_language_ui()

func _update_language_ui():
	var u = Config.UI_TEXT[current_lang]
	if lang_button:
		lang_button.text = u["lang_toggle"]
	_update_music_buttons()

	$UILayer/MenuScreen/OverlayContent/TitleHBox/Title.text = u["title"]
	$UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/ModeHeader.text = u["mode_header"]
	$UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DiffHeader.text = u["diff_header"]
	btn_start.text = u["start_game"]

	btn_classic.text = u["mode_classic"]
	btn_defense.text = u["mode_defense"]

	var diff_grid = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DifficultyButtons
	for btn in diff_grid.get_children():
		if btn is Button and btn.has_meta("diff"):
			var d_key = btn.get_meta("diff")
			btn.text = u["diff_" + d_key.to_lower()]

	$UILayer/HUD/TopPanel/MarginContainer/HBox/HpContainer/HpLabel.text = u["hp_label"]
	$UILayer/HUD/TopPanel/MarginContainer/HBox/TowerHpContainer/TowerHpLabel.text = u["tower_label"]
	$UILayer/HUD/TopPanel/MarginContainer/HBox/LevelContainer/LevelLabel.text = u["level_label"]
	$UILayer/HUD/TopPanel/MarginContainer/HBox/WaveContainer/WaveLabel.text = u["wave_label"]
	$UILayer/HUD/TopPanel/MarginContainer/HBox/ScoreContainer/ScoreLabel.text = u["score_label"]
	$UILayer/HUD/TopPanel/MarginContainer/HBox/HighScoreContainer/HighScoreLabel.text = u["best_label"]

	$UILayer/PauseScreen/OverlayContent/PauseTitle.text = u["paused_title"]
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnResume.text = u["resume"]
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnRestartPause.text = u["restart"]
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnMenuPause.text = u["main_menu"]

	$UILayer/GameOverScreen/OverlayContent/GameOverTitle.text = u["game_over"]
	$UILayer/GameOverScreen/OverlayContent/MenuBox/ScoreHBox/FinalScoreLabel.text = u["final_score"]
	$UILayer/GameOverScreen/OverlayContent/MenuBox/BestHBox/FinalBestLabel.text = u["final_best"]
	$UILayer/GameOverScreen/OverlayContent/MenuBox/NewRecordTag.text = u["new_record"]
	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnRestart.text = u["play_again"]
	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnMenuGameover.text = u["main_menu"]

	$UILayer/TouchControls/TouchLeft/Label.text = u["touch_left"]
	$UILayer/TouchControls/TouchRight/Label.text = u["touch_right"]
	touch_sword.text = u["touch_sword"]

	_update_difficulty_panel()

func _select_mode(m: String):
	sound_system.play_click()
	selected_mode = m
	_update_button_states()
	_update_difficulty_panel()

func _select_difficulty(d: String):
	sound_system.play_click()
	selected_difficulty = d
	_update_button_states()
	_update_difficulty_panel()

func _update_button_states():
	# Mode cards: icon + filled tile when active
	for pair in [[btn_classic, "CLASSIC", tex_shuriken], [btn_defense, "DEFENSE", tex_tower]]:
		var btn: Button = pair[0]
		var act = (selected_mode == pair[1])
		var sb = UIStyle.box(Color("#e67e22") if act else Color("#2b2140"), Color("#ffd27a") if act else Color("#6c5a8a"), 12, 3 if act else 2)
		UIStyle.set_btn_styles(btn, sb, sb, sb)
		btn.icon = pair[2]
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", Color.WHITE if act else Color("#c9bfe0"))
		btn.custom_minimum_size.y = 56

	# Difficulty chips: colored per difficulty, filled when active
	var diff_grid = $UILayer/MenuScreen/OverlayContent/MenuBoxContainer/MenuBox/DifficultyButtons
	for btn in diff_grid.get_children():
		if btn is Button and btn.has_meta("diff"):
			var d_key = btn.get_meta("diff")
			var col: Color = UIStyle.DIFF_COLORS.get(d_key, Color("#7f8c8d"))
			var act = (d_key == selected_difficulty)
			var bg = col if act else Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 0.95)
			var sb = UIStyle.box(bg, Color.WHITE if act else col, 10, 3 if act else 2)
			UIStyle.set_btn_styles(btn, sb, sb, sb)
			btn.add_theme_color_override("font_color", Color("#1a1028") if act else col)

func _update_difficulty_panel():
	_update_button_states()
	var mode_cfg = Config.GAME_MODES[current_lang][selected_mode]
	var diff_cfg = Config.DIFFICULTIES[current_lang][selected_difficulty]
	diff_title.text = mode_cfg["title"] + " - " + diff_cfg["title"]
	diff_desc.text = mode_cfg["desc"] + "\n" + diff_cfg["desc"]
	diff_stats.text = diff_cfg["stats"]

func _set_state(new_state: GameState):
	state = new_state
	key_left = false
	key_right = false
	menu_screen.visible = (state == GameState.MENU)
	pause_screen.visible = (state == GameState.PAUSED)
	gameover_screen.visible = (state == GameState.GAMEOVER)
	hud.visible = (state == GameState.PLAYING or state == GameState.PAUSED)
	touch_controls.visible = (state == GameState.PLAYING)
	sound_system.set_music_mode({GameState.MENU: "menu", GameState.PLAYING: "play", GameState.PAUSED: "paused", GameState.GAMEOVER: "stop"}[state])

func toggle_pause():
	if state == GameState.PLAYING:
		sound_system.play_click()
		_set_state(GameState.PAUSED)
	elif state == GameState.PAUSED:
		sound_system.play_click()
		_set_state(GameState.PLAYING)

func start_game():
	sound_system.play_click()
	_update_layout_for_viewport()

	var diff_num = Config.DIFFICULTIES_NUMERIC[selected_difficulty]
	var mode_num = Config.GAME_MODES_NUMERIC[selected_mode]

	score = 0
	level = diff_num.get("startLevel", 1)
	current_wave = 1
	current_exp = 0
	exp_to_next_level = 100
	game_time = 0.0
	last_spawn_time = 0.0
	current_spawn_interval = mode_num["initialSpawnInterval"] / 1000.0
	last_shoot_time = -10.0
	last_sword_time = -10.0
	last_tower_shoot_time = -10.0
	is_sword_attacking = false
	sword_attack_timer = 0.0
	is_player_dead_in_defense = false
	player_respawn_timer = 0.0

	shurikens.clear()
	tower_arrows.clear()
	enemies.clear()
	particles.clear()
	floating_texts.clear()


	player = {
		"x": view_width / 2.0 - Config.PLAYER["WIDTH"] / 2.0,
		"y": ground_y - Config.PLAYER["HEIGHT"],
		"width": Config.PLAYER["WIDTH"],
		"height": Config.PLAYER["HEIGHT"],
		"hp": diff_num["playerHp"],
		"maxHp": diff_num["playerHp"],
		"facing": "right",
		"moving": false,
		"invincibleTimer": 0.0
	}

	if selected_mode == "DEFENSE":
		tower = {
			"x": view_width / 2.0 - Config.TOWER["WIDTH"] / 2.0,
			"y": ground_y - Config.TOWER["HEIGHT"],
			"width": Config.TOWER["WIDTH"],
			"height": Config.TOWER["HEIGHT"],
			"hp": Config.TOWER["MAX_HP"],
			"maxHp": Config.TOWER["MAX_HP"]
		}
		tower_hp_container.visible = true
		_update_tower_hp_display()
	else:
		tower_hp_container.visible = false

	_update_hp_display()
	_update_level_display()
	score_val.text = "0"
	_set_state(GameState.PLAYING)

func _update_hp_display():
	for c in hp_hearts.get_children():
		hp_hearts.remove_child(c)
		c.queue_free()
	var max_hp = player.get("maxHp", 3)
	var cur_hp = player.get("hp", 0)
	if max_hp > 10:
		var icon = TextureRect.new()
		icon.texture = tex_heart_filled
		icon.custom_minimum_size = Vector2(18, 16)
		hp_hearts.add_child(icon)
		var lbl = Label.new()
		lbl.text = "x" + str(max(cur_hp, 0))
		if custom_font:
			lbl.add_theme_font_override("font", custom_font)
		hp_hearts.add_child(lbl)
		return
	for i in range(max_hp):
		var heart_rect = TextureRect.new()
		heart_rect.texture = tex_heart_filled if i < cur_hp else tex_heart_empty
		heart_rect.custom_minimum_size = Vector2(18, 16)
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_hearts.add_child(heart_rect)

func _update_tower_hp_display():
	if selected_mode == "DEFENSE":
		var pct = int(clamp((float(tower["hp"]) / float(tower["maxHp"])) * 100.0, 0.0, 100.0))
		tower_hp_val.text = str(pct) + "%"

func _update_level_display():
	level_val.text = str(level)
	wave_val.text = str(current_wave)
	var pct = clamp(float(current_exp) / float(exp_to_next_level), 0.0, 1.0)
	exp_bar_fill.size.x = pct * 50.0

func add_exp(amt: int):
	current_exp += amt
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		exp_to_next_level = int(round(exp_to_next_level * 1.35))
		sound_system.play_level_up()
		_add_particles(player["x"] + player["width"] / 2.0, player["y"] + player["height"] / 2.0, Color("#2ecc71"), 30)
		floating_texts.append({
			"text": "LEVEL UP! LV." + str(level),
			"x": player["x"] + player["width"] / 2.0,
			"y": player["y"] - 20.0,
			"color": Color("#2ecc71"),
			"life": 1.0
		})
	_update_level_display()

func add_score(pts: int):
	var mult = Config.DIFFICULTIES_NUMERIC[selected_difficulty]["scoreMultiplier"] * Config.GAME_MODES_NUMERIC[selected_mode]["scoreMultiplier"]
	score += int(round(pts * mult))
	score_val.text = str(score)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_music()

func _process(delta):
	if state == GameState.PLAYING:
		_update_game(delta)
	renderer.queue_redraw()

func _update_game(delta: float):
	delta = min(delta, 0.05)
	game_time += delta

	# Key inputs
	var move_left = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or key_left
	var move_right = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or key_right
	var do_sword = Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_Z)

	# Handle Player Invincibility
	if player["invincibleTimer"] > 0.0:
		player["invincibleTimer"] -= delta

	# Handle Player Respawn in Tower Defense
	if is_player_dead_in_defense:
		player_respawn_timer -= delta
		if player_respawn_timer <= 0.0:
			is_player_dead_in_defense = false
			player["hp"] = player["maxHp"]
			player["x"] = view_width / 2.0 - player["width"] / 2.0
			player["invincibleTimer"] = Config.PLAYER["INVINCIBILITY_DURATION_MS"] / 1000.0
			_update_hp_display()

	# Player Movement
	if not is_player_dead_in_defense:
		var move_speed = Config.PLAYER["SPEED"] * delta
		player["moving"] = false
		if move_left:
			player["x"] = max(Config.PLAYER["MOVE_BOUNDS_MARGIN"], player["x"] - move_speed)
			player["facing"] = "left"
			player["moving"] = true
		elif move_right:
			player["x"] = min(view_width - Config.PLAYER["MOVE_BOUNDS_MARGIN"] - player["width"], player["x"] + move_speed)
			player["facing"] = "right"
			player["moving"] = true

		# Auto shoot continuously on cooldown
		shoot_shuriken()

		if do_sword:
			perform_sword_attack()

	# Handle Sword Attack Duration
	if is_sword_attacking:
		sword_attack_timer -= delta
		if sword_attack_timer <= 0.0:
			is_sword_attacking = false

	# Wave & Spawn Progression
	var new_wave = 1 + int(game_time / (Config.SPAWN["DIFFICULTY_RAMP_INTERVAL_MS"] / 1000.0))
	if new_wave != current_wave:
		current_wave = new_wave
		_update_level_display()
	var base_interval = Config.GAME_MODES_NUMERIC[selected_mode]["initialSpawnInterval"]
	var rate_mult = Config.DIFFICULTIES_NUMERIC[selected_difficulty]["enemySpawnRateMultiplier"]
	var raw_interval = max(Config.SPAWN["MIN_INTERVAL_MS"], base_interval - (current_wave - 1) * Config.SPAWN["INTERVAL_DECREASE_STEP"])
	current_spawn_interval = max(Config.SPAWN["MIN_INTERVAL_MS"] / 1000.0, (raw_interval / 1000.0) * rate_mult)

	if game_time - last_spawn_time >= current_spawn_interval:
		last_spawn_time = game_time
		spawn_enemy()

	# Tower Auto Shooting (Defense Mode & Level 6+)
	if selected_mode == "DEFENSE" and level >= Config.TOWER["AUTO_SHOOT_LEVEL"]:
		if game_time - last_tower_shoot_time >= Config.TOWER["AUTO_SHOOT_COOLDOWN_MS"] / 1000.0:
			last_tower_shoot_time = game_time
			tower_shoot_arrow()

	# Update Shurikens
	var new_shurikens = []
	for s in shurikens:
		s["x"] += s["vx"] * delta
		if s["x"] >= -50 and s["x"] <= view_width + 50:
			new_shurikens.append(s)
	shurikens = new_shurikens

	# Update Tower Arrows
	var new_arrows = []
	for a in tower_arrows:
		a["x"] += a["vx"] * delta
		a["y"] += a["vy"] * delta
		if a["x"] >= -50 and a["x"] <= view_width + 50 and a["y"] >= -50 and a["y"] <= view_height + 50:
			new_arrows.append(a)
	tower_arrows = new_arrows

	# Update Enemies & Collisions
	var diff_num = Config.DIFFICULTIES_NUMERIC[selected_difficulty]
	var enemy_speed_mult = diff_num["enemySpeedMultiplier"]
	var new_enemies = []

	for e in enemies:
		e["x"] += e["vx"] * enemy_speed_mult * delta

		# Check Sword Slash Attack Hit
		if is_sword_attacking and not e.get("slashed", false):
			var s_range = _get_sword_range()
			var p_center_x = player["x"] + player["width"] / 2.0
			var is_god = (selected_difficulty == "GOD")
			var in_range = false
			if is_god:
				in_range = abs((e["x"] + e["width"] / 2.0) - p_center_x) <= s_range
			elif player["facing"] == "right" and e["x"] + e["width"] >= p_center_x and e["x"] <= p_center_x + s_range:
				in_range = true
			elif player["facing"] == "left" and e["x"] <= p_center_x and e["x"] + e["width"] >= p_center_x - s_range:
				in_range = true

			if in_range:
				e["slashed"] = true
				var dmg = 10 if is_god else 2
				e["hp"] -= dmg
				sound_system.play_enemy_hit()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#e74c3c"), Config.PARTICLES["HIT_COUNT"])
				floating_texts.append({
					"text": "SLASH!",
					"x": e["x"] + e["width"] / 2.0,
					"y": e["y"] - 10.0,
					"color": Color("#e74c3c"),
					"life": 0.5
				})

		# Check Shuriken Collisions
		for s in shurikens:
			if s.get("hit", false): continue
			var s_rect = Rect2(s["x"], s["y"], s["size"], s["size"])
			var e_rect = Rect2(e["x"], e["y"], e["width"], e["height"])
			if s_rect.intersects(e_rect):
				s["hit"] = true
				e["hp"] -= 1 + int((level - 1) * 0.5)
				sound_system.play_enemy_hit()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#f39c12"), Config.PARTICLES["HIT_COUNT"])

		# Check Tower Arrow Collisions
		for a in tower_arrows:
			if a.get("hit", false): continue
			var a_rect = Rect2(a["x"] - 18, a["y"] - 4.5, 36, 9)
			var e_rect = Rect2(e["x"], e["y"], e["width"], e["height"])
			if a_rect.intersects(e_rect):
				a["hit"] = true
				e["hp"] -= 2
				sound_system.play_enemy_hit()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#f1c40f"), Config.PARTICLES["HIT_COUNT"])

		# Clean hit shurikens and arrows
		shurikens = shurikens.filter(func(s): return not s.get("hit", false))
		tower_arrows = tower_arrows.filter(func(a): return not a.get("hit", false))

		# Check Enemy Death
		if e["hp"] <= 0:
			_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, e["color"], Config.PARTICLES["DEATH_COUNT"])
			add_score(e["scoreValue"])
			add_exp(e["expValue"])
			continue

		# Check Collision with Player
		if not is_player_dead_in_defense and player["invincibleTimer"] <= 0.0:
			var p_rect = Rect2(player["x"], player["y"], player["width"], player["height"])
			var e_rect = Rect2(e["x"], e["y"], e["width"], e["height"])
			if p_rect.intersects(e_rect):
				player["hp"] -= 1
				player["invincibleTimer"] = Config.PLAYER["INVINCIBILITY_DURATION_MS"] / 1000.0
				sound_system.play_player_hurt()
				_update_hp_display()
				_add_particles(player["x"] + player["width"] / 2.0, player["y"] + player["height"] / 2.0, Color("#e74c3c"), 20)

				if player["hp"] <= 0:
					if selected_mode == "DEFENSE":
						is_player_dead_in_defense = true
						player_respawn_timer = 1.0
					else:
						game_over()
						return

		# Check Collision with Tower (Tower Defense Mode)
		if selected_mode == "DEFENSE":
			var t_rect = Rect2(tower["x"], tower["y"], tower["width"], tower["height"])
			var e_rect = Rect2(e["x"], e["y"], e["width"], e["height"])
			if t_rect.intersects(e_rect):
				tower["hp"] -= min(25, 5 * e["maxHp"])
				_update_tower_hp_display()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#e74c3c"), 15)
				sound_system.play_player_hurt()
				if tower["hp"] <= 0:
					game_over()
					return
				continue

		# Remove enemies reaching edges (Classic mode center defense)
		if selected_mode == "CLASSIC":
			if (e["vx"] > 0 and e["x"] > view_width + 50) or (e["vx"] < 0 and e["x"] < -100):
				continue

		new_enemies.append(e)

	enemies = new_enemies

	# Update Particles
	var new_particles = []
	for p in particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["life"] -= delta
		if p["life"] > 0:
			new_particles.append(p)
	particles = new_particles

	# Update Floating Texts
	var new_texts = []
	for ft in floating_texts:
		ft["y"] -= 30.0 * delta
		ft["life"] -= delta
		if ft["life"] > 0:
			new_texts.append(ft)
	floating_texts = new_texts

func shoot_shuriken():
	if game_time - last_shoot_time < Config.PLAYER["SHOOT_COOLDOWN_MS"] / 1000.0: return
	if shurikens.size() >= Config.SHURIKEN["MAX_COUNT"]: return
	last_shoot_time = game_time
	sound_system.play_shuriken_throw()
	var sz = _get_shuriken_size()
	var dir = -1.0 if player["facing"] == "left" else 1.0
	shurikens.append({
		"x": player["x"] + player["width"] / 2.0 - sz / 2.0,
		"y": player["y"] + player["height"] / 2.0 - sz / 2.0,
		"vx": dir * Config.SHURIKEN["SPEED"],
		"size": sz
	})

func perform_sword_attack():
	if game_time - last_sword_time < Config.PLAYER["SWORD_COOLDOWN_MS"] / 1000.0: return
	last_sword_time = game_time
	is_sword_attacking = true
	for en in enemies:
		en["slashed"] = false
	sword_attack_timer = Config.PLAYER["SWORD_DURATION_MS"] / 1000.0
	sound_system.play_sword_slash()

func tower_shoot_arrow():
	if enemies.size() == 0: return
	var t_center_x = tower["x"] + tower["width"] / 2.0
	var target_e = enemies[0]
	var min_dist = abs(target_e["x"] + target_e["width"] / 2.0 - t_center_x)
	for e in enemies:
		var d = abs(e["x"] + e["width"] / 2.0 - t_center_x)
		if d < min_dist:
			min_dist = d
			target_e = e

	var start = Vector2(t_center_x, tower["y"] + 30.0)
	var target = Vector2(target_e["x"] + target_e["width"] / 2.0, target_e["y"] + target_e["height"] / 2.0)
	var vel = (target - start).normalized() * Config.SHURIKEN["SPEED"] * 1.2
	tower_arrows.append({"x": start.x, "y": start.y, "vx": vel.x, "vy": vel.y})

func spawn_enemy():
	var side = "left" if randf() < 0.5 else "right"
	var type_key = _pick_enemy_type()
	var type = Config.ENEMY_TYPES[type_key]
	var spawn_x = -type["width"] - 20.0 if side == "left" else view_width + 20.0
	var vx = type["baseSpeed"] if side == "left" else -type["baseSpeed"]
	var diff_hp_mult = Config.DIFFICULTIES_NUMERIC[selected_difficulty]["enemyHpMultiplier"]
	var hp_val = max(1, int(round(type["hp"] * diff_hp_mult)))

	enemies.append({
		"type": type_key,
		"x": spawn_x,
		"y": ground_y - type["height"],
		"width": type["width"],
		"height": type["height"],
		"vx": vx,
		"hp": hp_val,
		"maxHp": hp_val,
		"expValue": type["expValue"],
		"scoreValue": type["scoreValue"],
		"color": type["color"]
	})

func _pick_enemy_type() -> String:
	var pool = []
	var total_w = 0
	for k in Config.ENEMY_TYPES.keys():
		var type = Config.ENEMY_TYPES[k]
		var req = type.get("reqLevel", 1)
		if level >= req:
			pool.append(type)
			total_w += type["spawnWeight"]
	var rnd = randi() % max(1, total_w)
	var accum = 0
	for type in pool:
		accum += type["spawnWeight"]
		if rnd < accum:
			return type["id"]
	return "NORMAL"

func _get_shuriken_size() -> float:
	return Config.SHURIKEN["BASE_SIZE"] + min(level - 1, 5) * 1.2

func _get_sword_range() -> float:
	if selected_difficulty == "GOD": return 300.0
	return Config.PLAYER["BASE_SWORD_RANGE"] + (level - 1) * 8.0

func _add_particles(x: float, y: float, col: Color, count: int):
	for i in range(count):
		var angle = randf() * PI * 2.0
		var speed = randf_range(50.0, 200.0)
		particles.append({
			"x": x, "y": y,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"color": col,
			"life": randf_range(0.2, 0.5)
		})

func game_over():
	sound_system.play_game_over()
	_set_state(GameState.GAMEOVER)
	var is_new = (score > high_score)
	if is_new:
		high_score = score
		_save_high_score()

	final_score_val.text = str(score)
	final_best_val.text = str(high_score)
	new_record_tag.visible = is_new
