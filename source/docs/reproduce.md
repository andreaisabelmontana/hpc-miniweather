# MiniWeather HPC - Reproducibility Guide

## Quick Reproduction

```bash
# Clone repository
git clone https://github.com/Khawwash/HPC_MiniWeather_Project.git
cd HPC_MiniWeather_Project
git checkout riley-mpi-openmp-implementation

# Load modules (Magic Castle / Alliance)
module purge --force
module load gcc/12.3 openmpi/4.1.5 cmake/3.27

# Build
cmake -B build -DENABLE_MPI=ON -DENABLE_OPENMP=ON
cmake --build build -j4

# Quick test
export OMP_NUM_THREADS=2
mpirun -np 2 ./build/miniweather --nx 32 --ny 32 --nz 32 --steps 10
```

## Full Experiment Reproduction

### 1. Strong Scaling (Fixed problem size)

```bash
cd build
export OMP_NUM_THREADS=2

# 1 rank (baseline)
mpirun --oversubscribe -np 1 ./miniweather --nx 128 --ny 128 --nz 128 --steps 200

# 2 ranks
mpirun --oversubscribe -np 2 ./miniweather --nx 128 --ny 128 --nz 128 --steps 200

# 4 ranks
mpirun --oversubscribe -np 4 ./miniweather --nx 128 --ny 128 --nz 128 --steps 200

# 8 ranks
mpirun --oversubscribe -np 8 ./miniweather --nx 128 --ny 128 --nz 128 --steps 200
```

**Expected Results:**
| Ranks | Time (s) | Speedup | Efficiency |
|-------|----------|---------|------------|
| 1 | ~0.51 | 1.00x | 100% |
| 2 | ~0.38 | 1.34x | 67% |
| 4 | ~0.46 | 1.12x | 28% |
| 8 | ~0.53 | 0.96x | 12% |

### 2. Weak Scaling (Problem grows with ranks)

```bash
# 1 rank: 64^3
mpirun --oversubscribe -np 1 ./miniweather --nx 64 --ny 64 --nz 64 --steps 200

# 2 ranks: 64x64x128
mpirun --oversubscribe -np 2 ./miniweather --nx 64 --ny 64 --nz 128 --steps 200

# 4 ranks: 64x64x256
mpirun --oversubscribe -np 4 ./miniweather --nx 64 --ny 64 --nz 256 --steps 200

# 8 ranks: 64x64x512
mpirun --oversubscribe -np 8 ./miniweather --nx 64 --ny 64 --nz 512 --steps 200
```

**Expected Results:**
| Ranks | Grid | Time (s) | Efficiency |
|-------|------|----------|------------|
| 1 | 64³ | ~0.52 | 100% |
| 2 | 64×64×128 | ~0.37 | 139% |
| 4 | 64×64×256 | ~0.47 | 111% |
| 8 | 64×64×512 | ~0.53 | 98% |

### 3. Sensitivity Analysis (Tile Size)

```bash
for TILE in 8 16 32 64; do
  echo "Tile size: $TILE"
  mpirun --oversubscribe -np 2 ./miniweather --nx 128 --ny 128 --nz 128 --steps 100 --ti $TILE --tj $TILE
done
```

### 4. CPU Profiling

```bash
# perf stat
perf stat -e cycles,instructions,cache-references,cache-misses \
  mpirun -np 2 ./miniweather --nx 64 --ny 64 --nz 64 --steps 100

# perf record + report
perf record -g mpirun -np 2 ./miniweather --nx 64 --ny 64 --nz 64 --steps 100
perf report
```

### 5. SLURM Job Submission

```bash
# Main job (2 nodes)
sbatch submit.sbatch

# Scaling experiments
sbatch slurm/strong_scaling.sbatch
sbatch slurm/weak_scaling.sbatch

# Profiling
sbatch slurm/profile_cpu.sbatch
```

### 6. Generate Plots

```bash
python3 scripts/plot_results.py
# OR manually with matplotlib (see scripts/plot_results.py)
```

## Environment Details

| Component | Version |
|-----------|---------|
| OS | Rocky Linux 8 |
| Compiler | GCC 12.3 |
| MPI | OpenMPI 4.1.5 |
| CMake | 3.27 |
| Python | 3.10+ (for plotting) |

## Git Information

- **Repository:** https://github.com/Khawwash/HPC_MiniWeather_Project
- **Branch:** `riley-mpi-openmp-implementation`
- **Commit:** `b80dbd0`

## Output Files

After running experiments, check:
- `results/*.csv` - Performance data
- `results/*.png` - Plots
- `results/*.out` - SLURM job logs
- `results/perf_*.log` - Profiling data

## Troubleshooting

1. **Module not found:** Try `module spider gcc` to find available versions
2. **MPI error on login node:** Use `--oversubscribe` flag
3. **Job pending:** Check `squeue -u $USER` and partition limits with `sinfo`
4. **Build fails:** Ensure CMake 3.22+ and C++17 support
