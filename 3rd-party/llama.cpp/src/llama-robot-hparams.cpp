// therobot runtime extension — spec loader implementation (E1)
//
// Reads the `therobot.*` contract (gguf-extension-spec.md v1) via the public
// gguf API so it can operate on either a llama_model_loader's metadata or a
// bare gguf_context (tools/robot-inspect uses the latter).

#include "llama-robot-hparams.h"

#include "llama-impl.h"
#include "llama-model-loader.h"

#include "gguf.h"

#include <map>
#include <stdexcept>

//
// low-level KV readers (lenient on integer widths, strict on semantics)
//

static int robot_kv_find(const gguf_context * ctx, const std::string & key) {
    return gguf_find_key(ctx, key.c_str());
}

bool llama_robot_kv_get_str(const gguf_context * ctx, const std::string & key, std::string & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    if (gguf_get_kv_type(ctx, id) != GGUF_TYPE_STRING) {
        throw std::runtime_error(format("therobot: key '%s' must be a string", key.c_str()));
    }
    out = gguf_get_val_str(ctx, id);
    return true;
}

bool llama_robot_kv_get_u32(const gguf_context * ctx, const std::string & key, uint32_t & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    switch (gguf_get_kv_type(ctx, id)) {
        case GGUF_TYPE_UINT8:  out = gguf_get_val_u8 (ctx, id); break;
        case GGUF_TYPE_UINT16: out = gguf_get_val_u16(ctx, id); break;
        case GGUF_TYPE_UINT32: out = gguf_get_val_u32(ctx, id); break;
        case GGUF_TYPE_INT8:   { int8_t  v = gguf_get_val_i8 (ctx, id); if (v < 0) { throw std::runtime_error(format("therobot: key '%s' must be non-negative", key.c_str())); } out = (uint32_t) v; break; }
        case GGUF_TYPE_INT16:  { int16_t v = gguf_get_val_i16(ctx, id); if (v < 0) { throw std::runtime_error(format("therobot: key '%s' must be non-negative", key.c_str())); } out = (uint32_t) v; break; }
        case GGUF_TYPE_INT32:  { int32_t v = gguf_get_val_i32(ctx, id); if (v < 0) { throw std::runtime_error(format("therobot: key '%s' must be non-negative", key.c_str())); } out = (uint32_t) v; break; }
        default:
            throw std::runtime_error(format("therobot: key '%s' must be an unsigned integer", key.c_str()));
    }
    return true;
}

bool llama_robot_kv_get_f32(const gguf_context * ctx, const std::string & key, float & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    switch (gguf_get_kv_type(ctx, id)) {
        case GGUF_TYPE_FLOAT32: out = gguf_get_val_f32(ctx, id); break;
        case GGUF_TYPE_FLOAT64: out = (float) gguf_get_val_f64(ctx, id); break;
        default:
            throw std::runtime_error(format("therobot: key '%s' must be a float", key.c_str()));
    }
    return true;
}

bool llama_robot_kv_get_str_arr(const gguf_context * ctx, const std::string & key, std::vector<std::string> & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    if (gguf_get_kv_type(ctx, id) != GGUF_TYPE_ARRAY || gguf_get_arr_type(ctx, id) != GGUF_TYPE_STRING) {
        throw std::runtime_error(format("therobot: key '%s' must be an array of strings", key.c_str()));
    }
    const size_t n = gguf_get_arr_n(ctx, id);
    out.clear();
    out.reserve(n);
    for (size_t i = 0; i < n; ++i) {
        out.emplace_back(gguf_get_arr_str(ctx, id, i));
    }
    return true;
}

