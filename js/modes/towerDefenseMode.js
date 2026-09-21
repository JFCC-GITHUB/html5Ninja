// ==========================================
// TOWER DEFENSE MODE MODULE
// ==========================================
import {
  GAME_CONFIG, getSprites, SoundSystem, checkAABBCollision,
  createPlayer, getShurikenSize, getSwordRange, createParticles,
  drawBackground
} from '../common.js';

export class TowerDefenseMode {
  constructor(ctx, canvas, uiElements) {
    this.ctx = ctx;
    this.canvas = canvas;
    this.ui = uiElements;
    this.sprites = getSprites();

    this.selectedDifficulty = 'NORMAL';
    this.score = 0;
    this.level = 1;
    this.currentWave = 1;
    this.currentExp = 0;
    this.expToNextLevel = 100;

    this.player = null;
    this.tower = null;
    this.shurikens = [];
    this.towerArrows = [];
    this.enemies = [];
    this.particles = [];
    this.floatingTexts = [];

    this.lastSpawnTime = 0;
    this.gameStartTime = 0;
    this.lastShootTime = 0;
    this.lastSwordTime = 0;
    this.lastTowerShootTime = 0;
  }

  init(selectedDifficulty) {
    this.selectedDifficulty = selectedDifficulty;
    const diff = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    this.score = 0;
    this.level = diff.startLevel || 1;
    this.currentWave = 1;
    this.currentExp = 0;
    this.expToNextLevel = 100;

    this.gameStartTime = Date.now();
    this.lastSpawnTime = Date.now();
    this.lastTowerShootTime = Date.now();
    this.shurikens = [];
    this.towerArrows = [];
    this.enemies = [];
    this.particles = [];
    this.floatingTexts = [];

    this.player = createPlayer(diff.playerHp);
    this.tower = {
      x: GAME_CONFIG.CANVAS_WIDTH / 2 - GAME_CONFIG.TOWER.WIDTH / 2,
      y: GAME_CONFIG.CANVAS_HEIGHT - GAME_CONFIG.TOWER.HEIGHT - 40,
      width: GAME_CONFIG.TOWER.WIDTH,
      height: GAME_CONFIG.TOWER.HEIGHT,
      hp: GAME_CONFIG.TOWER.MAX_HP,
      maxHp: GAME_CONFIG.TOWER.MAX_HP,
    };

    this.ui.towerHpContainer.classList.remove('hidden');
    this.updateHpDisplay();
    this.updateTowerHpDisplay();
    this.updateLevelDisplay();
    this.ui.scoreVal.textContent = '0';
  }

  updateHpDisplay() {
    this.ui.hpHearts.innerHTML = '';
    for (let i = 0; i < this.player.maxHp; i++) {
      const heart = document.createElement('span');
      heart.textContent = i < this.player.hp ? '❤️' : '🖤';
      this.ui.hpHearts.appendChild(heart);
    }
  }

  updateTowerHpDisplay() {
    const percent = Math.max(0, Math.floor((this.tower.hp / this.tower.maxHp) * 100));
    this.ui.towerHpVal.textContent = `${percent}%`;
  }

  updateLevelDisplay() {
    this.ui.levelVal.textContent = this.level;
    this.ui.waveVal.textContent = this.currentWave;
    const fillPercent = Math.min(100, Math.floor((this.currentExp / this.expToNextLevel) * 100));
    this.ui.expBarFill.style.width = `${fillPercent}%`;
  }

  addExp(amount) {
    this.currentExp += amount;
    while (this.currentExp >= this.expToNextLevel) {
      this.currentExp -= this.expToNextLevel;
      this.level += 1;
      this.expToNextLevel = Math.round(this.expToNextLevel * 1.35);
      SoundSystem.playLevelUp();
      createParticles(this.particles, this.player.x + this.player.width / 2, this.player.y + this.player.height / 2, '#2ecc71', 30);
      this.floatingTexts.push({
        text: `LEVEL UP! LV.${this.level}`,
        x: this.player.x + this.player.width / 2,
        y: this.player.y - 20,
        color: '#2ecc71',
        life: 1.0,
      });
    }
    this.updateLevelDisplay();
  }

