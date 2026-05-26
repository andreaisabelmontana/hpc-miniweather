#!/bin/bash
#SBATCH --job-name=miniWeather_CP
#SBATCH --output=$HOME/HPC_MiniWeather_Project/results/mpi_%j.out
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00

module purge --force
module load gcc
module load openmpi

# ensure output folder exists
mkdir -p $HOME/HPC_MiniWeather_Project/results

# move to the build folder
cd $HOME/HPC_MiniWeather_Project/build

# run MPI program
srun ./miniweather
