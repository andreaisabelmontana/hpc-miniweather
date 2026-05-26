// ============================================================
// 2D analogue of the cluster's 3D 7-point stencil.
//
// On the cluster, each cell at (i,j,k) gets a weighted average of itself
// and its 6 face-neighbours (±x, ±y, ±z). Here we run the same kernel in
// 2D — 5-point stencil (centre + 4 face-neighbours) — so it's directly
// drawable on a canvas. The math is the same diffusion operator:
//
//   u' = (1 - 4α) · u  +  α · (u_left + u_right + u_up + u_down)
//
// On top of that we add:
//   - buoyancy: a small upward velocity proportional to temperature anomaly,
//     so hot pockets rise (the original code does this in 3D)
//   - wind: optional horizontal advection
//   - heat sources / sinks at the boundaries (Dirichlet-style forcing)
//
// We use Float32Array so the JIT can vectorise the inner loops, and we
// double-buffer (uA / uB) to avoid in-place hazards in the stencil.
// ============================================================

export const PRESETS = {
  thermal: (nx, ny) => {
    // Cool stratified atmosphere with a warm blob near the bottom centre.
    const u = new Float32Array(nx * ny);
    for (let j = 0; j < ny; j++) {
      const cool = 0.05 + 0.10 * (j / ny);
      for (let i = 0; i < nx; i++) u[j * nx + i] = cool;
    }
    addBlob(u, nx, ny, nx * 0.5, ny * 0.25, ny * 0.10, 0.85);
    return { u, gravity: true, wind: 0.0 };
  },

  collision: (nx, ny) => {
    const u = new Float32Array(nx * ny).fill(0.08);
    addBlob(u, nx, ny, nx * 0.30, ny * 0.30, ny * 0.10, 0.85);
    addBlob(u, nx, ny, nx * 0.70, ny * 0.30, ny * 0.10, 0.85);
    return { u, gravity: true, wind: 0.0 };
  },

  wave: (nx, ny) => {
    // Sinusoidal "plane wave" pattern — same vibe as the cluster's wave preset.
    const u = new Float32Array(nx * ny);
    for (let j = 0; j < ny; j++) {
      for (let i = 0; i < nx; i++) {
        u[j * nx + i] = 0.5 + 0.4 * Math.sin(2 * Math.PI * (i / nx) * 3) * Math.cos(2 * Math.PI * (j / ny) * 2);
      }
    }
    return { u, gravity: false, wind: 0.0 };
  },

  sphere: (nx, ny) => {
    // Single Gaussian — direct 2D analogue of the cluster's "sphere" preset.
    const u = new Float32Array(nx * ny).fill(0.05);
    addBlob(u, nx, ny, nx * 0.5, ny * 0.5, Math.min(nx, ny) * 0.10, 0.95);
    return { u, gravity: false, wind: 0.0 };
  },

  vortex: (nx, ny) => {
    // Concentric rings spinning around centre — produced by a swirling wind.
    const u = new Float32Array(nx * ny);
    const cx = nx / 2, cy = ny / 2;
    for (let j = 0; j < ny; j++) {
      for (let i = 0; i < nx; i++) {
        const dx = i - cx, dy = j - cy;
        const r = Math.sqrt(dx*dx + dy*dy);
        u[j * nx + i] = 0.5 + 0.45 * Math.sin(r * 0.35);
      }
    }
    return { u, gravity: false, wind: 0.0, swirl: true };
  },
};

function addBlob(u, nx, ny, cx, cy, sigma, amp) {
  const s2 = 2 * sigma * sigma;
  for (let j = 0; j < ny; j++) {
    for (let i = 0; i < nx; i++) {
      const dx = i - cx, dy = j - cy;
      u[j * nx + i] = Math.min(1, u[j * nx + i] + amp * Math.exp(-(dx*dx + dy*dy) / s2));
    }
  }
}

// ----- The actual stencil -------------------------------------------------

