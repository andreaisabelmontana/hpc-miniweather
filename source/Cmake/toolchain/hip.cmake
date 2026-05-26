message(STATUS "Applying HIP toolchain helpers")

if(NOT DEFINED CMAKE_HIP_FLAGS)
	set(CMAKE_HIP_FLAGS "-O3")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_HIP_FLAGS}")


