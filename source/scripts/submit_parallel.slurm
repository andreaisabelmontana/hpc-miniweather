#!/bin/bash
#SBATCH -J miniweather-parallel-cpu
#SBATCH --output=results/parallel%j.out
#SBATCH --error=results/parallel%j.err
#SBATCH --partition=node
##SBATCH -A user44
#SBATCH -N 2
#SBATCH --ntasks-per-node=2
#SBATCH --mem=1G
#SBATCH -t 00:10:00

cd $SLURM_SUBMIT_DIR

module purge
module load openmpi/4.1 gcc/12 cmake

mkdir -p build && cd build
cmake .. -DENABLE_MPI=ON -DENABLE_OPENMP=ON
make -j
cd ..

echo "PARALLEL EXECUTION"
srun ./build/miniweather --backend serial -nx 256 -ny 256 -nz 256 -t 10