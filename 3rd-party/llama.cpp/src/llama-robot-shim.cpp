// therobot runtime extension — shim module loader (E3)

#include "llama-robot-shim.h"

#include "llama-impl.h"
#include "llama-mmap.h"
#include "llama-robot-hparams.h"
#include "llama-robot-model.h"

#include "ggml-backend.h"
#include "gguf.h"

#include <cstring>
#include <stdexcept>
#include <vector>

//
// gate parsing — "always" | "modulator:<subject><op><val>" | "probe:<subject><op><val>"
//

static llama_robot_shim_gate robot_shim_parse_gate(const std::string & text) {
    llama_robot_shim_gate gate;
    if (text.empty() || text == "always") {
        return gate;
    }

    std::string rest;
    if (text.compare(0, 10, "modulator:") == 0) {
        gate.kind = llama_robot_shim_gate::GATE_MODULATOR;
        rest = text.substr(10);
    } else if (text.compare(0, 6, "probe:") == 0) {
        gate.kind = llama_robot_shim_gate::GATE_PROBE;
        rest = text.substr(6);
    } else {
        throw std::runtime_error(format("therobot: invalid shim gate '%s'", text.c_str()));
    }

    // find the operator (two-char ops first)
    static const char * ops[] = { ">=", "<=", ">", "<" };
    size_t op_pos = std::string::npos;
    for (const char * op : ops) {
        const size_t pos = rest.find(op);
        if (pos != std::string::npos) {
            op_pos = pos;
            gate.op = op;
            break;
        }
    }
    if (op_pos == std::string::npos || op_pos == 0) {
        throw std::runtime_error(format("therobot: shim gate '%s' has no <subject><op><value> expression", text.c_str()));
    }

    gate.subject = rest.substr(0, op_pos);
    try {
        gate.value = std::stof(rest.substr(op_pos + gate.op.size()));
    } catch (...) {
        throw std::runtime_error(format("therobot: shim gate '%s' has a malformed value", text.c_str()));
    }
    return gate;
}

//
// loader
//

static ggml_tensor * robot_shim_find_meta(ggml_context * meta_ctx, const char * name) {
    for (ggml_tensor * t = ggml_get_first_tensor(meta_ctx); t != nullptr; t = ggml_get_next_tensor(meta_ctx, t)) {
        if (strcmp(ggml_get_name(t), name) == 0) {
            return t;
        }
    }
    return nullptr;
}

