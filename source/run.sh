#!/bin/bash
# =============================================================================
# MiniWeather HPC - Main Run Script
# =============================================================================
# Usage: ./run.sh [mode] [options]
#   mode: build | run | test | scale | profile | clean
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
RESULTS_DIR="${PROJECT_DIR}/results"

# Default parameters
NX=${NX:-64}
NY=${NY:-64}
NZ=${NZ:-64}
STEPS=${STEPS:-100}
NPROCS=${NPROCS:-4}
OMP_THREADS=${OMP_THREADS:-4}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

load_modules() {
    echo "Loading modules..."
    module purge --force 2>/dev/null || true
    module load gcc/12.3 2>/dev/null || module load gcc
    module load openmpi/4.1.5 2>/dev/null || module load openmpi
    module load cmake/3.27 2>/dev/null || module load cmake
    export OMP_NUM_THREADS=${OMP_THREADS}
}

build() {
    echo "=== Building MiniWeather ==="
    load_modules
    
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    
    cmake .. \
        -DENABLE_MPI=ON \
        -DENABLE_OPENMP=ON \
        -DENABLE_CUDA=${ENABLE_CUDA:-OFF} \
        -DENABLE_HIP=${ENABLE_HIP:-OFF}
    
    make -j$(nproc)
    
    echo "Build complete: ${BUILD_DIR}/miniweather"
}

run_single() {
    echo "=== Running Single Node ==="
    load_modules
    
    cd "${BUILD_DIR}"
    export OMP_NUM_THREADS=${OMP_THREADS}
    
    echo "Config: nx=${NX}, ny=${NY}, nz=${NZ}, steps=${STEPS}"
    echo "MPI ranks: ${NPROCS}, OMP threads: ${OMP_THREADS}"
    
    mpirun -np ${NPROCS} ./miniweather \
        --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS}
}

run_test() {
    echo "=== Running Sanity Test ==="
    load_modules
    
    cd "${BUILD_DIR}"
    
    # Small test
    echo "Running small test (16^3)..."
    mpirun -np 2 ./miniweather --nx 16 --ny 16 --nz 16 --steps 10
    
    echo "Test passed!"
}

run_scaling() {
    echo "=== Running Scaling Tests ==="
    load_modules
    
    mkdir -p "${RESULTS_DIR}"
    cd "${BUILD_DIR}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="${RESULTS_DIR}/scaling_${TIMESTAMP}.csv"
    
    echo "nodes,ranks,threads,nx,ny,nz,steps,time_s,glups" > "${OUTPUT_FILE}"
    
    # Strong scaling: fixed problem size, vary ranks
    echo "--- Strong Scaling ---"
    for RANKS in 1 2 4 8; do
        echo "Running with ${RANKS} ranks..."
        export OMP_NUM_THREADS=${OMP_THREADS}
        
        OUTPUT=$(mpirun -np ${RANKS} ./miniweather \
            --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} 2>&1)
        
        TIME=$(echo "$OUTPUT" | grep "Time" | awk '{print $3}')
        GLUPS=$(echo "$OUTPUT" | grep "GLUPS" | awk '{print $5}')
        
        echo "1,${RANKS},${OMP_THREADS},${NX},${NY},${NZ},${STEPS},${TIME},${GLUPS}" >> "${OUTPUT_FILE}"
    done
    
    echo "Results saved to: ${OUTPUT_FILE}"
}

run_profile() {
    echo "=== Running Profiling ==="
    load_modules
    
    mkdir -p "${RESULTS_DIR}"
    cd "${BUILD_DIR}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Basic perf profile
    echo "Running perf profile..."
    perf stat -e cycles,instructions,cache-references,cache-misses \
        mpirun -np ${NPROCS} ./miniweather \
        --nx ${NX} --ny ${NY} --nz ${NZ} --steps ${STEPS} \
        2>&1 | tee "${RESULTS_DIR}/perf_${TIMESTAMP}.log"
    
    echo "Profile saved to: ${RESULTS_DIR}/perf_${TIMESTAMP}.log"
}

clean() {
    echo "=== Cleaning Build ==="
    rm -rf "${BUILD_DIR}"
    echo "Clean complete"
}

show_help() {
    echo "MiniWeather HPC - Run Script"
    echo ""
    echo "Usage: ./run.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  build    - Build the project"
    echo "  run      - Run single execution"
    echo "  test     - Run sanity test"
    echo "  scale    - Run scaling experiments"
    echo "  profile  - Run with profiling"
    echo "  clean    - Clean build directory"
    echo ""
    echo "Environment variables:"
    echo "  NX, NY, NZ     - Grid dimensions (default: 64)"
    echo "  STEPS          - Time steps (default: 100)"
    echo "  NPROCS         - MPI ranks (default: 4)"
    echo "  OMP_THREADS    - OpenMP threads (default: 4)"
    echo "  ENABLE_CUDA    - Enable CUDA (default: OFF)"
    echo "  ENABLE_HIP     - Enable HIP (default: OFF)"
    echo ""
    echo "Examples:"
    echo "  ./run.sh build"
    echo "  ./run.sh run"
    echo "  NX=128 NY=128 NZ=128 NPROCS=8 ./run.sh run"
    echo "  ./run.sh scale"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
case "${1:-help}" in
    build)   build ;;
    run)     run_single ;;
    test)    run_test ;;
    scale)   run_scaling ;;
    profile) run_profile ;;
    clean)   clean ;;
    *)       show_help ;;
esac
