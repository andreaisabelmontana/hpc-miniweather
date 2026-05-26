# Module suggestions for cluster environments

This file lists example module commands.

CPU build example (GCC + OpenMPI):

	module purge
	module load gcc/12.2.0 openmpi/4.1.4 cmake/3.22

GPU build example (CUDA + GCC):

	module purge
	module load gcc/12.2.0 cuda/12.0.0 openmpi/4.1.4 cmake/3.22

ROCm / HIP example:

	module purge
	module load rocm/5.7.0 openmpi/4.1.4 cmake/3.22

Adjust specific module names/versions to your site.
