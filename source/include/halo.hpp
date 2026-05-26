#pragma once
#include <vector>

#ifdef MINIW_MPI
#include "mpi.h"
#endif

namespace miniw {

struct Halo {
    int nx = 16;
    int ny = 16;
    int nz = 16;
};

#ifdef MINIW_MPI
class HaloExchange {
public:
    HaloExchange(int nx, int ny, int nz);
    void start_exchange(std::vector<double>& field);
    void finish_exchange(std::vector<double>& field);
private:
    int nx, ny, nz;
    int left_rank, right_rank;
    std::vector<double> send_left, send_right;
    std::vector<double> recv_left, recv_right;
#ifdef MINIW_MPI
    MPI_Request send_requests[2], recv_requests[2];
#endif
};
#endif

} // namespace miniw