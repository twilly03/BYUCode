cmake_minimum_required(VERSION 3.16)
project(DataLog)

set(CMAKE_CXX_STANDARD 17)

file(GLOB SOURCES
        *.h
        *.cpp
        )

add_executable(DataLog ${SOURCES})

