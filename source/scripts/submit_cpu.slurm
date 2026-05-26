#!/bin/bash
# SLURM job template for CPU runs
# Edit account/partition/nodes/ntasks as required by your cluster
# Usage: sbatch submit_cpu.slurm

#SBATCH --job-name=miniweather-cpu
#SBATCH --output=miniweather-cpu.%j.out
#SBATCH --error=miniweather-cpu.%j.err
#SBATCH --partition=standard
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

## Load modules as needed (adjust to your cluster)
# module purge
# module load gcc/12 openmpi/4.1

echo "Starting CPU job on $(hostname)"
cd "$SLURM_SUBMIT_DIR"
srun ./build/miniweather
