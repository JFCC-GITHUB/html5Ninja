# Main.gd
extends Node2D

enum GameState { MENU, PLAYING, PAUSED, GAMEOVER }

var state: GameState = GameState.MENU
var selected_mode: String = "CLASSIC"
var selected_difficulty: String = "NORMAL"

var score: int = 0
var high_score: int = 0
var level: int = 1
var current_wave: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 100

var game_start_time: float = 0.0
var last_spawn_time: float = 0.0
var current_spawn_interval: float = 1800.0
var last_shoot_time: float = 0.0
var last_sword_time: float = 0.0
var last_tower_shoot_time: float = 0.0

var is_sword_attacking: bool = false
var sword_attack_timer: float = 0.0
var player_respawn_timer: float = 0.0
var is_player_dead_in_defense: bool = false

# Game Entities
var player: Dictionary = {}
var tower: Dictionary = {}
var shurikens: Array = []
var tower_arrows: Array = []
var enemies: Array = []
var particles: Array = []
var floating_texts: Array = []

# Textures
var tex_ninja_idle_r: ImageTexture
var tex_ninja_idle_l: ImageTexture
var tex_ninja_run_r: ImageTexture
var tex_ninja_run_l: ImageTexture
var tex_shuriken: ImageTexture
var tex_tower: ImageTexture
var tex_arrow: ImageTexture
var enemy_textures: Dictionary = {}
var custom_font: FontFile

# Node References
@onready var sound_system: SoundSystem = $SoundSystem
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD
@onready var menu_screen: Control = $UILayer/MenuScreen
@onready var pause_screen: Control = $UILayer/PauseScreen
@onready var gameover_screen: Control = $UILayer/GameOverScreen
@onready var touch_controls: Control = $UILayer/TouchControls

# HUD UI References
@onready var hp_hearts: HBoxContainer = $UILayer/HUD/HpHearts
@onready var tower_hp_container: HBoxContainer = $UILayer/HUD/TowerHpContainer
@onready var tower_hp_val: Label = $UILayer/HUD/TowerHpContainer/TowerHpVal
@onready var level_val: Label = $UILayer/HUD/LevelContainer/LevelVal
@onready var wave_val: Label = $UILayer/HUD/WaveContainer/WaveVal
@onready var exp_bar_fill: ColorRect = $UILayer/HUD/LevelContainer/ExpBarContainer/ExpBarFill
@onready var score_val: Label = $UILayer/HUD/ScoreContainer/ScoreVal
@onready var high_score_val: Label = $UILayer/HUD/HighScoreContainer/HighScoreVal

# Menu UI References
@onready var diff_title: Label = $UILayer/MenuScreen/OverlayContent/MenuBox/DiffDetailPanel/DiffTitle
@onready var diff_desc: Label = $UILayer/MenuScreen/OverlayContent/MenuBox/DiffDetailPanel/DiffDesc
@onready var diff_stats: Label = $UILayer/MenuScreen/OverlayContent/MenuBox/DiffDetailPanel/DiffStats
@onready var btn_classic: Button = $UILayer/MenuScreen/OverlayContent/MenuBox/ModeButtons/BtnClassic
@onready var btn_defense: Button = $UILayer/MenuScreen/OverlayContent/MenuBox/ModeButtons/BtnDefense

# GameOver UI References
@onready var final_score_val: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/FinalScoreVal
@onready var final_best_val: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/FinalBestVal
@onready var new_record_tag: Label = $UILayer/GameOverScreen/OverlayContent/MenuBox/NewRecordTag

# Key inputs
var key_left: bool = false
var key_right: bool = false

func _ready():
	_setup_custom_font()
	_generate_textures()
	_load_high_score()
	_update_difficulty_panel()
	_connect_ui_signals()
	_set_state(GameState.MENU)

func _setup_custom_font():
	if ResourceLoader.exists("res://fonts/NotoSansTC-Regular.ttf"):
		custom_font = load("res://fonts/NotoSansTC-Regular.ttf")
		if custom_font:
			var theme = Theme.new()
			theme.default_font = custom_font
			theme.default_font_size = 14
			ui_layer.get_children().map(func(c): if c is Control: c.theme = theme)

