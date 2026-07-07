// therobot runtime extension — state banks + modulator, host side (E4)

#include "llama-robot-state.h"

#include "llama-context.h"
#include "llama-hparams.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-memory.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include "ggml-backend.h"

#include <cstring>
#include <stdexcept>
#include <vector>

bool llama_robot_state_enabled(const llama_robot_model_iface & iface) {
    return iface.robot.has_feature(LLAMA_ROBOT_FEATURE_STATE) ||
           iface.robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR);
}

uint32_t llama_robot_state_width(const llama_robot_model_iface & iface) {
    uint32_t s = 0;
    for (const auto & bank : iface.robot.state.banks) {
        s += bank.width;
    }
    return s;
}

//
// graph input: push host state into the graph before every compute
//

void llm_graph_input_robot::set_input(const llama_ubatch * ubatch) {
    GGML_UNUSED(ubatch);

    if (mean_w != nullptr) {
        const int64_t n = mean_w->ne[0];
        std::vector<float> w(n, n > 0 ? 1.0f / (float) n : 0.0f);
        ggml_backend_tensor_set(mean_w, w.data(), 0, n * sizeof(float));
    }

    if (m_in != nullptr) {
        const size_t n = (size_t) m_in->ne[0];
        if (st != nullptr && st->m.size() == n) {
            ggml_backend_tensor_set(m_in, st->m.data(), 0, n * sizeof(float));
        } else {
            std::vector<float> zeros(n, 0.0f);
            ggml_backend_tensor_set(m_in, zeros.data(), 0, n * sizeof(float));
        }
    }

    if (recall_in != nullptr) {
        const size_t n = (size_t) recall_in->ne[0];
        if (st != nullptr && st->recall.size() == n) {
            ggml_backend_tensor_set(recall_in, st->recall.data(), 0, n * sizeof(float));
        } else {
            std::vector<float> zeros(n, 0.0f);
            ggml_backend_tensor_set(recall_in, zeros.data(), 0, n * sizeof(float));
        }
    }

    for (const auto & [L, t] : s_in) {
        const size_t n = (size_t) t->ne[0];
        const std::vector<float> * bank = st != nullptr ? st->bank(L) : nullptr;
        if (bank != nullptr && bank->size() == n) {
            ggml_backend_tensor_set(t, bank->data(), 0, n * sizeof(float));
        } else {
            std::vector<float> zeros(n, 0.0f);
            ggml_backend_tensor_set(t, zeros.data(), 0, n * sizeof(float));
        }
    }
}

//
// context hooks (fenced call sites in llama_context::process_ubatch)
//

void llama_robot_state_prepare(llama_context * ctx) {
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    if (iface == nullptr || !llama_robot_state_enabled(*iface)) {
        return;
    }

    auto & st = ctx->robot_state;
    if (!st) {
        st = std::make_shared<llama_robot_context_state>();
    }
    if (st->state_ready) {
        return;
    }

    if (iface->robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) {
        st->m.assign(iface->robot.modulator.dim, 0.0f);
    }
    if (llama_robot_memory_enabled(*iface)) {
        st->recall.assign(iface->robot.modulator.dim, 0.0f);
    }
    if (iface->robot.has_feature(LLAMA_ROBOT_FEATURE_STATE)) {
        const uint32_t S = llama_robot_state_width(*iface);
        for (const uint32_t L : iface->robot.state.layers) {
            if (st->bank(L) == nullptr) {
                st->banks.emplace_back(L, std::vector<float>(S, 0.0f));
            }
        }
    }
    st->state_ready = true;

    LLAMA_LOG_INFO("therobot: session state initialized (m: %zu channels, %zu state bank(s))\n",
            st->m.size(), st->banks.size());
}

void llama_robot_state_capture(llama_context * ctx, llm_graph_result * res, const llama_ubatch * ubatch) {
    auto & st = ctx->robot_state;
    if (!st || !st->state_ready || res == nullptr) {
        return;
    }
    ggml_cgraph * gf = res->get_gf();
    if (gf == nullptr) {
        return;
    }

    if (!st->m.empty()) {
        ggml_tensor * t = ggml_graph_get_tensor(gf, "robot_mod_out");
        if (t != nullptr && t->buffer != nullptr) {
            ggml_backend_tensor_get(t, st->m.data(), 0, st->m.size() * sizeof(float));
        }
    }

    for (auto & [L, bank] : st->banks) {
        ggml_tensor * t = ggml_graph_get_tensor(gf, format("robot_state_out-%u", L).c_str());
        if (t != nullptr && t->buffer != nullptr) {
            ggml_backend_tensor_get(t, bank.data(), 0, bank.size() * sizeof(float));
        }
    }

    // E5: per-decode episodic memory update (summary → salience gate → recall)
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    if (iface != nullptr) {
        llama_robot_memory_update(*iface, *st, res, ubatch);
    }
}

