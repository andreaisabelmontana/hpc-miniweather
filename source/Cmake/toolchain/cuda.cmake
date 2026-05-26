message(STATUS "Applying CUDA toolchain helpers")

# Ensure CUDA language uses a consistent standard 
if(NOT DEFINED CMAKE_CUDA_STANDARD)
	set(CMAKE_CUDA_STANDARD 17)
	set(CMAKE_CUDA_STANDARD_REQUIRED ON)
endif()


if(NOT DEFINED CMAKE_CUDA_FLAGS)
	set(CMAKE_CUDA_FLAGS "-O3 --expt-relaxed-constexpr")
endif()

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}")

# Hint: set(CMAKE_CUDA_ARCHITECTURES 70 80 90) in CI or local toolchain for target GPUs
