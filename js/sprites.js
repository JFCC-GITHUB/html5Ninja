// ==========================================
// SPRITE GENERATOR MODULE
// ==========================================
import { GAME_CONFIG } from './config.js';

function createCanvas(w, h) {
  const canvas = document.createElement('canvas');
  canvas.width = w; canvas.height = h;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  return { canvas, ctx };
}

function drawPixelMatrix(ctx, matrix, palette, pixelSize = 2, offsetX = 0, offsetY = 0) {
  for (let r = 0; r < matrix.length; r++) {
    const row = matrix[r];
    for (let c = 0; c < row.length; c++) {
      const char = row[c];
      if (char !== '.' && palette[char]) {
        ctx.fillStyle = palette[char];
        ctx.fillRect(offsetX + c * pixelSize, offsetY + r * pixelSize, pixelSize, pixelSize);
      }
    }
  }
}

const NINJA_PALETTE = { 'B': '#1a1a24', 'D': '#2d2d44', 'S': '#f1c40f', 'F': '#ffdbac', 'E': '#000000', 'R': '#e74c3c' };
const NINJA_IDLE_MATRIX = [
  "......RRRRRR......", ".....RRRRRRRR.....", "....BBBBBBBBBB....", "...BBBBBBBBBBBB...",
  "...BBFFFFFFBBBB...", "...BBFEFFEFEBBB...", "...BBFFFFFFBBBB...", "...SSSSSSSSSSSS...",
  "....BBBBBBBBBB....", "....BDDDDDBBBB....", "...BBDDDDDDBBBB...", "...BBDDDDDDBBBB...",
  "...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "....BDDDDDDDDB....",
  "....BBBB..BBBB....", "....BBBB..BBBB....", "....BBBB..BBBB....", "....BBBB..BBBB....",
  "....BBBB..BBBB....", "...BBBBB..BBBBB...", "...BBBBB..BBBBB...", ".................."
];
const NINJA_RUN_MATRIX = [
  "......RRRRRR......", ".....RRRRRRRR.....", "....BBBBBBBBBB....", "...BBBBBBBBBBBB...",
  "...BBFFFFFFBBBB...", "...BBFEFFEFEBBB...", "...BBFFFFFFBBBB...", "...SSSSSSSSSSSS...",
  "....BBBBBBBBBB....", "....BDDDDDBBBB....", "...BBDDDDDDBBBB...", "...BBDDDDDDBBBB...",
  "...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "....BDDDDDDDDB....", ".....BBBBBBBB.....",
  "....BBBB...BBBB...", "...BBBB.....BBBB..", "..BBBB.......BBBB.", "..BBBB.......BBBB.",
  ".BBBBB.......BBBBB", ".BBBBB.......BBBBB", ".................."
];

function createNinjaSprites() {
  const width = GAME_CONFIG.PLAYER.WIDTH; // 48
  const height = GAME_CONFIG.PLAYER.HEIGHT; // 64
  const pSize = height / 24; // 2.6666666666666665

  const idleLeft = createCanvas(width, height); drawPixelMatrix(idleLeft.ctx, NINJA_IDLE_MATRIX, NINJA_PALETTE, pSize);
  const idleRight = createCanvas(width, height); idleRight.ctx.translate(width, 0); idleRight.ctx.scale(-1, 1); drawPixelMatrix(idleRight.ctx, NINJA_IDLE_MATRIX, NINJA_PALETTE, pSize);
  const runLeft = createCanvas(width, height); drawPixelMatrix(runLeft.ctx, NINJA_RUN_MATRIX, NINJA_PALETTE, pSize);
  const runRight = createCanvas(width, height); runRight.ctx.translate(width, 0); runRight.ctx.scale(-1, 1); drawPixelMatrix(runRight.ctx, NINJA_RUN_MATRIX, NINJA_PALETTE, pSize);
  return { idleRight: idleRight.canvas, idleLeft: idleLeft.canvas, runRight: runRight.canvas, runLeft: runLeft.canvas };
}

