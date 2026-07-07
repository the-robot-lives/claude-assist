// therobot runtime extension — model factory + extension tensor claim (E1)

#include "llama-robot-model.h"

#include "llama-impl.h"
#include "llama-model-loader.h"

#include "models/models.h"

#include <cctype>
#include <sstream>
#include <stdexcept>

bool llama_robot_is_ext_tensor(const std::string & name) {
    // global extension tensors: robot.probe.*, robot.mod.*, robot.mem.*,
    // robot.delta.*, robot.settle.*, robot.shim.* (spec §1.2–§1.7, §4)
    if (name.compare(0, 6, "robot.") == 0) {
        return true;
    }
    // per-block extension tensors: blk.{L}.robot_state.*, blk.{L}.robot_film.*,
    // blk.{L}.robot_delta.*
    if (name.compare(0, 4, "blk.") == 0) {
        size_t pos = 4;
        while (pos < name.size() && std::isdigit((unsigned char) name[pos])) {
            pos++;
        }
        if (pos > 4 && pos + 7 <= name.size() && name.compare(pos, 7, ".robot_") == 0) {
            return true;
        }
    }
    return false;
}

void llama_robot_claim_ext_tensors(llama_model_loader & ml, std::vector<llama_robot_ext_tensor> & out) {
    for (const auto & it : ml.weights_map) {
        const std::string & name = it.first;
        if (!llama_robot_is_ext_tensor(name)) {
            continue;
        }

        const ggml_tensor * t = it.second.tensor;

        llama_robot_ext_tensor rec;
        rec.name   = name;
        rec.type   = t->type;
        for (int d = 0; d < GGML_MAX_DIMS; ++d) {
            rec.ne[d] = t->ne[d];
        }
        rec.nbytes = ggml_nbytes(t);
        out.push_back(std::move(rec));

        // mirror the loader's skip-unused-tensor bookkeeping so that
        // done_getting_tensors() and load_all_data() accounting stay exact
        ml.size_data -= rec.nbytes;
        ml.n_created++;

        LLAMA_LOG_INFO("therobot: claimed extension tensor %s (%s, %zu bytes)\n",
                name.c_str(), ggml_type_name(rec.type), rec.nbytes);
    }
}

static llama_model * llama_robot_model_mapping(
        const llama_model_params & params,
        llama_robot_hparams robot) {
    // wrapped donor families. Adding a family is one line here — the wrapper
    // template does the rest (llamacpp-extensions.md §1: family, not enum
    // explosion). Keep in sync with docs/robot/patch-points.md.
    switch (robot.base_arch) {
        case LLM_ARCH_LLAMA:    return new llama_model_robot<llama_model_llama>   (params, std::move(robot));
        case LLM_ARCH_QWEN2:    return new llama_model_robot<llama_model_qwen2>   (params, std::move(robot));
        case LLM_ARCH_QWEN2MOE: return new llama_model_robot<llama_model_qwen2moe>(params, std::move(robot));
        case LLM_ARCH_QWEN3:    return new llama_model_robot<llama_model_qwen3>   (params, std::move(robot));
        case LLM_ARCH_MAMBA:    return new llama_model_robot<llama_model_mamba>   (params, std::move(robot));
        default:
            throw std::runtime_error(format(
                "therobot: base architecture '%s' is not wrapped by this runtime yet "
                "(supported: llama, qwen2, qwen2moe, qwen3, mamba)",
                robot.base_architecture.c_str()));
    }
}

llama_model * llama_robot_model_create(llama_model_loader & ml, const llama_model_params & params) {
    llama_robot_hparams robot;
    llama_robot_hparams_load(robot, ml);

    const llm_arch base_arch = robot.base_arch;

    {
        std::ostringstream feats;
        for (const auto f : robot.features) {
            feats << ' ' << llama_robot_feature_name(f);
        }
        LLAMA_LOG_INFO("therobot: spec v%u, base architecture '%s', level L%u, features:%s\n",
                robot.spec_version, robot.base_architecture.c_str(), robot.level,
                robot.features.empty() ? " (none — L0 passthrough)" : feats.str().c_str());
        if (!robot.donor_id.empty()) {
            LLAMA_LOG_INFO("therobot: donor '%s'\n", robot.donor_id.c_str());
        }
    }

    // Rebind the loader's per-arch KV formatting to the donor family: all base
    // hparams/tensors in a therobot file use the donor's stock keys/names
    // unchanged (spec §1.1).
    ml.arch_name = llm_arch_name(base_arch);
    ml.llm_kv    = LLM_KV(base_arch);

    llama_model * model = llama_robot_model_mapping(params, std::move(robot));

    // mirror llama_model_create(arch, params): the model runs *as* the donor
    // arch internally — that is what makes the superset/parity invariant hold
    model->arch = base_arch;

    const auto & devices = model->devices;
    if (!devices.empty() && devices[0].is_meta && !llm_arch_supports_sm_tensor(base_arch)) {
        throw std::runtime_error(std::string("LLAMA_SPLIT_MODE_TENSOR not implemented for architecture '") + llm_arch_name(base_arch) + "'");
    }

    return model;
}
