#include "stencil.hpp"

namespace miniw {

void run_stencil_cpu(int argc, char** argv) {
#ifdef MINIW_MPI
	run_stencil_cpu_parallel(argc, argv);
#else
	run_stencil_cpu_serial(argc, argv);
#endif
}	
	
} // namespace miniw
