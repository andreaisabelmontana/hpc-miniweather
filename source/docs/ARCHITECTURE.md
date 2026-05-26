# Architecture

## Targets
- `core`: library containing timer, CLI parsing, halo helpers, and CPU stencil implementations.
- `miniweather`: executable that links `core` (and optional `cpu_blocked`/GPU libs when present).

## Ownership
- Build/CMake: team build maintainers.
- CPU kernels and correctness: stencil authors.
- Documentation and CI: repo maintainers.
