cmake_minimum_required(VERSION 3.6.0)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION
${CMAKE_CURRENT_SOURCE_DIR}/../src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)
set(SOURCES
../../lib/opencv-cpp/emphasize_red.cpp
../../lib/opencv-cpp/emphasize_red.h
)
add_library(emphasize_red SHARED ${SOURCES})
target_link_libraries(emphasize_red lib_opencv)