function createShurikenSprite() {
  const { canvas, ctx } = createCanvas(32, 32);
  ctx.fillStyle = '#bdc3c7'; ctx.strokeStyle = '#2c3e50'; ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(16, 0); ctx.lineTo(20, 12); ctx.lineTo(32, 16); ctx.lineTo(20, 20);
  ctx.lineTo(16, 32); ctx.lineTo(12, 20); ctx.lineTo(0, 16); ctx.lineTo(12, 12);
  ctx.closePath(); ctx.fill(); ctx.stroke();
  ctx.fillStyle = '#111'; ctx.beginPath(); ctx.arc(16, 16, 5, 0, Math.PI * 2); ctx.fill();
  return canvas;
}

function createEnemySprites(colorMain, colorSub, width, height) {
  const { canvas, ctx } = createCanvas(width, height);
  const pSize = Math.max(1, Math.floor(width / 16));
  ctx.fillStyle = colorMain; ctx.fillRect(pSize * 2, pSize * 2, width - pSize * 4, height - pSize * 4);
  ctx.fillStyle = '#111'; ctx.fillRect(pSize * 3, pSize * 3, width - pSize * 6, pSize * 6);
  ctx.fillStyle = '#fff'; ctx.fillRect(pSize * 4, pSize * 5, pSize * 2, pSize * 2); ctx.fillRect(width - pSize * 6, pSize * 5, pSize * 2, pSize * 2);
  ctx.fillStyle = '#e74c3c'; ctx.fillRect(pSize * 5, pSize * 5, pSize, pSize * 2); ctx.fillRect(width - pSize * 5, pSize * 5, pSize, pSize * 2);
  ctx.fillStyle = colorSub; ctx.fillRect(pSize * 2, pSize * 2, width - pSize * 4, pSize * 2);
  ctx.fillStyle = '#2c3e50'; ctx.fillRect(pSize * 2, height / 2, width - pSize * 4, pSize * 3);
  ctx.fillStyle = colorMain; ctx.fillRect(pSize * 3, height - pSize * 5, pSize * 4, pSize * 5); ctx.fillRect(width - pSize * 7, height - pSize * 5, pSize * 4, pSize * 5);
  const leftCanvas = createCanvas(width, height); leftCanvas.ctx.translate(width, 0); leftCanvas.ctx.scale(-1, 1); leftCanvas.ctx.drawImage(canvas, 0, 0);
  return { right: canvas, left: leftCanvas.canvas };
}

let cache = null;
export function getSprites() {
  if (cache) return cache;
  cache = {
    ninja: createNinjaSprites(),
    shuriken: createShurikenSprite(),
    enemies: {
      NORMAL: createEnemySprites(GAME_CONFIG.ENEMY_TYPES.NORMAL.color, '#c0392b', GAME_CONFIG.ENEMY_TYPES.NORMAL.width, GAME_CONFIG.ENEMY_TYPES.NORMAL.height),
      FAST: createEnemySprites(GAME_CONFIG.ENEMY_TYPES.FAST.color, '#f39c12', GAME_CONFIG.ENEMY_TYPES.FAST.width, GAME_CONFIG.ENEMY_TYPES.FAST.height),
      TANK: createEnemySprites(GAME_CONFIG.ENEMY_TYPES.TANK.color, '#9b59b6', GAME_CONFIG.ENEMY_TYPES.TANK.width, GAME_CONFIG.ENEMY_TYPES.TANK.height),
      SHADOW: createEnemySprites(GAME_CONFIG.ENEMY_TYPES.SHADOW.color, '#2c3e50', GAME_CONFIG.ENEMY_TYPES.SHADOW.width, GAME_CONFIG.ENEMY_TYPES.SHADOW.height),
      BOSS: createEnemySprites(GAME_CONFIG.ENEMY_TYPES.BOSS.color, '#e74c3c', GAME_CONFIG.ENEMY_TYPES.BOSS.width, GAME_CONFIG.ENEMY_TYPES.BOSS.height),
    }
  };
  return cache;
}
