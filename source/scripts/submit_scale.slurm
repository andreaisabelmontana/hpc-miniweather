#!/bin/bash
#SBATCH -J miniweather-scaling-cpu
#SBATCH --output=results/scaling%j.out
#SBATCH --error=results/scaling%j.err
#SBATCH --partition=node
#SBATCH -N 4
#SBATCH --ntasks=4
#SBATCH --mem-per-cpu=512M
#SBATCH -t 00:15:00

cd $SLURM_SUBMIT_DIR

module purge
module load openmpi/4.1 gcc/12 cmake

if [ ! -f build/miniweather ]; then
    mkdir -p build && cd build
    cmake .. -DENABLE_MPI=ON -DENABLE_OPENMP=ON
    make -j
    cd ..
fi

echo "Test 3: 16 ranks (4 nodes)"
srun -N 4 -n 16 ./build/miniweather --backend parallel -nx 64 -ny 64 -nz 64 -t 10