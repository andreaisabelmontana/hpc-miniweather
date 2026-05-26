# EuroHPC Development Access Proposal

## MiniWeather 3D Stencil: Scaling Weather Simulation Kernels to Exascale

**Project Acronym:** MINIW-SCALE  
**Principal Investigator:** [Name]  
**Institution:** [University/Organization]  
**Requested System:** [LUMI / Leonardo / MareNostrum 5]  
**Requested Resources:** [X] GPU-node-hours  

---

## 1. Abstract (300 words max)

Weather and climate prediction are critical for societal resilience, requiring computational capabilities that push the boundaries of current HPC systems. This proposal seeks Development Access to [TARGET_SYSTEM] to optimize and scale our MiniWeather 3D stencil code, a representative kernel for atmospheric simulations.

Our prototype implements a 7-point stencil computation using hybrid MPI+OpenMP parallelization with GPU acceleration via CUDA/HIP. Initial results on our institutional cluster demonstrate [X] GLUPS throughput on [Y] GPU nodes with [Z]% parallel efficiency. However, scaling beyond [N] nodes reveals communication bottlenecks that require optimization on a production EuroHPC system.

The objectives of this Development Access are:
1. Port and optimize our code for [AMD MI250X / NVIDIA A100] GPUs
2. Achieve >80% weak scaling efficiency up to 64 GPU nodes
3. Implement advanced optimizations (temporal blocking, GPU-aware MPI)
4. Generate performance data for a future Regular Access proposal

This work directly supports the European Green Deal by improving the efficiency of climate simulation codes that inform policy decisions. The optimized code will be released as open-source, benefiting the broader computational climate science community.

**Keywords:** stencil computation, GPU computing, MPI, weather simulation, performance optimization

---

## 2. State of the Art

### 2.1 Scientific Context

Numerical weather prediction (NWP) and climate modeling solve systems of partial differential equations on structured grids. The core computational kernel—stencil updates—accounts for 60-80% of execution time in production codes like IFS (ECMWF), ICON (DWD), and WRF.

### 2.2 Technical Challenges

Modern stencil codes face several challenges on GPU-accelerated systems:

1. **Memory bandwidth limitation**: Stencil operations have low arithmetic intensity (1-2 FLOPS/byte), making them memory-bound
2. **Communication overhead**: Halo exchange between domains creates synchronization barriers
3. **GPU utilization**: Small local domains may not saturate GPU compute capacity
4. **Portability**: Different GPU architectures (NVIDIA, AMD, Intel) require different optimization strategies

### 2.3 Related Work

| Code | Parallelization | Peak Performance |
|------|-----------------|------------------|
| miniWeather | MPI+OpenMP+OpenACC | ~5 GLUPS (V100) |
| Stella | MPI+CUDA | ~15 GLUPS (A100) |
| GridTools | MPI+CUDA/HIP | ~20 GLUPS (A100) |

Our implementation builds on miniWeather while incorporating advanced optimizations from Stella and GridTools research.

---

## 3. Technical Approach

### 3.1 Current Implementation (TRL 4)

Our prototype includes:
- 7-point stencil with configurable grid sizes
- MPI domain decomposition (1D in Z-dimension)
- OpenMP threading with SIMD vectorization
- CUDA/HIP GPU kernels (naive and shared-memory variants)
- Non-blocking halo exchange
- Comprehensive timing instrumentation

**Performance on institutional cluster:**
- CPU: [X] GLUPS on [Y] nodes (Intel Xeon / AMD EPYC)
- GPU: [X] GLUPS on [Y] NVIDIA V100/A100

### 3.2 Proposed Optimizations

| Optimization | Expected Improvement | Implementation Effort |
|--------------|---------------------|----------------------|
| 2D domain decomposition | 20-30% scaling | Medium |
| Temporal blocking | 15-25% compute | High |
| GPU-aware MPI | 30-40% communication | Medium |
| Mixed precision (FP32/FP16) | 50-100% throughput | Low |
| Kernel fusion | 10-20% memory BW | Medium |

### 3.3 Target Architecture

**Primary target:** [LUMI-G / Leonardo Booster / MareNostrum 5 ACC]
- GPU: [AMD MI250X / NVIDIA A100 / Intel PVC]
- Interconnect: [Slingshot-11 / InfiniBand HDR / ...]
- Software: [ROCm / CUDA / oneAPI]

### 3.4 Portability Strategy

We use preprocessor-based abstraction for GPU portability:
```cpp
#ifdef MINIW_CUDA
  // CUDA implementation
#elif defined(MINIW_HIP)  
  // HIP implementation
#elif defined(MINIW_SYCL)
  // SYCL implementation
#endif
```

---

## 4. Work Plan

### 4.1 Timeline (3 months)

| Month | Tasks | Deliverables |
|-------|-------|--------------|
| 1 | Port to target system, baseline benchmarks | Performance report |
| 2 | Implement optimizations, profiling | Optimized kernels |
| 3 | Scaling experiments, documentation | Final report, code release |

