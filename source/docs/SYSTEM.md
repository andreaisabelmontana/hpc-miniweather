# System Configuration

**MiniWeather HPC Project - System Documentation**

## Cluster Information

| Property | Value |
|----------|-------|
| **Cluster Name** | Magic Castle (Academic HPC) |
| **Login Node** | `login1` |
| **Job Scheduler** | Slurm Workload Manager |
| **Operating System** | AlmaLinux 9.6 (Sage Margay) |
| **Kernel Version** | 5.14.0-570.41.1.el9_6.x86_64 |

## Node Types

### CPU Nodes (`node[1-8]`)
| Property | Value |
|----------|-------|
| Count | 8 nodes |
| CPU | Intel Xeon Platinum 8473C |
| Cores per Node | 2 (partition limit) |
| Memory | ~16 GB per node |
| Partition | `cpubase_bycore_b1` (default), `node` |

### GPU Nodes (`gpu-node[1-2]`)
| Property | Value |
|----------|-------|
| Count | 2 nodes |
| CPU | Intel Xeon Platinum 8473C |
| GPU | NVIDIA (available for GPU workloads) |
| Partition | `gpu-node` |

## Software Environment

### Loaded Modules
```
Currently Loaded Modules:
  1) CCconfig               6) flexiblas/3.3.1       11) pmix/4.2.4
  2) gentoo/2023            7) gcccore/.12.3         12) ucc/1.2.0
  3) imkl/2023.2.0          8) hwloc/2.9.1           13) openmpi/4.1.5
  4) StdEnv/2023            9) ucx/1.14.1
  5) gcc/12.3              10) libfabric/1.18.0
```

### Compiler & Runtime Versions
| Component | Version |
|-----------|---------|
| **GCC** | 12.3.1 20230526 (Gentoo) |
| **CMake** | 3.27.7 |
| **OpenMPI** | 4.1.5 |
| **Intel MKL** | 2023.2.0 |
| **UCX** | 1.14.1 |
| **libfabric** | 1.18.0 |

### Module Load Commands
```bash
module purge
module load StdEnv/2023
module load gcc/12.3
module load openmpi/4.1.5
module load cmake/3.27.7
```

## Build Configuration

### CMake Options
```bash
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++ \
  -DENABLE_MPI=ON \
  -DENABLE_OPENMP=ON
```

### Compiler Flags
- **Optimization**: `-O3 -march=native`
- **OpenMP**: `-fopenmp`
- **MPI**: Provided by `mpicxx` wrapper

## Runtime Environment

### Environment Variables
```bash
export OMP_NUM_THREADS=2          # Threads per MPI rank
export OMP_PROC_BIND=close        # Thread binding
export OMP_PLACES=cores           # Thread placement
```

### Slurm Resource Limits
| Resource | Limit |
|----------|-------|
| Max CPUs per node | 2 |
| Max Memory per job | 4 GB |
| Default Partition | `cpubase_bycore_b1` |
| Time Limit | Unlimited |

## Network Interconnect

- **Fabric**: libfabric 1.18.0
- **Transport**: UCX 1.14.1 (Unified Communication X)
- **MPI Implementation**: Open MPI 4.1.5 with PMIx 4.2.4

## Reproducibility Notes

1. **Module Consistency**: Always load `StdEnv/2023` first to ensure consistent environment
2. **MPI Binding**: Use `--map-by core` for optimal thread placement
3. **Oversubscription**: Use `--oversubscribe` when testing with more ranks than available cores
4. **Scratch Space**: Clean `/scratch` after jobs to respect fair-use policy

---
*Document generated: December 2024*
*Cluster: Magic Castle Academic HPC*
