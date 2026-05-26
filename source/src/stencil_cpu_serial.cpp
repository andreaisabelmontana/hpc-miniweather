#include "stencil.hpp"
#include "cli.hpp"
#include "timer.hpp"
#include <iostream>
#include <vector>

namespace miniw {

// Checker funtion
bool check_constant_field(const std::vector<double>& field, int nx, int ny, int nz, int stride_y, int stride_z) {
	double first = field[1 * stride_y * stride_z + 1 * stride_z + 1];
	for (int i = 1; i <= nx; ++i) {
                    for (int j = 1; j <= ny; ++j) {
                            for (int k = 1; k <= nz; ++k) {
				int idx = i * stride_y * stride_z + j * stride_z + k;
				if (std::abs(field[idx] - first) > 1e-10) {
					return false;
				}
			}
		}
	}
	return true;
}

void run_stencil_cpu_serial (int argc, char** argv) {
	Cli cli = parse_cli(argc, argv);

	// Allocate 3D arrays with 1-cell halos
	int nx = cli.nx + 2, ny = cli.ny + 2, nz = cli.nz + 2;
	std::vector<double> current(nx * ny * nz, 0.0);
	std::vector<double> next(nx * ny * nz, 0.0);

	// Initialize field
	for (int i = 1; i <= cli.nx; ++i) {
		for (int j = 1; j <= cli.ny; ++j) {
			for (int k = 1; k <= cli.nz; ++k) {
				int idx = i * ny * nz + j * nz + k;
				current[idx] = i + j + k;
			}
		}
	}

	Timer timer;

	// Time stepping loop
	for (int step=0; step<cli.steps; ++step) {
		for (int i = 1; i <= cli.nx; ++i) {
			for (int j = 1; j <= cli.ny; ++j) {
                        	for (int k = 1; k <= cli.nz; ++k) {
					int idx = i * ny * nz + j * nz + k;
					
					// 7-Point Stencil
					next[idx] = (current[(i-1) * ny * nz + j * nz + k] +
						current[(i+1) * ny * nz + j * nz + k] +
						current[i * ny * nz + (j-1) * nz + k] +
						current[i * ny * nz + (j+1) * nz + k] +
						current[i * ny * nz + j * nz + (k-1)] +
						current[i * ny * nz + j * nz + (k+1)] +
						current[idx] * 4.0) / 10.0;
				}
			}
		}
		// Ping-pong buffer
		std::swap(current, next);
	}

	double elapsed = timer.elapsed();
	double glups = (cli.nx * cli.ny * cli.nz * cli.steps) / elapsed /1e9;

	std::cout << "[SERIAL] Completed: " << cli.steps << " steps\n";
	std::cout << "[SERIAL] Time: " << elapsed << " s, GLUPS: " << glups << "\n";

	// Check for correctness
	if (check_constant_field(current, cli.nx, cli.ny, cli.nz, ny, nz)) {
		std::cout << "[SERIAL] Constant field test: PASSED\n";
	} else { 
		std::cout << "[SERIAL] Constant field test: FAILED\n"; 
	}
}

} // namespace miniw