func _generate_textures():
	tex_ninja_idle_r = PixelGenerator.create_ninja_texture(false, false)
	tex_ninja_idle_l = PixelGenerator.create_ninja_texture(false, true)
	tex_ninja_run_r = PixelGenerator.create_ninja_texture(true, false)
	tex_ninja_run_l = PixelGenerator.create_ninja_texture(true, true)
	tex_shuriken = PixelGenerator.create_shuriken_texture()
	tex_tower = PixelGenerator.create_tower_texture(int(Config.TOWER["WIDTH"]), int(Config.TOWER["HEIGHT"]))
	tex_arrow = PixelGenerator.create_arrow_texture()

	for k in Config.ENEMY_TYPES.keys():
		var type = Config.ENEMY_TYPES[k]
		var sub_c = Color("#c0392b") if k == "NORMAL" else (Color("#f39c12") if k == "FAST" else (Color("#9b59b6") if k == "TANK" else (Color("#2c3e50") if k == "SHADOW" else Color("#e74c3c"))))
		enemy_textures[k] = {
			"right": PixelGenerator.create_enemy_texture(type["color"], sub_c, int(type["width"]), int(type["height"]), false),
			"left": PixelGenerator.create_enemy_texture(type["color"], sub_c, int(type["width"]), int(type["height"]), true)
		}

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

	var diff_grid = $UILayer/MenuScreen/OverlayContent/MenuBox/DifficultyButtons
	for btn in diff_grid.get_children():
		if btn is Button and btn.has_meta("diff"):
			var d_key = btn.get_meta("diff")
			btn.pressed.connect(func(): _select_difficulty(d_key))

	$UILayer/MenuScreen/OverlayContent/MenuBox/BtnStart.pressed.connect(start_game)
	$UILayer/HUD/BtnPause.pressed.connect(toggle_pause)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnResume.pressed.connect(toggle_pause)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnRestartPause.pressed.connect(start_game)
	$UILayer/PauseScreen/OverlayContent/MenuBox/BtnMenuPause.pressed.connect(func(): _set_state(GameState.MENU))

	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnRestart.pressed.connect(start_game)
	$UILayer/GameOverScreen/OverlayContent/MenuBox/BtnMenuGameover.pressed.connect(func(): _set_state(GameState.MENU))

	# Touch Controls
	var touch_l = $UILayer/TouchControls/TouchLeft
	var touch_r = $UILayer/TouchControls/TouchRight
	var touch_s = $UILayer/TouchControls/TouchSword

	touch_l.gui_input.connect(func(event):
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			key_left = event.pressed
	)
	touch_r.gui_input.connect(func(event):
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			key_right = event.pressed
	)
	touch_s.pressed.connect(func(): perform_sword_attack())

func _select_mode(m: String):
	sound_system.play_click()
	selected_mode = m
	btn_classic.modulate = Color(1, 1, 1, 1) if m == "CLASSIC" else Color(0.6, 0.6, 0.6, 1)
	btn_defense.modulate = Color(1, 1, 1, 1) if m == "DEFENSE" else Color(0.6, 0.6, 0.6, 1)
	_update_difficulty_panel()

func _select_difficulty(d: String):
	sound_system.play_click()
	selected_difficulty = d
	_update_difficulty_panel()

func _update_difficulty_panel():
	var mode_cfg = Config.GAME_MODES[selected_mode]
	var diff_cfg = Config.DIFFICULTIES[selected_difficulty]
	diff_title.text = mode_cfg["title"] + " - " + diff_cfg["title"]
	diff_desc.text = mode_cfg["desc"] + "\n" + diff_cfg["desc"]
	diff_stats.text = diff_cfg["stats"]

func _set_state(new_state: GameState):
	state = new_state
	menu_screen.visible = (state == GameState.MENU)
	pause_screen.visible = (state == GameState.PAUSED)
	gameover_screen.visible = (state == GameState.GAMEOVER)
	hud.visible = (state == GameState.PLAYING or state == GameState.PAUSED)
	touch_controls.visible = (state == GameState.PLAYING)

