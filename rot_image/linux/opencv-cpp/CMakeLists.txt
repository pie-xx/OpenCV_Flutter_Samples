cmake_minimum_required(VERSION 3.0)
project(tran_library)
set(CMAKE_CXX_STANDARD 11)
set(SOURCE_FILES
 rot.cpp
 rot.h)
find_package(OpenCV REQUIRED)
add_library(OpenCV_ffi SHARED ${SOURCE_FILES})
target_link_libraries(OpenCV_ffi ${OpenCV_LIBS})
