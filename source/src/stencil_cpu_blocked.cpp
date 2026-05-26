#include "stencil.hpp"
#include "cli.hpp"
#include "timer.hpp"
#include "halo.hpp"
#include <vector>
#include <iostream>
#include <omp.h>
#include <algorithm>

#ifdef MINIW_MPI
#include "mpi.h"
#endif

namespace miniw {

void run_stencil_cpu_blocked(int argc, char** argv) {

    // -------------------------------
    // Parse CLI
    // -------------------------------
    Cli cli = parse_cli(argc, argv);
    int nx = cli.nx;
    int ny = cli.ny;
    int nz_global = cli.nz;

    int Ti = cli.ti;
    int Tj = cli.tj;
    int Tt = cli.timesteps_per_tile;      // temporal block (1–4 typical)

    // -------------------------------
    // MPI domain decomposition in z (if enabled)
    // -------------------------------
#ifdef MINIW_MPI
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
#else
    int rank = 0, size = 1;
#endif

    int local_nz = nz_global / size;
    int remainder = nz_global % size;
    if (rank < remainder) local_nz += 1;

    // Calculate starting z-index for this rank (0-based)
    int z_start = 0;
    for (int r = 0; r < rank; ++r) {
        int prev_local = nz_global / size;
        if (r < remainder) prev_local += 1;
        z_start += prev_local;
    }

    // padded with halo
    int NX = nx + 2;
    int NY = ny + 2;
    int NZ = local_nz + 2;   // local nz + 2 halos

    std::vector<double> current(NX * NY * NZ, 0.0);
    std::vector<double> next(NX * NY * NZ, 0.0);

    // -------------------------------
    // initialize
    // -------------------------------
    auto idx = [&](int i, int j, int k) {
        return i * NY * NZ + j * NZ + k;
    };

    // initialize local slab values (k offset by z_start)
    for (int i = 1; i <= nx; ++i)
        for (int j = 1; j <= ny; ++j)
            for (int k = 1; k <= local_nz; ++k)
                current[idx(i, j, k)] = i + j + (k + z_start);

    // Halo exchange (only if MPI enabled)
#ifdef MINIW_MPI
    HaloExchange halo(NX, NY, NZ);
#endif

    // -------------------------------
    // Timers
    // -------------------------------
    Timer t_total;
    Timer t_interior, t_halo, t_boundary;
    double sum_interior = 0.0;
    double sum_halo = 0.0;
    double sum_boundary = 0.0;

    // -------------------------------
    // Main loop (temporal blocking)
    // -------------------------------
    for (int step = 0; step < cli.steps; step += Tt) {

        int tsteps = std::min(Tt, cli.steps - step);

        // For correctness with MPI, do tsteps sub-timesteps,
        // and perform halo exchange around each sub-timestep.
        for (int tt = 0; tt < tsteps; ++tt) {

            // ---- halo exchange (non-blocking start) ----
            t_halo.start();
#ifdef MINIW_MPI
            halo.start_exchange(current);
#endif
            sum_halo += t_halo.elapsed();

            // ---- interior compute (tile over i,j, full local_k) ----
            t_interior.start();

            // We parallelize over tiles (ii, jj). collapse(2) lets OpenMP distribute tiles.
#ifdef MINIW_OMP
#pragma omp parallel for collapse(2) schedule(dynamic)
#endif
            for (int ii = 1; ii <= nx; ii += Ti) {
                for (int jj = 1; jj <= ny; jj += Tj) {

                    int i_end = std::min(ii + Ti - 1, nx);
                    int j_end = std::min(jj + Tj - 1, ny);

                    // compute tile
                    for (int i = ii; i <= i_end; ++i) {
                        for (int j = jj; j <= j_end; ++j) {

#ifdef MINIW_OMP
#pragma omp simd
#endif
                            for (int k = 1; k <= local_nz; ++k) {
                                // Prefetch a little ahead in k
                                // ensure we don't go out of bounds when prefetching k+4
                                if (k + 4 < NZ) __builtin_prefetch(&current[idx(i, j, k + 4)], 0, 1);

                                next[idx(i, j, k)] =
                                    ( current[idx(i - 1, j, k)] +
                                      current[idx(i + 1, j, k)] +
                                      current[idx(i, j - 1, k)] +
                                      current[idx(i, j + 1, k)] +
                                      current[idx(i, j, k - 1)] +
                                      current[idx(i, j, k + 1)] +
                                      current[idx(i, j, k)] * 4.0 ) / 10.0;
                            }
                        }
                    }
                }
            } // tiles

            sum_interior += t_interior.elapsed();

            // ---- finish halo exchange (wait for comms to complete) ----
            t_halo.start(); // measure waiting time as part of halo time
#ifdef MINIW_MPI
            halo.finish_exchange(current);
#endif
            sum_halo += t_halo.elapsed();

            // ---- boundary timer placeholder (no separate boundary loop currently) ----
            t_boundary.start();
            // If you later split boundary updates into separate loops, measure it here.
            sum_boundary += t_boundary.elapsed();

            // swap fields for this sub-timestep
            std::swap(current, next);
        } // tt sub-timesteps
    } // step outer

    double elapsed = t_total.elapsed();

    // GLUPS uses global nz (not local) to compute full problem size
    double glups = (double(nx) * double(ny) * double(nz_global) * double(cli.steps)) / elapsed / 1e9;

    // print results on rank 0
#ifdef MINIW_MPI
    if (rank == 0) {
#endif
        std::cout << "[BLOCKED] Time " << elapsed << " s  GLUPS " << glups << "\n";
        std::cout << "[BLOCKED] Ti=" << Ti << " Tj=" << Tj
                  << " Tt=" << Tt << " (OpenMP+SIMD+Prefetch)\n";

        std::cout << "--- Timer Breakdown ---\n";
        std::cout << "Interior:  " << sum_interior  << " s\n";
        std::cout << "Halo:      " << sum_halo      << " s\n";
        std::cout << "Boundary:  " << sum_boundary  << " s\n";
        std::cout << "TotalTimers: " << (sum_interior + sum_halo + sum_boundary) << " s\n";
#ifdef MINIW_MPI
    }
    MPI_Finalize();
#endif

} // run_stencil_cpu_blocked

} // namespace miniw
