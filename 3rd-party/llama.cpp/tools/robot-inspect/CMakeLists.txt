# therobot runtime extension — manifest inspection tool (E1)
set(TARGET llama-robot-inspect)

add_executable(${TARGET} robot-inspect.cpp)
target_link_libraries(${TARGET} PRIVATE llama ${CMAKE_THREAD_LIBS_INIT})
target_compile_features(${TARGET} PRIVATE cxx_std_17)

if(LLAMA_TOOLS_INSTALL)
    install(TARGETS ${TARGET} RUNTIME)
endif()
