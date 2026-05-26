# 1) Require modern CMake & declare project/languages
cmake_minimum_required(VERSION 3.22)
project(miniweather-hpc LANGUAGES C CXX)

# --- macOS: make libc++ headers visible to IntelliSense/AppleClang ---
if(APPLE)
  execute_process(
    COMMAND xcrun --show-sdk-path --sdk macosx
    OUTPUT_VARIABLE MACOS_SDK_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(MACOS_SDK_PATH)
    message(STATUS "macOS SDK path: ${MACOS_SDK_PATH}")
    # Keep as SYSTEM to avoid warning noise
    include_directories(SYSTEM "${MACOS_SDK_PATH}/usr/include/c++/v1")
    include_directories(SYSTEM "${MACOS_SDK_PATH}/usr/include")
  endif()
  add_compile_options(-stdlib=libc++)  # compile with libc++
  add_link_options(-stdlib=libc++)     # link with libc++
endif()

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 3) Feature toggles (OpenMP OFF by default on mac)  # <<<
option(ENABLE_MPI     "Build with MPI"            ON)
if(APPLE)
  set(_omp_default OFF)
else()
  set(_omp_default ON)
endif()
option(ENABLE_OPENMP  "Build with OpenMP"         ${_omp_default})
option(ENABLE_CUDA    "Build CUDA GPU variant"    OFF)
option(ENABLE_HIP     "Build HIP GPU variant"     OFF)
option(ENABLE_OPENACC "Build OpenACC variant"     OFF)

# 4) Dependencies
if(ENABLE_MPI)
  find_package(MPI REQUIRED COMPONENTS CXX)         # link MPI C from C++ (portable)
  add_compile_definitions(MINIW_MPI)
endif()

if(ENABLE_OPENMP)
  find_package(OpenMP REQUIRED)                   # provides OpenMP::OpenMP_CXX
  add_compile_definitions(MINIW_OMP)
endif()

# GPU options guarded  # <<<
if(ENABLE_CUDA)
  enable_language(CUDA)
  set(CMAKE_CUDA_STANDARD 14)
  set(CMAKE_CUDA_STANDARD_REQUIRED ON)
  add_compile_definitions(MINIW_CUDA)
endif()

if(ENABLE_HIP)
  find_package(HIP REQUIRED)
  add_compile_definitions(MINIW_HIP)
endif()

if(ENABLE_OPENACC)
  find_package(OpenACC REQUIRED)
  add_compile_definitions(MINIW_OPENACC)
endif()

# 5) Core library (shared code)
add_library(core
  src/timer.cpp
  src/halo.cpp
  src/cli.cpp
  src/stencil_cpu_serial.cpp    # New Serial version
  src/stencil_cpu_parallel.cpp  # New Parallel version
  src/stencil_cpu.cpp           # Using as a wrapper now
)
target_include_directories(core PUBLIC ${CMAKE_SOURCE_DIR}/include)  # <<<
target_compile_options(core PRIVATE -Wall -Wextra)
if(ENABLE_MPI)
  target_link_libraries(core PUBLIC MPI::MPI_CXX)
endif()
if(ENABLE_OPENMP)
  target_link_libraries(core PUBLIC OpenMP::OpenMP_CXX)
endif()

# 7) Optional CPU-blocked lib (only if file exists)
if(EXISTS "${CMAKE_SOURCE_DIR}/src/stencil_cpu_blocked.cpp")
  add_library(cpu_blocked src/stencil_cpu_blocked.cpp)
  target_link_libraries(cpu_blocked PUBLIC core)
endif()

# 8) GPU variants (optional)
if(ENABLE_CUDA AND EXISTS "${CMAKE_SOURCE_DIR}/src/stencil_gpu.cu")
  add_library(gpu_cuda src/stencil_gpu.cu)
  target_link_libraries(gpu_cuda PUBLIC core)
endif()

if(ENABLE_HIP AND EXISTS "${CMAKE_SOURCE_DIR}/src/stencil_hip.cpp")
  hip_add_library(gpu_hip src/stencil_hip.cpp)
  target_link_libraries(gpu_hip PUBLIC core)
endif()

# ---- Executable: ONLY main.cpp here (everything else is in core)  # <<<
add_executable(miniweather src/main.cpp)
target_link_libraries(miniweather PUBLIC core)
# If optional libs exist, link them too
if(TARGET cpu_blocked)
  target_link_libraries(miniweather PUBLIC cpu_blocked)
endif()
if(TARGET gpu_cuda)
  target_link_libraries(miniweather PUBLIC gpu_cuda)
endif()
if(TARGET gpu_hip)
  target_link_libraries(miniweather PUBLIC gpu_hip)
endif()

