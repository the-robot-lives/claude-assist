// therobot runtime extension — tap read-back + probe evaluation (E2)
//
// Implements the public API in include/llama-robot.h. Tap tensors are named
// graph outputs (`robot_tap-<i>`, added by llama_robot_graph_add_taps); after
// a decode they are located by name in the most recent graph and their last
// position is copied out. Probe heads are small host-side linear layers over
// a tap slice, materialized at load by llama_robot_materialize_ext_tensors.

#include "llama-robot.h"

#include "llama-context.h"
#include "llama-graph.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-delta.h"
#include "llama-robot-memory.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"
#include "llama-robot-state.h"

#include "ggml.h"

#include <algorithm>
#include <cstring>
#include <vector>

static const llama_robot_model_iface * robot_iface(const llama_model * model) {
    return dynamic_cast<const llama_robot_model_iface *>(model);
}

bool llama_robot_enabled(const llama_model * model) {
    return robot_iface(model) != nullptr;
}

int32_t llama_robot_tap_count(const llama_model * model) {
    const auto * iface = robot_iface(model);
    return iface == nullptr ? 0 : (int32_t) iface->robot.bottlenecks.size();
}

static const llama_robot_bottleneck * robot_tap(const llama_model * model, int32_t tap_id) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || tap_id < 0 || (size_t) tap_id >= iface->robot.bottlenecks.size()) {
        return nullptr;
    }
    return &iface->robot.bottlenecks[tap_id];
}

const char * llama_robot_tap_name(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? nullptr : bn->name.c_str();
}

const char * llama_robot_tap_point(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? nullptr : bn->point.c_str();
}

int32_t llama_robot_tap_width(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? -1 : (int32_t) bn->width;
}

int32_t llama_robot_tap_layer(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? -1 : (int32_t) bn->layer;
}

int32_t llama_robot_tap_attr_count(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? 0 : (int32_t) bn->attributes.size();
}

const char * llama_robot_tap_attr(const llama_model * model, int32_t tap_id, int32_t attr_id) {
    const auto * bn = robot_tap(model, tap_id);
    if (bn == nullptr || attr_id < 0 || (size_t) attr_id >= bn->attributes.size()) {
        return nullptr;
    }
    return bn->attributes[attr_id].c_str();
}

bool llama_robot_tap_read(llama_context * ctx, int32_t tap_id, float * dst) {
    const auto * bn = robot_tap(&ctx->get_model(), tap_id);
    if (bn == nullptr || dst == nullptr) {
        return false;
    }

    // make sure any in-flight (async) compute has finished
    ctx->synchronize();

    llm_graph_result * res = ctx->robot_last_res();
    if (res == nullptr) {
        return false;
    }
    ggml_cgraph * gf = res->get_gf();
    if (gf == nullptr) {
        return false;
    }

    ggml_tensor * tap = ggml_graph_get_tensor(gf, format("robot_tap-%d", tap_id).c_str());
    if (tap == nullptr || tap->buffer == nullptr) {
        return false; // tap disabled, or no graph computed yet
    }

    GGML_ASSERT(tap->type == GGML_TYPE_F32);
    GGML_ASSERT(tap->ne[0] == (int64_t) bn->width);

    const int64_t rows = tap->ne[1];
    if (rows <= 0) {
        return false; // e.g. a last-layer tap in a decode with no requested outputs
    }

    // most recent position = last row of the (contiguous) tap tensor
    const size_t row_bytes = (size_t) bn->width * sizeof(float);
    ggml_backend_tensor_get(tap, dst, (size_t) (rows - 1) * row_bytes, row_bytes);

    return true;
}

// probe head tensors for (tap, attr) — spec §1.2: robot.probe.{i}.{attr}.weight/.bias
static ggml_tensor * robot_probe_weight(const llama_robot_model_iface * iface, int32_t tap_id, const char * attr) {
    return iface->robot_ext_tensor(format("robot.probe.%d.%s.weight", tap_id, attr));
}

int32_t llama_robot_probe_dim(const llama_model * model, int32_t tap_id, const char * attr) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || attr == nullptr || robot_tap(model, tap_id) == nullptr) {
        return -1;
    }
    const ggml_tensor * w = robot_probe_weight(iface, tap_id, attr);
    return w == nullptr ? -1 : (int32_t) w->ne[1];
}