export class Sim {
  constructor(nx, ny) {
    this.resize(nx, ny);
    this.diff   = 0.20;
    this.buoy   = 0.10;
    this.wind   = 0.0;
    this.gravity = true;
    this.swirl  = false;
    this.step   = 0;
  }

  resize(nx, ny) {
    this.nx = nx; this.ny = ny;
    this.uA = new Float32Array(nx * ny);
    this.uB = new Float32Array(nx * ny);
  }

  load(preset) {
    const { u, gravity = false, wind = 0, swirl = false } = preset(this.nx, this.ny);
    this.uA.set(u);
    this.uB.set(u);
    this.gravity = gravity;
    this.swirl   = swirl;
    if (wind !== undefined) this.windPreset = wind;
    this.step = 0;
  }

  /**
   * One timestep:
   *   1. apply 5-point stencil with weight α = diff/4
   *   2. add buoyancy: hot cells get pushed up
   *   3. add wind: shift the field horizontally a fraction
   *   4. enforce zero-gradient (Neumann) BC at the edges
   */
  tick() {
    const { nx, ny, uA, uB } = this;
    const alpha = this.diff / 4.0;
    const buoy  = this.gravity ? this.buoy : 0;
    const wind  = this.wind;

    // 5-point stencil over the interior
    for (let j = 1; j < ny - 1; j++) {
      const rowA = j * nx;
      const rowU = (j - 1) * nx;
      const rowD = (j + 1) * nx;
      for (let i = 1; i < nx - 1; i++) {
        const c = uA[rowA + i];
        const n = uA[rowU + i];
        const s = uA[rowD + i];
        const e = uA[rowA + i + 1];
        const w = uA[rowA + i - 1];
        uB[rowA + i] = (1 - 4 * alpha) * c + alpha * (n + s + e + w);
      }
    }

    // Buoyancy & wind advection (semi-Lagrangian-ish: simple shift)
    if (buoy > 0 || wind !== 0 || this.swirl) {
      const tmp = new Float32Array(uB);
      for (let j = 1; j < ny - 1; j++) {
        for (let i = 1; i < nx - 1; i++) {
          const c = tmp[j * nx + i];
          let vx = wind;
          let vy = buoy > 0 ? -buoy * (c - 0.2) : 0;
          if (this.swirl) {
            const dx = i - nx / 2, dy = j - ny / 2;
            const r = Math.sqrt(dx*dx + dy*dy) + 0.01;
            vx += -dy / r * 0.4;
            vy +=  dx / r * 0.4;
          }
          // Sample from upstream position; bilinear interpolation.
          const xs = i - vx, ys = j - vy;
          const x0 = Math.max(0, Math.min(nx - 1, Math.floor(xs)));
          const y0 = Math.max(0, Math.min(ny - 1, Math.floor(ys)));
          const x1 = Math.min(nx - 1, x0 + 1), y1 = Math.min(ny - 1, y0 + 1);
          const fx = Math.max(0, Math.min(1, xs - x0));
          const fy = Math.max(0, Math.min(1, ys - y0));
          const a = tmp[y0 * nx + x0], b = tmp[y0 * nx + x1];
          const cc = tmp[y1 * nx + x0], d = tmp[y1 * nx + x1];
          uB[j * nx + i] = (1 - fx) * (1 - fy) * a + fx * (1 - fy) * b
                         + (1 - fx) * fy * cc        + fx * fy * d;
        }
      }
    }

    // Neumann BC: copy interior into border so heat doesn't artificially escape.
    for (let i = 0; i < nx; i++) {
      uB[i]                  = uB[nx + i];                 // top
      uB[(ny - 1) * nx + i]  = uB[(ny - 2) * nx + i];      // bottom
    }
    for (let j = 0; j < ny; j++) {
      uB[j * nx]             = uB[j * nx + 1];             // left
      uB[j * nx + nx - 1]    = uB[j * nx + nx - 2];        // right
    }

    // Swap buffers
    const t = this.uA; this.uA = this.uB; this.uB = t;
    this.step++;
  }
}
