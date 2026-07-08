# robot-ffi — C-ABI shim over common_sampler for the Rust robot-tui.
# Produces a static lib (librobot-ffi.a) plus the installed public header.

set(TARGET robot-ffi)

add_library(${TARGET} STATIC robot-ffi.cpp)
target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(${TARGET} PUBLIC llama llama-common ${CMAKE_THREAD_LIBS_INIT})
target_compile_features(${TARGET} PRIVATE cxx_std_17)

# position-independent so it can be linked into the Rust cdylib/bin
set_target_properties(${TARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON)

if(LLAMA_TOOLS_INSTALL)
    install(TARGETS ${TARGET} ARCHIVE)
endif()
