#include "stencil.hpp"
#include "cli.hpp"
#include "timer.hpp"
#include "halo.hpp"
#include <iostream>
#include <vector>
#include <omp.h>

#ifdef MINIW_MPI
#include "mpi.h"
#endif

namespace miniw {

void run_stencil_cpu_parallel(int argc, char** argv) {
    // Parse cli
    Cli cli = parse_cli(argc, argv);

#ifdef MINIW_MPI
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
#else
    int rank = 0, size = 1;
#endif

    // Domain decomposition in z-dimension
    int global_nz = cli.nz;
    int local_nz = global_nz / size;
    int remainder = global_nz % size;
    if (rank < remainder) {
        local_nz += 1;
    }

    // Calculate starting z-index for this rank
    int z_start = 0;
    for (int r = 0; r < rank; ++r) {
        int prev_local_nz = global_nz / size;
        if (r < remainder) {
            prev_local_nz += 1;
        }
        z_start += prev_local_nz;
    }

    // Allocate 3D arrays with 1-cell halos
    int nx = cli.nx + 2, ny = cli.ny + 2, nz = local_nz + 2;
    std::vector<double> current(nx * ny * nz, 0.0);
    std::vector<double> next(nx * ny * nz, 0.0);

    // Initialize field
    for (int i = 1; i <= cli.nx; ++i) {
        for (int j = 1; j <= cli.ny; ++j) {
            for (int k = 1; k <= local_nz; ++k) {
                int idx = i * ny * nz + j * nz + k;
                current[idx] = i + j + (k + z_start);
            }
        }
    }

#ifdef MINIW_MPI
    HaloExchange halo(nx, ny, nz);
#endif

    // ---------------------------
    // Owner B Timers
    // ---------------------------
    Timer t_interior, t_halo, t_boundary;
    double sum_interior = 0.0;
    double sum_halo = 0.0;
    double sum_boundary = 0.0;

    // Whole-program timer
    Timer total_timer;

    // ---------------------------
    // Main compute loop
    // ---------------------------
    for (int step = 0; step < cli.steps; ++step) {

        // ---------------------------
        // Halo exchange timing
        // ---------------------------
        t_halo.start();
#ifdef MINIW_MPI
        halo.start_exchange(current);
#endif
        sum_halo += t_halo.elapsed();

        // ---------------------------
        // Interior compute timing
        // ---------------------------
        t_interior.start();

#ifdef MINIW_OMP
#pragma omp parallel for collapse(2)
#endif
        for (int i = 1; i <= cli.nx; ++i) {
            for (int j = 1; j <= cli.ny; ++j) {
#ifdef MINIW_OMP
#pragma omp simd
#endif
                for (int k = 1; k <= local_nz; ++k) {
                    int idx = i * ny * nz + j * nz + k;

                    // 7-Point Stencil
                    next[idx] = (current[(i - 1) * ny * nz + j * nz + k] +
                                 current[(i + 1) * ny * nz + j * nz + k] +
                                 current[i * ny * nz + (j - 1) * nz + k] +
                                 current[i * ny * nz + (j + 1) * nz + k] +
                                 current[i * ny * nz + j * nz + (k - 1)] +
                                 current[i * ny * nz + j * nz + (k + 1)] +
                                 current[idx] * 4.0) / 10.0;
                }
            }
        }

        sum_interior += t_interior.elapsed();

        // ---------------------------
        // Finish halo + boundary timing
        // ---------------------------
#ifdef MINIW_MPI
        halo.finish_exchange(current);
#endif

        t_boundary.start();
        // Currently no separate boundary compute → placeholder timer
        sum_boundary += t_boundary.elapsed();

        // Swap fields
        std::swap(current, next);
    }

    double total_elapsed = total_timer.elapsed();

#ifdef MINIW_MPI
    if (rank == 0) {
#endif
        // GLUPS
        double glups = (cli.nx * cli.ny * cli.nz * cli.steps)
                        / total_elapsed / 1e9;

        std::cout << "[PARALLEL] Time " << total_elapsed
                  << " s, GLUPS: " << glups << "\n";

        std::cout << "[PARALLEL] Configuration: " << size << " ranks";
#ifdef MINIW_OMP
        std::cout << " with OpenMP";
#endif
        std::cout << "\n";

        // ---- Timer Breakdown ----
        std::cout << "--- Timer Breakdown ---\n";
        std::cout << "Interior:  " << sum_interior  << " s\n";
        std::cout << "Halo:      " << sum_halo      << " s\n";
        std::cout << "Boundary:  " << sum_boundary  << " s\n";
        std::cout << "Total:     "
                  << (sum_interior + sum_halo + sum_boundary)
                  << " s\n";

#ifdef MINIW_MPI
    }
#endif

#ifdef MINIW_MPI
    MPI_Finalize();
#endif
}

} // namespace miniw

