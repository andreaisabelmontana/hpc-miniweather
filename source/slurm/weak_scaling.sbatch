#!/bin/bash
# =============================================================================
# Weak Scaling Test - Problem Size Grows with Ranks
# =============================================================================

#SBATCH --job-name=weak_scale
#SBATCH --output=results/weak_scaling_%j.out
#SBATCH --error=results/weak_scaling_%j.err
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --time=02:00:00

# Base problem size per rank
NX_BASE=64
NY_BASE=64
NZ_BASE=64
STEPS=200

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_PROC_BIND=close
export OMP_PLACES=cores

# Load modules
module purge --force
module load gcc openmpi

cd $HOME/HPC_MiniWeather_Project/build
mkdir -p $HOME/HPC_MiniWeather_Project/results

RESULTS_FILE="$HOME/HPC_MiniWeather_Project/results/weak_scaling.csv"

echo "=== Weak Scaling Experiment ==="
echo "Base problem per rank: ${NX_BASE}x${NY_BASE}x${NZ_BASE}"
echo ""

# Header
echo "experiment,nodes,ranks_per_node,total_ranks,threads,nx,ny,nz,steps,time_s,glups,efficiency" > ${RESULTS_FILE}

# Baseline: 1 rank
echo "--- 1 rank (baseline) ---"
OUTPUT=$(srun -N1 -n1 ./miniweather --nx ${NX_BASE} --ny ${NY_BASE} --nz ${NZ_BASE} --steps ${STEPS} 2>&1)
TIME_BASE=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+')
GLUPS_BASE=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+')
echo "weak,1,1,1,${OMP_NUM_THREADS},${NX_BASE},${NY_BASE},${NZ_BASE},${STEPS},${TIME_BASE},${GLUPS_BASE},1.00" >> ${RESULTS_FILE}
echo "Time: ${TIME_BASE}s, GLUPS: ${GLUPS_BASE}"

# Scale up: grow NZ with ranks (weak scaling in Z dimension)
for TOTAL in 2 4 8 16; do
    NZ_SCALED=$((NZ_BASE * TOTAL))
    
    # Determine node layout
    if [ ${TOTAL} -le 4 ]; then
        NODES=1
        RPN=${TOTAL}
    elif [ ${TOTAL} -le 8 ]; then
        NODES=2
        RPN=$((TOTAL / 2))
    else
        NODES=4
        RPN=$((TOTAL / 4))
    fi
    
    echo "--- ${TOTAL} ranks: ${NX_BASE}x${NY_BASE}x${NZ_SCALED} ---"
    OUTPUT=$(srun -N${NODES} -n${TOTAL} --ntasks-per-node=${RPN} \
        ./miniweather --nx ${NX_BASE} --ny ${NY_BASE} --nz ${NZ_SCALED} --steps ${STEPS} 2>&1)
    
    TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+')
    GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+')
    
    # Weak scaling efficiency: T_base / T_n (ideally = 1.0)
    if [ -n "${TIME}" ] && [ -n "${TIME_BASE}" ]; then
        EFF=$(echo "scale=4; ${TIME_BASE} / ${TIME}" | bc)
    else
        EFF="N/A"
    fi
    
    echo "weak,${NODES},${RPN},${TOTAL},${OMP_NUM_THREADS},${NX_BASE},${NY_BASE},${NZ_SCALED},${STEPS},${TIME},${GLUPS},${EFF}" >> ${RESULTS_FILE}
    echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Efficiency: ${EFF}"
done

echo ""
echo "Results saved to: ${RESULTS_FILE}"
