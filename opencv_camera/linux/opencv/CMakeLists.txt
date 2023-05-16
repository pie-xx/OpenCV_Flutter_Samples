cmake_minimum_required(VERSION 3.0)
project(tran_library)

set(CMAKE_CXX_STANDARD 11)

set(SOURCE_FILES
        capture.cpp
        capture.h)

find_package(OpenCV REQUIRED)

add_library(OpenCVcamera SHARED ${SOURCE_FILES})
target_link_libraries(OpenCVcamera ${OpenCV_LIBS})
