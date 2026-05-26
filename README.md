# HPC MiniWeather — visualization

An interactive in-browser visualization of the **HPC MiniWeather Project**, plus a mirror
of the original source so this repo is self-contained.

> **Live demo:** https://andreaisabelmontana.github.io/hpc-miniweather/

## What this repo is

```
hpc-miniweather/
├── source/                       Mirror of the team's C++ HPC project.
│   ├── src/                      4 implementations of the same 7-point stencil:
│   │   ├── stencil_cpu_serial.cpp        single-thread baseline
│   │   ├── stencil_cpu_blocked.cpp       cache-blocked CPU
│   │   ├── stencil_cpu_parallel.cpp      OpenMP + MPI halo exchange
│   │   ├── stencil_gpu.cu                CUDA
│   │   ├── halo.cpp / cli.cpp / timer.cpp
│   │   └── main.cpp
│   ├── include/, env/, slurm/, scripts/, tests/, profiling/, docs/
│   ├── results/                  PNG slices + isosurface renders + animated GIF
│   ├── CMakeLists.txt, run.sh, submit*.sbatch / *.slurm
│   └── requirements.txt
└── web/                          GitHub Pages site (this is what gets deployed)
    ├── index.html                Hero + live sim + cluster outputs + backends
    ├── source-overview.html      Plain-English tour of the source/ tree
    ├── style.css                 Forest-green design system
    ├── favicon.svg
    ├── src/
    │   ├── sim.js                2D 7-point stencil solver (Float32 + double-buffered)
    │   └── app.js                Canvas rendering, colormap, UI wiring
    └── assets/
        ├── viz/, viz_wave/, viz_sphere/, viz_animation/
                                  Real cluster outputs (PNGs + GIF), copied
                                  from source/results/ so the live page can show them.
```

## What you can do on the live site

- Watch a **2D analogue of the cluster's 7-point stencil** run on an HTML canvas.
- Switch between presets that mirror the cluster's: rising thermal, two thermals colliding,
  plane wave, hot sphere, vortex.
- Slide diffusion / buoyancy / wind / resolution and see the algorithm respond live.
- See the **actual cluster outputs** (PNG slices + 3D isosurfaces + an animated GIF)
  next to the in-browser sim.
- Click through to a source overview that explains what each `source/src/*.cpp` file does.

## Two improvements over a bare README

1. **You can see the algorithm running.** The whole point of the project is a 7-point
   stencil; previously you had to read the code (or run it on the cluster) to know what
   that meant. Now you watch it.
2. **Side-by-side cluster + browser.** The page puts the real 3D cluster artefacts
   directly next to the live 2D analogue, so it's obvious which is "the answer" and
   which is "the interactive teaching aid".

## Local development

The web/ folder is a plain static site — no build step, no dependencies.

```bash
cd web
# any local web server will do
python3 -m http.server 8000
# then open http://localhost:8000
```

The simulation lives in `web/src/sim.js`. The kernel itself (one stencil step) is the
inner double-loop in `Sim.tick()` — that's the analogue of the triple-loops in
`source/src/stencil_cpu_serial.cpp`.

## Deploying

Pushes to `main` that touch `web/` (or the workflow file) trigger the GitHub Pages
deploy via `.github/workflows/deploy.yml`. The first deploy requires Pages to be
enabled on the repo (Settings → Pages → Source: **GitHub Actions**).

## Credits

- **Cluster solver and outputs:** the BCSAI HPC team, forked through
  [`Geethika2506/HPC_MiniWeather_Project`](https://github.com/Geethika2506/HPC_MiniWeather_Project)
  from [`Khawwash/HPC_MiniWeather_Project`](https://github.com/Khawwash/HPC_MiniWeather_Project).
- **In-browser visualization layer:** Andrea Montana, IE BCSAI, Fall 2025.

The `source/` directory mirrors Geethika's repo as-is; nothing in it has been rewritten,
only re-hosted so this repo is self-contained.