static bool robot_kv_get_u32_arr(const gguf_context * ctx, const std::string & key, std::vector<uint32_t> & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    if (gguf_get_kv_type(ctx, id) != GGUF_TYPE_ARRAY) {
        throw std::runtime_error(format("therobot: key '%s' must be an array", key.c_str()));
    }
    const size_t n = gguf_get_arr_n(ctx, id);
    const void * data = gguf_get_arr_data(ctx, id);
    out.clear();
    out.reserve(n);
    switch (gguf_get_arr_type(ctx, id)) {
        case GGUF_TYPE_UINT32: for (size_t i = 0; i < n; ++i) { out.push_back(((const uint32_t *) data)[i]); } break;
        case GGUF_TYPE_INT32:  for (size_t i = 0; i < n; ++i) {
                const int32_t v = ((const int32_t *) data)[i];
                if (v < 0) { throw std::runtime_error(format("therobot: key '%s' entries must be non-negative", key.c_str())); }
                out.push_back((uint32_t) v);
            } break;
        default:
            throw std::runtime_error(format("therobot: key '%s' must be an array of unsigned integers", key.c_str()));
    }
    return true;
}

static bool robot_kv_get_f32_arr(const gguf_context * ctx, const std::string & key, std::vector<float> & out, bool required) {
    const int id = robot_kv_find(ctx, key);
    if (id < 0) {
        if (required) {
            throw std::runtime_error(format("therobot: missing required key '%s'", key.c_str()));
        }
        return false;
    }
    if (gguf_get_kv_type(ctx, id) != GGUF_TYPE_ARRAY || gguf_get_arr_type(ctx, id) != GGUF_TYPE_FLOAT32) {
        throw std::runtime_error(format("therobot: key '%s' must be an array of f32", key.c_str()));
    }
    const size_t n = gguf_get_arr_n(ctx, id);
    const float * data = (const float *) gguf_get_arr_data(ctx, id);
    out.assign(data, data + n);
    return true;
}

//
// feature negotiation
//

static const std::map<std::string, llama_robot_feature> LLAMA_ROBOT_FEATURE_NAMES = {
    { "taps",      LLAMA_ROBOT_FEATURE_TAPS      },
    { "shims",     LLAMA_ROBOT_FEATURE_SHIMS     },
    { "state",     LLAMA_ROBOT_FEATURE_STATE     },
    { "modulator", LLAMA_ROBOT_FEATURE_MODULATOR },
    { "memory",    LLAMA_ROBOT_FEATURE_MEMORY    },
    { "delta",     LLAMA_ROBOT_FEATURE_DELTA     },
    { "settle",    LLAMA_ROBOT_FEATURE_SETTLE    },
};

// features whose runtime behavior is actually implemented. Grows with the
// work packages: E2 adds taps, E3 shims, E4 state+modulator, E5 memory,
// E6 delta, E7 settle. A file *requiring* a known-but-unimplemented feature
// is refused — running it degraded would violate the required-feature
// semantics of spec §1.1.
static const std::set<llama_robot_feature> LLAMA_ROBOT_FEATURES_IMPLEMENTED = {
    LLAMA_ROBOT_FEATURE_TAPS,      // E2 — bottleneck taps + probe heads
    LLAMA_ROBOT_FEATURE_SHIMS,     // E3 — slice-scoped shim engine (module files, hot attach/detach)
    LLAMA_ROBOT_FEATURE_STATE,     // E4 — grafted leaky state banks
    LLAMA_ROBOT_FEATURE_MODULATOR, // E4 — modulator bus m + FiLM gating
    LLAMA_ROBOT_FEATURE_MEMORY,    // E5 — salience-gated episodic store feeding m
    LLAMA_ROBOT_FEATURE_DELTA,     // E6 — change-triggered execution (off by default per context)
    LLAMA_ROBOT_FEATURE_SETTLE,    // E7 — canvas settling decoder (jacobi-ar objective)
};

const char * llama_robot_feature_name(llama_robot_feature f) {
    for (const auto & kv : LLAMA_ROBOT_FEATURE_NAMES) {
        if (kv.second == f) {
            return kv.first.c_str();
        }
    }
    return "(unknown)";
}

