#ifndef CLI_HPP
#define CLI_HPP

#include <string>

struct Cli {
    int nx = 128;
    int ny = 128;
    int nz = 128;
    int steps = 10;

    std::string backend = "serial";

    // Owner-C blocked CPU parameters
    int ti = 32;
    int tj = 32;
    int timesteps_per_tile = 1;
};

Cli parse_cli(int argc, char** argv);

#endif
