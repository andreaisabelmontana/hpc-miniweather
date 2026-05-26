/**
 * MiniWeather HPC - GPU Stencil Implementation (CUDA/HIP)
 * 
 * 7-point stencil computation on GPU using CUDA (or HIP for AMD GPUs).
 * Supports domain decomposition with MPI + GPU.
 */

#include "stencil.hpp"
#include "cli.hpp"
#include "timer.hpp"
#include <iostream>
#include <vector>

#ifdef MINIW_CUDA
#include <cuda_runtime.h>
#define GPU_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            std::cerr << "CUDA Error: " << cudaGetErrorString(err) \
                      << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
            exit(1); \
        } \
    } while(0)
#endif

#ifdef MINIW_HIP
#include <hip/hip_runtime.h>
#define GPU_CHECK(call) \
    do { \
        hipError_t err = call; \
        if (err != hipSuccess) { \
            std::cerr << "HIP Error: " << hipGetErrorString(err) \
                      << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
            exit(1); \
        } \
    } while(0)
#endif

#ifdef MINIW_MPI
#include <mpi.h>
#endif

namespace miniw {

#if defined(MINIW_CUDA) || defined(MINIW_HIP)

// =============================================================================
// GPU Kernel: 7-Point Stencil
// =============================================================================
__global__ void stencil_kernel(
    const double* __restrict__ current,
    double* __restrict__ next,
    int nx, int ny, int nz,
    int stride_y, int stride_z)
{
    // 3D thread indexing
    int i = blockIdx.x * blockDim.x + threadIdx.x + 1;  // Skip halo
    int j = blockIdx.y * blockDim.y + threadIdx.y + 1;
    int k = blockIdx.z * blockDim.z + threadIdx.z + 1;
    
    if (i <= nx && j <= ny && k <= nz) {
        int idx = i * stride_y * stride_z + j * stride_z + k;
        
        // 7-point stencil
        next[idx] = (
            current[(i - 1) * stride_y * stride_z + j * stride_z + k] +
            current[(i + 1) * stride_y * stride_z + j * stride_z + k] +
            current[i * stride_y * stride_z + (j - 1) * stride_z + k] +
            current[i * stride_y * stride_z + (j + 1) * stride_z + k] +
            current[i * stride_y * stride_z + j * stride_z + (k - 1)] +
            current[i * stride_y * stride_z + j * stride_z + (k + 1)] +
            current[idx] * 4.0
        ) / 10.0;
    }
}

// =============================================================================
// GPU Kernel: 7-Point Stencil with Shared Memory (Cache Blocking)
// =============================================================================
__global__ void stencil_kernel_shared(
    const double* __restrict__ current,
    double* __restrict__ next,
    int nx, int ny, int nz,
    int stride_y, int stride_z)
{
    // Shared memory tile with halo
    __shared__ double tile[10][10][10];  // 8x8x8 + 1 halo on each side
    
    int tx = threadIdx.x;
    int ty = threadIdx.y;
    int tz = threadIdx.z;
    
    int i = blockIdx.x * (blockDim.x - 2) + tx;
    int j = blockIdx.y * (blockDim.y - 2) + ty;
    int k = blockIdx.z * (blockDim.z - 2) + tz;
    
    // Load data into shared memory (including halos)
    if (i < nx + 2 && j < ny + 2 && k < nz + 2) {
        int idx = i * stride_y * stride_z + j * stride_z + k;
        tile[tx][ty][tz] = current[idx];
    }
    __syncthreads();
    
    // Compute stencil for interior points only
    if (tx > 0 && tx < blockDim.x - 1 &&
        ty > 0 && ty < blockDim.y - 1 &&
        tz > 0 && tz < blockDim.z - 1 &&
        i > 0 && i <= nx &&
        j > 0 && j <= ny &&
        k > 0 && k <= nz)
    {
        int idx = i * stride_y * stride_z + j * stride_z + k;
        
        next[idx] = (
            tile[tx - 1][ty][tz] +
            tile[tx + 1][ty][tz] +
            tile[tx][ty - 1][tz] +
            tile[tx][ty + 1][tz] +
            tile[tx][ty][tz - 1] +
            tile[tx][ty][tz + 1] +
            tile[tx][ty][tz] * 4.0
        ) / 10.0;
    }
}

#endif  // CUDA or HIP

// =============================================================================
// Main GPU Stencil Function
// =============================================================================
void run_stencil_gpu(int argc, char** argv) {
#if defined(MINIW_CUDA) || defined(MINIW_HIP)
    
    Cli cli = parse_cli(argc, argv);
    
#ifdef MINIW_MPI
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
#else
    int rank = 0, size = 1;
#endif

    // Select GPU based on MPI rank (for multi-GPU)
    int device_count = 0;
#ifdef MINIW_CUDA
    cudaGetDeviceCount(&device_count);
    cudaSetDevice(rank % device_count);
#endif
#ifdef MINIW_HIP
    hipGetDeviceCount(&device_count);
    hipSetDevice(rank % device_count);
#endif

    // Domain decomposition in z-dimension
    int global_nz = cli.nz;
    int local_nz = global_nz / size;
    int remainder = global_nz % size;
    if (rank < remainder) local_nz += 1;

    // Grid with halos
    int nx = cli.nx;
    int ny = cli.ny;
    int NX = nx + 2;
    int NY = ny + 2;
    int NZ = local_nz + 2;
    
    size_t array_size = NX * NY * NZ * sizeof(double);
    
    // Host arrays
    std::vector<double> h_current(NX * NY * NZ, 0.0);
    std::vector<double> h_next(NX * NY * NZ, 0.0);
    
    // Initialize field
    for (int i = 1; i <= nx; ++i) {
        for (int j = 1; j <= ny; ++j) {
            for (int k = 1; k <= local_nz; ++k) {
                int idx = i * NY * NZ + j * NZ + k;
                h_current[idx] = i + j + k;
            }
        }
    }
    
    // Device arrays
    double *d_current, *d_next;
#ifdef MINIW_CUDA
    GPU_CHECK(cudaMalloc(&d_current, array_size));
    GPU_CHECK(cudaMalloc(&d_next, array_size));
    GPU_CHECK(cudaMemcpy(d_current, h_current.data(), array_size, cudaMemcpyHostToDevice));
#endif
#ifdef MINIW_HIP
    GPU_CHECK(hipMalloc(&d_current, array_size));
    GPU_CHECK(hipMalloc(&d_next, array_size));
    GPU_CHECK(hipMemcpy(d_current, h_current.data(), array_size, hipMemcpyHostToDevice));
#endif
    
    // Kernel configuration
    dim3 block(8, 8, 8);
    dim3 grid(
        (nx + block.x - 1) / block.x,
        (ny + block.y - 1) / block.y,
        (local_nz + block.z - 1) / block.z
    );
    
    // Timing
    Timer timer;
    
    // Time stepping loop
    for (int step = 0; step < cli.steps; ++step) {
        
#ifdef MINIW_CUDA
        stencil_kernel<<<grid, block>>>(
            d_current, d_next, nx, ny, local_nz, NY, NZ);
        cudaDeviceSynchronize();
#endif
#ifdef MINIW_HIP
        hipLaunchKernelGGL(stencil_kernel, grid, block, 0, 0,
            d_current, d_next, nx, ny, local_nz, NY, NZ);
        hipDeviceSynchronize();
#endif
        
        // Swap pointers
        std::swap(d_current, d_next);
        
        // TODO: MPI halo exchange for multi-GPU
    }
    
    double elapsed = timer.elapsed();
    
    // Copy results back
#ifdef MINIW_CUDA
    GPU_CHECK(cudaMemcpy(h_current.data(), d_current, array_size, cudaMemcpyDeviceToHost));
    cudaFree(d_current);
    cudaFree(d_next);
#endif
#ifdef MINIW_HIP
    GPU_CHECK(hipMemcpy(h_current.data(), d_current, array_size, hipMemcpyDeviceToHost));
    hipFree(d_current);
    hipFree(d_next);
#endif
    
    // Output results
#ifdef MINIW_MPI
    if (rank == 0) {
#endif
        double glups = (double)(cli.nx * cli.ny * cli.nz * cli.steps) / elapsed / 1e9;
        
        std::cout << "[GPU] Time " << elapsed << " s, GLUPS: " << glups << "\n";
        std::cout << "[GPU] Configuration: " << size << " GPUs";
        std::cout << ", Grid: " << nx << "x" << ny << "x" << cli.nz << "\n";
#ifdef MINIW_MPI
    }
    MPI_Finalize();
#endif

#else
    // No GPU support compiled
    std::cerr << "Error: GPU support not compiled. "
              << "Rebuild with -DENABLE_CUDA=ON or -DENABLE_HIP=ON\n";
    exit(1);
#endif  // CUDA or HIP
}

}  // namespace miniw
