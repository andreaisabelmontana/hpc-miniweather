message(STATUS "Applying Clang toolchain helpers")

if(NOT DEFINED CMAKE_CLANG_OPT_FLAGS)
	set(CMAKE_CLANG_OPT_FLAGS "-O3 -fno-exceptions -fno-rtti")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_CLANG_OPT_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CLANG_OPT_FLAGS} -fno-common")

if(DEFINED ENABLE_SANITIZERS AND ENABLE_SANITIZERS)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address,undefined -fno-omit-frame-pointer")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")
