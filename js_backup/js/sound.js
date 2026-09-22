// ==========================================
// SOUND SYSTEM MODULE
// ==========================================
let audioCtx = null;

export function initAudioContext() {
  if (!audioCtx) {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    audioCtx = new AudioContext();
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function playTone(freq, type = 'square', duration = 0.1, startVol = 0.2, endVol = 0) {
  try {
    initAudioContext();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
    gain.gain.setValueAtTime(startVol, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(Math.max(endVol, 0.0001), audioCtx.currentTime + duration);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + duration);
  } catch (e) {}
}

export const SoundSystem = {
  init: initAudioContext,
  playShurikenThrow: () => playTone(800, 'sawtooth', 0.08, 0.15, 0.01),
  playEnemyHit: () => playTone(220, 'square', 0.12, 0.25, 0.01),
  playPlayerHurt: () => playTone(150, 'sawtooth', 0.2, 0.3, 0.01),
  playGameOver: () => [400, 350, 300, 250, 180].forEach((f, i) => setTimeout(() => playTone(f, 'triangle', 0.2, 0.25, 0.01), i * 120)),
  playClick: () => playTone(600, 'sine', 0.05, 0.15, 0.01),
  playSwordSlash: () => playTone(1200, 'sawtooth', 0.12, 0.35, 0.01),
  playLevelUp: () => [523, 659, 783, 1046].forEach((f, i) => setTimeout(() => playTone(f, 'sine', 0.15, 0.3, 0.01), i * 80)),
};
