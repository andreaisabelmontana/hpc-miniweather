# MiniWeather HPC Project

A high-performance 3D stencil-based mini-weather simulation for HPC clusters.

## Overview

This project implements a 7-point stencil computation using:
- **MPI** for distributed memory parallelism
- **OpenMP** for shared memory parallelism  
- **CUDA/HIP** for GPU acceleration (optional)

## Quick Start

### On Magic Castle Cluster (Slurm)

```bash
# 1. Clone and build
git clone https://github.com/Khawwash/HPC_MiniWeather_Project.git
cd HPC_MiniWeather_Project
./run.sh build

# 2. Run interactive test
./run.sh test

# 3. Submit to Slurm
sbatch submit.sbatch
```

### Local Development

```bash
# macOS (no MPI/OpenMP)
cmake -S . -B build -DENABLE_MPI=OFF -DENABLE_OPENMP=OFF
cmake --build build
./build/miniweather --nx 32 --ny 32 --nz 32 --steps 10

# Linux with MPI
cmake -S . -B build -DENABLE_MPI=ON -DENABLE_OPENMP=ON
cmake --build build
mpirun -np 4 ./build/miniweather --nx 64 --ny 64 --nz 64 --steps 100
```

## Project Structure

```
HPC_MiniWeather_Project/
├── src/                    # Source code
│   ├── main.cpp           # Entry point
│   ├── stencil_cpu_serial.cpp
│   ├── stencil_cpu_parallel.cpp
│   ├── stencil_cpu_blocked.cpp
│   ├── stencil_gpu.cpp
│   ├── halo.cpp           # MPI halo exchange
│   └── cli.cpp            # Command-line parsing
├── include/               # Headers
├── env/                   # Environment setup
│   ├── modules.txt        # Module load commands
│   ├── miniweather.def    # Apptainer recipe
│   └── environment.yml    # Conda environment
├── slurm/                 # SLURM job scripts
│   ├── strong_scaling.sbatch
│   ├── weak_scaling.sbatch
│   ├── profile_cpu.sbatch
│   └── profile_gpu.sbatch
├── data/                  # Sample data/configs
├── results/               # Output (CSV, plots, logs)
├── scripts/               # Helper scripts
│   ├── plot_results.py
│   └── collect_results.py
├── docs/                  # Documentation
│   ├── paper.md           # Short paper (4-6 pages)
│   ├── eurohpc_proposal.md
│   └── pitch_slides.md
├── profiling/             # Profiling guide
├── tests/                 # Test scripts
├── run.sh                 # Main run script
├── submit.sbatch          # Main SLURM submit
└── CMakeLists.txt         # Build configuration
```

## Command-Line Options

```
./miniweather [options]

Options:
  --nx <int>      Grid points in X (default: 64)
  --ny <int>      Grid points in Y (default: 64)
  --nz <int>      Grid points in Z (default: 64)
  --steps <int>   Time steps (default: 100)
  --ti <int>      Tile size I for blocking (default: 16)
  --tj <int>      Tile size J for blocking (default: 16)
```

## Build Options

```bash
cmake -B build \
  -DENABLE_MPI=ON \      # MPI support
  -DENABLE_OPENMP=ON \   # OpenMP threading
  -DENABLE_CUDA=OFF \    # CUDA GPU support
  -DENABLE_HIP=OFF       # HIP GPU support
```

## Running Experiments

### Scaling Tests

```bash
# Strong scaling
sbatch slurm/strong_scaling.sbatch

# Weak scaling  
sbatch slurm/weak_scaling.sbatch
```

### Profiling

```bash
# CPU profiling
sbatch slurm/profile_cpu.sbatch

# GPU profiling
sbatch slurm/profile_gpu.sbatch
```

### Generate Plots

```bash
python scripts/plot_results.py
```

## Performance

Example results on Magic Castle cluster:

| Configuration | Time (s) | GLUPS | Efficiency |
|--------------|----------|-------|------------|
| 1 node, 4 ranks | X.XX | X.XX | 100% |
| 2 nodes, 8 ranks | X.XX | X.XX | XX% |
| 4 nodes, 16 ranks | X.XX | X.XX | XX% |

## Documentation

- [Architecture](ARCHITECTURE.md) - Code design and algorithms
- [Results](RESULTS.md) - Experiment results template
- [Paper](paper.md) - Short paper (4-6 pages)
- [EuroHPC Proposal](eurohpc_proposal.md) - Development Access proposal
- [Pitch Slides](pitch_slides.md) - 5-minute presentation outline

## Team

- [Team member names]

## License

MIT License

## Acknowledgments

- Based on [miniWeather](https://github.com/mrnorman/miniWeather) by Matt Norman
- Magic Castle cluster provided by [Institution]
