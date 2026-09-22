// ==========================================
// ENTITIES & PHYSICS MODULE
// ==========================================
import { GAME_CONFIG } from './config.js';

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
  };
}

export function checkAABBCollision(rect1, rect2) {
  return (
    rect1.x < rect2.x + rect2.width &&
    rect1.x + rect1.width > rect2.x &&
    rect1.y < rect2.y + rect2.height &&
    rect1.y + rect1.height > rect2.y
  );
}

export function getShurikenSize(level) {
  return GAME_CONFIG.SHURIKEN.BASE_SIZE + (level - 1) * 4;
}

export function getSwordRange(level) {
  return GAME_CONFIG.PLAYER.BASE_SWORD_RANGE + (level - 1) * 22;
}