//
// per-feature section parsers (spec §1.2–§1.7)
//

static void robot_load_bottlenecks(llama_robot_hparams & robot, const gguf_context * ctx) {
    uint32_t count = 0;
    llama_robot_kv_get_u32(ctx, "therobot.bottleneck.count", count, true);
    robot.bottlenecks.resize(count);
    for (uint32_t i = 0; i < count; ++i) {
        auto & bn = robot.bottlenecks[i];
        const std::string p = format("therobot.bottleneck.%u.", i);
        llama_robot_kv_get_str    (ctx, p + "name",         bn.name,         true);
        llama_robot_kv_get_u32    (ctx, p + "layer",        bn.layer,        true);
        llama_robot_kv_get_str    (ctx, p + "point",        bn.point,        true);
        llama_robot_kv_get_u32    (ctx, p + "offset",       bn.offset,       true);
        llama_robot_kv_get_u32    (ctx, p + "width",        bn.width,        true);
        llama_robot_kv_get_str_arr(ctx, p + "attributes",   bn.attributes,   true);
        llama_robot_kv_get_f32    (ctx, p + "decodability", bn.decodability, false);
        llama_robot_kv_get_f32    (ctx, p + "selectivity",  bn.selectivity,  false);
        if (bn.point != "resid_post" && bn.point != "attn_out" && bn.point != "ffn_out") {
            throw std::runtime_error(format("therobot: bottleneck %u has invalid point '%s' (expected resid_post|attn_out|ffn_out)", i, bn.point.c_str()));
        }
        if (bn.width == 0) {
            throw std::runtime_error(format("therobot: bottleneck %u has zero width", i));
        }
    }
}

static void robot_load_state(llama_robot_hparams & robot, const gguf_context * ctx) {
    uint32_t bank_count = 0;
    llama_robot_kv_get_u32(ctx, "therobot.state.bank_count", bank_count, true);
    robot.state.banks.resize(bank_count);
    for (uint32_t b = 0; b < bank_count; ++b) {
        auto & bank = robot.state.banks[b];
        const std::string p = format("therobot.state.bank.%u.", b);
        llama_robot_kv_get_str(ctx, p + "name",  bank.name,  true);
        llama_robot_kv_get_u32(ctx, p + "width", bank.width, true);
        if (bank.name != "fast" && bank.name != "mid" && bank.name != "slow" && bank.name != "glacial") {
            throw std::runtime_error(format("therobot: state bank %u has invalid name '%s' (expected fast|mid|slow|glacial)", b, bank.name.c_str()));
        }
    }
    robot_kv_get_u32_arr(ctx, "therobot.state.layers", robot.state.layers, true);
}

static void robot_load_modulator(llama_robot_hparams & robot, const gguf_context * ctx) {
    llama_robot_kv_get_u32    (ctx, "therobot.modulator.dim",      robot.modulator.dim,      true);
    llama_robot_kv_get_str_arr(ctx, "therobot.modulator.channels", robot.modulator.channels, true);
    llama_robot_kv_get_str    (ctx, "therobot.modulator.source",   robot.modulator.source,   true);
    if (robot.modulator.source != "pooled" && robot.modulator.source != "glacial") {
        throw std::runtime_error(format("therobot: invalid modulator source '%s' (expected pooled|glacial)", robot.modulator.source.c_str()));
    }
    if (robot.modulator.source == "glacial" && !robot.has_feature(LLAMA_ROBOT_FEATURE_STATE)) {
        throw std::runtime_error("therobot: modulator source 'glacial' requires the 'state' feature");
    }
}