  shootShuriken() {
    if (this.player.isDead) return;
    const now = Date.now();
    if (now - this.lastShootTime < GAME_CONFIG.PLAYER.SHOOT_COOLDOWN_MS) return;
    if (this.shurikens.length >= GAME_CONFIG.SHURIKEN.MAX_COUNT) return;
    this.lastShootTime = now;
    SoundSystem.playShurikenThrow();
    const size = getShurikenSize(this.level);
    const dir = this.player.facing === 'RIGHT' ? 1 : -1;
    this.shurikens.push({
      x: this.player.facing === 'RIGHT' ? this.player.x + this.player.width : this.player.x - size,
      y: this.player.y + 20 - (size - GAME_CONFIG.SHURIKEN.BASE_SIZE) / 2,
      vx: GAME_CONFIG.SHURIKEN.SPEED * dir,
      size: size,
      rotation: 0,
    });
  }

  performSwordAttack() {
    if (this.player.isDead) return;
    const now = Date.now();
    if (now - this.lastSwordTime < GAME_CONFIG.PLAYER.SWORD_COOLDOWN_MS) return;
    this.lastSwordTime = now;
    this.player.isSwordslashing = true;
    this.player.swordUntil = now + GAME_CONFIG.PLAYER.SWORD_DURATION_MS;
    SoundSystem.playSwordSlash();

    const currentSwordRange = getSwordRange(this.level);
    const diff = GAME_CONFIG.DIFFICULTIES[this.selectedDifficulty];
    const swordDamage = 3 + Math.floor((this.level - 1) * 1.5);
    const isMultiDirection = this.level >= 3;

    let swordBox = null;
    if (isMultiDirection) {
      swordBox = {
        x: this.player.x + this.player.width / 2 - currentSwordRange,
        y: this.player.y + this.player.height / 2 - currentSwordRange,
        width: currentSwordRange * 2,
        height: currentSwordRange * 2
      };
    } else {
      swordBox = {
        x: this.player.facing === 'RIGHT' ? this.player.x + this.player.width : this.player.x - currentSwordRange,
        y: this.player.y - 15,
        width: currentSwordRange,
        height: this.player.height + 30
      };
    }

    for (let eIdx = this.enemies.length - 1; eIdx >= 0; eIdx--) {
      const enemy = this.enemies[eIdx];
      if (checkAABBCollision(swordBox, enemy)) {
        enemy.hp -= swordDamage;
        createParticles(this.particles, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, '#e74c3c', 15);
        if (enemy.hp <= 0) {
          SoundSystem.playEnemyHit();
          createParticles(this.particles, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, GAME_CONFIG.ENEMY_TYPES[enemy.type].color, GAME_CONFIG.PARTICLES.DEATH_COUNT);
          this.score += Math.round(enemy.scoreValue * diff.scoreMultiplier);
          this.ui.scoreVal.textContent = this.score;
          this.addExp(enemy.expValue);
          this.enemies.splice(eIdx, 1);
        } else {
          SoundSystem.playEnemyHit();
        }
      }
    }
  }

