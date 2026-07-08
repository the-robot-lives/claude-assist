// therobot runtime extension — episodic memory implementation (E5)

#include "llama-robot-memory.h"

#include "llama-batch.h"
#include "llama-graph.h"
#include "llama-impl.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include "ggml.h"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <vector>

// running-quantile window and warmup for the salience gate
static constexpr size_t ROBOT_MEM_WINDOW = 128;
static constexpr size_t ROBOT_MEM_WARMUP = 8;
static constexpr int    ROBOT_MEM_TOP_K  = 4;

bool llama_robot_memory_enabled(const llama_robot_model_iface & iface) {
    return iface.robot.has_feature(LLAMA_ROBOT_FEATURE_MEMORY);
}

uint32_t llama_robot_memory_summary_dim(const llama_robot_model_iface & iface) {
    uint32_t d = 0;
    for (const auto & bn : iface.robot.bottlenecks) {
        d += bn.width;
    }
    return d;
}

void llama_robot_memory_validate(const llama_robot_model_iface & iface) {
    if (!llama_robot_memory_enabled(iface)) {
        return;
    }
    const auto & mem = iface.robot.memory;

    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS) || iface.robot.bottlenecks.empty()) {
        throw std::runtime_error("therobot: memory feature requires declared bottlenecks (taps)");
    }
    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) {
        throw std::runtime_error("therobot: memory feature requires the modulator bus (recall injects into m)");
    }
    if (mem.value_dim != iface.robot.modulator.dim) {
        throw std::runtime_error(format("therobot: memory value_dim (%u) must equal the modulator dim (%u) — recall lives in modulator space",
                mem.value_dim, iface.robot.modulator.dim));
    }
    if (mem.capacity == 0 || mem.key_dim == 0) {
        throw std::runtime_error("therobot: memory capacity and key_dim must be positive");
    }
    if (!(mem.decay_halflife > 0.0f)) {
        throw std::runtime_error("therobot: memory decay_halflife must be positive");
    }

    const int64_t D = llama_robot_memory_summary_dim(iface);

    const ggml_tensor * kw = iface.robot_ext_tensor("robot.mem.summary.key.weight");
    const ggml_tensor * vw = iface.robot_ext_tensor("robot.mem.summary.value.weight");
    if (kw == nullptr || vw == nullptr) {
        throw std::runtime_error("therobot: missing robot.mem.summary.key.weight / value.weight");
    }
    if (kw->type != GGML_TYPE_F32 || kw->ne[0] != D || kw->ne[1] != (int64_t) mem.key_dim) {
        throw std::runtime_error(format("therobot: robot.mem.summary.key.weight must be f32 [%lld, %u]", (long long) D, mem.key_dim));
    }
    if (vw->type != GGML_TYPE_F32 || vw->ne[0] != D || vw->ne[1] != (int64_t) mem.value_dim) {
        throw std::runtime_error(format("therobot: robot.mem.summary.value.weight must be f32 [%lld, %u]", (long long) D, mem.value_dim));
    }
    const ggml_tensor * sw = iface.robot_ext_tensor("robot.mem.salience.weight");
    if (sw != nullptr) {
        const int64_t M = (int64_t) iface.robot.modulator.dim;
        if (sw->type != GGML_TYPE_F32 || (sw->ne[0] != 2 && sw->ne[0] != 2 + M)) {
            throw std::runtime_error(format(
                "therobot: robot.mem.salience.weight must be f32 [2] (surprise, ‖m‖) or "
                "[2+modulator_dim=%lld] (surprise, ‖m‖, per-channel importance); got [%lld]",
                (long long) (2 + M), (long long) sw->ne[0]));
        }
    }
}

// host matvec over a [D, O] f32 extension tensor
static void robot_mem_project(const ggml_tensor * w, const std::vector<float> & x, std::vector<float> & out) {
    const int64_t D = w->ne[0];
    const int64_t O = w->ne[1];
    out.assign(O, 0.0f);
    for (int64_t o = 0; o < O; ++o) {
        const float * row = (const float *) ((const char *) w->data + o * w->nb[1]);
        float acc = 0.0f;
        for (int64_t k = 0; k < D; ++k) {
            acc += row[k] * x[k];
        }
        out[o] = acc;
    }
}

static float robot_mem_cosine(const std::vector<float> & a, const std::vector<float> & b) {
    float dot = 0.0f, na = 0.0f, nb = 0.0f;
    for (size_t i = 0; i < a.size(); ++i) {
        dot += a[i] * b[i];
        na  += a[i] * a[i];
        nb  += b[i] * b[i];
    }
    if (na <= 0.0f || nb <= 0.0f) {
        return 0.0f;
    }
    return dot / (std::sqrt(na) * std::sqrt(nb));
}

