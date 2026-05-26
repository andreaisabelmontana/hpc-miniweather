#include "halo.hpp"
#include <vector>

#ifdef MINIW_MPI
#include "mpi.h"
#include <cstring>

namespace miniw {

HaloExchange::HaloExchange(int nx_, int ny_, int nz_)
    : nx(nx_), ny(ny_), nz(nz_) {
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    left_rank = (rank - 1 + size) % size;
    right_rank = (rank + 1) % size;

    send_left.resize(nx * ny);
    send_right.resize(nx * ny);
    recv_left.resize(nx * ny);
    recv_right.resize(nx * ny);
}

void HaloExchange::start_exchange(std::vector<double>& field) {
    // Pack left
    for (int i = 0; i < nx; ++i)
        for (int j = 0; j < ny; ++j)
            send_left[i * ny + j] = field[i * ny * nz + j * nz + 1];

    // Pack right
    for (int i = 0; i < nx; ++i)
        for (int j = 0; j < ny; ++j)
            send_right[i * ny + j] = field[i * ny * nz + j * nz + (nz - 2)];

    MPI_Irecv(recv_left.data(), nx * ny, MPI_DOUBLE, left_rank, 0, MPI_COMM_WORLD, &recv_requests[0]);
    MPI_Irecv(recv_right.data(), nx * ny, MPI_DOUBLE, right_rank, 1, MPI_COMM_WORLD, &recv_requests[1]);
    MPI_Isend(send_left.data(), nx * ny, MPI_DOUBLE, left_rank, 1, MPI_COMM_WORLD, &send_requests[0]);
    MPI_Isend(send_right.data(), nx * ny, MPI_DOUBLE, right_rank, 0, MPI_COMM_WORLD, &send_requests[1]);
}

void HaloExchange::finish_exchange(std::vector<double>& field) {
    MPI_Waitall(2, recv_requests, MPI_STATUSES_IGNORE);

    for (int i = 0; i < nx; ++i)
        for (int j = 0; j < ny; ++j)
            field[i * ny * nz + j * nz + 0] = recv_left[i * ny + j];

    for (int i = 0; i < nx; ++i)
        for (int j = 0; j < ny; ++j)
            field[i * ny * nz + j * nz + (nz - 1)] = recv_right[i * ny + j];

    MPI_Waitall(2, send_requests, MPI_STATUSES_IGNORE);
}

} // namespace miniw
#endif

