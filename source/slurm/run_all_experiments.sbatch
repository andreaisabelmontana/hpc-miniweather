#!/bin/bash
# =============================================================================
# Complete Experiment Suite for MiniWeather HPC
# Runs: Strong scaling, Weak scaling, Sensitivity, Optimization comparison
# =============================================================================

#SBATCH --job-name=all_experiments
#SBATCH --output=results/all_experiments_%j.out
#SBATCH --error=results/all_experiments_%j.err
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --time=01:00:00

# Setup
module purge --force
module load gcc openmpi

cd $HOME/HPC_MiniWeather_Project/build
mkdir -p $HOME/HPC_MiniWeather_Project/results

export OMP_NUM_THREADS=2
export OMP_PROC_BIND=close

RESULTS_DIR="$HOME/HPC_MiniWeather_Project/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=============================================="
echo "MiniWeather HPC - Complete Experiment Suite"
echo "Timestamp: ${TIMESTAMP}"
echo "=============================================="
echo ""

# =============================================================================
# 1. STRONG SCALING: Fixed problem size, increase ranks
# =============================================================================
echo "=== 1. STRONG SCALING ==="
echo "Fixed problem: 128x128x128, 200 steps"
echo ""

STRONG_FILE="${RESULTS_DIR}/strong_scaling_${TIMESTAMP}.csv"
echo "experiment,nodes,total_ranks,threads,nx,ny,nz,steps,time_s,glups,speedup,efficiency" > ${STRONG_FILE}

# Baseline: 1 rank
echo "--- 1 rank (baseline) ---"
OUTPUT=$(srun -N1 -n1 --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 200 2>&1)
TIME_BASE=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS_BASE=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
echo "strong,1,1,2,128,128,128,200,${TIME_BASE},${GLUPS_BASE},1.00,1.00" >> ${STRONG_FILE}
echo "Time: ${TIME_BASE}s, GLUPS: ${GLUPS_BASE}"

# 2 ranks
echo "--- 2 ranks ---"
OUTPUT=$(srun -N2 -n2 --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 200 2>&1)
TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
SPEEDUP=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc 2>/dev/null || echo "N/A")
EFF=$(echo "scale=4; ${SPEEDUP} / 2" | bc 2>/dev/null || echo "N/A")
echo "strong,2,2,2,128,128,128,200,${TIME},${GLUPS},${SPEEDUP},${EFF}" >> ${STRONG_FILE}
echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Speedup: ${SPEEDUP}, Efficiency: ${EFF}"

# 4 ranks
echo "--- 4 ranks ---"
OUTPUT=$(srun -N4 -n4 --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 200 2>&1)
TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
SPEEDUP=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc 2>/dev/null || echo "N/A")
EFF=$(echo "scale=4; ${SPEEDUP} / 4" | bc 2>/dev/null || echo "N/A")
echo "strong,4,4,2,128,128,128,200,${TIME},${GLUPS},${SPEEDUP},${EFF}" >> ${STRONG_FILE}
echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Speedup: ${SPEEDUP}, Efficiency: ${EFF}"

echo ""
echo "Strong scaling results: ${STRONG_FILE}"
echo ""

# =============================================================================
# 2. WEAK SCALING: Problem grows with ranks (constant work per rank)
# =============================================================================
echo "=== 2. WEAK SCALING ==="
echo "Base problem per rank: 64x64x64"
echo ""

WEAK_FILE="${RESULTS_DIR}/weak_scaling_${TIMESTAMP}.csv"
echo "experiment,nodes,total_ranks,threads,nx,ny,nz,total_points,steps,time_s,glups,efficiency" > ${WEAK_FILE}

# Baseline: 1 rank, 64^3
echo "--- 1 rank: 64x64x64 ---"
OUTPUT=$(srun -N1 -n1 --exclusive ./miniweather --nx 64 --ny 64 --nz 64 --steps 200 2>&1)
TIME_BASE=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS_BASE=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
POINTS=$((64*64*64))
echo "weak,1,1,2,64,64,64,${POINTS},200,${TIME_BASE},${GLUPS_BASE},1.00" >> ${WEAK_FILE}
echo "Time: ${TIME_BASE}s, GLUPS: ${GLUPS_BASE}"

# 2 ranks: 64x64x128 (double Z)
echo "--- 2 ranks: 64x64x128 ---"
OUTPUT=$(srun -N2 -n2 --exclusive ./miniweather --nx 64 --ny 64 --nz 128 --steps 200 2>&1)
TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
EFF=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc 2>/dev/null || echo "N/A")
POINTS=$((64*64*128))
echo "weak,2,2,2,64,64,128,${POINTS},200,${TIME},${GLUPS},${EFF}" >> ${WEAK_FILE}
echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Efficiency: ${EFF}"

# 4 ranks: 64x64x256 (4x Z)
echo "--- 4 ranks: 64x64x256 ---"
OUTPUT=$(srun -N4 -n4 --exclusive ./miniweather --nx 64 --ny 64 --nz 256 --steps 200 2>&1)
TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
EFF=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc 2>/dev/null || echo "N/A")
POINTS=$((64*64*256))
echo "weak,4,4,2,64,64,256,${POINTS},200,${TIME},${GLUPS},${EFF}" >> ${WEAK_FILE}
echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Efficiency: ${EFF}"

echo ""
echo "Weak scaling results: ${WEAK_FILE}"
echo ""

# =============================================================================
# 3. SENSITIVITY ANALYSIS: Grid size sweep (parameter study)
# =============================================================================
echo "=== 3. SENSITIVITY ANALYSIS: Grid Size Sweep ==="
echo "Varying grid size with fixed 2 ranks, 100 steps"
echo ""

