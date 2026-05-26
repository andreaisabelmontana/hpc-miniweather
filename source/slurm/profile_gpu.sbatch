#!/bin/bash
# =============================================================================
# GPU Profiling Script (Nsight Systems / Nsight Compute)
# =============================================================================

#SBATCH --job-name=profile_gpu
#SBATCH --output=results/profile_gpu_%j.out
#SBATCH --error=results/profile_gpu_%j.err
#SBATCH --partition=gpubase_a100_full
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=00:30:00

NX=128
NY=128
NZ=128
STEPS=100

module purge --force
module load gcc cuda openmpi

cd $HOME/HPC_MiniWeather_Project/build
mkdir -p $HOME/HPC_MiniWeather_Project/results

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="$HOME/HPC_MiniWeather_Project/results"

echo "=== GPU Profiling ==="
echo "Grid: ${NX}x${NY}x${NZ}, Steps: ${STEPS}"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
echo ""

# -----------------------------------------------------------------------------
# 1. nvidia-smi monitoring (background)
# -----------------------------------------------------------------------------
nvidia-smi dmon -s pucvmet -d 1 > ${RESULTS_DIR}/nvidia_smi_${TIMESTAMP}.log &
NVMON_PID=$!

# -----------------------------------------------------------------------------
# 2. Nsight Systems (timeline profiling)
# -----------------------------------------------------------------------------
echo "--- Nsight Systems ---"
if command -v nsys &> /dev/null; then
    nsys profile \
        --output=${RESULTS_DIR}/nsys_${TIMESTAMP} \
        --trace=cuda,mpi,nvtx \
        --force-overwrite=true \
        ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS}
    
    # Export stats
    nsys stats ${RESULTS_DIR}/nsys_${TIMESTAMP}.nsys-rep \
        > ${RESULTS_DIR}/nsys_stats_${TIMESTAMP}.txt 2>&1
    
    echo "Nsight Systems report: ${RESULTS_DIR}/nsys_${TIMESTAMP}.nsys-rep"
else
    echo "Nsight Systems not available, running normally..."
    ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS}
fi

# -----------------------------------------------------------------------------
# 3. Nsight Compute (kernel analysis) - single kernel
# -----------------------------------------------------------------------------
echo ""
echo "--- Nsight Compute (kernel analysis) ---"
if command -v ncu &> /dev/null; then
    ncu --set full \
        --target-processes all \
        --launch-count 3 \
        --output ${RESULTS_DIR}/ncu_${TIMESTAMP} \
        ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps 10
    
    echo "Nsight Compute report: ${RESULTS_DIR}/ncu_${TIMESTAMP}.ncu-rep"
fi

# Stop nvidia-smi monitoring
kill $NVMON_PID 2>/dev/null

echo ""
echo "=== GPU Profiling Complete ==="
echo "Results in: ${RESULTS_DIR}"