  spawnEnemy() {
    const diff = GAME_CONFIG.DIFFICULTIES[this.selectedDifficulty];
    const side = Math.random() < 0.5 ? 'LEFT' : 'RIGHT';
    const elapsedSec = (Date.now() - this.gameStartTime) / 1000;
    this.currentWave = 1 + Math.floor(elapsedSec / 15);

    let availableTypes = Object.values(GAME_CONFIG.ENEMY_TYPES).filter((t) => !t.reqLevel || this.level >= t.reqLevel || this.currentWave >= t.reqLevel);
    const totalWeight = availableTypes.reduce((sum, t) => sum + t.spawnWeight, 0);
    let rand = Math.random() * totalWeight;
    let typeConfig = availableTypes[0];
    for (const t of availableTypes) {
      if (rand <= t.spawnWeight) {
        typeConfig = t;
        break;
      }
      rand -= t.spawnWeight;
    }

    const startX = side === 'LEFT' ? -typeConfig.width - 10 : GAME_CONFIG.CANVAS_WIDTH + 10;
    const moveDir = side === 'LEFT' ? 1 : -1;
    const waveHpBonus = Math.floor((this.currentWave - 1) * 0.8) + Math.floor((this.level - 1) * 0.5);
    const waveSpeedMultiplier = 1 + (this.currentWave - 1) * 0.06 + (this.level - 1) * 0.03;
    const maxHp = Math.round((typeConfig.hp + waveHpBonus) * diff.enemyHpMultiplier);

    this.enemies.push({
      type: typeConfig.id,
      x: startX,
      y: GAME_CONFIG.CANVAS_HEIGHT - typeConfig.height - 40,
      width: typeConfig.width,
      height: typeConfig.height,
      vx: typeConfig.baseSpeed * diff.enemySpeedMultiplier * waveSpeedMultiplier * moveDir,
      hp: maxHp,
      maxHp: maxHp,
      expValue: typeConfig.expValue,
      scoreValue: typeConfig.scoreValue,
      facing: side === 'LEFT' ? 'RIGHT' : 'LEFT',
    });
  }

  towerAutoShoot() {
    const now = Date.now();
    if (now - this.lastTowerShootTime < GAME_CONFIG.TOWER.AUTO_SHOOT_COOLDOWN_MS) return;

    let nearestLeft = null;
    let nearestRight = null;
    const towerCenterX = this.tower.x + this.tower.width / 2;

    for (const enemy of this.enemies) {
      const eCenterX = enemy.x + enemy.width / 2;
      if (eCenterX < towerCenterX) {
        if (!nearestLeft || eCenterX > (nearestLeft.x + nearestLeft.width / 2)) nearestLeft = enemy;
      } else {
        if (!nearestRight || eCenterX < (nearestRight.x + nearestRight.width / 2)) nearestRight = enemy;
      }
    }

    if (nearestLeft || nearestRight) {
      this.lastTowerShootTime = now;
      SoundSystem.playShurikenThrow();
      const towerTopY = this.tower.y + 20;
      const arrowSpeed = 11;

      const fireArrowToTarget = (target) => {
        const targetX = target.x + target.width / 2;
        const targetY = target.y + target.height / 2;
        const dx = targetX - towerCenterX;
        const dy = targetY - towerTopY;
        const dist = Math.hypot(dx, dy) || 1;
        this.towerArrows.push({
          x: towerCenterX,
          y: towerTopY,
          vx: (dx / dist) * arrowSpeed,
          vy: (dy / dist) * arrowSpeed,
        });
      };

      if (nearestLeft) fireArrowToTarget(nearestLeft);
      if (nearestRight) fireArrowToTarget(nearestRight);
    }
  }

