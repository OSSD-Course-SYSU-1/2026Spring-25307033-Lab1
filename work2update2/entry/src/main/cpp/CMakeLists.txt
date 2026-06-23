
# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(nativeDemo)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/player)

add_library(entry SHARED avplayer_playing_ndk.cpp player/avplayer_playing.cpp)
target_link_libraries(entry PUBLIC libace_napi.z.so libhilog_ndk.z.so libavplayer.so libnative_media_core.so libuv.so)