//
// load-time graft validation
//

static void robot_check_shape(const ggml_tensor * t, const char * what, int64_t ne0, int64_t ne1) {
    if (t == nullptr) {
        throw std::runtime_error(format("therobot: missing grafted tensor %s", what));
    }
    if (t->type != GGML_TYPE_F32) {
        throw std::runtime_error(format("therobot: grafted tensor %s must be f32", what));
    }
    if (t->ne[0] != ne0 || (ne1 > 0 && t->ne[1] != ne1)) {
        throw std::runtime_error(format("therobot: grafted tensor %s has shape [%lld, %lld], expected [%lld, %lld]",
                what, (long long) t->ne[0], (long long) t->ne[1], (long long) ne0, (long long) ne1));
    }
}

void llama_robot_validate_grafts(const llama_robot_model_iface & iface, const llama_hparams & hparams) {
    const auto & robot = iface.robot;

    const int64_t n_embd  = hparams.n_embd;
    const uint32_t n_layer = hparams.n_layer();

    if (robot.has_feature(LLAMA_ROBOT_FEATURE_STATE)) {
        const int64_t S = llama_robot_state_width(iface);
        if (S == 0) {
            throw std::runtime_error("therobot: state feature with zero total bank width");
        }
        for (const uint32_t L : robot.state.layers) {
            if (L + 1 >= n_layer) {
                throw std::runtime_error(format(
                        "therobot: state layer %u invalid — the final layer's rows are output-filtered "
                        "(n_layer = %u); cover an earlier block", L, n_layer));
            }
            robot_check_shape(iface.robot_ext_tensor(format("blk.%u.robot_state.alpha", L)),
                    format("blk.%u.robot_state.alpha", L).c_str(), S, -1);
            robot_check_shape(iface.robot_ext_tensor(format("blk.%u.robot_state.in_proj.weight", L)),
                    format("blk.%u.robot_state.in_proj.weight", L).c_str(), n_embd, S);
            robot_check_shape(iface.robot_ext_tensor(format("blk.%u.robot_state.out_proj.weight", L)),
                    format("blk.%u.robot_state.out_proj.weight", L).c_str(), S, n_embd);
        }
    }

    if (robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR)) {
        const int64_t M = robot.modulator.dim;
        if (M == 0 || robot.modulator.channels.size() != (size_t) M) {
            throw std::runtime_error("therobot: modulator dim / channel names mismatch");
        }
        robot_check_shape(iface.robot_ext_tensor("robot.mod.alpha"), "robot.mod.alpha", M, -1);
        robot_check_shape(iface.robot_ext_tensor("robot.mod.cell.weight"), "robot.mod.cell.weight", M, M);

        int64_t pool_in = n_embd;
        if (robot.modulator.source == "glacial") {
            int64_t wg = 0;
            for (const auto & bank : robot.state.banks) {
                if (bank.name == "glacial") { wg = bank.width; }
            }
            if (wg == 0) {
                throw std::runtime_error("therobot: glacial modulator source but no glacial state bank");
            }
            pool_in = wg;
        }
        robot_check_shape(iface.robot_ext_tensor("robot.mod.pool.weight"), "robot.mod.pool.weight", pool_in, M);

        // FiLM heads are optional per block, but must be well-formed where present
        for (uint32_t L = 0; L < n_layer; ++L) {
            ggml_tensor * gw = iface.robot_ext_tensor(format("blk.%u.robot_film.gamma.weight", L));
            if (gw == nullptr) {
                continue;
            }
            robot_check_shape(gw, format("blk.%u.robot_film.gamma.weight", L).c_str(), M, n_embd);
            ggml_tensor * bw = iface.robot_ext_tensor(format("blk.%u.robot_film.beta.weight", L));
            if (bw != nullptr) {
                robot_check_shape(bw, format("blk.%u.robot_film.beta.weight", L).c_str(), M, n_embd);
            }
        }
    }

    // E5 memory-head tensors (requires taps + modulator; value_dim == M)
    llama_robot_memory_validate(iface);
}