// concatenate the decode's tap outputs (last position of each) in declaration order
static bool robot_mem_summarize(
        const llama_robot_model_iface & iface,
        llm_graph_result * res,
        std::vector<float> & summary) {
    ggml_cgraph * gf = res->get_gf();
    if (gf == nullptr) {
        return false;
    }
    summary.clear();
    summary.reserve(llama_robot_memory_summary_dim(iface));
    for (size_t i = 0; i < iface.robot.bottlenecks.size(); ++i) {
        const auto & bn = iface.robot.bottlenecks[i];
        ggml_tensor * tap = ggml_graph_get_tensor(gf, format("robot_tap-%zu", i).c_str());
        if (tap == nullptr || tap->buffer == nullptr || tap->ne[1] <= 0) {
            return false; // tap disabled or no rows this decode
        }
        std::vector<float> row(bn.width);
        const size_t row_bytes = (size_t) bn.width * sizeof(float);
        ggml_backend_tensor_get(tap, row.data(), (size_t) (tap->ne[1] - 1) * row_bytes, row_bytes);
        summary.insert(summary.end(), row.begin(), row.end());
    }
    return true;
}

static void robot_mem_evict_if_full(const llama_robot_model_iface & iface, llama_robot_context_state & st) {
    const uint32_t cap = iface.robot.memory.capacity;
    while (st.mem.size() >= cap) {
        // decay-based eviction: drop the entry with the lowest retention score
        size_t worst = 0;
        float  worst_score = 0.0f;
        for (size_t i = 0; i < st.mem.size(); ++i) {
            const float age = (float) (st.mem_clock - st.mem[i].timestamp);
            const float score = st.mem[i].salience * std::exp2(-age / iface.robot.memory.decay_halflife);
            if (i == 0 || score < worst_score) {
                worst = i;
                worst_score = score;
            }
        }
        st.mem.erase(st.mem.begin() + worst);
    }
}

static bool robot_mem_write(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st,
        const std::vector<float> & summary,
        float salience) {
    const ggml_tensor * kw = iface.robot_ext_tensor("robot.mem.summary.key.weight");
    const ggml_tensor * vw = iface.robot_ext_tensor("robot.mem.summary.value.weight");
    if (kw == nullptr || vw == nullptr || summary.empty()) {
        return false;
    }

    robot_mem_evict_if_full(iface, st);

    llama_robot_memory_entry e;
    robot_mem_project(kw, summary, e.key);
    robot_mem_project(vw, summary, e.value);
    e.salience  = salience;
    e.timestamp = st.mem_clock;
    st.mem.push_back(std::move(e));

    LLAMA_LOG_DEBUG("therobot: memory write (salience %.3f, clock %llu, %zu stored)\n",
            salience, (unsigned long long) st.mem_clock, st.mem.size());
    return true;
}

// recall = recency-weighted cosine top-k mean of stored values, queried by the
// key-projection of the current summary
static void robot_mem_refresh_recall(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st) {
    st.recall.assign(iface.robot.modulator.dim, 0.0f);
    if (st.mem.empty() || st.last_summary.empty()) {
        return;
    }
    const ggml_tensor * kw = iface.robot_ext_tensor("robot.mem.summary.key.weight");
    if (kw == nullptr) {
        return;
    }

    std::vector<float> query;
    robot_mem_project(kw, st.last_summary, query);

    std::vector<std::pair<float, size_t>> scored; // (weight, entry)
    for (size_t i = 0; i < st.mem.size(); ++i) {
        const float cos = robot_mem_cosine(query, st.mem[i].key);
        if (cos <= 0.0f) {
            continue; // content-addressed: only positively matching memories fire
        }
        const float age = (float) (st.mem_clock - st.mem[i].timestamp);
        const float w = cos * std::exp2(-age / iface.robot.memory.decay_halflife);
        scored.emplace_back(w, i);
    }
    if (scored.empty()) {
        return;
    }
    std::sort(scored.begin(), scored.end(), [](const auto & a, const auto & b) { return a.first > b.first; });
    if (scored.size() > (size_t) ROBOT_MEM_TOP_K) {
        scored.resize(ROBOT_MEM_TOP_K);
    }

    float wsum = 0.0f;
    for (const auto & [w, i] : scored) {
        wsum += w;
        for (size_t c = 0; c < st.recall.size(); ++c) {
            st.recall[c] += w * st.mem[i].value[c];
        }
    }
    // recency-weighted mean, scaled by the strongest match's weight so recall
    // fades as memories age (a plain mean would never decay)
    const float top = scored[0].first;
    for (auto & v : st.recall) {
        v = (v / wsum) * top;
    }
}

// −log p(token) under the previous decode's last-position distribution
static float robot_mem_surprise(const llama_robot_context_state & st, const llama_ubatch * ubatch) {
    if (st.prev_logits.empty() || ubatch == nullptr || ubatch->token == nullptr || ubatch->n_tokens == 0) {
        return 0.0f;
    }
    const int32_t tok = ubatch->token[0];
    if (tok < 0 || (size_t) tok >= st.prev_logits.size()) {
        return 0.0f;
    }
    float mx = st.prev_logits[0];
    for (const float v : st.prev_logits) {
        mx = std::fmax(mx, v);
    }
    double lse = 0.0;
    for (const float v : st.prev_logits) {
        lse += std::exp((double) v - mx);
    }
    const float logp = st.prev_logits[tok] - mx - (float) std::log(lse);
    return -logp;
}

