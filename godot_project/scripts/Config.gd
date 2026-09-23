# Config.gd
class_name Config

const CANVAS_WIDTH: float = 960.0
const CANVAS_HEIGHT: float = 540.0

const UI_TEXT = {
	"zh": {
		"lang_toggle": "English",
		"title": "忍者手裏劍",
		"subtitle": "SHURIKEN HERO v2.2.0 (Godot Port)",
		"creators": "Creators: JFCC & Jules",
		"mode_header": "選擇模式 (Game Mode)",
		"mode_classic": "經典防守",
		"mode_defense": "箭塔防禦",
		"diff_header": "選擇難度 (Difficulty)",
		"diff_god": "上帝",
		"diff_very_easy": "極簡",
		"diff_easy": "簡單",
		"diff_normal": "普通",
		"diff_hard": "困難",
		"diff_nightmare": "噩夢",
		"start_game": "開始遊戲 (START)",
		"hp_label": "HP:",
		"tower_label": "TOWER:",
		"level_label": "LV:",
		"wave_label": "WAVE:",
		"score_label": "SCORE:",
		"best_label": "BEST:",
		"paused_title": "遊戲暫停 (PAUSED)",
		"resume": "繼續遊戲 (Resume)",
		"restart": "重新開始 (Restart)",
		"main_menu": "返回主選單 (Main Menu)",
		"game_over": "GAME OVER",
		"final_score": "最終得分：",
		"final_best": "歷史最高：",
		"new_record": "刷新最高紀錄！",
		"play_again": "再試一次 (Play Again)",
		"touch_left": "左移 & 射擊",
		"touch_right": "右移 & 射擊",
		"touch_sword": "斬擊"
	},
	"en": {
		"lang_toggle": "繁體中文",
		"title": "NINJA SHURIKEN",
		"subtitle": "SHURIKEN HERO v2.2.0 (Godot Port)",
		"creators": "Creators: JFCC & Jules",
		"mode_header": "Game Mode",
		"mode_classic": "Classic Defense",
		"mode_defense": "Tower Defense",
		"diff_header": "Difficulty",
		"diff_god": "GOD",
		"diff_very_easy": "V.EASY",
		"diff_easy": "EASY",
		"diff_normal": "NORMAL",
		"diff_hard": "HARD",
		"diff_nightmare": "NIGHTMARE",
		"start_game": "START GAME",
		"hp_label": "HP:",
		"tower_label": "TOWER:",
		"level_label": "LV:",
		"wave_label": "WAVE:",
		"score_label": "SCORE:",
		"best_label": "BEST:",
		"paused_title": "PAUSED",
		"resume": "Resume",
		"restart": "Restart",
		"main_menu": "Main Menu",
		"game_over": "GAME OVER",
		"final_score": "Final Score: ",
		"final_best": "High Score: ",
		"new_record": "NEW HIGH SCORE!",
		"play_again": "Play Again",
		"touch_left": "Left / Shoot",
		"touch_right": "Right / Shoot",
		"touch_sword": "Slash"
	}
}

const PLAYER = {
	"WIDTH": 48.0,
	"HEIGHT": 48.0,
	"SPEED": 320.0,
	"SHOOT_COOLDOWN_MS": 200.0,
	"SWORD_COOLDOWN_MS": 300.0,
	"SWORD_DURATION_MS": 150.0,
	"BASE_SWORD_RANGE": 90.0,
	"INVINCIBILITY_DURATION_MS": 1000.0,
	"MOVE_BOUNDS_MARGIN": 0.0
}

const SHURIKEN = {
	"BASE_SIZE": 16.0,
	"SPEED": 520.0,
	"MAX_COUNT": 30
}

const TOWER = {
	"WIDTH": 80.0,
	"HEIGHT": 140.0,
	"MAX_HP": 100,
	"AUTO_SHOOT_LEVEL": 6,
	"AUTO_SHOOT_COOLDOWN_MS": 1000.0
}

