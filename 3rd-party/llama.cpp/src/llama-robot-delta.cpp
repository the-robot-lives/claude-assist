// therobot runtime extension — delta executor host side (E6)

#include "llama-robot-delta.h"

#include "llama-graph.h"
#include "llama-hparams.h"
#include "llama-impl.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include "ggml.h"

#include <stdexcept>
#include <vector>

bool llama_robot_delta_feature(const llama_robot_model_iface & iface) {
    return iface.robot.has_feature(LLAMA_ROBOT_FEATURE_DELTA);
}

int32_t llama_robot_delta_blocks(const llama_robot_model_iface & iface, uint32_t * layers, int32_t max) {
    int32_t n = 0;
    for (const auto & rec : iface.robot_ext_tensors) {
        int L = -1;
        if (sscanf(rec.name.c_str(), "blk.%d.robot_delta.theta_base", &L) == 1 && L >= 0) {
            if (layers != nullptr && n < max) {
                layers[n] = (uint32_t) L;
            }
            n++;
        }
    }
    return n;
}

void llama_robot_delta_validate(const llama_robot_model_iface & iface, const llama_hparams & hparams) {
    if (!llama_robot_delta_feature(iface)) {
        return;
    }
    if (iface.robot.delta.granularity != "block") {
        throw std::runtime_error("therobot: delta v1 supports block granularity only");
    }
    if (iface.robot.delta.heartbeat == 0) {
        throw std::runtime_error("therobot: delta heartbeat must be positive (dense sweeps bound divergence)");
    }

    const uint32_t n_layer = hparams.n_layer();
    std::vector<uint32_t> layers(n_layer, 0);
    const int32_t n = llama_robot_delta_blocks(iface, layers.data(), (int32_t) layers.size());
    if (n == 0) {
        throw std::runtime_error("therobot: delta feature but no blk.{L}.robot_delta.theta_base tensors");
    }
    for (int32_t i = 0; i < n; ++i) {
        const uint32_t L = layers[i];
        if (L == 0 || L >= n_layer) {
            throw std::runtime_error(format(
                    "therobot: delta block %u invalid — v1 covers blocks 1..%u (block 0 reads the embedding stream)",
                    L, n_layer - 1));
        }
        const ggml_tensor * th = iface.robot_ext_tensor(format("blk.%u.robot_delta.theta_base", L));
        if (th == nullptr || th->type != GGML_TYPE_F32 || th->ne[0] != 1) {
            throw std::runtime_error(format("therobot: blk.%u.robot_delta.theta_base must be f32 [1]", L));
        }
    }

    if (const ggml_tensor * ew = iface.robot_ext_tensor("robot.delta.excitability.weight")) {
        if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) {
            throw std::runtime_error("therobot: delta excitability requires the modulator bus");
        }
        if (ew->type != GGML_TYPE_F32 || ew->ne[0] != (int64_t) iface.robot.modulator.dim || ew->ne[1] != 1) {
            throw std::runtime_error(format("therobot: robot.delta.excitability.weight must be f32 [%u, 1]",
                    iface.robot.modulator.dim));
        }
    }
}

void llama_robot_delta_prepare(const llama_robot_model_iface & iface, llama_robot_context_state & st, int64_t n_embd) {
    if (!llama_robot_delta_feature(iface) || !st.delta.empty()) {
        return;
    }
    std::vector<uint32_t> layers(128, 0);
    const int32_t n = llama_robot_delta_blocks(iface, layers.data(), (int32_t) layers.size());
    for (int32_t i = 0; i < n; ++i) {
        llama_robot_context_state::delta_block b;
        b.layer = layers[i];
        b.held_in.assign(n_embd, 0.0f);
        b.held_out.assign(n_embd, 0.0f);
        st.delta.push_back(std::move(b));
    }
    // delta_since_dense starts at UINT64_MAX → the first delta-mode token is
    // always a forced dense sweep, which initializes the holds
}

bool llama_robot_delta_force_dense(const llama_robot_model_iface & iface, const llama_robot_context_state & st) {
    return st.delta_since_dense >= iface.robot.delta.heartbeat;
}

void llama_robot_delta_capture(const llama_robot_model_iface & iface, llama_robot_context_state & st,
        llm_graph_result * res, uint32_t n_tokens) {
    if (!llama_robot_delta_feature(iface) || !st.delta_enabled || st.delta.empty()) {
        return;
    }
    ggml_cgraph * gf = res->get_gf();
    if (gf == nullptr) {
        return;
    }

    if (n_tokens != 1) {
        // prompt / batched ubatch ran dense: every held state is stale in a
        // known-good way — treat it as a dense sweep boundary and re-force on
        // the next streaming token so the holds re-initialize
        st.delta_since_dense = UINT64_MAX;
        return;
    }

    // if the graph carries no delta nodes (e.g. built before enable), skip
    if (ggml_graph_get_tensor(gf, format("robot_delta_fire-%u", st.delta[0].layer).c_str()) == nullptr) {
        return;
    }

    // same decision set_input made for this decode (since_dense is unchanged
    // between set_input and capture)
    const bool forced = llama_robot_delta_force_dense(iface, st);

    for (auto & b : st.delta) {
        float fire = 0.0f;
        ggml_tensor * tf = ggml_graph_get_tensor(gf, format("robot_delta_fire-%u", b.layer).c_str());
        if (tf != nullptr && tf->buffer != nullptr) {
            ggml_backend_tensor_get(tf, &fire, 0, sizeof(float));
        }

        if (fire > 0.5f) {
            b.fires++;
            ggml_tensor * hin = ggml_graph_get_tensor(gf, format("robot_delta_hin-%u", b.layer).c_str());
            ggml_tensor * hout = ggml_graph_get_tensor(gf, format("robot_delta_hout-%u", b.layer).c_str());
            if (hin != nullptr && hin->buffer != nullptr) {
                ggml_backend_tensor_get(hin, b.held_in.data(), 0, b.held_in.size() * sizeof(float));
            }
            if (hout != nullptr && hout->buffer != nullptr) {
                ggml_backend_tensor_get(hout, b.held_out.data(), 0, b.held_out.size() * sizeof(float));
            }
        }

        // leaky refractory pressure: fatigue = ρ·fatigue + gain·fired
        float rho = 0.0f, gain = 0.0f;
        if (const ggml_tensor * tr = iface.robot_ext_tensor(format("blk.%u.robot_delta.fatigue.rho", b.layer))) {
            rho = ((const float *) tr->data)[0];
        }
        if (const ggml_tensor * tg = iface.robot_ext_tensor(format("blk.%u.robot_delta.fatigue.gain", b.layer))) {
            gain = ((const float *) tg->data)[0];
        }
        b.fatigue = rho * b.fatigue + (fire > 0.5f ? gain : 0.0f);
    }

    st.delta_tokens++;
    if (forced) {
        st.delta_since_dense = 1; // the forced token was the dense sweep
    } else {
        st.delta_since_dense++;
    }
}
