// ==========================================
// GAME CONFIGURATION (STANDALONE MODULE)
// ==========================================
export const GAME_CONFIG = {
  CANVAS_WIDTH: 800,
  CANVAS_HEIGHT: 450,
  HIGH_SCORE_KEY: 'ninja_game_high_score',
  PLAYER: {
    INITIAL_HP: 3,
    INVINCIBILITY_DURATION_MS: 1500,
    SPEED: 4.5,
    WIDTH: 48,
    HEIGHT: 64,
    MOVE_BOUNDS_MARGIN: 80,
    SHOOT_COOLDOWN_MS: 180,
    SWORD_COOLDOWN_MS: 280,
    BASE_SWORD_RANGE: 90,
    SWORD_DURATION_MS: 200,
  },
  SHURIKEN: {
    SPEED: 9,
    BASE_SIZE: 20,
    MAX_COUNT: 12,
  },
  GAME_MODES: {
    CLASSIC: {
      id: 'CLASSIC',
      title: '經典防守 (Classic Defense)',
      badge: '🛡️ 經典',
      desc: '中央防守經典玩法！擊退陸續襲來的各路忍者。',
      scoreMultiplier: 1.0,
      initialSpawnInterval: 1800,
    },
    DEFENSE: {
      id: 'DEFENSE',
      title: '箭塔防禦 (Tower Defense)',
      badge: '🏹 箭塔',
      desc: '守護中央高聳箭塔！玩家死後1秒復活，箭塔摧毀即宣告失敗！LV.6起箭塔開啟自動伏擊箭矢射擊！',
      scoreMultiplier: 1.5,
      initialSpawnInterval: 1600,
    }
  },
  DIFFICULTIES: {
    GOD: {
      title: '上帝模式 (GOD MODE)',
      desc: '無敵神將！登場即享最高等級 (LV.10) 360度巨大化斬擊，敵人稀少極易擊破！',
      stats: '初始血量: ❤️x10 | 滿級能力 (LV.10) | 敵人速度: 40% | 分數加成: x5.0',
      enemySpeedMultiplier: 0.4, enemyHpMultiplier: 0.5, enemySpawnRateMultiplier: 2.5, playerHp: 10, startLevel: 10, scoreMultiplier: 5.0
    },
    VERY_EASY: {
      title: '極簡模式 (Very Easy)',
      desc: '輕鬆體驗！敵人速度極慢，血量極少，適合新手娛樂。',
      stats: '初始血量: ❤️x5 | 敵人速度: 60% | 敵人生命: 70% | 分數加成: x0.8',
      enemySpeedMultiplier: 0.6, enemyHpMultiplier: 0.7, enemySpawnRateMultiplier: 1.5, playerHp: 5, startLevel: 1, scoreMultiplier: 0.8
    },
    EASY: {
      title: '簡單模式 (Easy)',
      desc: '較為輕鬆！適中的節奏與較多的生命值。',
      stats: '初始血量: ❤️x4 | 敵人速度: 80% | 敵人生命: 85% | 分數加成: x1.0',
      enemySpeedMultiplier: 0.8, enemyHpMultiplier: 0.85, enemySpawnRateMultiplier: 1.2, playerHp: 4, startLevel: 1, scoreMultiplier: 1.0
    },
    NORMAL: {
      title: '普通模式 (Normal)',
      desc: '標準挑戰！敵人屬性平衡，適合所有玩家。',
      stats: '初始血量: ❤️x3 | 敵人速度: 100% | 敵人生命: 100% | 分數加成: x1.5',
      enemySpeedMultiplier: 1.0, enemyHpMultiplier: 1.0, enemySpawnRateMultiplier: 1.0, playerHp: 3, startLevel: 1, scoreMultiplier: 1.5
    },
    HARD: {
      title: '困難模式 (Hard)',
      desc: '高難挑戰！敵人移動敏捷且生命力強，考驗反應！',
      stats: '初始血量: ❤️x2 | 敵人速度: 125% | 敵人生命: 130% | 分數加成: x2.0',
      enemySpeedMultiplier: 1.25, enemyHpMultiplier: 1.3, enemySpawnRateMultiplier: 0.8, playerHp: 2, startLevel: 1, scoreMultiplier: 2.0
    },
    NIGHTMARE: {
      title: '噩夢模式 (Nightmare)',
      desc: '極限地獄！敵人群聚狂暴襲來，容錯率極低！',
      stats: '初始血量: ❤️x1 | 敵人速度: 150% | 敵人生命: 170% | 分數加成: x0.6',
      enemySpeedMultiplier: 1.5, enemyHpMultiplier: 1.7, enemySpawnRateMultiplier: 0.6, playerHp: 1, startLevel: 1, scoreMultiplier: 3.0
    }
  },
  ENEMY_TYPES: {
    NORMAL: { id: 'NORMAL', name: '普通忍', width: 42, height: 58, baseSpeed: 1.8, hp: 1, expValue: 20, scoreValue: 100, color: '#e74c3c', spawnWeight: 45 },
    FAST: { id: 'FAST', name: '疾風忍', width: 36, height: 50, baseSpeed: 3.2, hp: 1, expValue: 35, scoreValue: 200, color: '#f1c40f', spawnWeight: 25 },
    TANK: { id: 'TANK', name: '重裝忍', width: 58, height: 74, baseSpeed: 1.0, hp: 3, expValue: 60, scoreValue: 350, color: '#8e44ad', spawnWeight: 15 },
    SHADOW: { id: 'SHADOW', name: '影忍', width: 40, height: 54, baseSpeed: 4.2, hp: 2, expValue: 80, scoreValue: 500, color: '#34495e', spawnWeight: 10, reqLevel: 3 },
    BOSS: { id: 'BOSS', name: '鬼將', width: 68, height: 84, baseSpeed: 1.2, hp: 6, expValue: 150, scoreValue: 800, color: '#2c3e50', spawnWeight: 5, reqLevel: 5 }
  },
  TOWER: {
    MAX_HP: 500,
    WIDTH: 60,
    HEIGHT: 180,
    AUTO_SHOOT_LEVEL: 6,
    AUTO_SHOOT_COOLDOWN_MS: 800,
  },
  SPAWN: {
    INITIAL_INTERVAL_MS: 1800,
    MIN_INTERVAL_MS: 400,
    DIFFICULTY_RAMP_INTERVAL_MS: 5000,
    INTERVAL_DECREASE_STEP: 50,
  },
  PARTICLES: { HIT_COUNT: 12, DEATH_COUNT: 25 }
};
