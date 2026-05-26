#pragma once

namespace miniw {

// CPU implementations
void run_stencil_cpu(int argc, char** argv);
void run_stencil_cpu_serial(int argc, char** argv);
void run_stencil_cpu_parallel(int argc, char** argv);
void run_stencil_cpu_blocked(int argc, char** argv);

// GPU implementation (CUDA/HIP)
void run_stencil_gpu(int argc, char** argv);

} // namespace miniw