bool llama_robot_probe_eval(llama_context * ctx, int32_t tap_id, const char * attr, float * dst) {
    const llama_model * model = &ctx->get_model();
    const auto * iface = robot_iface(model);
    const auto * bn    = robot_tap(model, tap_id);
    if (iface == nullptr || bn == nullptr || attr == nullptr || dst == nullptr) {
        return false;
    }

    const ggml_tensor * w = robot_probe_weight(iface, tap_id, attr);
    if (w == nullptr) {
        LLAMA_LOG_WARN("therobot: no probe head 'robot.probe.%d.%s.*' in this model\n", tap_id, attr);
        return false;
    }
    if (w->ne[0] != (int64_t) bn->width) {
        LLAMA_LOG_ERROR("therobot: probe 'robot.probe.%d.%s.weight' input dim %lld != tap width %u\n",
                tap_id, attr, (long long) w->ne[0], bn->width);
        return false;
    }
    const ggml_tensor * b = iface->robot_ext_tensor(format("robot.probe.%d.%s.bias", tap_id, attr));

    std::vector<float> x(bn->width);
    if (!llama_robot_tap_read(ctx, tap_id, x.data())) {
        return false;
    }

    const int64_t n_in  = w->ne[0];
    const int64_t n_out = w->ne[1];

    // probe heads are small and quantization-exempt (spec §2): f32 or f16
    for (int64_t o = 0; o < n_out; ++o) {
        float acc = 0.0f;
        if (w->type == GGML_TYPE_F32) {
            const float * wrow = (const float *) ((const char *) w->data + o*w->nb[1]);
            for (int64_t k = 0; k < n_in; ++k) {
                acc += wrow[k] * x[k];
            }
        } else if (w->type == GGML_TYPE_F16) {
            const ggml_fp16_t * wrow = (const ggml_fp16_t *) ((const char *) w->data + o*w->nb[1]);
            for (int64_t k = 0; k < n_in; ++k) {
                acc += ggml_fp16_to_fp32(wrow[k]) * x[k];
            }
        } else {
            LLAMA_LOG_ERROR("therobot: probe weight type %s not supported (expected f32/f16)\n", ggml_type_name(w->type));
            return false;
        }
        if (b != nullptr) {
            if (b->type == GGML_TYPE_F32) {
                acc += ((const float *) b->data)[o];
            } else if (b->type == GGML_TYPE_F16) {
                acc += ggml_fp16_to_fp32(((const ggml_fp16_t *) b->data)[o]);
            }
        }
        dst[o] = acc;
    }

    return true;
}

//
// E3 — shim lifecycle + per-context attach/detach
//

llama_robot_shim * llama_robot_shim_init(const llama_model * model, const char * path) {
    try {
        return llama_robot_shim_load(model, path);
    } catch (const std::exception & e) {
        LLAMA_LOG_ERROR("%s\n", e.what());
        return nullptr;
    }
}

void llama_robot_shim_free(llama_robot_shim * shim) {
    delete shim;
}

const char * llama_robot_shim_name(const llama_robot_shim * shim) {
    return shim == nullptr ? nullptr : shim->name.c_str();
}

const char * llama_robot_shim_version(const llama_robot_shim * shim) {
    return shim == nullptr ? nullptr : shim->version.c_str();
}

const char * llama_robot_shim_effect(const llama_robot_shim * shim) {
    return shim == nullptr ? nullptr : shim->effect.c_str();
}

const char * llama_robot_shim_target(const llama_robot_shim * shim) {
    return shim == nullptr ? nullptr : shim->target_bottleneck.c_str();
}

float llama_robot_shim_selectivity(const llama_robot_shim * shim) {
    return shim == nullptr ? 0.0f : shim->selectivity;
}

static bool robot_state_has(const llama_robot_context_state * st, const std::string & name) {
    if (st == nullptr) {
        return false;
    }
    for (const auto * s : st->shims) {
        if (s->name == name) {
            return true;
        }
    }
    return false;
}

