#!/bin/bash
# SLURM job template for GPU runs
# Edit account/partition/gres as required by your cluster
# Usage: sbatch submit_gpu.slurm

#SBATCH --job-name=miniweather-gpu
#SBATCH --output=miniweather-gpu.%j.out
#SBATCH --error=miniweather-gpu.%j.err
#SBATCH --partition=gpu
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --mem=64G

## Load modules (CUDA/ROCm) as needed
# module purge
# module load cuda/12/0 gcc/12 openmpi/4.1

echo "Starting GPU job on $(hostname)"
srun ./miniweather