static void robot_load_memory(llama_robot_hparams & robot, const gguf_context * ctx) {
    llama_robot_kv_get_u32(ctx, "therobot.memory.key_dim",   robot.memory.key_dim,   true);
    llama_robot_kv_get_u32(ctx, "therobot.memory.value_dim", robot.memory.value_dim, true);
    llama_robot_kv_get_u32(ctx, "therobot.memory.capacity",  robot.memory.capacity,  true);
    llama_robot_kv_get_f32(ctx, "therobot.memory.decay_halflife", robot.memory.decay_halflife, true);
    llama_robot_kv_get_f32(ctx, "therobot.memory.salience.threshold_quantile", robot.memory.salience_threshold_quantile, true);
    // absolute salience floor (optional, default 0 = relative gate only)
    llama_robot_kv_get_f32(ctx, "therobot.memory.salience.floor", robot.memory.salience_floor, false);
}

static void robot_load_delta(llama_robot_hparams & robot, const gguf_context * ctx) {
    llama_robot_kv_get_str(ctx, "therobot.delta.granularity", robot.delta.granularity, true);
    llama_robot_kv_get_u32(ctx, "therobot.delta.heartbeat",   robot.delta.heartbeat,   true);
    llama_robot_kv_get_f32(ctx, "therobot.delta.target_keep_rate", robot.delta.target_keep_rate, false);
    if (robot.delta.granularity != "block") {
        // channel_group is reserved by spec v1 but not accepted by any runtime yet
        throw std::runtime_error(format("therobot: unsupported delta granularity '%s' (v1 accepts 'block')", robot.delta.granularity.c_str()));
    }
}

static void robot_load_settle(llama_robot_hparams & robot, const gguf_context * ctx) {
    llama_robot_kv_get_str    (ctx, "therobot.settle.objective",     robot.settle.objective,     true);
    llama_robot_kv_get_u32    (ctx, "therobot.settle.mask_token_id", robot.settle.mask_token_id, true);
    llama_robot_kv_get_u32    (ctx, "therobot.settle.max_steps",     robot.settle.max_steps,     true);
    llama_robot_kv_get_f32    (ctx, "therobot.settle.epsilon",       robot.settle.epsilon,       true);
    robot_kv_get_f32_arr(ctx, "therobot.settle.m_schedule",    robot.settle.m_schedule,    false);
}

// sentinel key whose presence indicates the feature's KV section was emitted
static const char * robot_feature_probe_key(llama_robot_feature f) {
    switch (f) {
        case LLAMA_ROBOT_FEATURE_TAPS:      return "therobot.bottleneck.count";
        case LLAMA_ROBOT_FEATURE_STATE:     return "therobot.state.bank_count";
        case LLAMA_ROBOT_FEATURE_MODULATOR: return "therobot.modulator.dim";
        case LLAMA_ROBOT_FEATURE_MEMORY:    return "therobot.memory.key_dim";
        case LLAMA_ROBOT_FEATURE_DELTA:     return "therobot.delta.granularity";
        case LLAMA_ROBOT_FEATURE_SETTLE:    return "therobot.settle.objective";
        case LLAMA_ROBOT_FEATURE_SHIMS:     return nullptr; // shims ship as separate module files (spec §4)
    }
    return nullptr;
}

//
// entry points
//