const ENEMY_TYPES = {
	"NORMAL": {
		"id": "NORMAL",
		"width": 42.0,
		"height": 42.0,
		"baseSpeed": 80.0,
		"hp": 1,
		"expValue": 10,
		"scoreValue": 100,
		"spawnWeight": 60,
		"reqLevel": 1,
		"color": Color("#e74c3c")
	},
	"FAST": {
		"id": "FAST",
		"width": 36.0,
		"height": 36.0,
		"baseSpeed": 160.0,
		"hp": 1,
		"expValue": 15,
		"scoreValue": 150,
		"spawnWeight": 25,
		"reqLevel": 2,
		"color": Color("#f1c40f")
	},
	"TANK": {
		"id": "TANK",
		"width": 58.0,
		"height": 58.0,
		"baseSpeed": 45.0,
		"hp": 3,
		"expValue": 35,
		"scoreValue": 300,
		"spawnWeight": 12,
		"reqLevel": 3,
		"color": Color("#8e44ad")
	},
	"SHADOW": {
		"id": "SHADOW",
		"width": 38.0,
		"height": 38.0,
		"baseSpeed": 220.0,
		"hp": 1,
		"expValue": 25,
		"scoreValue": 250,
		"spawnWeight": 8,
		"reqLevel": 5,
		"color": Color("#34495e")
	},
	"BOSS": {
		"id": "BOSS",
		"width": 80.0,
		"height": 80.0,
		"baseSpeed": 35.0,
		"hp": 10,
		"expValue": 100,
		"scoreValue": 1000,
		"spawnWeight": 3,
		"reqLevel": 7,
		"color": Color("#c0392b")
	}
}

const GAME_MODES_NUMERIC = {
	"CLASSIC": {
		"initialSpawnInterval": 1800.0,
		"scoreMultiplier": 1.0
	},
	"DEFENSE": {
		"initialSpawnInterval": 1400.0,
		"scoreMultiplier": 1.2
	}
}

const GAME_MODES = {
	"zh": {
		"CLASSIC": {
			"title": "經典防守 (Classic Defense)",
			"desc": "中央防守經典玩法！擊退陸續襲來的各路忍者。"
		},
		"DEFENSE": {
			"title": "箭塔防禦 (Tower Defense)",
			"desc": "守護中央箭塔！等級達到 Lv.6 箭塔將解鎖自動射擊支援。"
		}
	},
	"en": {
		"CLASSIC": {
			"title": "Classic Defense",
			"desc": "Defend the center! Repel incoming ninjas from both sides."
		},
		"DEFENSE": {
			"title": "Tower Defense",
			"desc": "Protect the central tower! Unlocks auto-shooting support at Lv.6."
		}
	}
}

const DIFFICULTIES_NUMERIC = {
	"GOD": {
		"playerHp": 99,
		"enemySpeedMultiplier": 0.5,
		"enemyHpMultiplier": 0.5,
		"enemySpawnRateMultiplier": 1.5,
		"scoreMultiplier": 0.1,
		"startLevel": 10
	},
	"VERY_EASY": {
		"playerHp": 5,
		"enemySpeedMultiplier": 0.7,
		"enemyHpMultiplier": 0.7,
		"enemySpawnRateMultiplier": 1.3,
		"scoreMultiplier": 0.5
	},
	"EASY": {
		"playerHp": 4,
		"enemySpeedMultiplier": 0.85,
		"enemyHpMultiplier": 0.85,
		"enemySpawnRateMultiplier": 1.1,
		"scoreMultiplier": 0.8
	},
	"NORMAL": {
		"playerHp": 3,
		"enemySpeedMultiplier": 1.0,
		"enemyHpMultiplier": 1.0,
		"enemySpawnRateMultiplier": 1.0,
		"scoreMultiplier": 1.0
	},
	"HARD": {
		"playerHp": 2,
		"enemySpeedMultiplier": 1.25,
		"enemyHpMultiplier": 1.3,
		"enemySpawnRateMultiplier": 0.8,
		"scoreMultiplier": 1.5
	},
	"NIGHTMARE": {
		"playerHp": 1,
		"enemySpeedMultiplier": 1.5,
		"enemyHpMultiplier": 1.6,
		"enemySpawnRateMultiplier": 0.65,
		"scoreMultiplier": 2.2
	}
}

