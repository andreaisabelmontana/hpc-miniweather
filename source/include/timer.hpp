#pragma once
#include <chrono>
#include <cstddef>

namespace miniw {

class Timer {
public:
	Timer() { start(); }
	void start() { t0 = std::chrono::steady_clock::now(); }
	double elapsed() const { return std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count(); }
private:
	std::chrono::time_point<std::chrono::steady_clock> t0;
};

// Simple version string exported from the core library
const char* core_version();

} // namespace miniw
