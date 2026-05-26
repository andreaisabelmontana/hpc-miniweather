#!/usr/bin/env bash
# Small helper to build & run examples locally or on a node


set -euo pipefail

MODE=${1:-cpu}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

case "$MODE" in
	cpu)
		mkdir -p build && cd build
		cmake .. -DENABLE_CUDA=OFF -DENABLE_HIP=OFF
		make -j || make
		./miniweather
		;;
	gpu)
		mkdir -p build-cuda && cd build-cuda
		cmake .. -DENABLE_CUDA=ON
		make -j || make
		./miniweather
		;;
	*)
		echo "Usage: $0 [cpu|gpu]"
		exit 2
		;;
esac