const DIFFICULTIES = {
	"zh": {
		"GOD": {
			"title": "上帝模式 (GOD)",
			"desc": "無敵割草體驗！初始 Lv.10、超狂血量與全螢幕斬擊！",
			"stats": "初始血量: HPx99 | 敵人速度: 50% | 敵人生命: 50% | 分數加成: x0.1"
		},
		"VERY_EASY": {
			"title": "極簡模式 (Very Easy)",
			"desc": "輕鬆體驗！敵人速度緩慢且血量較低。",
			"stats": "初始血量: HPx5 | 敵人速度: 70% | 敵人生命: 70% | 分數加成: x0.5"
		},
		"EASY": {
			"title": "簡單模式 (Easy)",
			"desc": "適合新手入門，難度溫和。",
			"stats": "初始血量: HPx4 | 敵人速度: 85% | 敵人生命: 85% | 分數加成: x0.8"
		},
		"NORMAL": {
			"title": "普通模式 (Normal)",
			"desc": "標準挑戰！敵人屬性平衡，適合所有玩家。",
			"stats": "初始血量: HPx3 | 敵人速度: 100% | 敵人生命: 100% | 分數加成: x1.0"
		},
		"HARD": {
			"title": "困難模式 (Hard)",
			"desc": "高難度挑戰！敵人更快速且強壯。",
			"stats": "初始血量: HPx2 | 敵人速度: 125% | 敵人生命: 130% | 分數加成: x1.5"
		},
		"NIGHTMARE": {
			"title": "噩夢模式 (Nightmare)",
			"desc": "極限容錯率！一擊即死等級的終極考驗！",
			"stats": "初始血量: HPx1 | 敵人速度: 150% | 敵人生命: 160% | 分數加成: x2.2"
		}
	},
	"en": {
		"GOD": {
			"title": "GOD Mode",
			"desc": "Ultimate power! Start Lv.10, huge HP, full screen slashes!",
			"stats": "HP: x99 | Speed: 50% | Enemy HP: 50% | Score Mult: x0.1"
		},
		"VERY_EASY": {
			"title": "Very Easy",
			"desc": "Relaxing gameplay! Slow enemies with low HP.",
			"stats": "HP: x5 | Speed: 70% | Enemy HP: 70% | Score Mult: x0.5"
		},
		"EASY": {
			"title": "Easy",
			"desc": "Beginner friendly, gentle difficulty curve.",
			"stats": "HP: x4 | Speed: 85% | Enemy HP: 85% | Score Mult: x0.8"
		},
		"NORMAL": {
			"title": "Normal",
			"desc": "Standard challenge! Balanced enemy stats.",
			"stats": "HP: x3 | Speed: 100% | Enemy HP: 100% | Score Mult: x1.0"
		},
		"HARD": {
			"title": "Hard",
			"desc": "High difficulty! Faster & tougher enemies.",
			"stats": "HP: x2 | Speed: 125% | Enemy HP: 130% | Score Mult: x1.5"
		},
		"NIGHTMARE": {
			"title": "Nightmare",
			"desc": "Zero room for error! One hit lethal challenge!",
			"stats": "HP: x1 | Speed: 150% | Enemy HP: 160% | Score Mult: x2.2"
		}
	}
}

const SPAWN = {
	"MIN_INTERVAL_MS": 300.0,
	"INTERVAL_DECREASE_STEP": 80.0,
	"DIFFICULTY_RAMP_INTERVAL_MS": 10000.0
}

const PARTICLES = {
	"HIT_COUNT": 8,
	"DEATH_COUNT": 16
}
