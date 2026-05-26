#!/bin/bash
# =============================================================================
# Strong Scaling Test - Fixed Problem Size, Variable Ranks
# =============================================================================

#SBATCH --job-name=strong_scale
#SBATCH --output=results/strong_scaling_%j.out
#SBATCH --error=results/strong_scaling_%j.err
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --time=02:00:00

# Fixed problem size
NX=128
NY=128
NZ=128
STEPS=200

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_PROC_BIND=close
export OMP_PLACES=cores

# Load modules
module purge --force
module load gcc openmpi

cd $HOME/HPC_MiniWeather_Project/build
mkdir -p $HOME/HPC_MiniWeather_Project/results

RESULTS_FILE="$HOME/HPC_MiniWeather_Project/results/strong_scaling.csv"

echo "=== Strong Scaling Experiment ==="
echo "Fixed problem: ${NX}x${NY}x${NZ}, ${STEPS} steps"
echo ""

# Header
echo "experiment,nodes,ranks_per_node,total_ranks,threads,nx,ny,nz,steps,time_s,glups,efficiency" > ${RESULTS_FILE}

# Baseline: 1 node, 1 rank
echo "--- 1 node, 1 rank ---"
OUTPUT=$(srun -N1 -n1 ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} 2>&1)
TIME_BASE=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+')
GLUPS_BASE=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+')
echo "strong,1,1,1,${OMP_NUM_THREADS},${NX},${NY},${NZ},${STEPS},${TIME_BASE},${GLUPS_BASE},1.00" >> ${RESULTS_FILE}
echo "Time: ${TIME_BASE}s, GLUPS: ${GLUPS_BASE}"

# Scale up
for NODES in 1 2 4; do
    for RPN in 1 2 4; do
        TOTAL=$((NODES * RPN))
        if [ ${TOTAL} -gt 16 ]; then continue; fi
        if [ ${NODES} -eq 1 ] && [ ${RPN} -eq 1 ]; then continue; fi
        
        echo "--- ${NODES} nodes, ${RPN} ranks/node (${TOTAL} total) ---"
        OUTPUT=$(srun -N${NODES} -n${TOTAL} --ntasks-per-node=${RPN} \
            ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} 2>&1)
        
        TIME=$(echo "$OUTPUT" | grep -oP 'Time \K[0-9.]+')
        GLUPS=$(echo "$OUTPUT" | grep -oP 'GLUPS: \K[0-9.]+')
        
        # Calculate efficiency: (T_base / T_n) / n
        if [ -n "${TIME}" ] && [ -n "${TIME_BASE}" ]; then
            EFF=$(echo "scale=4; (${TIME_BASE} / ${TIME}) / ${TOTAL}" | bc)
        else
            EFF="N/A"
        fi
        
        echo "strong,${NODES},${RPN},${TOTAL},${OMP_NUM_THREADS},${NX},${NY},${NZ},${STEPS},${TIME},${GLUPS},${EFF}" >> ${RESULTS_FILE}
        echo "Time: ${TIME}s, GLUPS: ${GLUPS}, Efficiency: ${EFF}"
    done
done

echo ""
echo "Results saved to: ${RESULTS_FILE}"
