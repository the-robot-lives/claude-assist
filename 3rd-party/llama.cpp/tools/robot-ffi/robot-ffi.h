// robot-ffi — a thin extern "C" shim exposing llama.cpp's common_sampler (the
// same sampler chain llama-cli uses) to non-C++ callers (the Rust robot-tui).
//
// Everything else the TUI needs is already C-ABI: model/context lifecycle and
// decoding from llama.h, chat templating via llama_chat_apply_template, and the
// therobot introspection from llama-robot.h. This shim only wraps the sampler,
// which lives in common/ as C++ and does not otherwise cross the FFI boundary.

#ifndef ROBOT_FFI_H
#define ROBOT_FFI_H

#include "llama.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct robot_sampler robot_sampler;

// Mirror of the common_params_sampling knobs the TUI exposes. Defaults come from
// robot_sampler_default_params(); anything not listed uses common's defaults.
typedef struct robot_sampler_params {
    uint32_t seed;            // LLAMA_DEFAULT_SEED for random
    int32_t  top_k;           // <= 0 to disable
    float    top_p;           // 1.0 to disable
    float    min_p;           // 0.0 to disable
    float    temp;            // <= 0.0 => greedy
    int32_t  penalty_last_n;  // 0 disables, -1 = ctx size
    float    penalty_repeat;  // 1.0 disables
} robot_sampler_params;

// Mute llama AND ggml logging (the Metal backend logs kernel-pipeline compiles
// through ggml, not llama). Call once before loading a model so nothing writes
// to the terminal and corrupts a full-screen TUI.
void robot_silence_logs(void);

// Belt-and-suspenders: redirect the process's stderr (where llama/ggml default
// their output) to `path`, so even a log line that bypasses the callbacks lands
// in a file instead of the terminal. Call before backend init. stdout (the TUI)
// is untouched.
void robot_log_to_file(const char * path);

// sensible chat defaults (temp 0.7, top_p 0.95, top_k 40, repeat 1.1)
robot_sampler_params robot_sampler_default_params(void);

// build a sampler chain for `model`; free with robot_sampler_free
robot_sampler * robot_sampler_init(const struct llama_model * model, robot_sampler_params params);
void            robot_sampler_free(robot_sampler * s);

// sample the next token from the logits at position `idx` (-1 = last), then call
// robot_sampler_accept with the chosen token before the next decode
llama_token robot_sampler_sample(robot_sampler * s, struct llama_context * ctx, int32_t idx);
void        robot_sampler_accept(robot_sampler * s, llama_token id);
void        robot_sampler_reset(robot_sampler * s);

#ifdef __cplusplus
}
#endif

#endif // ROBOT_FFI_H
