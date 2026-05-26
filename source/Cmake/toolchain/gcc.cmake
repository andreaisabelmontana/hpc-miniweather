# This file is intended to hold recommended flags and tweaks for gcc/ g++.

message(STATUS "Applying GCC toolchain helpers")

# The user can override these by setting CMAKE_CXX_FLAGS externally if desired.

if(NOT DEFINED CMAKE_GCC_OPT_FLAGS)
	set(CMAKE_GCC_OPT_FLAGS "-O3 -fno-exceptions -fno-rtti")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_GCC_OPT_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_GCC_OPT_FLAGS} -fno-common")


set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")