  update(keys, onGameOver) {
    const now = Date.now();

    // Player respawn handling (1 second delay after defeat)
    if (this.player.isDead) {
      if (now > this.player.respawnUntil) {
        const diff = GAME_CONFIG.DIFFICULTIES[this.selectedDifficulty];
        this.player.isDead = false;
        this.player.hp = diff.playerHp;
        this.player.isInvincible = true;
        this.player.invincibleUntil = now + GAME_CONFIG.PLAYER.INVINCIBILITY_DURATION_MS;
        this.player.x = GAME_CONFIG.CANVAS_WIDTH / 2 - this.player.width / 2;
        this.updateHpDisplay();
        createParticles(this.particles, this.player.x + this.player.width / 2, this.player.y + this.player.height / 2, '#3498db', 25);
        this.floatingTexts.push({
          text: 'RESPAWNED!',
          x: this.player.x + this.player.width / 2,
          y: this.player.y - 20,
          color: '#3498db',
          life: 1.0,
        });
      }
    } else {
      if (this.player.isInvincible && now > this.player.invincibleUntil) this.player.isInvincible = false;
      if (this.player.isSwordslashing && now > this.player.swordUntil) this.player.isSwordslashing = false;

      this.player.isMoving = false;
      const minX = GAME_CONFIG.PLAYER.MOVE_BOUNDS_MARGIN;
      const maxX = GAME_CONFIG.CANVAS_WIDTH - GAME_CONFIG.PLAYER.MOVE_BOUNDS_MARGIN - this.player.width;

      if (keys.left) { this.player.x -= GAME_CONFIG.PLAYER.SPEED; this.player.isMoving = true; this.player.facing = 'LEFT'; }
      if (keys.right) { this.player.x += GAME_CONFIG.PLAYER.SPEED; this.player.isMoving = true; this.player.facing = 'RIGHT'; }

      // Auto-fire shuriken continuously in player's facing direction
      this.shootShuriken();

      this.player.x = Math.max(minX, Math.min(maxX, this.player.x));
    }

    // Tower Auto Shoot
    this.towerAutoShoot();

    // Spawning enemies
    const diff = GAME_CONFIG.DIFFICULTIES[this.selectedDifficulty];
    const currentRampInterval = Math.max(
      GAME_CONFIG.SPAWN.MIN_INTERVAL_MS,
      (GAME_CONFIG.SPAWN.INITIAL_INTERVAL_MS - Math.floor((now - this.gameStartTime) / GAME_CONFIG.SPAWN.DIFFICULTY_RAMP_INTERVAL_MS) * GAME_CONFIG.SPAWN.INTERVAL_DECREASE_STEP) * diff.enemySpawnRateMultiplier
    );

    if (now - this.lastSpawnTime > currentRampInterval) { this.spawnEnemy(); this.lastSpawnTime = now; }

    // Shurikens update
    for (let i = this.shurikens.length - 1; i >= 0; i--) {
      const s = this.shurikens[i]; s.x += s.vx; s.rotation += 0.3;
      if (s.x < -50 || s.x > GAME_CONFIG.CANVAS_WIDTH + 50) this.shurikens.splice(i, 1);
    }

    // Tower arrows update
    for (let i = this.towerArrows.length - 1; i >= 0; i--) {
      const arrow = this.towerArrows[i];
      arrow.x += arrow.vx;
      arrow.y += arrow.vy;
      if (arrow.x < -50 || arrow.x > GAME_CONFIG.CANVAS_WIDTH + 50 || arrow.y < -50 || arrow.y > GAME_CONFIG.CANVAS_HEIGHT + 50) {
        this.towerArrows.splice(i, 1);
      }
    }

    const shurikenDamage = 1 + Math.floor((this.level - 1) * 0.8);
    const arrowDamage = 2 + Math.floor((this.level - 1) * 1.2);

    for (let eIdx = this.enemies.length - 1; eIdx >= 0; eIdx--) {
      const enemy = this.enemies[eIdx]; enemy.x += enemy.vx;

      // Player shuriken collisions
      for (let sIdx = this.shurikens.length - 1; sIdx >= 0; sIdx--) {
        const s = this.shurikens[sIdx];
        if (checkAABBCollision({ x: s.x, y: s.y, width: s.size, height: s.size }, enemy)) {
          this.shurikens.splice(sIdx, 1);
          enemy.hp -= shurikenDamage;
          createParticles(this.particles, s.x + s.size / 2, s.y + s.size / 2, '#f1c40f', 8);
          if (enemy.hp <= 0) {
            SoundSystem.playEnemyHit();
            createParticles(this.particles, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, GAME_CONFIG.ENEMY_TYPES[enemy.type].color, GAME_CONFIG.PARTICLES.DEATH_COUNT);
            this.score += Math.round(enemy.scoreValue * diff.scoreMultiplier);
            this.ui.scoreVal.textContent = this.score;
            this.addExp(enemy.expValue);
            this.enemies.splice(eIdx, 1);
            break;
          } else { SoundSystem.playEnemyHit(); }
        }
      }

      if (!this.enemies[eIdx]) continue;

      // Tower arrow collisions
      for (let aIdx = this.towerArrows.length - 1; aIdx >= 0; aIdx--) {
        const arrow = this.towerArrows[aIdx];
        if (checkAABBCollision({ x: arrow.x - 16, y: arrow.y - 12, width: 32, height: 24 }, enemy)) {
          this.towerArrows.splice(aIdx, 1);
          enemy.hp -= arrowDamage;
          createParticles(this.particles, arrow.x, arrow.y, '#e67e22', 12);
          if (enemy.hp <= 0) {
            SoundSystem.playEnemyHit();
            createParticles(this.particles, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, GAME_CONFIG.ENEMY_TYPES[enemy.type].color, GAME_CONFIG.PARTICLES.DEATH_COUNT);
            this.score += Math.round(enemy.scoreValue * diff.scoreMultiplier);
            this.ui.scoreVal.textContent = this.score;
            this.addExp(enemy.expValue);
            this.enemies.splice(eIdx, 1);
            break;
          } else { SoundSystem.playEnemyHit(); }
        }
      }

      if (!this.enemies[eIdx]) continue;

      // Enemy vs Player collision
      if (!this.player.isDead && !this.player.isInvincible && checkAABBCollision(enemy, this.player)) {
        this.player.hp -= 1;
        this.updateHpDisplay();
        SoundSystem.playPlayerHurt();
        createParticles(this.particles, this.player.x + this.player.width / 2, this.player.y + this.player.height / 2, '#e74c3c', 15);
        if (this.player.hp <= 0) {
          this.player.isDead = true;
          this.player.respawnUntil = now + 1000; // 1 second delay
        } else {
          this.player.isInvincible = true;
          this.player.invincibleUntil = now + GAME_CONFIG.PLAYER.INVINCIBILITY_DURATION_MS;
        }
      }

      // Enemy vs Tower collision
      if (checkAABBCollision(enemy, this.tower)) {
        this.tower.hp -= 1;
        this.updateTowerHpDisplay();
        SoundSystem.playPlayerHurt();
        createParticles(this.particles, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, '#f39c12', 10);
        if (this.tower.hp <= 0) {
          onGameOver(this.score);
          return;
        }
      }

      if ((enemy.vx < 0 && enemy.x < -enemy.width - 50) || (enemy.vx > 0 && enemy.x > GAME_CONFIG.CANVAS_WIDTH + 50)) this.enemies.splice(eIdx, 1);
    }

    for (let pIdx = this.particles.length - 1; pIdx >= 0; pIdx--) {
      const p = this.particles[pIdx]; p.x += p.vx; p.y += p.vy; p.life -= 0.04;
      if (p.life <= 0) this.particles.splice(pIdx, 1);
    }

    for (let tIdx = this.floatingTexts.length - 1; tIdx >= 0; tIdx--) {
      const ft = this.floatingTexts[tIdx];
      ft.y -= 1;
      ft.life -= 0.02;
      if (ft.life <= 0) this.floatingTexts.splice(tIdx, 1);
    }
  }