func toggle_pause():
	if state == GameState.PLAYING:
		sound_system.play_click()
		_set_state(GameState.PAUSED)
	elif state == GameState.PAUSED:
		sound_system.play_click()
		_set_state(GameState.PLAYING)

func start_game():
	sound_system.play_click()
	var diff_cfg = Config.DIFFICULTIES[selected_difficulty]
	var mode_cfg = Config.GAME_MODES[selected_mode]

	score = 0
	level = diff_cfg.get("startLevel", 1)
	current_wave = 1
	current_exp = 0
	exp_to_next_level = 100
	game_start_time = Time.get_ticks_msec() / 1000.0
	last_spawn_time = game_start_time
	current_spawn_interval = mode_cfg["initialSpawnInterval"] / 1000.0
	last_shoot_time = 0.0
	last_sword_time = 0.0
	last_tower_shoot_time = 0.0
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
		"x": Config.CANVAS_WIDTH / 2.0 - Config.PLAYER["WIDTH"] / 2.0,
		"y": Config.CANVAS_HEIGHT - Config.PLAYER["HEIGHT"] - 40.0,
		"width": Config.PLAYER["WIDTH"],
		"height": Config.PLAYER["HEIGHT"],
		"hp": diff_cfg["playerHp"],
		"maxHp": diff_cfg["playerHp"],
		"facing": "right",
		"moving": false,
		"invincibleTimer": 0.0
	}

	if selected_mode == "DEFENSE":
		tower = {
			"x": Config.CANVAS_WIDTH / 2.0 - Config.TOWER["WIDTH"] / 2.0,
			"y": Config.CANVAS_HEIGHT - Config.TOWER["HEIGHT"] - 40.0,
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
		c.queue_free()
	for i in range(player["maxHp"]):
		var lbl = Label.new()
		lbl.text = "HP" if i < player["hp"] else "--"
		if custom_font: lbl.add_theme_font_override("font", custom_font)
		hp_hearts.add_child(lbl)

func _update_tower_hp_display():
	if selected_mode == "DEFENSE":
		var pct = int(clamp((float(tower["hp"]) / float(tower["maxHp"])) * 100.0, 0.0, 100.0))
		tower_hp_val.text = str(pct) + "%"

func _update_level_display():
	level_val.text = str(level)
	wave_val.text = str(current_wave)
	var pct = clamp(float(current_exp) / float(exp_to_next_level), 0.0, 1.0)
	exp_bar_fill.custom_minimum_size.x = pct * 70.0

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
	var mult = Config.DIFFICULTIES[selected_difficulty]["scoreMultiplier"] * Config.GAME_MODES[selected_mode]["scoreMultiplier"]
	score += int(round(pts * mult))
	score_val.text = str(score)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func _process(delta):
	if state == GameState.PLAYING:
		_update_game(delta)
	queue_redraw()

func _update_game(delta: float):
	var now = Time.get_ticks_msec() / 1000.0

	# Key inputs
	var move_left = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or key_left
	var move_right = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or key_right
	var do_shoot = Input.is_key_pressed(KEY_SPACE) or move_left or move_right
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
			player["x"] = min(Config.CANVAS_WIDTH - Config.PLAYER["MOVE_BOUNDS_MARGIN"] - player["width"], player["x"] + move_speed)
			player["facing"] = "right"
			player["moving"] = true

		if do_shoot:
			shoot_shuriken()
		if do_sword:
			perform_sword_attack()

	# Handle Sword Attack Duration
	if is_sword_attacking:
		sword_attack_timer -= delta
		if sword_attack_timer <= 0.0:
			is_sword_attacking = false

	# Wave & Spawn Progression
	var elapsed = now - game_start_time
	current_wave = 1 + int(elapsed / (Config.SPAWN["DIFFICULTY_RAMP_INTERVAL_MS"] / 1000.0))
	var base_interval = Config.GAME_MODES[selected_mode]["initialSpawnInterval"]
	var rate_mult = Config.DIFFICULTIES[selected_difficulty]["enemySpawnRateMultiplier"]
	var raw_interval = max(Config.SPAWN["MIN_INTERVAL_MS"], base_interval - (current_wave - 1) * Config.SPAWN["INTERVAL_DECREASE_STEP"])
	current_spawn_interval = (raw_interval / 1000.0) * rate_mult

	if now - last_spawn_time >= current_spawn_interval:
		last_spawn_time = now
		spawn_enemy()

	# Tower Auto Shooting (Defense Mode & Level 6+)
	if selected_mode == "DEFENSE" and level >= Config.TOWER["AUTO_SHOOT_LEVEL"]:
		if now - last_tower_shoot_time >= Config.TOWER["AUTO_SHOOT_COOLDOWN_MS"] / 1000.0:
			last_tower_shoot_time = now
			tower_shoot_arrow()

	# Update Shurikens
	var new_shurikens = []
	for s in shurikens:
		s["x"] += s["vx"] * delta
		if s["x"] >= -50 and s["x"] <= Config.CANVAS_WIDTH + 50:
			new_shurikens.append(s)
	shurikens = new_shurikens

	# Update Tower Arrows
	var new_arrows = []
	for a in tower_arrows:
		a["x"] += a["vx"] * delta
		if a["x"] >= -50 and a["x"] <= Config.CANVAS_WIDTH + 50:
			new_arrows.append(a)
	tower_arrows = new_arrows

	# Update Enemies & Collisions
	var diff_cfg = Config.DIFFICULTIES[selected_difficulty]
	var enemy_speed_mult = diff_cfg["enemySpeedMultiplier"]
	var new_enemies = []

	for e in enemies:
		e["x"] += e["vx"] * enemy_speed_mult * delta

		# Check Sword Slash Attack Hit
		if is_sword_attacking:
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
				e["hp"] -= 1
				sound_system.play_enemy_hit()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#f39c12"), Config.PARTICLES["HIT_COUNT"])

		# Check Tower Arrow Collisions
		for a in tower_arrows:
			if a.get("hit", false): continue
			var a_rect = Rect2(a["x"], a["y"], 24, 8)
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
			sound_system.play_enemy_hit()
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
				tower["hp"] -= e["hp"] * 10
				_update_tower_hp_display()
				_add_particles(e["x"] + e["width"] / 2.0, e["y"] + e["height"] / 2.0, Color("#e74c3c"), 15)
				sound_system.play_player_hurt()
				if tower["hp"] <= 0:
					game_over()
					return
				continue

		# Remove enemies reaching edges (Classic mode center defense)
		if selected_mode == "CLASSIC":
			if (e["vx"] > 0 and e["x"] > Config.CANVAS_WIDTH + 50) or (e["vx"] < 0 and e["x"] < -100):
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
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shoot_time < Config.PLAYER["SHOOT_COOLDOWN_MS"] / 1000.0: return
	if shurikens.size() >= Config.SHURIKEN["MAX_COUNT"]: return
	last_shoot_time = now
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
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_sword_time < Config.PLAYER["SWORD_COOLDOWN_MS"] / 1000.0: return
	last_sword_time = now
	is_sword_attacking = true
	sword_attack_timer = Config.PLAYER["SWORD_DURATION_MS"] / 1000.0
	sound_system.play_sword_slash()

func tower_shoot_arrow():
	if enemies.size() == 0: return
	# Find nearest enemy
	var t_center_x = tower["x"] + tower["width"] / 2.0
	var target_e = enemies[0]
	var min_dist = abs(target_e["x"] - t_center_x)
	for e in enemies:
		var d = abs(e["x"] - t_center_x)
		if d < min_dist:
			min_dist = d
			target_e = e

	var dir = 1.0 if target_e["x"] > t_center_x else -1.0
	tower_arrows.append({
		"x": t_center_x,
		"y": tower["y"] + 30.0,
		"vx": dir * Config.SHURIKEN["SPEED"] * 1.2
	})

func spawn_enemy():
	var side = "left" if randf() < 0.5 else "right"
	var type_key = _pick_enemy_type()
	var type = Config.ENEMY_TYPES[type_key]
	var spawn_x = -type["width"] - 20.0 if side == "left" else Config.CANVAS_WIDTH + 20.0
	var vx = type["baseSpeed"] if side == "left" else -type["baseSpeed"]
	var diff_hp_mult = Config.DIFFICULTIES[selected_difficulty]["enemyHpMultiplier"]
	var hp_val = max(1, int(round(type["hp"] * diff_hp_mult)))

	enemies.append({
		"type": type_key,
		"x": spawn_x,
		"y": Config.CANVAS_HEIGHT - type["height"] - 40.0,
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
	return Config.SHURIKEN["BASE_SIZE"] + (level - 1) * 1.5

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

func _draw():
	# Background
	draw_rect(Rect2(0, 0, Config.CANVAS_WIDTH, Config.CANVAS_HEIGHT), Color("#111116"))
	# Ground
	draw_rect(Rect2(0, Config.CANVAS_HEIGHT - 40, Config.CANVAS_WIDTH, 40), Color("#1a1c29"))
	draw_line(Vector2(0, Config.CANVAS_HEIGHT - 40), Vector2(Config.CANVAS_WIDTH, Config.CANVAS_HEIGHT - 40), Color("#f39c12"), 2.0)

	if state == GameState.MENU: return

	# Draw Tower
	if selected_mode == "DEFENSE":
		draw_texture(tex_tower, Vector2(tower["x"], tower["y"]))

	# Draw Player
	if not is_player_dead_in_defense:
		var p_tex = tex_ninja_run_r if player["moving"] and player["facing"] == "right" else (
			tex_ninja_run_l if player["moving"] and player["facing"] == "left" else (
				tex_ninja_idle_r if player["facing"] == "right" else tex_ninja_idle_l
			)
		)
		var is_inv = (player["invincibleTimer"] > 0.0 and fmod(player["invincibleTimer"] * 10.0, 1.0) > 0.5)
		if not is_inv:
			draw_texture(p_tex, Vector2(player["x"], player["y"]))

		# Draw Sword Slash Visual
		if is_sword_attacking:
			var s_range = _get_sword_range()
			var p_center_x = player["x"] + player["width"] / 2.0
			var p_center_y = player["y"] + player["height"] / 2.0
			var arc_color = Color(0.9, 0.2, 0.2, 0.6)
			if selected_difficulty == "GOD":
				draw_circle(Vector2(p_center_x, p_center_y), s_range, Color(1, 0.8, 0.2, 0.4))
			else:
				var start_a = -PI / 3.0 if player["facing"] == "right" else PI - PI / 3.0
				var end_a = PI / 3.0 if player["facing"] == "right" else PI + PI / 3.0
				draw_arc(Vector2(p_center_x, p_center_y), s_range, start_a, end_a, 16, arc_color, 8.0)

	# Draw Enemies
	for e in enemies:
		var side_str = "right" if e["vx"] > 0 else "left"
		var tex = enemy_textures[e["type"]][side_str]
		draw_texture(tex, Vector2(e["x"], e["y"]))
		# HP Bar if hp > 1
		if e["maxHp"] > 1:
			var bar_w = e["width"]
			var hp_pct = float(e["hp"]) / float(e["maxHp"])
			draw_rect(Rect2(e["x"], e["y"] - 8, bar_w, 4), Color("#000000"))
			draw_rect(Rect2(e["x"], e["y"] - 8, bar_w * hp_pct, 4), Color("#e74c3c"))

	# Draw Shurikens
	for s in shurikens:
		draw_texture(tex_shuriken, Vector2(s["x"], s["y"]))

	# Draw Tower Arrows
	for a in tower_arrows:
		draw_texture(tex_arrow, Vector2(a["x"], a["y"]))

	# Draw Particles
	for p in particles:
		draw_rect(Rect2(p["x"], p["y"], 3, 3), p["color"])

	# Draw Floating Text
	var active_font = custom_font if custom_font else ThemeDB.fallback_font
	for ft in floating_texts:
		var c = ft["color"]
		c.a = clamp(ft["life"], 0.0, 1.0)
		draw_string(active_font, Vector2(ft["x"] - 30, ft["y"]), ft["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, c)
