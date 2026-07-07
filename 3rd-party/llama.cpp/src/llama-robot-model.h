#pragma once

// therobot runtime extension — architecture-family model wrapper (E1)
//
// One architecture (`therobot`) wraps an open-ended set of donor base
// families (llamacpp-extensions.md §1). The wrapper is a template over the
// donor's model class: hparams/tensors/graph all dispatch to the donor
// implementation, with therobot additions layered at explicit points. At E1
// the graph is a pure passthrough (L0); insertion points arrive with E2+.
//
// therobot-fork-only code; not included by stock translation units.

#include "llama-robot-hparams.h"

#include "llama-model.h"

#include <array>
#include <cstddef>
#include <string>
#include <vector>

// extension tensor claimed from a therobot file (`robot.*` / `blk.{L}.robot_*`)
struct llama_robot_ext_tensor {
    std::string name;
    ggml_type   type = GGML_TYPE_F32;
    std::array<int64_t, GGML_MAX_DIMS> ne = { 0, 0, 0, 0 };
    size_t      nbytes = 0;
};

// true for tensor names in the therobot extension namespace (spec §1.2–§1.7)
bool llama_robot_is_ext_tensor(const std::string & name);

// Claim every extension tensor in the file so the loader's tensor accounting
// stays consistent (mirrors the loader's skip-unused-tensor bookkeeping).
// E1 records their metadata; materialization into compute buffers lands with
// the work packages that consume them (E2 taps, E4 state/modulator, ...).
void llama_robot_claim_ext_tensors(llama_model_loader & ml, std::vector<llama_robot_ext_tensor> & out);

template <typename TBase>
struct llama_model_robot : public TBase {
    llama_robot_hparams robot;
    std::vector<llama_robot_ext_tensor> robot_ext_tensors;

    llama_model_robot(const llama_model_params & params, llama_robot_hparams robot_hparams)
        : TBase(params), robot(std::move(robot_hparams)) {}

    void load_arch_tensors(llama_model_loader & ml) override {
        TBase::load_arch_tensors(ml);
        llama_robot_claim_ext_tensors(ml, robot_ext_tensors);
    }

    // load_arch_hparams and build_arch_graph are inherited from the donor:
    // base keys/tensors use the donor family's stock names (spec §1.1) and the
    // E1 graph is the donor graph, untouched.
};

// Factory: called by llama_model_create() when general.architecture is
// "therobot". Parses + negotiates the spec, rebinds the loader's per-arch KV
// formatting to the donor family, and instantiates the wrapped donor model
// with model->arch set to the *donor* arch so every base behavior switch
// (rope type, memory layout, chat template, ...) acts as the donor.
llama_model * llama_robot_model_create(llama_model_loader & ml, const llama_model_params & params);
