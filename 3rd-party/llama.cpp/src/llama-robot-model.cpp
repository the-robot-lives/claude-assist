// therobot runtime extension — model factory, extension tensors, taps (E1/E2)

#include "llama-robot-model.h"

#include "llama-graph.h"
#include "llama-hparams.h"
#include "llama-impl.h"
#include "llama-mmap.h"
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

ggml_tensor * llama_robot_model_iface::robot_ext_tensor(const std::string & name) const {
    const auto it = robot_ext_data.find(name);
    return it == robot_ext_data.end() ? nullptr : it->second;
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

void llama_robot_materialize_ext_tensors(llama_model_loader & ml, llama_robot_model_iface & iface) {
    if (iface.robot_ext_tensors.empty()) {
        return;
    }
    if (ml.files.empty()) {
        LLAMA_LOG_WARN("therobot: no open model files — extension tensors not materialized\n");
        return;
    }

    size_t mem_size = 0;
    for (const auto & rec : iface.robot_ext_tensors) {
        mem_size += ggml_tensor_overhead() + GGML_PAD(rec.nbytes, GGML_MEM_ALIGN);
    }

    ggml_init_params ip = {
        /*.mem_size   =*/ mem_size + ggml_tensor_overhead(), // slack
        /*.mem_buffer =*/ nullptr,
        /*.no_alloc   =*/ false,
    };
    iface.robot_ext_ctx.reset(ggml_init(ip));
    if (!iface.robot_ext_ctx) {
        throw std::runtime_error("therobot: failed to allocate extension tensor context");
    }

    for (const auto & rec : iface.robot_ext_tensors) {
        int n_dims = 1;
        for (int d = GGML_MAX_DIMS - 1; d > 0; --d) {
            if (rec.ne[d] > 1) { n_dims = d + 1; break; }
        }
        ggml_tensor * t = ggml_new_tensor(iface.robot_ext_ctx.get(), rec.type, n_dims, rec.ne.data());
        if (t == nullptr) {
            throw std::runtime_error(format("therobot: failed to create extension tensor '%s'", rec.name.c_str()));
        }
        ggml_set_name(t, rec.name.c_str());

        // read straight from the (still open) model file — independent of the
        // mmap fragments that load_all_data may already have released
        const auto & w = ml.require_weight(rec.name.c_str());
        const auto & file = ml.files.at(w.idx);
        file->seek(w.offs, SEEK_SET);
        file->read_raw(t->data, rec.nbytes);

        iface.robot_ext_data.emplace(rec.name, t);
    }

    LLAMA_LOG_INFO("therobot: materialized %zu extension tensor(s) host-side\n", iface.robot_ext_data.size());
}

void llama_robot_validate_taps(const llama_robot_model_iface & iface, const llama_hparams & hparams) {
    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS)) {
        return;
    }
    const uint32_t n_layer = hparams.n_layer();
    const uint32_t n_embd  = (uint32_t) hparams.n_embd;
    for (size_t i = 0; i < iface.robot.bottlenecks.size(); ++i) {
        const auto & bn = iface.robot.bottlenecks[i];
        if (bn.layer >= n_layer) {
            throw std::runtime_error(format("therobot: bottleneck %zu ('%s') layer %u out of range (n_layer = %u)",
                    i, bn.name.c_str(), bn.layer, n_layer));
        }
        if (bn.offset + bn.width > n_embd) {
            throw std::runtime_error(format("therobot: bottleneck %zu ('%s') slice [%u..%u) exceeds n_embd = %u",
                    i, bn.name.c_str(), bn.offset, bn.offset + bn.width, n_embd));
        }
    }
}

// spec §1.2 point → graph tensor base name (named by llama_context's graph cb
// as "<base>-<il>"). Note: some model families name both the FFN branch output
// and the post-residual sum "ffn_out"; ggml_graph_get_tensor returns the first
// occurrence, which is the branch output — the cleave-point semantics we want.
static const char * robot_tap_point_base(const std::string & point) {
    if (point == "resid_post") { return "l_out";    }
    if (point == "attn_out")   { return "attn_out"; }
    if (point == "ffn_out")    { return "ffn_out";  }
    return nullptr;
}

void llama_robot_graph_add_taps(const llama_robot_model_iface & iface, llm_graph_context * g) {
    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS)) {
        return;
    }
    for (size_t i = 0; i < iface.robot.bottlenecks.size(); ++i) {
        const auto & bn = iface.robot.bottlenecks[i];

        const char * base = robot_tap_point_base(bn.point);
        GGML_ASSERT(base != nullptr); // validated at spec parse

        const std::string src_name = format("%s-%d", base, (int) bn.layer);
        ggml_tensor * src = ggml_graph_get_tensor(g->gf, src_name.c_str());
        if (src == nullptr) {
            LLAMA_LOG_WARN("therobot: tap %zu ('%s'): tensor '%s' not found in donor graph — tap disabled\n",
                    i, bn.name.c_str(), src_name.c_str());
            continue;
        }
        GGML_ASSERT(src->type == GGML_TYPE_F32);
        GGML_ASSERT((int64_t) bn.offset + bn.width <= src->ne[0]);

        // slice channels [offset, offset+width) across all positions in the
        // ubatch, make it contiguous, and mark it as a named graph output
        ggml_tensor * view = ggml_view_2d(g->ctx0, src,
                bn.width, src->ne[1],
                src->nb[1],
                (size_t) bn.offset * src->nb[0]);
        ggml_tensor * tap = ggml_cont(g->ctx0, view);
        ggml_set_name(tap, format("robot_tap-%zu", i).c_str());
        ggml_set_output(tap);
        ggml_build_forward_expand(g->gf, tap);
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