SENS_FILE="${RESULTS_DIR}/sensitivity_gridsize_${TIMESTAMP}.csv"
echo "experiment,grid_size,nx,ny,nz,total_points,steps,time_s,glups,points_per_second" > ${SENS_FILE}

for SIZE in 32 48 64 96 128; do
    echo "--- Grid: ${SIZE}^3 ---"
    OUTPUT=$(srun -N2 -n2 --exclusive ./miniweather --nx ${SIZE} --ny ${SIZE} --nz ${SIZE} --steps 100 2>&1)
    TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
    GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
    POINTS=$((SIZE*SIZE*SIZE))
    PPS=$(echo "scale=2; ${POINTS} * 100 / ${TIME}" | bc 2>/dev/null || echo "N/A")
    echo "sensitivity,${SIZE},${SIZE},${SIZE},${SIZE},${POINTS},100,${TIME},${GLUPS},${PPS}" >> ${SENS_FILE}
    echo "Grid: ${SIZE}^3, Time: ${TIME}s, GLUPS: ${GLUPS}"
done

echo ""
echo "Sensitivity results: ${SENS_FILE}"
echo ""

# =============================================================================
# 4. OPTIMIZATION COMPARISON: OpenMP thread scaling
# =============================================================================
echo "=== 4. OPTIMIZATION: OpenMP Thread Scaling ==="
echo "Fixed 2 MPI ranks, varying OMP threads"
echo ""

OPT_FILE="${RESULTS_DIR}/optimization_threads_${TIMESTAMP}.csv"
echo "experiment,ranks,omp_threads,total_threads,nx,ny,nz,steps,time_s,glups,speedup" > ${OPT_FILE}

# Baseline: 1 thread per rank
echo "--- 1 OMP thread per rank ---"
export OMP_NUM_THREADS=1
OUTPUT=$(srun -N2 -n2 --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 100 2>&1)
TIME_BASE=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
echo "optimization,2,1,2,128,128,128,100,${TIME_BASE},${GLUPS},1.00" >> ${OPT_FILE}
echo "OMP=1: Time: ${TIME_BASE}s, GLUPS: ${GLUPS}"

# 2 threads per rank
echo "--- 2 OMP threads per rank ---"
export OMP_NUM_THREADS=2
OUTPUT=$(srun -N2 -n2 --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 100 2>&1)
TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+' | head -1)
GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+' | head -1)
SPEEDUP=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc 2>/dev/null || echo "N/A")
echo "optimization,2,2,4,128,128,128,100,${TIME},${GLUPS},${SPEEDUP}" >> ${OPT_FILE}
echo "OMP=2: Time: ${TIME}s, GLUPS: ${GLUPS}, Speedup: ${SPEEDUP}"

echo ""
echo "Optimization results: ${OPT_FILE}"
echo ""

# =============================================================================
# 5. TIMER BREAKDOWN ANALYSIS
# =============================================================================
echo "=== 5. TIMER BREAKDOWN ==="
echo ""

TIMER_FILE="${RESULTS_DIR}/timer_breakdown_${TIMESTAMP}.csv"
echo "ranks,interior_s,halo_s,boundary_s,total_s,interior_pct,halo_pct,comm_overhead_pct" > ${TIMER_FILE}

for RANKS in 1 2 4; do
    NODES=${RANKS}
    echo "--- ${RANKS} ranks ---"
    OUTPUT=$(srun -N${NODES} -n${RANKS} --exclusive ./miniweather --nx 128 --ny 128 --nz 128 --steps 100 2>&1)
    
    INTERIOR=$(echo "$OUTPUT" | grep "Interior:" | awk '{print $2}')
    HALO=$(echo "$OUTPUT" | grep "Halo:" | awk '{print $2}')
    BOUNDARY=$(echo "$OUTPUT" | grep "Boundary:" | awk '{print $2}')
    TOTAL=$(echo "$OUTPUT" | grep "Total:" | awk '{print $2}')
    
    if [ -n "${TOTAL}" ] && [ "${TOTAL}" != "0" ]; then
        INT_PCT=$(echo "scale=2; ${INTERIOR} / ${TOTAL} * 100" | bc 2>/dev/null || echo "N/A")
        HALO_PCT=$(echo "scale=2; ${HALO} / ${TOTAL} * 100" | bc 2>/dev/null || echo "N/A")
        COMM_PCT=${HALO_PCT}
    else
        INT_PCT="N/A"
        HALO_PCT="N/A"
        COMM_PCT="N/A"
    fi
    
    echo "${RANKS},${INTERIOR},${HALO},${BOUNDARY},${TOTAL},${INT_PCT},${HALO_PCT},${COMM_PCT}" >> ${TIMER_FILE}
    echo "Ranks: ${RANKS}, Interior: ${INT_PCT}%, Halo: ${HALO_PCT}%"
done

echo ""
echo "Timer breakdown: ${TIMER_FILE}"
echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo "=============================================="
echo "EXPERIMENT SUITE COMPLETE"
echo "=============================================="
echo ""
echo "Output files:"
echo "  - Strong scaling: ${STRONG_FILE}"
echo "  - Weak scaling:   ${WEAK_FILE}"
echo "  - Sensitivity:    ${SENS_FILE}"
echo "  - Optimization:   ${OPT_FILE}"
echo "  - Timer breakdown: ${TIMER_FILE}"
echo ""
echo "Next steps:"
echo "  python3 scripts/plot_results.py"
echo ""
