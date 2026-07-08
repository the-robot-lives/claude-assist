#pragma once

// therobot runtime extension — architecture-family model wrapper (E1/E2)
//
// One architecture (`therobot`) wraps an open-ended set of donor base
// families (llamacpp-extensions.md §1). The wrapper is a template over the
// donor's model class: hparams/tensors/graph all dispatch to the donor
// implementation, with therobot additions layered at explicit points:
//   - E1: spec parsing, feature negotiation, extension tensor claim
//   - E2: bottleneck taps marked as graph outputs + materialized probe heads
//
// therobot-fork-only code; not included by stock translation units.

#include "llama-robot-hparams.h"
#include "llama-robot-semvec.h" // llama_robot_validate_semvec in the wrapper's load_tensors
#include "llama-robot-state.h"  // llama_robot_validate_grafts in the wrapper's load_tensors

#include "llama-graph.h" // llm_graph_params::robot in the wrapper's build_arch_graph
#include "llama-model.h"

#include "ggml-cpp.h"

#include <array>
#include <cstddef>
#include <string>
#include <unordered_map>
#include <vector>

struct llm_graph_context;

// extension tensor claimed from a therobot file (`robot.*` / `blk.{L}.robot_*`)
struct llama_robot_ext_tensor {
    std::string name;
    ggml_type   type = GGML_TYPE_F32;
    std::array<int64_t, GGML_MAX_DIMS> ne = { 0, 0, 0, 0 };
    size_t      nbytes = 0;
};

// true for tensor names in the therobot extension namespace (spec §1.2–§1.7)
bool llama_robot_is_ext_tensor(const std::string & name);

// Non-template face of a wrapped model, reachable from a `const llama_model *`
// via dynamic_cast (the public API and the context-side code use this).
struct llama_robot_model_iface {
    llama_robot_hparams robot;

    // extension tensors claimed at load (E1) ...
    std::vector<llama_robot_ext_tensor> robot_ext_tensors;

    // ... and materialized after the base load (E2). They live in a CPU
    // backend buffer: host-readable for probe heads, and usable as graph
    // leaves for FiLM / state / modulator subgraphs (E4). Extension tensors
    // are small and exempt from quantization (spec §2).
    ggml_context_ptr        robot_ext_ctx;
    ggml_backend_buffer_ptr robot_ext_buf;
    std::unordered_map<std::string, ggml_tensor *> robot_ext_data;

    virtual ~llama_robot_model_iface() = default;

    // materialized extension tensor by exact name, or nullptr
    ggml_tensor * robot_ext_tensor(const std::string & name) const;
};

// E1 — claim extension tensors so loader accounting stays consistent
void llama_robot_claim_ext_tensors(llama_model_loader & ml, std::vector<llama_robot_ext_tensor> & out);

// E2 — copy claimed extension tensor data into robot_ext_ctx (reads straight
// from the still-open model files; mmap-independent)
void llama_robot_materialize_ext_tensors(llama_model_loader & ml, llama_robot_model_iface & iface);

// E2 — validate declared bottlenecks against the donor's hparams
void llama_robot_validate_taps(const llama_robot_model_iface & iface, const llama_hparams & hparams);

// E2/E3/E4 — after the donor graph is built, per layer: apply FiLM modulation
// (E4), the leaky-state branch (E4), then the context's attached shims at
// their target bottlenecks (E3) — each spliced into the donor graph so
// downstream consumers read the edited stream — and finally mark each
// cleave-point slice (post-edit) as a named graph output `robot_tap-<i>`.
// The modulator update subgraph and the state/m graph inputs are added when
// the model carries those features.
struct llama_robot_context_state;
void llama_robot_graph_apply(const llama_robot_model_iface & iface, llm_graph_context * g,
        const llama_robot_context_state * st);

// Splice an edit into the built graph: `out` must compute a replacement for
// node `src` (and depend on it). Re-points downstream consumers and restores
// topological order. Shared by the shim, FiLM, and state passes.
void llama_robot_graph_splice_edit(struct ggml_cgraph * gf, ggml_tensor * src, ggml_tensor * out);

template <typename TBase>
struct llama_model_robot : public TBase, public llama_robot_model_iface {
    llama_model_robot(const llama_model_params & params, llama_robot_hparams robot_hparams)
        : TBase(params) {
        this->robot = std::move(robot_hparams);
    }

    void load_arch_hparams(llama_model_loader & ml) override {
        TBase::load_arch_hparams(ml);
        llama_robot_validate_taps(*this, this->hparams);
    }

    void load_arch_tensors(llama_model_loader & ml) override {
        TBase::load_arch_tensors(ml);
        llama_robot_claim_ext_tensors(ml, robot_ext_tensors);
    }

    bool load_tensors(llama_model_loader & ml) override {
        if (!TBase::load_tensors(ml)) {
            return false;
        }
        llama_robot_materialize_ext_tensors(ml, *this);
        llama_robot_validate_grafts(*this, this->hparams); // E4 shapes/coverage
        llama_robot_validate_semvec(*this, this->hparams); // readout-layer shapes/calibration
        return true;
    }

    std::unique_ptr<llm_graph_context> build_arch_graph(const llm_graph_params & params) const override {
        auto res = TBase::build_arch_graph(params);
        llama_robot_graph_apply(*this, res.get(), params.robot);
        return res;
    }
};

// Factory: called by llama_model_create() when general.architecture is
// "therobot". Parses + negotiates the spec, rebinds the loader's per-arch KV
// formatting to the donor family, and instantiates the wrapped donor model
// with model->arch set to the *donor* arch so every base behavior switch
// (rope type, memory layout, chat template, ...) acts as the donor.
llama_model * llama_robot_model_create(llama_model_loader & ml, const llama_model_params & params);
