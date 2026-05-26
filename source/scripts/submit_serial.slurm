#!/bin/bash
#SBATCH -J miniweather-serial-cpu
#SBATCH --output=results/serial_%j.out
#SBATCH --error=results/serial_%j.err
#SBATCH --partition=node
##SBATCH -A user44
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1G
#SBATCH -t 00:10:00

cd $SLURM_SUBMIT_DIR

module purge
module load openmpi/4.1 gcc/12 cmake

mkdir -p build && cd build
cmake .. -DENABLE_MPI=ON -DENABLE_OPENMP=ON
make -j
cd ..

echo "SERIAL EXECUTION"
./build/miniweather --backend serial -nx 256 -ny 256 -nz 256 -t 10