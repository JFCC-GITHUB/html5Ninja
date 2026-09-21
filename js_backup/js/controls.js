// ==========================================
// CONTROLS BINDING MODULE
// ==========================================
import { SoundSystem } from './sound.js';

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
    else if (e.code === 'Space') { keys.shoot = true; }
    else if (e.code === 'KeyJ' || e.code === 'KeyZ') { keys.sword = true; if (getGameState() === 'PLAYING') performSwordAttack(); }
  });

  window.addEventListener('keyup', (e) => {
    if (e.code === 'KeyA' || e.code === 'ArrowLeft') keys.left = false;
    if (e.code === 'KeyD' || e.code === 'ArrowRight') keys.right = false;
    if (e.code === 'Space') keys.shoot = false;
    if (e.code === 'KeyJ' || e.code === 'KeyZ') keys.sword = false;
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
