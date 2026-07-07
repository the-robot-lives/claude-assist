#pragma once

// therobot runtime extension — state banks + modulator (E4, planning §A/§B)
//
// A therobot context owns, next to the standard KV cache, per-covered-layer
// leaky state vectors and a per-session modulator vector m. Both live host-side
// in llama_robot_context_state, enter every decode's graph as input tensors
// (via a custom llm_graph_input), and are refreshed from named graph outputs
// after compute (fenced hook in llama_context::process_ubatch).
//
//   leaky state (per covered layer L, spec §1.3):
//     F   = in_proj(h)                     [S, T]
//     s_t = σ(α) ⊙ s_{t−1} + σ(−α) ⊙ F_t   (unrolled scan; exact per position)
//     h'  = h + out_proj([s_0 … s_{T−1}])  (out_proj zero at graft ⇒ L0 parity)
//
//   modulator (spec §1.4):
//     p     = mean_t(final stream)  |  glacial slice of the last state bank
//     z     = pool·p (+bias);  c = tanh(z + cell·m (+bias))
//     m_out = σ(α_m) ⊙ m + σ(−α_m) ⊙ c     (per-channel decay toward 0)
//
//   FiLM (per layer with robot_film heads):
//     h' = (γ_w·m + γ_b) ⊙ h + (β_w·m + β_b)   (γ_b=1, all else 0 at graft)
//
// v1 scope notes: one state per context (batch-1 / single-sequence streaming);
// state on the final layer is refused at load (its rows are output-filtered).
//
// therobot-fork-only code.

#include "llama-graph.h"

#include <cstdint>
#include <utility>
#include <vector>

struct llama_context;
struct llama_hparams;
struct llama_robot_model_iface;
struct llama_robot_context_state;

// Graph input pushing the host-side recurrent state (m + per-layer banks)
// into the compute graph at set_input time — this runs on every decode,
// whether or not the graph was reused, which is exactly the hook the
// recurrence needs. `st` is null for reserve graphs (set_input never runs
// on those; zero-filled defensively anyway).
class llm_graph_input_robot : public llm_graph_input_i {
public:
    explicit llm_graph_input_robot(const llama_robot_context_state * st) : st(st) {}
    virtual ~llm_graph_input_robot() = default;

    void set_input(const llama_ubatch * ubatch) override;

    bool can_reuse(const llm_graph_params & params) override {
        // shapes are model-constant; reuse is valid for the same context state
        return params.robot == st;
    }

    const llama_robot_context_state * st;

    ggml_tensor * m_in      = nullptr; // [M]
    ggml_tensor * mean_w    = nullptr; // [T*] pooled-mean weights (1/n each)
    ggml_tensor * recall_in = nullptr; // [M] episodic recall (E5), lags one decode
    std::vector<std::pair<uint32_t, ggml_tensor *>> s_in; // (layer, [S])
};

// true if the model carries E4 features (state banks and/or modulator)
bool llama_robot_state_enabled(const llama_robot_model_iface & iface);

// Called at the top of llama_context::process_ubatch (fenced): lazily creates
// and sizes the context's recurrent state for therobot models. No-op otherwise.
void llama_robot_state_prepare(llama_context * ctx);

// Called after a successful graph compute (fenced): pulls `robot_mod_out` and
// `robot_state_out-<L>` from the computed graph into the host-side state, then
// runs the per-decode episodic memory update (E5 — summary, salience gate,
// recall refresh). The ubatch supplies the incoming tokens for the surprise
// signal.
void llama_robot_state_capture(llama_context * ctx, llm_graph_result * res, const llama_ubatch * ubatch);

// load-time validation of grafted tensors against donor hparams (shapes,
// coverage, final-layer restriction); throws on contract violations
void llama_robot_validate_grafts(const llama_robot_model_iface & iface, const llama_hparams & hparams);

// per-covered-layer state width (Σ bank widths), from the manifest
uint32_t llama_robot_state_width(const llama_robot_model_iface & iface);
