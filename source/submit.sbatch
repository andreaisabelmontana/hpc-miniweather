#!/bin/bash
# =============================================================================
# MiniWeather HPC - Main SLURM Submit Script
# =============================================================================
# Submit: sbatch submit.sbatch
# =============================================================================

#SBATCH --job-name=miniweather
#SBATCH --output=results/miniweather_%j.out
#SBATCH --error=results/miniweather_%j.err
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --time=01:00:00

# =============================================================================
# Configuration
# =============================================================================
# Grid size
NX=${NX:-128}
NY=${NY:-128}
NZ=${NZ:-128}
STEPS=${STEPS:-500}

# Parallelization
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_PROC_BIND=close
export OMP_PLACES=cores

# =============================================================================
# Environment Setup
# =============================================================================
echo "=== Job Information ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Nodes: ${SLURM_NNODES}"
echo "Tasks per node: ${SLURM_NTASKS_PER_NODE}"
echo "CPUs per task: ${SLURM_CPUS_PER_TASK}"
echo "Total MPI ranks: ${SLURM_NTASKS}"
echo "OMP threads: ${OMP_NUM_THREADS}"
echo ""

# Load modules
module purge --force
module load gcc/12.3 || module load gcc
module load openmpi/4.1.5 || module load openmpi

# Create results directory
mkdir -p $HOME/HPC_MiniWeather_Project/results

# Move to build directory
cd $HOME/HPC_MiniWeather_Project/build

# =============================================================================
# Run Application
# =============================================================================
echo "=== Running MiniWeather ==="
echo "Grid: ${NX} x ${NY} x ${NZ}"
echo "Steps: ${STEPS}"
echo ""

srun ./miniweather --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS}

echo ""
echo "=== Job Complete ==="
echo "End time: $(date)"

# =============================================================================
# Collect Job Statistics
# =============================================================================
echo ""
echo "=== Job Statistics ==="
sacct -j ${SLURM_JOB_ID} --format=JobID,JobName,Partition,NNodes,NTasks,NCPUS,MaxRSS,Elapsed,State
