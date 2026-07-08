# llama-robot-cli — a fork of tools/cli (llama-cli) that adds a live therobot
# status panel (modulator / probes / episodic memory / delta) as a scroll-region
# top panel over the normal streaming chat. Depends on server-context like cli.

set(TARGET llama-robot-cli-impl)

add_library(${TARGET} robot-cli.cpp)
set_target_properties(${TARGET} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)

target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ../server)
target_link_libraries(${TARGET} PUBLIC server-context llama-common ${CMAKE_THREAD_LIBS_INIT})

if(LLAMA_TOOLS_INSTALL)
    install(TARGETS ${TARGET} LIBRARY)
endif()

# llama-robot-cli executable

set(TARGET llama-robot-cli)

add_executable(${TARGET} main.cpp)
target_link_libraries(${TARGET} PRIVATE llama-robot-cli-impl)
target_compile_features(${TARGET} PRIVATE cxx_std_17)

if(LLAMA_TOOLS_INSTALL)
    install(TARGETS ${TARGET} RUNTIME)
endif()