bool llama_robot_shim_attach(llama_context * ctx, const llama_robot_shim * shim) {
    if (ctx == nullptr || shim == nullptr) {
        return false;
    }
    if (shim->model != &ctx->get_model()) {
        LLAMA_LOG_ERROR("therobot: shim '%s' was loaded against a different model\n", shim->name.c_str());
        return false;
    }

    auto & st = ctx->robot_state;
    if (!st) {
        st = std::make_shared<llama_robot_context_state>();
    }

    if (robot_state_has(st.get(), shim->name)) {
        LLAMA_LOG_ERROR("therobot: shim '%s' is already attached\n", shim->name.c_str());
        return false;
    }

    // registry metadata (spec §4): dependencies must already be attached ...
    for (const auto & dep : shim->depends) {
        if (!robot_state_has(st.get(), dep)) {
            LLAMA_LOG_ERROR("therobot: shim '%s' depends on '%s', which is not attached\n",
                    shim->name.c_str(), dep.c_str());
            return false;
        }
    }
    // ... and conflicts are checked in both directions
    for (const auto & con : shim->conflicts) {
        if (robot_state_has(st.get(), con)) {
            LLAMA_LOG_ERROR("therobot: shim '%s' conflicts with attached shim '%s'\n",
                    shim->name.c_str(), con.c_str());
            return false;
        }
    }
    for (const auto * s : st->shims) {
        if (std::find(s->conflicts.begin(), s->conflicts.end(), shim->name) != s->conflicts.end()) {
            LLAMA_LOG_ERROR("therobot: attached shim '%s' declares a conflict with '%s'\n",
                    s->name.c_str(), shim->name.c_str());
            return false;
        }
    }

    st->shims.push_back(shim);
    st->epoch++; // invalidates graph reuse → next decode rebuilds with the shim

    LLAMA_LOG_INFO("therobot: attached shim '%s' → '%s' (%d attached)\n",
            shim->name.c_str(), shim->target_bottleneck.c_str(), (int) st->shims.size());
    return true;
}

bool llama_robot_shim_detach(llama_context * ctx, const char * name) {
    if (ctx == nullptr || name == nullptr || !ctx->robot_state) {
        return false;
    }
    auto & st = *ctx->robot_state;

    // refuse while another attached shim depends on it
    for (const auto * s : st.shims) {
        if (s->name != name &&
            std::find(s->depends.begin(), s->depends.end(), name) != s->depends.end()) {
            LLAMA_LOG_ERROR("therobot: cannot detach '%s': attached shim '%s' depends on it\n",
                    name, s->name.c_str());
            return false;
        }
    }

    for (auto it = st.shims.begin(); it != st.shims.end(); ++it) {
        if ((*it)->name == name) {
            st.shims.erase(it);
            st.epoch++;
            LLAMA_LOG_INFO("therobot: detached shim '%s' (%d attached)\n", name, (int) st.shims.size());
            return true;
        }
    }
    LLAMA_LOG_ERROR("therobot: no attached shim named '%s'\n", name);
    return false;
}

int32_t llama_robot_shim_count(const llama_context * ctx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return 0;
    }
    return (int32_t) ctx->robot_state->shims.size();
}

//
// E4 — modulator access + session checkpoint
//

int32_t llama_robot_mod_dim(const llama_model * model) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || !iface->robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) {
        return 0;
    }
    return (int32_t) iface->robot.modulator.dim;
}

const char * llama_robot_mod_channel(const llama_model * model, int32_t i) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || i < 0 || (size_t) i >= iface->robot.modulator.channels.size()) {
        return nullptr;
    }
    return iface->robot.modulator.channels[i].c_str();
}

static llama_robot_context_state * robot_session_state(llama_context * ctx) {
    if (ctx == nullptr) {
        return nullptr;
    }
    llama_robot_state_prepare(ctx); // idempotent; sizes m/banks on first use
    auto & st = ctx->robot_state;
    return st && st->state_ready ? st.get() : nullptr;
}

bool llama_robot_mod_get(llama_context * ctx, float * dst) {
    auto * st = robot_session_state(ctx);
    if (st == nullptr || st->m.empty() || dst == nullptr) {
        return false;
    }
    memcpy(dst, st->m.data(), st->m.size() * sizeof(float));
    return true;
}

bool llama_robot_mod_set(llama_context * ctx, const float * src) {
    auto * st = robot_session_state(ctx);
    if (st == nullptr || st->m.empty() || src == nullptr) {
        return false;
    }
    memcpy(st->m.data(), src, st->m.size() * sizeof(float));
    return true;
}