void llama_robot_hparams_load_gguf(llama_robot_hparams & robot, const gguf_context * ctx, bool negotiate) {
    // §1.1 identity & negotiation
    llama_robot_kv_get_u32(ctx, "therobot.spec_version", robot.spec_version, true);
    if (robot.spec_version != LLAMA_ROBOT_SPEC_VERSION) {
        throw std::runtime_error(format(
            "therobot: file requires spec version %u, this runtime implements version %u "
            "(contracts are never patched in place — upgrade the runtime)",
            robot.spec_version, LLAMA_ROBOT_SPEC_VERSION));
    }

    llama_robot_kv_get_str(ctx, "therobot.base_architecture", robot.base_architecture, true);
    robot.base_arch = llm_arch_from_string(robot.base_architecture);
    if (robot.base_arch == LLM_ARCH_UNKNOWN || robot.base_arch == LLM_ARCH_THEROBOT || robot.base_arch == LLM_ARCH_CLIP) {
        throw std::runtime_error(format("therobot: unknown or invalid base architecture '%s'", robot.base_architecture.c_str()));
    }

    llama_robot_kv_get_u32(ctx, "therobot.level", robot.level, false); // informational only
    llama_robot_kv_get_str(ctx, "therobot.donor.id", robot.donor_id, false);
    llama_robot_kv_get_str(ctx, "therobot.convert.lockfile_hash", robot.convert_lockfile_hash, false);

    // required features: refuse unknown; refuse known-but-unimplemented
    llama_robot_kv_get_str_arr(ctx, "therobot.features", robot.features_required_raw, false); // missing == empty == L0
    for (const auto & name : robot.features_required_raw) {
        const auto it = LLAMA_ROBOT_FEATURE_NAMES.find(name);
        if (it == LLAMA_ROBOT_FEATURE_NAMES.end()) {
            if (negotiate) {
                throw std::runtime_error(format("therobot: file requires unknown feature '%s' — refusing to load", name.c_str()));
            }
            LLAMA_LOG_WARN("therobot: file requires unknown feature '%s' — this runtime would refuse to load it\n", name.c_str());
            continue;
        }
        if (negotiate && LLAMA_ROBOT_FEATURES_IMPLEMENTED.count(it->second) == 0) {
            throw std::runtime_error(format(
                "therobot: file requires feature '%s', which this runtime does not implement yet — refusing to load",
                name.c_str()));
        }
        robot.features.insert(it->second);
    }

    // optional features: known ones are honored, unknown ones logged and ignored
    std::vector<std::string> optional_names;
    llama_robot_kv_get_str_arr(ctx, "therobot.features_optional", optional_names, false);
    for (const auto & name : optional_names) {
        const auto it = LLAMA_ROBOT_FEATURE_NAMES.find(name);
        if (it == LLAMA_ROBOT_FEATURE_NAMES.end()) {
            robot.features_unknown_optional.push_back(name);
            LLAMA_LOG_WARN("therobot: ignoring unknown optional feature '%s'\n", name.c_str());
            continue;
        }
        if (negotiate && LLAMA_ROBOT_FEATURES_IMPLEMENTED.count(it->second) == 0) {
            LLAMA_LOG_WARN("therobot: optional feature '%s' not implemented by this runtime — ignoring\n", name.c_str());
            continue;
        }
        // optional feature declared but its KV section never emitted: drop it
        const char * probe = robot_feature_probe_key(it->second);
        if (probe != nullptr && robot_kv_find(ctx, probe) < 0) {
            LLAMA_LOG_WARN("therobot: optional feature '%s' declared but its section is missing — ignoring\n", name.c_str());
            continue;
        }
        robot.features.insert(it->second);
    }

    // per-feature sections — parsed only for negotiated features
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS))      { robot_load_bottlenecks(robot, ctx); }
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_STATE))     { robot_load_state      (robot, ctx); }
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) { robot_load_modulator  (robot, ctx); }
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_MEMORY))    { robot_load_memory     (robot, ctx); }
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_DELTA))     { robot_load_delta      (robot, ctx); }
    if (robot.has_feature(LLAMA_ROBOT_FEATURE_SETTLE))    { robot_load_settle     (robot, ctx); }

    if (robot.is_passthrough()) {
        LLAMA_LOG_INFO("therobot: L0 passthrough file (base architecture '%s') — must behave identically to the donor\n",
                robot.base_architecture.c_str());
    }
}

void llama_robot_hparams_load(llama_robot_hparams & robot, llama_model_loader & ml) {
    if (ml.metadata == nullptr) {
        throw std::runtime_error("therobot: model loader has no gguf metadata");
    }
    llama_robot_hparams_load_gguf(robot, ml.metadata);
}