  render() {
    drawBackground(this.ctx, this.canvas);

    // Draw Central High Arrow Tower
    this.ctx.save();
    this.ctx.fillStyle = '#34495e';
    this.ctx.fillRect(this.tower.x, this.tower.y, this.tower.width, this.tower.height);
    this.ctx.fillStyle = '#2c3e50';
    this.ctx.fillRect(this.tower.x + 8, this.tower.y + 10, this.tower.width - 16, this.tower.height - 20);
    this.ctx.fillStyle = '#e74c3c';
    this.ctx.fillRect(this.tower.x - 6, this.tower.y, this.tower.width + 12, 12);

    // Tower Banner / Emblem
    this.ctx.fillStyle = '#f1c40f';
    this.ctx.beginPath();
    this.ctx.arc(this.tower.x + this.tower.width / 2, this.tower.y + 35, 12, 0, Math.PI * 2);
    this.ctx.fill();

    // Tower HP bar on top of tower
    this.ctx.fillStyle = 'rgba(0,0,0,0.7)';
    this.ctx.fillRect(this.tower.x - 10, this.tower.y - 16, this.tower.width + 20, 8);
    this.ctx.fillStyle = '#2ecc71';
    this.ctx.fillRect(this.tower.x - 10, this.tower.y - 16, (this.tower.width + 20) * (Math.max(0, this.tower.hp) / this.tower.maxHp), 8);
    this.ctx.restore();

    // Draw enemies
    this.enemies.forEach((enemy) => {
      const spriteSet = this.sprites.enemies[enemy.type];
      const sprite = enemy.facing === 'RIGHT' ? spriteSet.right : spriteSet.left;
      this.ctx.drawImage(sprite, enemy.x, enemy.y);
      if (enemy.maxHp > 1) {
        this.ctx.fillStyle = 'rgba(0,0,0,0.6)'; this.ctx.fillRect(enemy.x, enemy.y - 8, enemy.width, 4);
        this.ctx.fillStyle = '#2ecc71'; this.ctx.fillRect(enemy.x, enemy.y - 8, enemy.width * (Math.max(0, enemy.hp) / enemy.maxHp), 4);
      }
    });

    // Draw shurikens
    this.shurikens.forEach((s) => {
      this.ctx.save(); this.ctx.translate(s.x + s.size / 2, s.y + s.size / 2); this.ctx.rotate(s.rotation);
      this.ctx.drawImage(this.sprites.shuriken, -s.size / 2, -s.size / 2, s.size, s.size); this.ctx.restore();
    });

    // Draw tower arrows
    this.towerArrows.forEach((arrow) => {
      this.ctx.save();
      this.ctx.fillStyle = '#e67e22';
      this.ctx.fillRect(arrow.x - 8, arrow.y - 2, 16, 4);
      this.ctx.fillStyle = '#f39c12';
      this.ctx.beginPath();
      this.ctx.arc(arrow.vx > 0 ? arrow.x + 8 : arrow.x - 8, arrow.y, 4, 0, Math.PI * 2);
      this.ctx.fill();
      this.ctx.restore();
    });

    // Draw player
    if (this.player && !this.player.isDead && (!this.player.isInvincible || Math.floor(Date.now() / 80) % 2 === 0)) {
      const pSprite = this.player.facing === 'RIGHT' ? (this.player.isMoving ? this.sprites.ninja.runRight : this.sprites.ninja.idleRight) : (this.player.isMoving ? this.sprites.ninja.runLeft : this.sprites.ninja.idleLeft);
      this.ctx.drawImage(pSprite, this.player.x, this.player.y);

      if (this.player.isSwordslashing) {
        this.ctx.save();
        this.ctx.strokeStyle = this.level >= 3 ? '#e74c3c' : '#f1c40f';
        this.ctx.lineWidth = 6 + Math.floor(this.level * 1.5);
        this.ctx.shadowColor = this.level >= 3 ? '#f39c12' : '#e74c3c';
        this.ctx.shadowBlur = 12;
        this.ctx.beginPath();
        const currentSwordRange = getSwordRange(this.level);
        const centerX = this.player.x + this.player.width / 2;
        const centerY = this.player.y + this.player.height / 2;

        if (this.level >= 3) {
          this.ctx.arc(centerX, centerY, currentSwordRange, 0, Math.PI * 2);
        } else {
          const startX = this.player.facing === 'RIGHT' ? this.player.x + this.player.width : this.player.x;
          this.ctx.arc(
            startX, centerY,
            currentSwordRange,
            this.player.facing === 'RIGHT' ? -Math.PI / 4 : Math.PI * 3 / 4,
            this.player.facing === 'RIGHT' ? Math.PI / 4 : Math.PI * 5 / 4
          );
        }
        this.ctx.stroke();
        this.ctx.restore();
      }
    }

    this.particles.forEach((p) => {
      this.ctx.fillStyle = p.color; this.ctx.globalAlpha = p.life; this.ctx.fillRect(p.x, p.y, p.size, p.size); this.ctx.globalAlpha = 1.0;
    });

    this.floatingTexts.forEach((ft) => {
      this.ctx.save();
      this.ctx.fillStyle = ft.color;
      this.ctx.font = 'bold 16px Courier New';
      this.ctx.textAlign = 'center';
      this.ctx.globalAlpha = ft.life;
      this.ctx.shadowColor = '#000';
      this.ctx.shadowBlur = 4;
      this.ctx.fillText(ft.text, ft.x, ft.y);
      this.ctx.restore();
    });
  }
}
