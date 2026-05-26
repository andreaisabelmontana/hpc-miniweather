#pragma once
#include <string>

struct Cli {
  int nx{128}, ny{128}, nz{128}, steps{10};
  std::string backend{"cpu"};
};

Cli parse_cli(int argc, char** argv);