### 4.2 Milestones

| ID | Milestone | Success Criteria | Month |
|----|-----------|------------------|-------|
| M1 | Code runs on target system | Clean build, correct output | 1 |
| M2 | Single-node optimization | >50% of roofline | 1 |
| M3 | Multi-node scaling | >70% efficiency at 16 nodes | 2 |
| M4 | Large-scale tests | >60% efficiency at 64 nodes | 3 |

### 4.3 Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Compiler issues | Medium | High | Use vendor-supported toolchains |
| Scaling bottleneck | High | Medium | Implement multiple decomposition strategies |
| Queue wait times | Low | Medium | Submit jobs during off-peak hours |

---

## 5. Resource Justification

### 5.1 Computational Requirements

| Phase | Nodes | Time/Run | Runs | Total Node-Hours |
|-------|-------|----------|------|------------------|
| Porting & debugging | 1-4 | 1h | 50 | 100 |
| Single-node optimization | 1 | 2h | 30 | 60 |
| Profiling (Nsight/rocprof) | 1-4 | 1h | 20 | 40 |
| Strong scaling (1-64 nodes) | 1-64 | 0.5h | 40 | 500 |
| Weak scaling (1-64 nodes) | 1-64 | 0.5h | 40 | 500 |
| Final production runs | 64 | 2h | 10 | 1280 |
| **Total** | | | | **2480** |

**Requested:** 2,500 GPU-node-hours (with 10% contingency)

### 5.2 Storage Requirements

- Code and configuration: <1 GB
- Output data per run: ~100 MB
- Profiling data: ~10 GB total
- **Total storage:** <50 GB

### 5.3 Support Requirements

- Access to vendor profiling tools (Nsight Systems/Compute or rocprof)
- Technical support for GPU-aware MPI configuration
- Documentation for system-specific optimizations

---

## 6. Data Management and FAIR Principles

### 6.1 Data Generation

- Performance metrics (CSV): timing, throughput, efficiency
- Profiling reports: kernel analysis, memory bandwidth
- Scaling plots: PNG/SVG visualizations

### 6.2 FAIR Compliance

| Principle | Implementation |
|-----------|---------------|
| **Findable** | Data deposited in Zenodo with DOI |
| **Accessible** | Open access, CC-BY license |
| **Interoperable** | Standard formats (CSV, JSON, HDF5) |
| **Reusable** | Complete metadata, reproducible scripts |

### 6.3 Code Availability

- Repository: GitHub (public after publication)
- License: MIT or Apache 2.0
- Documentation: README, API docs, build instructions

---

## 7. Ethical Considerations

This project involves:
- ☐ Personal data: **No**
- ☐ Dual-use research: **No**
- ☐ Environmental impact: **Minimal** (optimized code reduces future energy consumption)
- ☑ Open science: **Yes** (code and data will be publicly released)

---

## 8. Expected Impact

### 8.1 Scientific Impact

- Demonstrate optimization strategies for stencil codes on EuroHPC systems
- Provide performance baseline for climate/weather code developers
- Contribute to portable GPU programming best practices

### 8.2 Societal Impact

- Enable more efficient weather and climate simulations
- Support European Green Deal through computational efficiency
- Train next-generation HPC developers

### 8.3 Dissemination Plan

| Activity | Timeline | Audience |
|----------|----------|----------|
| Technical report | Month 3 | HPC community |
| Conference presentation (SC/ISC) | Month 6 | Researchers |
| Open-source release | Month 3 | Developers |
| Tutorial/workshop | Month 6 | Students |

---

## 9. Team Qualifications

| Name | Role | Expertise |
|------|------|-----------|
| [PI Name] | Project Lead | HPC, parallel algorithms |
| [Member 2] | GPU Developer | CUDA/HIP, optimization |
| [Member 3] | MPI Expert | Distributed computing |
| [Member 4] | Performance Analyst | Profiling, roofline |

### 9.1 Relevant Experience

- [List previous HPC projects, publications, allocations]

---

## 10. References

1. Norman, M. R. (2020). miniWeather: A mini-app to introduce students to HPC programming.
2. Gysi, T., et al. (2015). STELLA: A domain-specific tool for structured grid methods.
3. Williams, S., et al. (2009). Roofline: An insightful visual performance model.
4. [Additional references]

---

## Appendix A: Code Repository

**URL:** https://github.com/[username]/HPC_MiniWeather_Project

**Build instructions:**
```bash
git clone https://github.com/[username]/HPC_MiniWeather_Project.git
cd HPC_MiniWeather_Project
module load [system-specific-modules]
cmake -B build -DENABLE_MPI=ON -DENABLE_HIP=ON
cmake --build build
srun -N 4 --gpus-per-node=4 ./build/miniweather --nx 256 --ny 256 --nz 256 --steps 1000
```

## Appendix B: Preliminary Results

[Insert scaling plots from institutional cluster]

## Appendix C: Letters of Support

[If applicable]
