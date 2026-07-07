#pragma once

// therobot runtime extension — shim engine (E3)
//
// Shims are behavior-override adapters scoped to a declared bottleneck slice
// (planning.md §E, gguf-extension-spec.md §4). They ship as standalone
// `therobot-shim` GGUF module files, hot-load/unload per context, and edit the
// slice with a gated FiLM-shaped transform:
//
//     y      = gain ⊙ x + steer + B(A·x)      (missing tensors: gain=1, steer=0, no low-rank term)
//     out    = x + g · (y − x)                 g ∈ {0,1} from the gate, per position
//
// The gate is evaluated *in-graph* (`step(w·x + b_eff)`), so the graph
// topology stays static while the edit toggles per token — this is what keeps
// graph reuse valid. `modulator:` gates parse but are refused until E4.
//
// therobot-fork-only code; llama-context.cpp includes this via a fenced
// insertion (epoch accessor only).

#include "llama-arch.h"

#include "ggml-cpp.h"

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

struct llama_model;
struct llama_robot_model_iface;

// spec §4 `therobot.shim.gate`
struct llama_robot_shim_gate {
    enum gate_kind {
        GATE_ALWAYS,
        GATE_MODULATOR, // parsed, refused at load until E4
        GATE_PROBE,
    };
    gate_kind   kind = GATE_ALWAYS;
    std::string subject; // modulator channel or probe attr
    std::string op;      // > < >= <=
    float       value = 0.0f;
};

struct llama_robot_shim {
    // identity / registry metadata (spec §4)
    uint32_t    spec_version = 0;
    std::string name;
    std::string version;
    std::string target_model;      // donor/model hash admission scores were measured against
    std::string target_bottleneck; // bottleneck name (spec §1.2)
    std::string effect;            // human-readable verified effect
    float       selectivity = 0.0f;
    std::vector<std::string> depends;
    std::vector<std::string> conflicts;
    llama_robot_shim_gate gate;

    // resolved against the model at init
    const llama_model * model = nullptr;
    int32_t  bottleneck_id = -1;
    uint32_t width = 0;

    // tensors, allocated in a CPU backend buffer (v0 targets CPU streaming;
    // the scheduler inserts copies when the model runs elsewhere)
    ggml_context_ptr        ctx;
    ggml_backend_buffer_ptr buf;

    ggml_tensor * t_a     = nullptr; // [width, rank]   low-rank down
    ggml_tensor * t_b     = nullptr; // [rank, width]   low-rank up
    ggml_tensor * t_steer = nullptr; // [width]         additive
    ggml_tensor * t_gain  = nullptr; // [width]         multiplicative
    ggml_tensor * t_gate_w = nullptr; // [width, 1]     gate direction (sign-folded for < / <=)
    ggml_tensor * t_gate_b = nullptr; // [1]            effective bias (op/value folded in)
};

// per-context therobot state: the attached shim set, in attach order
struct llama_robot_context_state {
    uint64_t epoch = 1; // bumps on attach/detach; keyed into llm_graph_params
    std::vector<const llama_robot_shim *> shims;
};

// epoch accessor used by llama_context::graph_params() (fenced call site);
// null state reads as epoch 0
inline uint64_t llama_robot_context_state_epoch(const llama_robot_context_state * st) {
    return st == nullptr ? 0 : st->epoch;
}

// Load and validate a shim module file against a therobot model: arch must be
// "therobot-shim", spec version must match, the target bottleneck must exist
// (taps feature), tensor shapes must match the slice width, and the gate must
// be implementable (`always` / `probe:` for E3). Throws on violations; a
// target_model hash mismatch only warns (admission enforcement is E8).
llama_robot_shim * llama_robot_shim_load(const llama_model * model, const char * path);
