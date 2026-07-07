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

    // ... and materialized into CPU-side copies after the base load (E2).
    // Extension tensors are small and exempt from quantization (spec §2), so
    // host memory is the right home until a work package moves specific ones
    // into the compute graph (E4+).
    ggml_context_ptr robot_ext_ctx;
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

// E2/E3 — after the donor graph is built: apply the context's attached shims
// at their target bottlenecks (slice-scoped gated edits, spliced into the
// donor graph so downstream consumers read the edited stream), then mark each
// cleave-point slice — post-shim — as a named graph output `robot_tap-<i>`.
struct llama_robot_context_state;
void llama_robot_graph_apply(const llama_robot_model_iface & iface, llm_graph_context * g,
        const llama_robot_context_state * st);

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
