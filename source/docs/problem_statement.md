# MiniWeather HPC - Problem Statement

## Problem Statement (200 words)

Weather and climate simulations require solving partial differential equations on massive 3D grids, consuming millions of compute hours annually on supercomputers. The core computational kernel—the stencil update—accounts for 60-80% of runtime in production codes like ECMWF's IFS and NOAA's GFS. Despite their simple structure, stencil computations are notoriously difficult to optimize due to their memory-bound nature (low arithmetic intensity of ~1 FLOP/byte) and communication requirements between distributed domains.

Our project implements a portable, high-performance 3D 7-point stencil code using hybrid MPI+OpenMP parallelization, representative of real weather model kernels. We target the Magic Castle cluster with 6-8 CPU nodes and optional GPU acceleration via CUDA/HIP. The code features domain decomposition with non-blocking halo exchange, cache-blocking optimizations, and comprehensive performance instrumentation.

This work directly supports climate science by demonstrating optimization techniques applicable to production codes, while providing a teaching vehicle for HPC concepts including parallel scaling, memory hierarchy optimization, and performance analysis using roofline models.

## Success Metrics

| Metric | Target | Achieved |
|--------|--------|----------|
| Strong scaling efficiency (2 ranks) | >60% | **66.8%** ✓ |
| Weak scaling efficiency (8 ranks) | >80% | **98.0%** ✓ |
| MPI communication overhead | <20% | **1.5%** ✓ |
| Measurable optimization impact | >10% | **34%** (MPI speedup) ✓ |
| Reproducible build & run | Yes | **Yes** ✓ |
| Documentation complete | Yes | **Yes** ✓ |

## Key Deliverables

1. ✅ Working MPI+OpenMP stencil code
2. ✅ Strong & weak scaling experiments  
3. ✅ CPU profiling with perf
4. ✅ Sensitivity analysis (tile size)
5. ✅ Performance plots (PNG)
6. ✅ Short paper with results
7. ✅ EuroHPC proposal template
8. ✅ 5-slide pitch outline
9. ✅ Reproducibility guide