void llama_robot_session_reset(llama_context * ctx, bool forget_memory) {
    if (ctx == nullptr || !ctx->robot_state) {
        return;
    }
    auto & st = *ctx->robot_state;

    // modulator m and the leaky state banks back to baseline (the arrow of
    // time is wiped — next decode starts as if the session just began)
    std::fill(st.m.begin(), st.m.end(), 0.0f);
    for (auto & [layer, bank] : st.banks) {
        std::fill(bank.begin(), bank.end(), 0.0f);
    }

    // E5 transient state: recall, the running surprise/salience history, and
    // the last summary. The episodic store itself is kept unless asked to
    // forget (long-term memory survives a session reset by default).
    std::fill(st.recall.begin(), st.recall.end(), 0.0f);
    st.last_summary.clear();
    st.prev_logits.clear();
    st.salience_window.clear();
    st.mem_clock = 0;
    if (forget_memory) {
        st.mem.clear();
    }

    // E6 delta holds: clear them and force a dense sweep on the next streaming
    // token so the held outputs re-initialize cleanly
    for (auto & b : st.delta) {
        std::fill(b.held_in.begin(),  b.held_in.end(),  0.0f);
        std::fill(b.held_out.begin(), b.held_out.end(), 0.0f);
        b.fatigue = 0.0f;
    }
    st.delta_since_dense = UINT64_MAX;

    LLAMA_LOG_INFO("therobot: session reset (arrow of time cleared%s)\n",
            forget_memory ? ", episodic memory forgotten" : ", memory kept");
}

// blob v2: magic, version, M, m[], n_banks, { layer, S, s[] }*,
//          mem_clock u64, recall_len, recall[], summary_len, summary[],
//          n_entries, { salience, timestamp u64, key_len, key[], val_len, val[] }*
static constexpr uint32_t ROBOT_SESSION_MAGIC   = 0x52534553; // "RSES"
static constexpr uint32_t ROBOT_SESSION_VERSION = 2;

size_t llama_robot_session_size(llama_context * ctx) {
    const auto * st = robot_session_state(ctx);
    if (st == nullptr) {
        return 0;
    }
    size_t n = 4 * sizeof(uint32_t) + st->m.size() * sizeof(float);
    for (const auto & [L, bank] : st->banks) {
        n += 2 * sizeof(uint32_t) + bank.size() * sizeof(float);
    }
    // E5 memory section
    n += sizeof(uint64_t);                                        // clock
    n += sizeof(uint32_t) + st->recall.size() * sizeof(float);    // recall
    n += sizeof(uint32_t) + st->last_summary.size() * sizeof(float); // summary
    n += sizeof(uint32_t);                                        // n_entries
    for (const auto & e : st->mem) {
        n += sizeof(float) + sizeof(uint64_t);
        n += sizeof(uint32_t) + e.key.size() * sizeof(float);
        n += sizeof(uint32_t) + e.value.size() * sizeof(float);
    }
    return n;
}

size_t llama_robot_session_save(llama_context * ctx, uint8_t * dst, size_t size) {
    const auto * st = robot_session_state(ctx);
    const size_t need = llama_robot_session_size(ctx);
    if (st == nullptr || dst == nullptr || size < need) {
        return 0;
    }
    uint8_t * p = dst;
    auto put_u32 = [&](uint32_t v) { memcpy(p, &v, 4); p += 4; };
    auto put_f32 = [&](const std::vector<float> & v) { memcpy(p, v.data(), v.size() * 4); p += v.size() * 4; };

    put_u32(ROBOT_SESSION_MAGIC);
    put_u32(ROBOT_SESSION_VERSION);
    put_u32((uint32_t) st->m.size());
    put_f32(st->m);
    put_u32((uint32_t) st->banks.size());
    for (const auto & [L, bank] : st->banks) {
        put_u32(L);
        put_u32((uint32_t) bank.size());
        put_f32(bank);
    }

    // E5 memory section
    auto put_u64 = [&](uint64_t v) { memcpy(p, &v, 8); p += 8; };
    put_u64(st->mem_clock);
    put_u32((uint32_t) st->recall.size());
    put_f32(st->recall);
    put_u32((uint32_t) st->last_summary.size());
    put_f32(st->last_summary);
    put_u32((uint32_t) st->mem.size());
    for (const auto & e : st->mem) {
        memcpy(p, &e.salience, 4); p += 4;
        put_u64(e.timestamp);
        put_u32((uint32_t) e.key.size());
        put_f32(e.key);
        put_u32((uint32_t) e.value.size());
        put_f32(e.value);
    }
    return (size_t) (p - dst);
}

