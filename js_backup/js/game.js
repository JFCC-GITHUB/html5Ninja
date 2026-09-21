// ==========================================
// MAIN GAME ROUTER MODULE
// ==========================================
import { GAME_CONFIG, SoundSystem, bindButton, setupControls, getSprites } from './common.js';
import { parseTOML } from './tomlParser.js';

// Asynchronously load & merge TOML config
try {
  fetch('config.toml').then((res) => res.text()).then((tomlText) => {
    const parsed = parseTOML(tomlText);
    if (parsed.player) {
      if (parsed.player.initial_hp) GAME_CONFIG.PLAYER.INITIAL_HP = parsed.player.initial_hp;
      if (parsed.player.speed) GAME_CONFIG.PLAYER.SPEED = parsed.player.speed;
      if (parsed.player.width) GAME_CONFIG.PLAYER.WIDTH = parsed.player.width;
      if (parsed.player.height) GAME_CONFIG.PLAYER.HEIGHT = parsed.player.height;
    }
  }).catch((e) => console.warn('TOML Load Warning:', e));
} catch (e) {}
import { ClassicMode } from './modes/classicMode.js';
import { TowerDefenseMode } from './modes/towerDefenseMode.js';

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

  const uiElements = {
    hpHearts: document.getElementById('hp-hearts'),
    towerHpContainer: document.getElementById('tower-hp-container'),
    towerHpVal: document.getElementById('tower-hp-val'),
    levelVal: document.getElementById('level-val'),
    waveVal: document.getElementById('wave-val'),
    expBarFill: document.getElementById('exp-bar-fill'),
    scoreVal: document.getElementById('score-val'),
    highScoreVal: document.getElementById('high-score-val'),
    finalScoreVal: document.getElementById('final-score-val'),
    finalBestVal: document.getElementById('final-best-val'),
    newRecordTag: document.getElementById('new-record-tag'),
  };

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

  const modeButtons = document.querySelectorAll('.btn-mode');
  const diffButtons = document.querySelectorAll('.btn-diff');

  let gameState = 'MENU';
  let selectedMode = 'CLASSIC';
  let selectedDifficulty = 'NORMAL';
  let highScore = parseInt(localStorage.getItem(GAME_CONFIG.HIGH_SCORE_KEY) || '0', 10);
  uiElements.highScoreVal.textContent = highScore;

  const classicHandler = new ClassicMode(ctx, canvas, uiElements);
  const towerHandler = new TowerDefenseMode(ctx, canvas, uiElements);
  let activeModeInstance = classicHandler;

  const keys = { left: false, right: false, shoot: false, sword: false };

  function updateDifficultyPanel() {
    const modeInfo = GAME_CONFIG.GAME_MODES[selectedMode];
    const diffInfo = GAME_CONFIG.DIFFICULTIES[selectedDifficulty];
    diffTitle.textContent = `${modeInfo.title} - ${diffInfo.title}`;
    diffDesc.textContent = `${modeInfo.desc} ${diffInfo.desc}`;
    diffStats.textContent = diffInfo.stats;
  }

  function renderMenuCharacterPreviews() {
    try {
      const sprites = getSprites();
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

  function startGame() {
    SoundSystem.playClick();
    if (selectedMode === 'DEFENSE') {
      activeModeInstance = towerHandler;
    } else {
      activeModeInstance = classicHandler;
    }

    activeModeInstance.init(selectedDifficulty);

    menuScreen.classList.add('hidden');
    pauseScreen.classList.add('hidden');
    gameOverScreen.classList.add('hidden');
    hud.classList.remove('hidden');
    touchControls.classList.remove('hidden');
    gameState = 'PLAYING';
  }

  function handleGameOver(finalScore) {
    gameState = 'GAMEOVER';
    SoundSystem.playGameOver();
    let isNewRecord = false;
    if (finalScore > highScore) {
      highScore = finalScore;
      localStorage.setItem(GAME_CONFIG.HIGH_SCORE_KEY, highScore.toString());
      uiElements.highScoreVal.textContent = highScore;
      isNewRecord = true;
    }
    uiElements.finalScoreVal.textContent = finalScore;
    uiElements.finalBestVal.textContent = highScore;
    if (isNewRecord) uiElements.newRecordTag.classList.remove('hidden'); else uiElements.newRecordTag.classList.add('hidden');
    hud.classList.add('hidden');
    touchControls.classList.add('hidden');
    gameOverScreen.classList.remove('hidden');
  }

  function pauseGame() { if (gameState === 'PLAYING') { gameState = 'PAUSED'; pauseScreen.classList.remove('hidden'); } }
  function resumeGame() { if (gameState === 'PAUSED') { gameState = 'PLAYING'; pauseScreen.classList.add('hidden'); } }
  function returnToMenu() { gameState = 'MENU'; pauseScreen.classList.add('hidden'); gameOverScreen.classList.add('hidden'); hud.classList.add('hidden'); touchControls.classList.add('hidden'); menuScreen.classList.remove('hidden'); }

  setupControls(keys, () => gameState, () => {
    if (gameState === 'PLAYING' && activeModeInstance) {
      activeModeInstance.performSwordAttack();
    }
  });

  modeButtons.forEach((btn) => {
    bindButton(btn, () => {
      SoundSystem.playClick();
      modeButtons.forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      selectedMode = btn.getAttribute('data-mode');
      updateDifficultyPanel();
    });
  });

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
    if (gameState !== 'PLAYING' || !activeModeInstance) return;
    activeModeInstance.update(keys, handleGameOver);
  }

  function render() {
    if (gameState === 'MENU') {
      const sprites = getSprites();
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = '#0f111a'; ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = '#181b26'; ctx.beginPath(); ctx.moveTo(0, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height); ctx.lineTo(0, canvas.height); ctx.fill();
      ctx.fillStyle = '#2c1e14'; ctx.fillRect(0, canvas.height - 40, canvas.width, 40);
      ctx.fillStyle = '#c0392b'; ctx.fillRect(0, canvas.height - 40, canvas.width, 4);

      const menuPlayerX = canvas.width / 2 - GAME_CONFIG.PLAYER.WIDTH / 2;
      const menuPlayerY = canvas.height - GAME_CONFIG.PLAYER.HEIGHT - 40;
      ctx.drawImage(sprites.ninja.idleRight, menuPlayerX, menuPlayerY);
      ctx.drawImage(sprites.enemies.NORMAL.right, 60, canvas.height - GAME_CONFIG.ENEMY_TYPES.NORMAL.height - 40);
      ctx.drawImage(sprites.enemies.FAST.left, canvas.width - 60 - GAME_CONFIG.ENEMY_TYPES.FAST.width, canvas.height - GAME_CONFIG.ENEMY_TYPES.FAST.height - 40);
    } else if (activeModeInstance) {
      activeModeInstance.render();
    }
  }

  function gameLoop() { update(1/60); render(); requestAnimationFrame(gameLoop); }
  requestAnimationFrame(gameLoop);
});
