// ============================================================
// Boot the canvas + wire up the UI controls.
// ============================================================

import { Sim, PRESETS } from './sim.js';

// ----- Canvas / rendering --------------------------------------------------

const canvas = document.getElementById('sim');
const ctx    = canvas.getContext('2d', { alpha: false });
const stepEl = document.getElementById('stat-step');
const rateEl = document.getElementById('stat-rate');
const fpsEl  = document.getElementById('stat-fps');

let sim = new Sim(128, 96);
sim.load(PRESETS.thermal);

// Pre-bake a 256-entry RGB colormap so we can do one table lookup per pixel
// instead of mixing floats in the hot path. The stops mirror --cmap-* in CSS.
const COLORS = (() => {
  const stops = [
    [10, 18, 48],
    [29, 58, 138],
    [37, 99, 235],
    [6, 182, 212],
    [16, 185, 129],
    [245, 158, 11],
    [220, 38, 38],
  ];
  const out = new Uint8ClampedArray(256 * 3);
  const segs = stops.length - 1;
  for (let i = 0; i < 256; i++) {
    const t = (i / 255) * segs;
    const k = Math.min(segs - 1, Math.floor(t));
    const f = t - k;
    const a = stops[k], b = stops[k + 1];
    out[i * 3 + 0] = a[0] + (b[0] - a[0]) * f;
    out[i * 3 + 1] = a[1] + (b[1] - a[1]) * f;
    out[i * 3 + 2] = a[2] + (b[2] - a[2]) * f;
  }
  return out;
})();

let imgData = null;

function ensureImageData() {
  if (imgData && imgData.width === sim.nx && imgData.height === sim.ny) return;
  // Resize canvas backing store to match grid; CSS scales it to fill the wrapper.
  canvas.width  = sim.nx;
  canvas.height = sim.ny;
  imgData = ctx.createImageData(sim.nx, sim.ny);
}

function render() {
  ensureImageData();
  const data = imgData.data;
  const u = sim.uA;
  const n = u.length;
  for (let p = 0, q = 0; p < n; p++, q += 4) {
    // Map [0..1] -> 0..255 via clamp; colors[3*idx] gives the RGB.
    let v = u[p];
    if (v < 0) v = 0; else if (v > 1) v = 1;
    const idx = (v * 255) | 0;
    const c = idx * 3;
    data[q]     = COLORS[c];
    data[q + 1] = COLORS[c + 1];
    data[q + 2] = COLORS[c + 2];
    data[q + 3] = 255;
  }
  ctx.putImageData(imgData, 0, 0);
}

// ----- Main loop -----------------------------------------------------------

let playing = true;
let lastT = performance.now();
let stepsSinceTick = 0;
let cellsPerSec = 0;
let fps = 0;

function loop(now) {
  const dt = now - lastT;
  lastT = now;

  if (playing) {
    // Run a couple of stencil ticks per frame so visual evolution looks lively
    // on coarse grids while staying interactive on fine ones.
    const targetMs = 16;       // budget per frame
    const t0 = performance.now();
    let ticks = 0;
    do {
      sim.tick();
      ticks++;
      stepsSinceTick++;
    } while (performance.now() - t0 < targetMs * 0.4 && ticks < 8);
  }

  render();

  // Stats
  if (now - statsLastT > 500) {
    cellsPerSec = (stepsSinceTick * sim.nx * sim.ny) / ((now - statsLastT) / 1000);
    fps = 1000 / Math.max(1, dt);
    stepsSinceTick = 0;
    statsLastT = now;
    stepEl.textContent = sim.step.toString();
    rateEl.textContent = fmtRate(cellsPerSec);
    fpsEl.textContent  = fps.toFixed(0);
  }

  requestAnimationFrame(loop);
}
let statsLastT = performance.now();

function fmtRate(n) {
  if (n >= 1e9) return (n / 1e9).toFixed(2) + ' G';
  if (n >= 1e6) return (n / 1e6).toFixed(2) + ' M';
  if (n >= 1e3) return (n / 1e3).toFixed(1) + ' k';
  return n.toFixed(0);
}

// ----- UI wiring -----------------------------------------------------------

const presetSeg = document.getElementById('preset-seg');
presetSeg.addEventListener('click', (e) => {
  const btn = e.target.closest('button[data-preset]');
  if (!btn) return;
  for (const b of presetSeg.querySelectorAll('button')) b.classList.remove('active');
  btn.classList.add('active');
  const name = btn.dataset.preset;
  if (PRESETS[name]) sim.load(PRESETS[name]);
});

function bindSlider(id, valId, onChange) {
  const el = document.getElementById(id);
  const val = document.getElementById(valId);
  const fmt = (v) => Number(v).toFixed(2);
  const apply = () => { onChange(+el.value); val.textContent = fmt(el.value); };
  el.addEventListener('input', apply);
  apply();
}
bindSlider('ctrl-diff', 'val-diff', (v) => sim.diff = v);
bindSlider('ctrl-buoy', 'val-buoy', (v) => sim.buoy = v);
bindSlider('ctrl-wind', 'val-wind', (v) => sim.wind = v * 0.5);

const resEl  = document.getElementById('ctrl-res');
const resVal = document.getElementById('val-res');
resEl.addEventListener('input', () => {
  const nx = +resEl.value;
  const ny = Math.round(nx * 0.75);
  resVal.textContent = `${nx} × ${ny}`;
  const currentPreset = presetSeg.querySelector('button.active')?.dataset.preset || 'thermal';
  sim.resize(nx, ny);
  sim.load(PRESETS[currentPreset]);
  imgData = null;
});

document.getElementById('btn-play').addEventListener('click', (e) => {
  playing = !playing;
  e.currentTarget.textContent = playing ? '⏸ Pause' : '▶ Play';
});
document.getElementById('btn-step').addEventListener('click', () => {
  if (!playing) { sim.tick(); render(); stepEl.textContent = sim.step; }
});
document.getElementById('btn-reset').addEventListener('click', () => {
  const currentPreset = presetSeg.querySelector('button.active')?.dataset.preset || 'thermal';
  sim.load(PRESETS[currentPreset]);
});

document.getElementById('yr').textContent = new Date().getFullYear();

requestAnimationFrame(loop);
