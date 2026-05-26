#include <iostream>
#include <cstring>
#include "timer.hpp"
#include "stencil.hpp"

int main(int argc, char** argv) {
	// Check for GPU backend
	bool use_gpu = false;
	for (int i = 1; i < argc; ++i) {
		if (std::strcmp(argv[i], "--backend") == 0 && i + 1 < argc) {
			if (std::strcmp(argv[i + 1], "gpu") == 0) {
				use_gpu = true;
			}
		}
	}
	
#ifdef MINIW_CUDA
	if (use_gpu) {
		miniw::run_stencil_gpu(argc, argv);
		return 0;
	}
#endif

#ifdef MINIW_MPI	
	miniw::run_stencil_cpu_parallel(argc, argv);
#else
	miniw::run_stencil_cpu_serial(argc, argv);
#endif
	return 0;
}