llama_robot_shim * llama_robot_shim_load(const llama_model * model, const char * path) {
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(model);
    if (iface == nullptr) {
        throw std::runtime_error("therobot: shims require a therobot model");
    }
    if (!iface->robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS)) {
        throw std::runtime_error("therobot: shims require a model with declared bottlenecks (taps feature)");
    }

    ggml_context * meta_ctx = nullptr;
    gguf_init_params gparams = {
        /*.no_alloc = */ true,
        /*.ctx      = */ &meta_ctx,
    };
    gguf_context * ctx = gguf_init_from_file(path, gparams);
    if (ctx == nullptr) {
        throw std::runtime_error(format("therobot: failed to read shim file '%s'", path));
    }

    // free gguf/meta contexts on all exit paths
    struct guard_t {
        gguf_context * g; ggml_context * m;
        ~guard_t() { gguf_free(g); ggml_free(m); }
    } guard { ctx, meta_ctx };

    std::unique_ptr<llama_robot_shim> shim(new llama_robot_shim());

    // §4 identity
    std::string arch;
    llama_robot_kv_get_str(ctx, "general.architecture", arch, true);
    if (arch != "therobot-shim") {
        throw std::runtime_error(format("therobot: '%s' is not a therobot-shim module (architecture '%s')", path, arch.c_str()));
    }
    llama_robot_kv_get_u32(ctx, "therobot.spec_version", shim->spec_version, true);
    if (shim->spec_version != LLAMA_ROBOT_SPEC_VERSION) {
        throw std::runtime_error(format("therobot: shim requires spec version %u, runtime implements %u",
                shim->spec_version, LLAMA_ROBOT_SPEC_VERSION));
    }

    llama_robot_kv_get_str(ctx, "therobot.shim.name",    shim->name,    true);
    llama_robot_kv_get_str(ctx, "therobot.shim.version", shim->version, false);
    llama_robot_kv_get_str(ctx, "therobot.shim.target_model", shim->target_model, false);
    llama_robot_kv_get_str(ctx, "therobot.shim.target_bottleneck", shim->target_bottleneck, true);
    llama_robot_kv_get_str(ctx, "therobot.shim.effect", shim->effect, false);
    llama_robot_kv_get_f32(ctx, "therobot.shim.selectivity", shim->selectivity, false);
    llama_robot_kv_get_str_arr(ctx, "therobot.shim.depends",   shim->depends,   false);
    llama_robot_kv_get_str_arr(ctx, "therobot.shim.conflicts", shim->conflicts, false);

    std::string gate_text = "always";
    llama_robot_kv_get_str(ctx, "therobot.shim.gate", gate_text, false);
    shim->gate = robot_shim_parse_gate(gate_text);
    if (shim->gate.kind == llama_robot_shim_gate::GATE_MODULATOR) {
        throw std::runtime_error("therobot: 'modulator:' shim gates need the modulator bus (E4) — not implemented yet");
    }

    // resolve target bottleneck
    for (size_t i = 0; i < iface->robot.bottlenecks.size(); ++i) {
        if (iface->robot.bottlenecks[i].name == shim->target_bottleneck) {
            shim->bottleneck_id = (int32_t) i;
            shim->width = iface->robot.bottlenecks[i].width;
            break;
        }
    }
    if (shim->bottleneck_id < 0) {
        throw std::runtime_error(format("therobot: shim '%s' targets unknown bottleneck '%s'",
                shim->name.c_str(), shim->target_bottleneck.c_str()));
    }

    // admission provenance: warn on hash mismatch (enforcement is E8 registry)
    if (!shim->target_model.empty() && !iface->robot.convert_lockfile_hash.empty() &&
        shim->target_model != iface->robot.convert_lockfile_hash) {
        LLAMA_LOG_WARN("therobot: shim '%s' admission scores were measured against model '%s', this model is '%s'\n",
                shim->name.c_str(), shim->target_model.c_str(), iface->robot.convert_lockfile_hash.c_str());
    }

    // collect + validate tensors (spec §4; v1 requires f32)
    const int64_t W = shim->width;

    ggml_tensor * m_a      = robot_shim_find_meta(meta_ctx, "robot.shim.a.weight");
    ggml_tensor * m_b      = robot_shim_find_meta(meta_ctx, "robot.shim.b.weight");
    ggml_tensor * m_steer  = robot_shim_find_meta(meta_ctx, "robot.shim.steer");
    ggml_tensor * m_gain   = robot_shim_find_meta(meta_ctx, "robot.shim.gain");
    ggml_tensor * m_gate_w = robot_shim_find_meta(meta_ctx, "robot.shim.gate.weight");
    ggml_tensor * m_gate_b = robot_shim_find_meta(meta_ctx, "robot.shim.gate.bias");

    auto check = [&](const ggml_tensor * t, const char * what, int64_t ne0, int64_t ne1) {
        if (t == nullptr) {
            return;
        }
        if (t->type != GGML_TYPE_F32) {
            throw std::runtime_error(format("therobot: shim tensor %s must be f32", what));
        }
        if (t->ne[0] != ne0 || (ne1 > 0 && t->ne[1] != ne1)) {
            throw std::runtime_error(format("therobot: shim tensor %s has shape [%lld, %lld], expected [%lld, %lld] (slice width %lld)",
                    what, (long long) t->ne[0], (long long) t->ne[1], (long long) ne0, (long long) ne1, (long long) W));
        }
    };
    check(m_steer,  "robot.shim.steer",       W, 1);
    check(m_gain,   "robot.shim.gain",        W, 1);
    check(m_gate_w, "robot.shim.gate.weight", W, 1);
    check(m_gate_b, "robot.shim.gate.bias",   1, 1);
    if ((m_a == nullptr) != (m_b == nullptr)) {
        throw std::runtime_error("therobot: shim low-rank pair requires both robot.shim.a.weight and robot.shim.b.weight");
    }
    if (m_a != nullptr) {
        check(m_a, "robot.shim.a.weight", W, m_a->ne[1]);
        check(m_b, "robot.shim.b.weight", m_a->ne[1], W);
    }
    if (m_gain == nullptr && m_steer == nullptr && m_a == nullptr) {
        LLAMA_LOG_WARN("therobot: shim '%s' declares no edit tensors — it will be a no-op\n", shim->name.c_str());
    }
    if (shim->gate.kind == llama_robot_shim_gate::GATE_PROBE && m_gate_w == nullptr) {
        throw std::runtime_error(format("therobot: shim '%s' has a probe gate but no robot.shim.gate.weight", shim->name.c_str()));
    }

    // create data tensors and allocate them in a CPU backend buffer (the
    // scheduler inserts copies if the model computes elsewhere)
    {
        const size_t n_tensors = 8; // upper bound incl. synthesized gate bias
        ggml_init_params ip = {
            /*.mem_size   =*/ n_tensors * ggml_tensor_overhead(),
            /*.mem_buffer =*/ nullptr,
            /*.no_alloc   =*/ true,
        };
        shim->ctx.reset(ggml_init(ip));

        auto dup = [&](ggml_tensor * meta) -> ggml_tensor * {
            if (meta == nullptr) {
                return nullptr;
            }
            ggml_tensor * t = ggml_dup_tensor(shim->ctx.get(), meta);
            ggml_set_name(t, ggml_get_name(meta));
            return t;
        };
        shim->t_a      = dup(m_a);
        shim->t_b      = dup(m_b);
        shim->t_steer  = dup(m_steer);
        shim->t_gain   = dup(m_gain);
        shim->t_gate_w = dup(m_gate_w);
        if (shim->gate.kind == llama_robot_shim_gate::GATE_PROBE) {
            // effective bias synthesized below (op/value folded in)
            shim->t_gate_b = ggml_new_tensor_1d(shim->ctx.get(), GGML_TYPE_F32, 1);
            ggml_set_name(shim->t_gate_b, "robot.shim.gate.bias_eff");
        }

        ggml_backend_dev_t cpu_dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
        if (cpu_dev == nullptr) {
            throw std::runtime_error("therobot: no CPU backend device found");
        }
        shim->buf.reset(ggml_backend_alloc_ctx_tensors_from_buft(shim->ctx.get(), ggml_backend_dev_buffer_type(cpu_dev)));
        if (!shim->buf) {
            throw std::runtime_error("therobot: failed to allocate shim tensor buffer");
        }
    }

    // load tensor data from the file
    {
        llama_file file(path, "rb", /*use_direct_io =*/ false);
        std::vector<uint8_t> read_buf;

        auto load = [&](ggml_tensor * meta, ggml_tensor * dst) {
            if (meta == nullptr || dst == nullptr) {
                return;
            }
            const size_t offs = gguf_get_data_offset(ctx) + gguf_get_tensor_offset(ctx, gguf_find_tensor(ctx, ggml_get_name(meta)));
            const size_t size = ggml_nbytes(meta);
            read_buf.resize(size);
            file.seek(offs, SEEK_SET);
            file.read_raw(read_buf.data(), size);
            ggml_backend_tensor_set(dst, read_buf.data(), 0, size);
        };
        load(m_a,     shim->t_a);
        load(m_b,     shim->t_b);
        load(m_steer, shim->t_steer);
        load(m_gain,  shim->t_gain);

        // gate: fold the comparison into the weight sign and an effective bias
        //   s = w·x + b;  s > v  →  step( w·x + (b − v))
        //                 s < v  →  step(−w·x + (v − b))
        // step(x) = x > 0, so > is strict and >= approximates > in f32
        if (shim->gate.kind == llama_robot_shim_gate::GATE_PROBE) {
            const bool less = (shim->gate.op == "<" || shim->gate.op == "<=");

            std::vector<float> wv(shim->width);
            const size_t wsize = ggml_nbytes(m_gate_w);
            file.seek(gguf_get_data_offset(ctx) + gguf_get_tensor_offset(ctx, gguf_find_tensor(ctx, "robot.shim.gate.weight")), SEEK_SET);
            file.read_raw(wv.data(), wsize);

            float bg = 0.0f;
            if (m_gate_b != nullptr) {
                file.seek(gguf_get_data_offset(ctx) + gguf_get_tensor_offset(ctx, gguf_find_tensor(ctx, "robot.shim.gate.bias")), SEEK_SET);
                file.read_raw(&bg, sizeof(bg));
            }

            if (less) {
                for (auto & v : wv) { v = -v; }
            }
            const float beff = less ? (shim->gate.value - bg) : (bg - shim->gate.value);

            ggml_backend_tensor_set(shim->t_gate_w, wv.data(), 0, wsize);
            ggml_backend_tensor_set(shim->t_gate_b, &beff, 0, sizeof(beff));
        }
    }

    shim->model = model;

    LLAMA_LOG_INFO("therobot: loaded shim '%s' v%s → bottleneck '%s' (tap %d, width %u), gate %s, selectivity %.3f\n",
            shim->name.c_str(), shim->version.empty() ? "?" : shim->version.c_str(),
            shim->target_bottleneck.c_str(), shim->bottleneck_id, shim->width,
            gate_text.c_str(), shim->selectivity);

    return shim.release();
}
