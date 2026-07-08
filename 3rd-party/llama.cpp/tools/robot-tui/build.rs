// Links the Rust TUI against the prebuilt llama.cpp libraries and the robot-ffi
// shim, and generates FFI bindings from wrapper.h with bindgen.
//
// You must build llama.cpp first (with -DLLAMA_BUILD_COMMON=ON so robot-ffi and
// llama-common exist), e.g.:
//   cmake -S 3rd-party/llama.cpp -B 3rd-party/llama.cpp/build -DLLAMA_BUILD_COMMON=ON
//   cmake --build 3rd-party/llama.cpp/build --target robot-ffi -j
//
// Point ROBOT_LLAMA_BUILD at that build dir if it is not ../../build.
// Library names below may need tweaking to match how your ggml backends were
// built (Metal/BLAS/CUDA split libs differ per platform); adjust and rebuild.

use std::{env, path::PathBuf};

fn main() {
    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let llama_root = manifest.join("../..").canonicalize().unwrap();

    let build = env::var("ROBOT_LLAMA_BUILD")
        .map(PathBuf::from)
        .unwrap_or_else(|_| llama_root.join("build"));
    let build = build.canonicalize().unwrap_or(build);
    let b = build.display();

    // ---- link search paths (where cmake dropped the libs) ----
    for d in [
        "bin", "src", "common",
        "ggml/src", "ggml/src/ggml-blas", "ggml/src/ggml-metal", "ggml/src/ggml-cpu",
        "tools/robot-ffi",
    ] {
        println!("cargo:rustc-link-search=native={b}/{d}");
    }

    // ---- static: our shim + common ----
    println!("cargo:rustc-link-lib=static=robot-ffi");
    println!("cargo:rustc-link-lib=static=llama-common");

    // ---- dynamic: llama + ggml backends (adjust to your build) ----
    for l in ["llama", "ggml", "ggml-base", "ggml-cpu"] {
        println!("cargo:rustc-link-lib=dylib={l}");
    }
    // present on typical macOS builds; harmless to request, comment out if absent
    #[cfg(target_os = "macos")]
    {
        println!("cargo:rustc-link-lib=dylib=ggml-metal");
        println!("cargo:rustc-link-lib=dylib=ggml-blas");
        for fw in ["Metal", "MetalKit", "Foundation", "Accelerate"] {
            println!("cargo:rustc-link-lib=framework={fw}");
        }
    }

    // c++ runtime for the shim + common
    #[cfg(target_os = "macos")]
    println!("cargo:rustc-link-lib=dylib=c++");
    #[cfg(target_os = "linux")]
    println!("cargo:rustc-link-lib=dylib=stdc++");

    // find the shared libs at runtime
    println!("cargo:rustc-link-arg=-Wl,-rpath,{b}/bin");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{b}/src");

    // ---- bindgen ----
    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .clang_arg(format!("-I{}/include", llama_root.display()))
        .clang_arg(format!("-I{}/tools/robot-ffi", llama_root.display()))
        .clang_arg(format!("-I{}/ggml/include", llama_root.display()))
        .allowlist_function("llama_.*")
        .allowlist_function("robot_.*")
        .allowlist_type("llama_.*")
        .allowlist_type("robot_.*")
        .allowlist_var("LLAMA_.*")
        .prepend_enum_name(false)
        .generate()
        .expect("bindgen failed");
    bindings
        .write_to_file(PathBuf::from(env::var("OUT_DIR").unwrap()).join("bindings.rs"))
        .expect("write bindings");

    // Re-run bindgen when the wrapper OR any header it includes changes —
    // otherwise edits to llama-robot.h / robot-ffi.h leave stale bindings.
    println!("cargo:rerun-if-changed=wrapper.h");
    println!("cargo:rerun-if-changed={}/include/llama-robot.h", llama_root.display());
    println!("cargo:rerun-if-changed={}/include/llama.h", llama_root.display());
    println!("cargo:rerun-if-changed={}/tools/robot-ffi/robot-ffi.h", llama_root.display());
    println!("cargo:rerun-if-env-changed=ROBOT_LLAMA_BUILD");
}
