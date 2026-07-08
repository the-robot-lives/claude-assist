# dependencies

find_package(Threads REQUIRED)

# third-party

# ...

# flags

llama_add_compile_flags()

# tools

if (EMSCRIPTEN)
else()
    add_subdirectory(batched-bench)
    add_subdirectory(gguf-split)
    add_subdirectory(imatrix)
    add_subdirectory(llama-bench)
    add_subdirectory(completion)
    add_subdirectory(perplexity)
    add_subdirectory(quantize)
    if (LLAMA_BUILD_SERVER)
        add_subdirectory(ui)
        add_subdirectory(cli)
        # ROBOT-EXT-BEGIN(build-tools-server)
        # robot-cli (C++ TUI fork) is parked — superseded by the Rust robot-tui
        # crate (tools/robot-tui) driving the robot-ffi C shim. Left in-tree for
        # reference but out of the build.
        # add_subdirectory(robot-cli)
        # ROBOT-EXT-END
        add_subdirectory(server)
    endif()
    add_subdirectory(tokenize)
    add_subdirectory(parser)
    add_subdirectory(tts)
    add_subdirectory(mtmd)
    if (GGML_RPC)
        add_subdirectory(rpc)
    endif()
    if (NOT GGML_BACKEND_DL AND GGML_CPU)
        # these tools use backends directly (no dynamic loading) and depend on CPU backend symbols
        add_subdirectory(cvector-generator)
        add_subdirectory(export-lora)
    endif()
    add_subdirectory(fit-params)
    add_subdirectory(results)
    # ROBOT-EXT-BEGIN(build-tools)
    add_subdirectory(robot-inspect)
    add_subdirectory(robot-run)
    if (LLAMA_BUILD_COMMON)
        add_subdirectory(robot-ffi)   # C shim for the Rust robot-tui
    endif()
    # ROBOT-EXT-END
endif()
