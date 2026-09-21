// ==========================================
// SHARED COMMON PROCEDURES MODULE
// ==========================================
import { GAME_CONFIG } from './config.js';
import { getSprites } from './sprites.js';
import { SoundSystem } from './sound.js';

export { GAME_CONFIG, getSprites, SoundSystem };

export function checkAABBCollision(rect1, rect2) {
  return (
    rect1.x < rect2.x + rect2.width &&
    rect1.x + rect1.width > rect2.x &&
    rect1.y < rect2.y + rect2.height &&
    rect1.y + rect1.height > rect2.y
  );
}

export function createPlayer(maxHp) {
  return {
    x: GAME_CONFIG.CANVAS_WIDTH / 2 - GAME_CONFIG.PLAYER.WIDTH / 2,
    y: GAME_CONFIG.CANVAS_HEIGHT - GAME_CONFIG.PLAYER.HEIGHT - 40,
    width: GAME_CONFIG.PLAYER.WIDTH,
    height: GAME_CONFIG.PLAYER.HEIGHT,
    facing: 'RIGHT',
    hp: maxHp,
    maxHp: maxHp,
    isInvincible: false,
    invincibleUntil: 0,
    isMoving: false,
    isSwordslashing: false,
    swordUntil: 0,
    isDead: false,
    respawnUntil: 0,
  };
}

export function getShurikenSize(level) {
  return GAME_CONFIG.SHURIKEN.BASE_SIZE + (level - 1) * 4;
}

export function getSwordRange(level) {
  return GAME_CONFIG.PLAYER.BASE_SWORD_RANGE + (level - 1) * 22;
}

export function createParticles(particles, x, y, color, count = GAME_CONFIG.PARTICLES.HIT_COUNT) {
  for (let i = 0; i < count; i++) {
    particles.push({
      x, y,
      vx: (Math.random() - 0.5) * 6,
      vy: (Math.random() - 0.5) * 6,
      size: Math.random() * 4 + 2,
      color, alpha: 1, life: 1.0,
    });
  }
}

export function bindButton(btn, callback) {
  if (!btn) return;
  let touched = false;
  btn.addEventListener('touchstart', (e) => {
    touched = true;
    if (e.cancelable) e.preventDefault();
    SoundSystem.init();
    callback(e);
  }, { passive: false });
  btn.addEventListener('click', (e) => {
    if (touched) {
      touched = false;
      return;
    }
    SoundSystem.init();
    callback(e);
  });
}

export function setupControls(keys, getGameState, performSwordAttack) {
  window.addEventListener('keydown', (e) => {
    if (e.code === 'KeyA' || e.code === 'ArrowLeft') { keys.left = true; }
    else if (e.code === 'KeyD' || e.code === 'ArrowRight') { keys.right = true; }
    else if (e.code === 'Space' || e.code === 'KeyJ' || e.code === 'KeyZ') {
      keys.sword = true;
      if (getGameState() === 'PLAYING') performSwordAttack();
    }
  });

  window.addEventListener('keyup', (e) => {
    if (e.code === 'KeyA' || e.code === 'ArrowLeft') keys.left = false;
    if (e.code === 'KeyD' || e.code === 'ArrowRight') keys.right = false;
    if (e.code === 'Space' || e.code === 'KeyJ' || e.code === 'KeyZ') keys.sword = false;
  });

  ['touchstart', 'touchend', 'mousedown', 'keydown'].forEach((eventType) => {
    window.addEventListener(eventType, () => { SoundSystem.init(); }, { passive: true });
  });

  const touchLeft = document.getElementById('touch-left');
  const touchRight = document.getElementById('touch-right');
  const touchSword = document.getElementById('touch-sword');

  function handleTouchLeft(e) {
    if (e && e.cancelable) e.preventDefault();
    SoundSystem.init();
    if (getGameState() === 'PLAYING') { keys.left = true; }
  }

  function handleTouchRight(e) {
    if (e && e.cancelable) e.preventDefault();
    SoundSystem.init();
    if (getGameState() === 'PLAYING') { keys.right = true; }
  }

  if (touchLeft) {
    touchLeft.addEventListener('touchstart', handleTouchLeft, { passive: false });
    touchLeft.addEventListener('touchend', (e) => { if (e && e.cancelable) e.preventDefault(); keys.left = false; }, { passive: false });
    touchLeft.addEventListener('touchcancel', () => { keys.left = false; }, { passive: true });
    touchLeft.addEventListener('mousedown', handleTouchLeft);
    touchLeft.addEventListener('mouseup', () => { keys.left = false; });
    touchLeft.addEventListener('mouseleave', () => { keys.left = false; });
  }

  if (touchRight) {
    touchRight.addEventListener('touchstart', handleTouchRight, { passive: false });
    touchRight.addEventListener('touchend', (e) => { if (e && e.cancelable) e.preventDefault(); keys.right = false; }, { passive: false });
    touchRight.addEventListener('touchcancel', () => { keys.right = false; }, { passive: true });
    touchRight.addEventListener('mousedown', handleTouchRight);
    touchRight.addEventListener('mouseup', () => { keys.right = false; });
    touchRight.addEventListener('mouseleave', () => { keys.right = false; });
  }

  bindButton(touchSword, () => {
    if (getGameState() === 'PLAYING') performSwordAttack();
  });
}

export function drawBackground(ctx, canvas) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#0f111a'; ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#f5f6fa'; ctx.beginPath(); ctx.arc(canvas.width / 2, 90, 45, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#dcdde1'; ctx.beginPath(); ctx.arc(canvas.width / 2 - 10, 80, 10, 0, Math.PI * 2); ctx.arc(canvas.width / 2 + 15, 105, 8, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#181b26'; ctx.beginPath(); ctx.moveTo(0, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height - 40); ctx.lineTo(canvas.width, canvas.height); ctx.lineTo(0, canvas.height); ctx.fill();
  ctx.fillStyle = '#2c1e14'; ctx.fillRect(0, canvas.height - 40, canvas.width, 40);
  ctx.fillStyle = '#c0392b'; ctx.fillRect(0, canvas.height - 40, canvas.width, 4);
}
