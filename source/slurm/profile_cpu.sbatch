#!/bin/bash
# =============================================================================
# CPU Profiling Script (perf / LIKWID)
# =============================================================================

#SBATCH --job-name=profile_cpu
#SBATCH --output=results/profile_cpu_%j.out
#SBATCH --error=results/profile_cpu_%j.err
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:30:00

NX=64
NY=64
NZ=64
STEPS=100

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

module purge --force
module load gcc openmpi

cd $HOME/HPC_MiniWeather_Project/build
mkdir -p $HOME/HPC_MiniWeather_Project/results

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="$HOME/HPC_MiniWeather_Project/results"

echo "=== CPU Profiling ==="
echo "Grid: ${NX}x${NY}x${NZ}, Steps: ${STEPS}"
echo "MPI ranks: ${SLURM_NTASKS}, OMP threads: ${OMP_NUM_THREADS}"
echo ""

# -----------------------------------------------------------------------------
# 1. Basic perf stat
# -----------------------------------------------------------------------------
echo "--- perf stat ---"
perf stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses \
    mpirun -np ${SLURM_NTASKS} ./miniweather \
    --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} \
    2>&1 | tee ${RESULTS_DIR}/perf_stat_${TIMESTAMP}.log

echo ""

# -----------------------------------------------------------------------------
# 2. perf record (sampling)
# -----------------------------------------------------------------------------
echo "--- perf record (sampling) ---"
perf record -g -o ${RESULTS_DIR}/perf_${TIMESTAMP}.data \
    mpirun -np ${SLURM_NTASKS} ./miniweather \
    --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS}

# Generate report
perf report -i ${RESULTS_DIR}/perf_${TIMESTAMP}.data --stdio \
    > ${RESULTS_DIR}/perf_report_${TIMESTAMP}.txt 2>&1

echo "perf report saved to: ${RESULTS_DIR}/perf_report_${TIMESTAMP}.txt"

# -----------------------------------------------------------------------------
# 3. LIKWID (if available)
# -----------------------------------------------------------------------------
if command -v likwid-perfctr &> /dev/null; then
    echo ""
    echo "--- LIKWID Memory Bandwidth ---"
    likwid-perfctr -g MEM -C 0-3 \
        mpirun -np 1 ./miniweather \
        --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} \
        2>&1 | tee ${RESULTS_DIR}/likwid_mem_${TIMESTAMP}.log
    
    echo ""
    echo "--- LIKWID FLOPS ---"
    likwid-perfctr -g FLOPS_DP -C 0-3 \
        mpirun -np 1 ./miniweather \
        --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} \
        2>&1 | tee ${RESULTS_DIR}/likwid_flops_${TIMESTAMP}.log
fi

echo ""
echo "=== Profiling Complete ==="
echo "Results in: ${RESULTS_DIR}"
