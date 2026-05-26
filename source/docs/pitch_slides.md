# MiniWeather HPC - Pitch Slides Outline

## 5-Minute Presentation (5 Slides)

---

## Slide 1: Problem & Impact

### Title: Accelerating Weather Simulation Kernels

**The Challenge:**
- Weather/climate models consume millions of CPU-hours annually
- 7-point stencil computations are the bottleneck (60-80% runtime)
- Memory-bound: limited by bandwidth, not compute

**Why It Matters:**
- Climate change demands faster, higher-resolution simulations
- 10x speedup → 10x more scenarios analyzed
- Direct support for European Green Deal

**Visual:** Globe with weather patterns + HPC cluster image

---

## Slide 2: Approach & Prototype

### Title: MiniWeather: A Portable HPC Stencil Code

**Our Solution:**
```
MPI (distributed) × OpenMP (shared) × GPU (accelerated)
```

**Key Features:**
- 7-point 3D stencil with halo exchange
- Domain decomposition in Z-dimension
- Cache-blocked CPU variant
- CUDA/HIP GPU kernels

**Code Quality:**
- CMake build system
- Modular architecture
- CI/CD pipeline
- Reproducible via Apptainer

**Visual:** Architecture diagram showing MPI ranks, OpenMP threads, GPU

---

## Slide 3: Scaling & Profiling Results

### Title: Performance Analysis

**Strong Scaling (128³ grid):**

| Ranks | Time (s) | Speedup | Efficiency |
|-------|----------|---------|------------|
| 1     | X.XX     | 1.00    | 100%       |
| 4     | X.XX     | X.XX    | XX%        |
| 8     | X.XX     | X.XX    | XX%        |
| 16    | X.XX     | X.XX    | XX%        |

**Throughput:** X.X GLUPS (CPU) / X.X GLUPS (GPU)

**Bottleneck Analysis:**
- 70% interior compute
- 20% halo exchange  
- 10% other

**Visual:** Scaling plot + timer breakdown pie chart

---

## Slide 4: EuroHPC Target & Resource Ask

### Title: Scaling to [LUMI / Leonardo]

**Target System:** LUMI-G (AMD MI250X GPUs)

**Why EuroHPC:**
- Need 64+ GPU nodes for production scaling
- Access to latest GPU architecture
- High-bandwidth interconnect essential

**Resource Request:**
- 2,500 GPU-node-hours
- 3-month Development Access
- Storage: 50 GB

**Expected Outcome:**
- >80% weak scaling efficiency at 64 nodes
- >15 GLUPS sustained throughput
- Open-source optimized code release

**Visual:** LUMI system photo + performance projection chart

---

## Slide 5: Risks, Milestones & Support

### Title: Path to Success

**Milestones:**

| Month | Goal | Deliverable |
|-------|------|-------------|
| 1 | Port & baseline | Working code on LUMI |
| 2 | Optimize | 2x speedup |
| 3 | Scale & publish | Paper + code release |

**Risks & Mitigations:**

| Risk | Mitigation |
|------|------------|
| AMD GPU porting issues | Use HIP compatibility layer |
| Communication bottleneck | GPU-aware MPI, overlap |
| Queue delays | Off-peak submissions |

**Support Needed:**
- Technical guidance on GPU-aware MPI
- Access to Nsight/rocprof profiling
- 1 hour consultation with system experts

**Call to Action:**
- Code ready: github.com/[repo]
- Team experienced in HPC
- Clear path to scientific impact

**Visual:** Timeline graphic + team photo

---

## Backup Slides

### B1: Roofline Analysis
[Roofline plot showing memory-bound nature]

### B2: Code Snippets
[Key kernel code]

### B3: Detailed Timer Breakdown
[Full profiling output]

### B4: Comparison with Related Work
[Table comparing to other stencil codes]