size_t llama_robot_session_load(llama_context * ctx, const uint8_t * src, size_t size) {
    auto * st = robot_session_state(ctx);
    if (st == nullptr || src == nullptr) {
        return 0;
    }
    const uint8_t * p = src;
    const uint8_t * end = src + size;
    auto get_u32 = [&](uint32_t & v) -> bool {
        if (p + 4 > end) { return false; }
        memcpy(&v, p, 4); p += 4; return true;
    };
    auto get_f32 = [&](std::vector<float> & v, uint32_t n) -> bool {
        if (p + (size_t) n * 4 > end) { return false; }
        v.resize(n);
        memcpy(v.data(), p, (size_t) n * 4); p += (size_t) n * 4; return true;
    };

    uint32_t magic = 0, version = 0, mdim = 0, n_banks = 0;
    if (!get_u32(magic) || magic != ROBOT_SESSION_MAGIC ||
        !get_u32(version) || version != ROBOT_SESSION_VERSION ||
        !get_u32(mdim) || mdim != st->m.size()) {
        LLAMA_LOG_ERROR("therobot: session blob is malformed or from a different model\n");
        return 0;
    }
    std::vector<float> m;
    if (!get_f32(m, mdim) || !get_u32(n_banks) || n_banks != st->banks.size()) {
        LLAMA_LOG_ERROR("therobot: session blob truncated or bank count mismatch\n");
        return 0;
    }
    std::vector<std::pair<uint32_t, std::vector<float>>> banks;
    for (uint32_t i = 0; i < n_banks; ++i) {
        uint32_t L = 0, S = 0;
        std::vector<float> bank;
        if (!get_u32(L) || !get_u32(S) || !get_f32(bank, S)) {
            LLAMA_LOG_ERROR("therobot: session blob truncated\n");
            return 0;
        }
        const auto * cur = st->bank(L);
        if (cur == nullptr || cur->size() != S) {
            LLAMA_LOG_ERROR("therobot: session blob bank layout mismatch (layer %u)\n", L);
            return 0;
        }
        banks.emplace_back(L, std::move(bank));
    }

    // E5 memory section
    auto get_u64 = [&](uint64_t & v) -> bool {
        if (p + 8 > end) { return false; }
        memcpy(&v, p, 8); p += 8; return true;
    };
    uint64_t clock = 0;
    uint32_t recall_len = 0, summary_len = 0, n_entries = 0;
    std::vector<float> recall, summary;
    std::vector<llama_robot_memory_entry> mem;
    if (!get_u64(clock) ||
        !get_u32(recall_len) || !get_f32(recall, recall_len) ||
        !get_u32(summary_len) || !get_f32(summary, summary_len) ||
        !get_u32(n_entries)) {
        LLAMA_LOG_ERROR("therobot: session blob truncated (memory section)\n");
        return 0;
    }
    for (uint32_t i = 0; i < n_entries; ++i) {
        llama_robot_memory_entry e;
        uint32_t klen = 0, vlen = 0;
        if (p + 4 > end) { LLAMA_LOG_ERROR("therobot: session blob truncated\n"); return 0; }
        memcpy(&e.salience, p, 4); p += 4;
        if (!get_u64(e.timestamp) ||
            !get_u32(klen) || !get_f32(e.key, klen) ||
            !get_u32(vlen) || !get_f32(e.value, vlen)) {
            LLAMA_LOG_ERROR("therobot: session blob truncated\n");
            return 0;
        }
        mem.push_back(std::move(e));
    }

    st->m = std::move(m);
    for (auto & [L, bank] : banks) {
        *st->bank(L) = std::move(bank);
    }
    st->mem_clock    = clock;
    st->recall       = std::move(recall);
    st->last_summary = std::move(summary);
    st->mem          = std::move(mem);
    // surprise history is not checkpointed: the first post-restore decode has
    // no previous distribution (documented v1 behavior)
    st->prev_logits.clear();
    return (size_t) (p - src);
}

//
// E5 — episodic memory API
//

int32_t llama_robot_memory_count(const llama_context * ctx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return 0;
    }
    return (int32_t) ctx->robot_state->mem.size();
}