static float robot_mem_quantile(std::vector<float> window, float q) {
    if (window.empty()) {
        return 0.0f;
    }
    std::sort(window.begin(), window.end());
    const size_t idx = (size_t) (q * (float) (window.size() - 1) + 0.5f);
    return window[std::min(idx, window.size() - 1)];
}

void llama_robot_memory_update(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st,
        llm_graph_result * res,
        const llama_ubatch * ubatch) {
    if (!llama_robot_memory_enabled(iface) || res == nullptr) {
        return;
    }

    // Salience of this decode. Surprise (−log p of the token under the previous
    // distribution) is the free, always-available bootstrap signal — but it
    // measures "startling", not "important". A rare glyph is surprising and
    // worthless; "allergic to penicillin" is unsurprising and must be kept. So
    // salience is a learned linear gate over [surprise, ‖m‖, m_0 … m_{M-1}]:
    // the modulator's emotional/importance channels (threat, valence, novelty,
    // goal-relevance …) drive retention too, so a calm-but-consequential input
    // can be written and a startling-but-trivial one skipped. salience.weight
    // length 2 = surprise+‖m‖ only (v1 default); length 2+M also weights each
    // named modulator channel, so importance is decoded from internal state,
    // not just prediction error. (A fully learned head over the bottleneck
    // summary content is the R5 training-side upgrade.)
    const int64_t M = (int64_t) st.m.size();
    const float surprise = robot_mem_surprise(st, ubatch);
    float mnorm = 0.0f;
    for (const float v : st.m) {
        mnorm += v * v;
    }
    mnorm = std::sqrt(mnorm);

    float salience;
    if (const ggml_tensor * sw = iface.robot_ext_tensor("robot.mem.salience.weight")) {
        const float * w = (const float *) sw->data;
        salience = w[0] * surprise + w[1] * mnorm;
        if (sw->ne[0] == 2 + M) {
            for (int64_t c = 0; c < M; ++c) {
                salience += w[2 + c] * st.m[c];   // per-channel importance
            }
        }
    } else {
        salience = surprise + mnorm;              // default weights = 1
    }

    // summarize this decode's bottleneck slices
    std::vector<float> summary;
    const bool have_summary = robot_mem_summarize(iface, res, summary);
    if (have_summary) {
        st.last_summary = summary;
    }

    // Salience gate. Two bars, both must clear:
    //   1. relative — quantile over a running window (writes the top (1−q) of
    //      recent decodes: self-calibrating, but always writes *something*);
    //   2. absolute — a fixed salience_floor (0 = off) so a whole quiet stretch
    //      writes nothing. Together: "rare AND meaningful" instead of a constant
    //      (1−q) trickle. salience must also be strictly positive.
    if (have_summary && salience > 0.0f && st.salience_window.size() >= ROBOT_MEM_WARMUP) {
        const float qthr = robot_mem_quantile(st.salience_window, iface.robot.memory.salience_threshold_quantile);
        const float thr  = std::max(qthr, iface.robot.memory.salience_floor);
        if (salience >= thr) {
            robot_mem_write(iface, st, summary, salience);
        }
    }
    st.salience_window.push_back(salience);
    if (st.salience_window.size() > ROBOT_MEM_WINDOW) {
        st.salience_window.erase(st.salience_window.begin());
    }

    // advance the token clock, then refresh recall for the next decode
    st.mem_clock += ubatch != nullptr ? ubatch->n_tokens : 1;
    robot_mem_refresh_recall(iface, st);

    // keep this decode's last-position distribution for the next surprise
    {
        ggml_tensor * t_logits = res->get_logits();
        if (t_logits != nullptr && t_logits->buffer != nullptr && t_logits->ne[1] > 0) {
            const int64_t n_vocab = t_logits->ne[0];
            st.prev_logits.resize(n_vocab);
            ggml_backend_tensor_get(t_logits, st.prev_logits.data(),
                    (size_t) (t_logits->ne[1] - 1) * n_vocab * sizeof(float), n_vocab * sizeof(float));
        }
    }
}

bool llama_robot_memory_write_now(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st,
        float salience) {
    if (!llama_robot_memory_enabled(iface) || st.last_summary.empty()) {
        return false;
    }
    if (!(salience > 0.0f)) {
        LLAMA_LOG_WARN("therobot: refusing memory write with non-positive salience %.3f\n", salience);
        return false;
    }
    if (!robot_mem_write(iface, st, st.last_summary, salience)) {
        return false;
    }
    robot_mem_refresh_recall(iface, st);
    return true;
}
