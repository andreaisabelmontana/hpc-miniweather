#!/usr/bin/env bash
set -euo pipefail

BIN="${1:-./build/miniweather}"

out="$($BIN --backend cpu -nx 16 -ny 16 -nz 16 -t 1 2>&1)"

echo "$out" | grep -q "miniweather baseline starting"
echo "$out" | grep -q "running CPU stencil"
echo "$out" | grep -q "elapsed:"

echo "$out"