bool llama_robot_memory_get(const llama_context * ctx, int32_t i,
                            float * salience, uint64_t * timestamp, uint64_t * age_tokens) {
    if (ctx == nullptr || !ctx->robot_state) {
        return false;
    }
    const auto & st = *ctx->robot_state;
    if (i < 0 || (size_t) i >= st.mem.size()) {
        return false;
    }
    const auto & e = st.mem[i];
    if (salience)   *salience   = e.salience;
    if (timestamp)  *timestamp  = e.timestamp;
    if (age_tokens) *age_tokens = st.mem_clock >= e.timestamp ? st.mem_clock - e.timestamp : 0;
    return true;
}

bool llama_robot_memory_value(const llama_context * ctx, int32_t i, float * dst) {
    if (ctx == nullptr || !ctx->robot_state || dst == nullptr) {
        return false;
    }
    const auto & st = *ctx->robot_state;
    if (i < 0 || (size_t) i >= st.mem.size()) {
        return false;
    }
    const auto & v = st.mem[i].value;
    std::copy(v.begin(), v.end(), dst);
    return true;
}

float llama_robot_memory_match(const llama_context * ctx, int32_t i) {
    if (ctx == nullptr || !ctx->robot_state || i < 0) {
        return 0.0f;
    }
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    if (iface == nullptr) {
        return 0.0f;
    }
    return llama_robot_memory_match_at(*iface, *ctx->robot_state, (size_t) i);
}

bool llama_robot_memory_write(llama_context * ctx, float salience) {
    if (ctx == nullptr) {
        return false;
    }
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    auto * st = robot_session_state(ctx);
    if (iface == nullptr || st == nullptr) {
        return false;
    }
    return llama_robot_memory_write_now(*iface, *st, salience);
}

void llama_robot_memory_forget(llama_context * ctx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return;
    }
    auto & st = *ctx->robot_state;
    st.mem.clear();
    st.recall.assign(st.recall.size(), 0.0f);
}

bool llama_robot_memory_recall(const llama_context * ctx, float * dst) {
    if (ctx == nullptr || !ctx->robot_state || dst == nullptr) {
        return false;
    }
    const auto & st = *ctx->robot_state;
    if (st.recall.empty()) {
        return false;
    }
    memcpy(dst, st.recall.data(), st.recall.size() * sizeof(float));
    return true;
}

//
// E6 — delta executor toggle + compute trace
//

bool llama_robot_delta_enable(llama_context * ctx, bool enable) {
    if (ctx == nullptr) {
        return false;
    }
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    if (iface == nullptr || !llama_robot_delta_feature(*iface)) {
        LLAMA_LOG_ERROR("therobot: model has no delta feature\n");
        return false;
    }
    auto * st = robot_session_state(ctx);
    if (st == nullptr) {
        return false;
    }
    if (st->delta_enabled == enable) {
        return true;
    }
    st->delta_enabled = enable;
    st->delta_since_dense = UINT64_MAX; // (re-)entering delta mode starts with a dense sweep
    st->epoch++;                        // topology change → rebuild on next decode
    LLAMA_LOG_INFO("therobot: delta mode %s (%zu covered block(s), heartbeat %u)\n",
            enable ? "enabled" : "disabled", st->delta.size(), iface->robot.delta.heartbeat);
    return true;
}

bool llama_robot_delta_enabled(const llama_context * ctx) {
    return ctx != nullptr && ctx->robot_state && ctx->robot_state->delta_enabled;
}

int32_t llama_robot_delta_block_count(const llama_model * model) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || !llama_robot_delta_feature(*iface)) {
        return 0;
    }
    return llama_robot_delta_blocks(*iface, nullptr, 0);
}

uint64_t llama_robot_delta_tokens(const llama_context * ctx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return 0;
    }
    return ctx->robot_state->delta_tokens;
}

uint64_t llama_robot_delta_fires(const llama_context * ctx, int32_t block_idx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return 0;
    }
    const auto & d = ctx->robot_state->delta;
    if (block_idx < 0 || (size_t) block_idx >= d.size()) {
        return 0;
    }
    return d[block_idx].fires;
}

float llama_robot_delta_keep_rate(const llama_context * ctx) {
    if (ctx == nullptr || !ctx->robot_state) {
        return 0.0f;
    }
    const auto & st = *ctx->robot_state;
    if (st.delta_tokens == 0 || st.delta.empty()) {
        return 0.0f;
    }
    uint64_t fires = 0;
    for (const auto & b : st.delta) {
        fires += b.fires;
    }
    return (float) fires / (float) (st.delta_tokens * st.delta.size());
}
