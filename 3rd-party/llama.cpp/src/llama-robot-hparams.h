#pragma once

// therobot runtime extension — spec loader (work package E1)
//
// Parses the `therobot.*` GGUF key-value contract defined in
// projects/therobotgguf/arch/runtime/gguf-extension-spec.md (spec v1) into
// llama_robot_hparams, and performs feature negotiation: unknown *required*
// features are refused, unknown optional features are ignored, and features
// this runtime knows about but has not implemented yet are refused with a
// distinct error (stage gates: taps/shims land with E2/E3, etc.).
//
// This file is therobot-fork-only code; it must not be included by stock
// upstream translation units (superset invariant, llamacpp-extensions.md §2).

#include "llama-arch.h"

#include <cstdint>
#include <set>
#include <string>
#include <vector>

struct llama_model_loader;
struct gguf_context;

// spec version implemented by this runtime
constexpr uint32_t LLAMA_ROBOT_SPEC_VERSION = 1;

// spec §1.1 `therobot.features` values known to spec v1
enum llama_robot_feature {
    LLAMA_ROBOT_FEATURE_TAPS,
    LLAMA_ROBOT_FEATURE_SHIMS,
    LLAMA_ROBOT_FEATURE_STATE,
    LLAMA_ROBOT_FEATURE_MODULATOR,
    LLAMA_ROBOT_FEATURE_MEMORY,
    LLAMA_ROBOT_FEATURE_DELTA,
    LLAMA_ROBOT_FEATURE_SETTLE,
};

const char * llama_robot_feature_name(llama_robot_feature f);

// spec §1.2 — bottlenecks / taps
struct llama_robot_bottleneck {
    std::string name;
    uint32_t    layer  = 0;             // block index
    std::string point;                  // resid_post | attn_out | ffn_out
    uint32_t    offset = 0;             // channel slice into the hidden dim
    uint32_t    width  = 0;
    std::vector<std::string> attributes;
    float decodability = 0.0f;          // admission scores measured at convert time
    float selectivity  = 0.0f;
};

// spec §1.3 — leaky state banks
struct llama_robot_state_bank {
    std::string name;                   // fast | mid | slow | glacial
    uint32_t    width = 0;              // channels per covered block
};

struct llama_robot_state_params {
    std::vector<llama_robot_state_bank> banks;
    std::vector<uint32_t> layers;       // blocks carrying state branches
};

// spec §1.4 — modulator
struct llama_robot_modulator_params {
    uint32_t dim = 0;                   // 8–32
    std::vector<std::string> channels;  // named, e.g. arousal, valence, attention
    std::string source;                 // pooled | glacial
};

// spec §1.5 — episodic memory
struct llama_robot_memory_params {
    uint32_t key_dim   = 0;
    uint32_t value_dim = 0;
    uint32_t capacity  = 0;             // runtime may override
    float    decay_halflife = 0.0f;     // tokens
    float    salience_threshold_quantile = 0.0f;
};

// spec §1.6 — delta inference
struct llama_robot_delta_params {
    std::string granularity;            // block (v1) | channel_group (reserved)
    uint32_t heartbeat = 0;             // tokens between dense sweeps
    float    target_keep_rate = 0.0f;   // calibration provenance
};

// spec §1.7 — settling
struct llama_robot_settle_params {
    std::string objective;              // mdlm | ...
    uint32_t mask_token_id = 0;
    uint32_t max_steps = 0;
    float    epsilon = 0.0f;
    std::vector<float> m_schedule;      // m-arousal → extra rounds
};

// spec §1 — parsed manifest of a therobot model file
struct llama_robot_hparams {
    uint32_t    spec_version = 0;
    std::string base_architecture;      // wrapped donor family: llama, qwen2, mamba, ...
    llm_arch    base_arch = LLM_ARCH_UNKNOWN;
    uint32_t    level = 0;              // informational only
    std::set<llama_robot_feature> features;           // required (known names)
    std::vector<std::string>      features_required_raw;    // as listed in the file
    std::vector<std::string>      features_unknown_optional; // logged, ignored
    std::string donor_id;               // HF id + revision of the donor
    std::string convert_lockfile_hash;  // provenance

    std::vector<llama_robot_bottleneck> bottlenecks;
    llama_robot_state_params     state;
    llama_robot_modulator_params modulator;
    llama_robot_memory_params    memory;
    llama_robot_delta_params     delta;
    llama_robot_settle_params    settle;

    bool has_feature(llama_robot_feature f) const { return features.count(f) > 0; }

    // L0 passthrough: empty required-feature list — must behave identically to
    // the donor under the base architecture (judged on the file's own list so
    // non-negotiated inspection doesn't misreport files with unknown features)
    bool is_passthrough() const { return features.empty() && features_required_raw.empty(); }
};

// Parse `therobot.*` keys from the loader's metadata. Throws std::runtime_error
// on contract violations: bad spec version, missing/unknown base architecture,
// unknown required feature, known-but-unimplemented required feature, or
// malformed per-feature sections.
void llama_robot_hparams_load(llama_robot_hparams & robot, llama_model_loader & ml);

// Same, from a bare gguf context. With negotiate=false (tools/robot-inspect),
// feature negotiation failures are logged instead of thrown so the manifest of
// a file this runtime cannot yet run can still be dumped.
void llama_robot_hparams_load_gguf(llama_robot_hparams & robot, const gguf_context * ctx, bool negotiate = true);
