// ==========================================
// MAIN GAME ENGINE MODULE
// ==========================================
import { GAME_CONFIG } from './config.js';
import { getSprites } from './sprites.js';
import { SoundSystem } from './sound.js';
import { bindButton, setupControls } from './controls.js';
import { createPlayer, checkAABBCollision, getShurikenSize, getSwordRange } from './entities.js';

window.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');
  canvas.width = GAME_CONFIG.CANVAS_WIDTH;
  canvas.height = GAME_CONFIG.CANVAS_HEIGHT;

  const menuScreen = document.getElementById('menu-screen');
  const pauseScreen = document.getElementById('pause-screen');
  const gameOverScreen = document.getElementById('gameover-screen');
  const hud = document.getElementById('hud');
  const touchControls = document.getElementById('touch-controls');
  const hpHearts = document.getElementById('hp-hearts');
  const levelVal = document.getElementById('level-val');
  const waveVal = document.getElementById('wave-val');
  const expBarFill = document.getElementById('exp-bar-fill');
  const scoreVal = document.getElementById('score-val');
  const highScoreVal = document.getElementById('high-score-val');
  const finalScoreVal = document.getElementById('final-score-val');
  const finalBestVal = document.getElementById('final-best-val');
  const newRecordTag = document.getElementById('new-record-tag');

  const diffTitle = document.getElementById('diff-title');
  const diffDesc = document.getElementById('diff-desc');
  const diffStats = document.getElementById('diff-stats');

  const btnStart = document.getElementById('btn-start');
  const btnPause = document.getElementById('btn-pause');
  const btnResume = document.getElementById('btn-resume');
  const btnRestartPause = document.getElementById('btn-restart-pause');
  const btnMenuPause = document.getElementById('btn-menu-pause');
  const btnRestart = document.getElementById('btn-restart');
  const btnMenuGameOver = document.getElementById('btn-menu-gameover');
  const diffButtons = document.querySelectorAll('.btn-diff');

  const sprites = getSprites();

  let gameState = 'MENU';
  let selectedDifficulty = 'NORMAL';
  let score = 0;
  let level = 1;
  let currentWave = 1;
  let currentExp = 0;
  let expToNextLevel = 100;
  let highScore = parseInt(localStorage.getItem(GAME_CONFIG.HIGH_SCORE_KEY) || '0', 10);

  let player = null;
  let shurikens = [];
  let enemies = [];
  let particles = [];
  let floatingTexts = [];
  let lastSpawnTime = 0;
  let gameStartTime = 0;
  let lastShootTime = 0;
  let lastSwordTime = 0;

  const keys = { left: false, right: false, shoot: false, sword: false };
  highScoreVal.textContent = highScore;

  function updateDifficultyPanel() {
    const modeInfo = GAME_CONFIG.GAME_MODES['CLASSIC'];
    const diffInfo = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    diffTitle.textContent = `${modeInfo.title} - ${diffInfo.title}`;
    diffDesc.textContent = `${modeInfo.desc} ${diffInfo.desc}`;
    diffStats.textContent = diffInfo.stats;
  }

  function renderMenuCharacterPreviews() {
    try {
      const pHero = document.getElementById('preview-hero');
      if (pHero) {
        const ctxH = pHero.getContext('2d');
        ctxH.clearRect(0, 0, pHero.width, pHero.height);
        ctxH.drawImage(sprites.ninja.idleRight, 2, 1);
      }

      const pFast = document.getElementById('preview-fast');
      if (pFast) {
        const ctxF = pFast.getContext('2d');
        ctxF.clearRect(0, 0, pFast.width, pFast.height);
        ctxF.drawImage(sprites.enemies.FAST.right, 2, 2);
      }

      const pNormal = document.getElementById('preview-normal');
      if (pNormal) {
        const ctxN = pNormal.getContext('2d');
        ctxN.clearRect(0, 0, pNormal.width, pNormal.height);
        ctxN.drawImage(sprites.enemies.NORMAL.right, 2, 2);
      }

      const pTank = document.getElementById('preview-tank');
      if (pTank) {
        const ctxT = pTank.getContext('2d');
        ctxT.clearRect(0, 0, pTank.width, pTank.height);
        ctxT.drawImage(sprites.enemies.TANK.right, 2, 1);
      }
    } catch (e) {
      console.warn('Preview render error:', e);
    }
  }

  function addExp(amount) {
    currentExp += amount;
    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      level += 1;
      expToNextLevel = Math.round(expToNextLevel * 1.35);
      SoundSystem.playLevelUp();
      createParticles(player.x + player.width / 2, player.y + player.height / 2, '#2ecc71', 30);
      floatingTexts.push({
        text: `LEVEL UP! LV.${level}`,
        x: player.x + player.width / 2,
        y: player.y - 20,
        color: '#2ecc71',
        life: 1.0,
      });
    }
    updateLevelDisplay();
  }

  function updateLevelDisplay() {
    levelVal.textContent = level;
    waveVal.textContent = currentWave;
    const fillPercent = Math.min(100, Math.floor((currentExp / expToNextLevel) * 100));
    expBarFill.style.width = `${fillPercent}%`;
  }

  function shootShuriken() {
    const now = Date.now();
    if (now - lastShootTime < GAME_CONFIG.PLAYER.SHOOT_COOLDOWN_MS) return;
    if (shurikens.length >= GAME_CONFIG.SHURIKEN.MAX_COUNT) return;
    lastShootTime = now;
    SoundSystem.playShurikenThrow();
    const size = getShurikenSize(level);
    const dir = player.facing === 'RIGHT' ? 1 : -1;
    shurikens.push({
      x: player.facing === 'RIGHT' ? player.x + player.width : player.x - size,
      y: player.y + 16 - (size - GAME_CONFIG.SHURIKEN.BASE_SIZE) / 2,
      vx: GAME_CONFIG.SHURIKEN.SPEED * dir,
      size: size,
      rotation: 0,
    });
  }

  function performSwordAttack() {
    const now = Date.now();
    if (now - lastSwordTime < GAME_CONFIG.PLAYER.SWORD_COOLDOWN_MS) return;
    lastSwordTime = now;
    player.isSwordslashing = true;
    player.swordUntil = now + GAME_CONFIG.PLAYER.SWORD_DURATION_MS;
    SoundSystem.playSwordSlash();

    const currentSwordRange = getSwordRange(level);
    const diff = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    const swordDamage = 3 + Math.floor((level - 1) * 1.5);
    const isMultiDirection = level >= 3;

    let swordBox = null;
    if (isMultiDirection) {
      swordBox = {
        x: player.x + player.width / 2 - currentSwordRange,
        y: player.y + player.height / 2 - currentSwordRange,
        width: currentSwordRange * 2,
        height: currentSwordRange * 2
      };
    } else {
      swordBox = {
        x: player.facing === 'RIGHT' ? player.x + player.width : player.x - currentSwordRange,
        y: player.y - 15,
        width: currentSwordRange,
        height: player.height + 30
      };
    }

    for (let eIdx = enemies.length - 1; eIdx >= 0; eIdx--) {
      const enemy = enemies[eIdx];
      if (checkAABBCollision(swordBox, enemy)) {
        enemy.hp -= swordDamage;
        createParticles(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, '#e74c3c', 15);
        if (enemy.hp <= 0) {
          SoundSystem.playEnemyHit();
          createParticles(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, GAME_CONFIG.ENEMY_TYPES[enemy.type].color, GAME_CONFIG.PARTICLES.DEATH_COUNT);
          score += Math.round(enemy.scoreValue * diff.scoreMultiplier);
          scoreVal.textContent = score;
          addExp(enemy.expValue);
          enemies.splice(eIdx, 1);
        } else {
          SoundSystem.playEnemyHit();
        }
      }
    }
  }

  function spawnEnemy() {
    const diff = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    const side = Math.random() < 0.5 ? 'LEFT' : 'RIGHT';
    const elapsedSec = (Date.now() - gameStartTime) / 1000;
    currentWave = 1 + Math.floor(elapsedSec / 15);

    let availableTypes = Object.values(GAME_CONFIG.ENEMY_TYPES).filter((t) => !t.reqLevel || level >= t.reqLevel || currentWave >= t.reqLevel);
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
    const waveHpBonus = Math.floor((currentWave - 1) * 0.8) + Math.floor((level - 1) * 0.5);
    const waveSpeedMultiplier = 1 + (currentWave - 1) * 0.06 + (level - 1) * 0.03;
    const maxHp = Math.round((typeConfig.hp + waveHpBonus) * diff.enemyHpMultiplier);

    enemies.push({
      type: typeConfig.id, x: startX, y: GAME_CONFIG.CANVAS_HEIGHT - typeConfig.height - 40,
      width: typeConfig.width, height: typeConfig.height,
      vx: typeConfig.baseSpeed * diff.enemySpeedMultiplier * waveSpeedMultiplier * moveDir,
      hp: maxHp, maxHp: maxHp,
      expValue: typeConfig.expValue, scoreValue: typeConfig.scoreValue,
      facing: side === 'LEFT' ? 'RIGHT' : 'LEFT',
    });
  }

  function createParticles(x, y, color, count = GAME_CONFIG.PARTICLES.HIT_COUNT) {
    for (let i = 0; i < count; i++) {
      particles.push({
        x, y, vx: (Math.random() - 0.5) * 6, vy: (Math.random() - 0.5) * 6,
        size: Math.random() * 4 + 2, color, alpha: 1, life: 1.0,
      });
    }
  }

  function updateHpDisplay() {
    hpHearts.innerHTML = '';
    for (let i = 0; i < player.maxHp; i++) {
      const heart = document.createElement('span');
      heart.textContent = i < player.hp ? '❤️' : '🖤';
      hpHearts.appendChild(heart);
    }
  }

  function startGame() {
    SoundSystem.playClick();
    const diff = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    score = 0; level = diff.startLevel || 1; currentWave = 1; currentExp = 0; expToNextLevel = 100;
    gameStartTime = Date.now(); lastSpawnTime = Date.now();
    shurikens = []; enemies = []; particles = []; floatingTexts = [];
    player = createPlayer(diff.playerHp); updateHpDisplay(); updateLevelDisplay(); scoreVal.textContent = '0';
    menuScreen.classList.add('hidden'); pauseScreen.classList.add('hidden'); gameOverScreen.classList.add('hidden');
    hud.classList.remove('hidden'); touchControls.classList.remove('hidden');
    gameState = 'PLAYING';
  }

  function triggerGameOver() {
    gameState = 'GAMEOVER'; SoundSystem.playGameOver();
    let isNewRecord = false;
    if (score > highScore) {
      highScore = score; localStorage.setItem(GAME_CONFIG.HIGH_SCORE_KEY, highScore.toString());
      highScoreVal.textContent = highScore; isNewRecord = true;
    }
    finalScoreVal.textContent = score; finalBestVal.textContent = highScore;
    if (isNewRecord) newRecordTag.classList.remove('hidden'); else newRecordTag.classList.add('hidden');
    hud.classList.add('hidden'); touchControls.classList.add('hidden'); gameOverScreen.classList.remove('hidden');
  }

  function pauseGame() { if (gameState === 'PLAYING') { gameState = 'PAUSED'; pauseScreen.classList.remove('hidden'); } }
  function resumeGame() { if (gameState === 'PAUSED') { gameState = 'PLAYING'; pauseScreen.classList.add('hidden'); } }
  function returnToMenu() { gameState = 'MENU'; pauseScreen.classList.add('hidden'); gameOverScreen.classList.add('hidden'); hud.classList.add('hidden'); touchControls.classList.add('hidden'); menuScreen.classList.remove('hidden'); }

  setupControls(keys, () => gameState, performSwordAttack);

  diffButtons.forEach((btn) => {
    bindButton(btn, () => {
      SoundSystem.playClick();
      diffButtons.forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      selectedDifficulty = btn.getAttribute('data-diff');
      updateDifficultyPanel();
    });
  });

  bindButton(btnStart, startGame);
  bindButton(btnPause, pauseGame);
  bindButton(btnResume, resumeGame);
  bindButton(btnRestartPause, startGame);
  bindButton(btnMenuPause, returnToMenu);
  bindButton(btnRestart, startGame);
  bindButton(btnMenuGameOver, returnToMenu);

  updateDifficultyPanel();
  renderMenuCharacterPreviews();

  function update(dt) {
    if (gameState !== 'PLAYING') return;
    const now = Date.now();
    if (player.isInvincible && now > player.invincibleUntil) player.isInvincible = false;
    if (player.isSwordslashing && now > player.swordUntil) player.isSwordslashing = false;

    player.isMoving = false;
    const minX = GAME_CONFIG.PLAYER.MOVE_BOUNDS_MARGIN;
    const maxX = GAME_CONFIG.CANVAS_WIDTH - GAME_CONFIG.PLAYER.MOVE_BOUNDS_MARGIN - player.width;

    if (keys.left) { player.x -= GAME_CONFIG.PLAYER.SPEED; player.isMoving = true; player.facing = 'LEFT'; shootShuriken(); }
    if (keys.right) { player.x += GAME_CONFIG.PLAYER.SPEED; player.isMoving = true; player.facing = 'RIGHT'; shootShuriken(); }
    if (keys.shoot) { shootShuriken(); }

    player.x = Math.max(minX, Math.min(maxX, player.x));

    const diff = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    const currentRampInterval = Math.max(
      GAME_CONFIG.SPAWN.MIN_INTERVAL_MS,
      (GAME_CONFIG.SPAWN.INITIAL_INTERVAL_MS - Math.floor((now - gameStartTime) / GAME_CONFIG.SPAWN.DIFFICULTY_RAMP_INTERVAL_MS) * GAME_CONFIG.SPAWN.INTERVAL_DECREASE_STEP) * diff.enemySpawnRateMultiplier
    );

    if (now - lastSpawnTime > currentRampInterval) { spawnEnemy(); lastSpawnTime = now; }

    for (let i = shurikens.length - 1; i >= 0; i--) {
      const s = shurikens[i]; s.x += s.vx; s.rotation += 0.3;
      if (s.x < -50 || s.x > GAME_CONFIG.CANVAS_WIDTH + 50) shurikens.splice(i, 1);
    }

    const shurikenDamage = 1 + Math.floor((level - 1) * 0.8);

    for (let eIdx = enemies.length - 1; eIdx >= 0; eIdx--) {
      const enemy = enemies[eIdx]; enemy.x += enemy.vx;
      for (let sIdx = shurikens.length - 1; sIdx >= 0; sIdx--) {
        const s = shurikens[sIdx];
        if (checkAABBCollision({ x: s.x, y: s.y, width: s.size, height: s.size }, enemy)) {
          shurikens.splice(sIdx, 1);
          enemy.hp -= shurikenDamage;
          createParticles(s.x + s.size / 2, s.y + s.size / 2, '#f1c40f', 8);
          if (enemy.hp <= 0) {
            SoundSystem.playEnemyHit();
            createParticles(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, GAME_CONFIG.ENEMY_TYPES[enemy.type].color, GAME_CONFIG.PARTICLES.DEATH_COUNT);
            score += Math.round(enemy.scoreValue * diff.scoreMultiplier);
            scoreVal.textContent = score;
            addExp(enemy.expValue);
            enemies.splice(eIdx, 1);
            break;
          } else { SoundSystem.playEnemyHit(); }
        }
      }

      if (enemies[eIdx] && !player.isInvincible && checkAABBCollision(enemy, player)) {
        player.hp -= 1; updateHpDisplay(); SoundSystem.playPlayerHurt(); createParticles(player.x + player.width / 2, player.y + player.height / 2, '#e74c3c', 15);
        if (player.hp <= 0) { triggerGameOver(); return; }
        else { player.isInvincible = true; player.invincibleUntil = now + GAME_CONFIG.PLAYER.INVINCIBILITY_DURATION_MS; }
      }

      if ((enemy.vx < 0 && enemy.x < -enemy.width - 50) || (enemy.vx > 0 && enemy.x > GAME_CONFIG.CANVAS_WIDTH + 50)) enemies.splice(eIdx, 1);
    }

    for (let pIdx = particles.length - 1; pIdx >= 0; pIdx--) {
      const p = particles[pIdx]; p.x += p.vx; p.y += p.vy; p.life -= 0.04;
      if (p.life <= 0) particles.splice(pIdx, 1);
    }

    for (let tIdx = floatingTexts.length - 1; tIdx >= 0; tIdx--) {
      const ft = floatingTexts[tIdx];
      ft.y -= 1;
      ft.life -= 0.02;
      if (ft.life <= 0) floatingTexts.splice(tIdx, 1);
    }
  }

  function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#0f111a'; ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#f5f6fa'; ctx.beginPath(); ctx.arc(canvas.width / 2, 90, 45, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#dcdde1'; ctx.beginPath(); ctx.arc(canvas.width / 2 - 10, 80, 10, 0, Math.PI * 2); ctx.arc(canvas.width / 2 + 15, 105, 8, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#181b26'; ctx.beginPath(); ctx.moveTo(0, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height); ctx.lineTo(0, canvas.height); ctx.fill();
    ctx.fillStyle = '#2c1e14'; ctx.fillRect(0, canvas.height - 40, canvas.width, 40);
    ctx.fillStyle = '#c0392b'; ctx.fillRect(0, canvas.height - 40, canvas.width, 4);

    if (gameState === 'MENU') {
      const menuPlayerX = canvas.width / 2 - GAME_CONFIG.PLAYER.WIDTH / 2;
      const menuPlayerY = canvas.height - GAME_CONFIG.PLAYER.HEIGHT - 40;
      ctx.drawImage(sprites.ninja.idleRight, menuPlayerX, menuPlayerY);
      ctx.drawImage(sprites.enemies.NORMAL.right, 60, canvas.height - GAME_CONFIG.ENEMY_TYPES.NORMAL.height - 40);
      ctx.drawImage(sprites.enemies.FAST.left, canvas.width - 60 - GAME_CONFIG.ENEMY_TYPES.FAST.width, canvas.height - GAME_CONFIG.ENEMY_TYPES.FAST.height - 40);
    } else if (gameState === 'PLAYING' || gameState === 'PAUSED') {
      enemies.forEach((enemy) => {
        const spriteSet = sprites.enemies[enemy.type];
        const sprite = enemy.facing === 'RIGHT' ? spriteSet.right : spriteSet.left;
        ctx.drawImage(sprite, enemy.x, enemy.y);
        if (enemy.maxHp > 1) {
          ctx.fillStyle = 'rgba(0,0,0,0.6)'; ctx.fillRect(enemy.x, enemy.y - 8, enemy.width, 4);
          ctx.fillStyle = '#2ecc71'; ctx.fillRect(enemy.x, enemy.y - 8, enemy.width * (Math.max(0, enemy.hp) / enemy.maxHp), 4);
        }
      });

      shurikens.forEach((s) => {
        ctx.save(); ctx.translate(s.x + s.size / 2, s.y + s.size / 2); ctx.rotate(s.rotation);
        ctx.drawImage(sprites.shuriken, -s.size / 2, -s.size / 2, s.size, s.size); ctx.restore();
      });

      if (player && (!player.isInvincible || Math.floor(Date.now() / 80) % 2 === 0)) {
        const pSprite = player.facing === 'RIGHT' ? (player.isMoving ? sprites.ninja.runRight : sprites.ninja.idleRight) : (player.isMoving ? sprites.ninja.runLeft : sprites.ninja.idleLeft);
        ctx.drawImage(pSprite, player.x, player.y);

        if (player.isSwordslashing) {
          ctx.save();
          ctx.strokeStyle = level >= 3 ? '#e74c3c' : '#f1c40f';
          ctx.lineWidth = 6 + Math.floor(level * 1.5);
          ctx.shadowColor = level >= 3 ? '#f39c12' : '#e74c3c';
          ctx.shadowBlur = 12;
          ctx.beginPath();
          const currentSwordRange = getSwordRange(level);
          const centerX = player.x + player.width / 2;
          const centerY = player.y + player.height / 2;

          if (level >= 3) {
            ctx.arc(centerX, centerY, currentSwordRange, 0, Math.PI * 2);
          } else {
            const startX = player.facing === 'RIGHT' ? player.x + player.width : player.x;
            ctx.arc(
              startX, centerY,
              currentSwordRange,
              player.facing === 'RIGHT' ? -Math.PI / 4 : Math.PI * 3 / 4,
              player.facing === 'RIGHT' ? Math.PI / 4 : Math.PI * 5 / 4
            );
          }
          ctx.stroke();
          ctx.restore();
        }
      }

      particles.forEach((p) => {
        ctx.fillStyle = p.color; ctx.globalAlpha = p.life; ctx.fillRect(p.x, p.y, p.size, p.size); ctx.globalAlpha = 1.0;
      });

      floatingTexts.forEach((ft) => {
        ctx.save();
        ctx.fillStyle = ft.color;
        ctx.font = 'bold 16px Courier New';
        ctx.textAlign = 'center';
        ctx.globalAlpha = ft.life;
        ctx.shadowColor = '#000';
        ctx.shadowBlur = 4;
        ctx.fillText(ft.text, ft.x, ft.y);
        ctx.restore();
      });
    }
  }

  function gameLoop() { update(1/60); render(); requestAnimationFrame(gameLoop); }
  requestAnimationFrame(gameLoop);
});
