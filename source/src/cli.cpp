#include "cli.hpp"
#include <cstring>
#include <cstdlib>

Cli parse_cli(int argc, char** argv) {
    Cli c;

    for (int i = 1; i < argc; ++i) {
        // Grid sizes
        if (!std::strcmp(argv[i], "-nx") && i+1 < argc)
            c.nx = std::atoi(argv[++i]);

        else if (!std::strcmp(argv[i], "-ny") && i+1 < argc)
            c.ny = std::atoi(argv[++i]);

        else if (!std::strcmp(argv[i], "-nz") && i+1 < argc)
            c.nz = std::atoi(argv[++i]);

        // Number of timesteps
        else if (!std::strcmp(argv[i], "-t") && i+1 < argc)
            c.steps = std::atoi(argv[++i]);

        // Backend mode (serial / parallel / blocked / gpu)
        else if (!std::strcmp(argv[i], "--backend") && i+1 < argc)
            c.backend = argv[++i];

        // ------- Added for BLOCKED CPU version -------
        else if (!std::strcmp(argv[i], "--ti") && i+1 < argc)
            c.ti = std::atoi(argv[++i]);

        else if (!std::strcmp(argv[i], "--tj") && i+1 < argc)
            c.tj = std::atoi(argv[++i]);

        else if (!std::strcmp(argv[i], "--tsteps") && i+1 < argc)
            c.timesteps_per_tile = std::atoi(argv[++i]);
        // ------------------------------------------------
    }

    return c;
}
