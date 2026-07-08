// therobot runtime extension — semvec readout layer implementation
//
// Public API surface lives in include/llama-robot.h (semvec block). The read
// path is llama_robot_tap_read + one host matvec against the site's proj
// tensor; the write path compiles Δs·G into an ephemeral steer-only shim and
// rides the E3 attach/splice/epoch machinery unchanged.

#include "llama-robot-semvec.h"

#include "llama-robot.h"

#include "llama-context.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include "ggml.h"
#include "ggml-backend.h"
#include "ggml-cpp.h"

#include <cmath>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>

static const llama_robot_model_iface * semvec_iface(const llama_model * model) {
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(model);
    if (iface == nullptr || !iface->robot.has_feature(LLAMA_ROBOT_FEATURE_SEMVEC)) {
        return nullptr;
    }
    return iface;
}

static const llama_robot_semvec_site * semvec_site(const llama_model * model, int32_t i) {
    const auto * iface = semvec_iface(model);
    if (iface == nullptr || i < 0 || (size_t) i >= iface->robot.semvec.sites.size()) {
        return nullptr;
    }
    return &iface->robot.semvec.sites[i];
}

// f32/f16 row-major accessor for a materialized 2D ext tensor: value [r, c]
// with ne[0] = row length (ggml dim 0 is contiguous)
static float semvec_at(const ggml_tensor * t, int64_t r, int64_t c) {
    if (t->type == GGML_TYPE_F32) {
        return *(const float *) ((const char *) t->data + r*t->nb[1] + c*t->nb[0]);
    }
    return ggml_fp16_to_fp32(*(const ggml_fp16_t *) ((const char *) t->data + r*t->nb[1] + c*t->nb[0]));
}

//
// validation (called at load; keeps the file's calibration claims honest)
//

void llama_robot_validate_semvec(const llama_robot_model_iface & iface, const llama_hparams & hparams) {
    GGML_UNUSED(hparams);
    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_SEMVEC)) {
        return;
    }
    const auto & sv = iface.robot.semvec;
    const int64_t D = (int64_t) sv.dim();
    for (const auto & s : sv.sites) {
        const ggml_tensor * proj  = iface.robot_ext_tensor("robot.semvec." + s.name + ".proj");
        const ggml_tensor * calib = iface.robot_ext_tensor("robot.semvec." + s.name + ".calib");
        if (proj == nullptr || calib == nullptr) {
            throw std::runtime_error(format("therobot: semvec site '%s' is missing proj/calib tensors", s.name.c_str()));
        }
        // converter writes proj as [d, D] and calib as [D, 2] (numpy row-major
        // → ggml ne[0] is the innermost dim: proj ne = {D, d}, calib ne = {2, D})
        if (proj->ne[0] != D || proj->ne[1] != (int64_t) s.width) {
            throw std::runtime_error(format(
                    "therobot: semvec site '%s' proj shape [%lld, %lld] != expected [D=%lld, d=%u]",
                    s.name.c_str(), (long long) proj->ne[0], (long long) proj->ne[1], (long long) D, s.width));
        }
        if (calib->ne[0] != 2 || calib->ne[1] != D) {
            throw std::runtime_error(format(
                    "therobot: semvec site '%s' calib shape [%lld, %lld] != expected [2, D=%lld]",
                    s.name.c_str(), (long long) calib->ne[0], (long long) calib->ne[1], (long long) D));
        }
        for (int64_t j = 0; j < D; ++j) {
            const float scale = semvec_at(calib, j, 0);
            if (scale != 0.0f && scale != 1.0f) {
                throw std::runtime_error(format(
                        "therobot: semvec site '%s' calib scale[%lld] = %f (must be 0 or 1)",
                        s.name.c_str(), (long long) j, scale));
            }
        }
        const ggml_tensor * ov = iface.robot_ext_tensor("robot.semvec." + s.name + ".overlay");
        if (ov != nullptr) {
            // overlay [D, d] → ggml ne = {d, D}
            if (ov->ne[0] != (int64_t) s.width || ov->ne[1] != D) {
                throw std::runtime_error(format(
                        "therobot: semvec site '%s' overlay shape [%lld, %lld] != expected [d=%u, D=%lld]",
                        s.name.c_str(), (long long) ov->ne[0], (long long) ov->ne[1], s.width, (long long) D));
            }
            // write calibration: G·E diagonal == 1 on writable (nonzero) rows
            for (int64_t j = 0; j < D; ++j) {
                float norm = 0.0f, diag = 0.0f;
                for (int64_t k = 0; k < (int64_t) s.width; ++k) {
                    const float g = semvec_at(ov, j, k);
                    norm += fabsf(g);
                    diag += g * semvec_at(proj, k, j);
                }
                if (norm > 0.0f && fabsf(diag - 1.0f) > 1e-3f) {
                    throw std::runtime_error(format(
                            "therobot: semvec site '%s' write calibration drifted on axis %lld (G·E = %f)",
                            s.name.c_str(), (long long) j, diag));
                }
            }
        }
    }
    LLAMA_LOG_INFO("therobot: semvec %s (hash %s) — %zu site(s), D = %u (%u named + %u latent)\n",
            sv.version.c_str(), sv.hash.c_str(), sv.sites.size(), sv.dim(), sv.named_dim, sv.latent_dim);
}

//
// public API — enumeration
//

int32_t llama_robot_semvec_site_count(const llama_model * model) {
    const auto * iface = semvec_iface(model);
    return iface == nullptr ? 0 : (int32_t) iface->robot.semvec.sites.size();
}

const char * llama_robot_semvec_site_name(const llama_model * model, int32_t i) {
    const auto * s = semvec_site(model, i);
    return s == nullptr ? nullptr : s->name.c_str();
}

int32_t llama_robot_semvec_dim(const llama_model * model) {
    const auto * iface = semvec_iface(model);
    return iface == nullptr ? 0 : (int32_t) iface->robot.semvec.dim();
}

int32_t llama_robot_semvec_named_dim(const llama_model * model) {
    const auto * iface = semvec_iface(model);
    return iface == nullptr ? 0 : (int32_t) iface->robot.semvec.named_dim;
}

const char * llama_robot_semvec_axis_name(const llama_model * model, int32_t axis) {
    const auto * iface = semvec_iface(model);
    if (iface == nullptr || axis < 0 || (size_t) axis >= iface->robot.semvec.axes.size()) {
        return nullptr;
    }
    return iface->robot.semvec.axes[axis].c_str();
}

int32_t llama_robot_semvec_axis_index(const llama_model * model, const char * name) {
    const auto * iface = semvec_iface(model);
    if (iface == nullptr || name == nullptr) {
        return -1;
    }
    const auto & axes = iface->robot.semvec.axes;
    for (size_t i = 0; i < axes.size(); ++i) {
        if (axes[i] == name) {
            return (int32_t) i;
        }
    }
    return -1;
}

//
// public API — read / query
//

bool llama_robot_semvec_read(llama_context * ctx, int32_t site, float * dst, size_t n) {
    if (ctx == nullptr || dst == nullptr) {
        return false;
    }
    const llama_model * model = &ctx->get_model();
    const auto * iface = semvec_iface(model);
    const auto * s = semvec_site(model, site);
    if (iface == nullptr || s == nullptr) {
        return false;
    }
    const size_t D = iface->robot.semvec.dim();
    if (n < D) {
        LLAMA_LOG_ERROR("therobot: semvec_read needs %zu floats, caller provided %zu\n", D, n);
        return false;
    }
    const ggml_tensor * proj  = iface->robot_ext_tensor("robot.semvec." + s->name + ".proj");
    const ggml_tensor * calib = iface->robot_ext_tensor("robot.semvec." + s->name + ".calib");
    if (proj == nullptr || calib == nullptr) {
        return false;
    }

    std::vector<float> x(s->width);
    if (!llama_robot_tap_read(ctx, s->tap_id, x.data())) {
        return false;
    }

    // s = h_slice · E + bias; non-admitted axes (scale 0) read as 0
    for (size_t j = 0; j < D; ++j) {
        const float scale = semvec_at(calib, (int64_t) j, 0);
        if (scale == 0.0f) {
            dst[j] = 0.0f;
            continue;
        }
        float acc = semvec_at(calib, (int64_t) j, 1);
        for (uint32_t k = 0; k < s->width; ++k) {
            acc += x[k] * semvec_at(proj, (int64_t) k, (int64_t) j);
        }
        dst[j] = acc;
    }
    return true;
}

float llama_robot_semvec_axis(const llama_model * model, const float * s, int32_t axis) {
    const auto * iface = semvec_iface(model);
    if (iface == nullptr || s == nullptr || axis < 0 || (uint32_t) axis >= iface->robot.semvec.dim()) {
        return 0.0f;
    }
    return s[axis];
}

float llama_robot_semvec_query(const llama_model * model, const float * s, const float * query, size_t n) {
    GGML_UNUSED(model);
    if (s == nullptr || query == nullptr || n == 0) {
        return 0.0f;
    }
    // plain cosine — the caller controls which block by offsetting the
    // pointers (latent block for zero-shot text queries; the query vector is
    // the text embedded + reduced through the SAME frozen semvec basis)
    double dot = 0.0, ns = 0.0, nq = 0.0;
    for (size_t i = 0; i < n; ++i) {
        dot += (double) s[i] * query[i];
        ns  += (double) s[i] * s[i];
        nq  += (double) query[i] * query[i];
    }
    if (ns <= 0.0 || nq <= 0.0) {
        return 0.0f;
    }
    return (float) (dot / (sqrt(ns) * sqrt(nq)));
}

//
// public API — the overlay (write path)
//

static std::string semvec_overlay_shim_name(const std::string & site) {
    return "__semvec_overlay:" + site;
}

// build an ephemeral steer-only shim in a CPU buffer (mirrors the E3 module
// loader's tensor allocation; GATE_ALWAYS, no deps/conflicts)
static llama_robot_shim * semvec_make_steer_shim(
        const llama_model * model, const llama_robot_semvec_site & site,
        int32_t bottleneck_id, const std::vector<float> & steer) {
    auto * shim = new llama_robot_shim();
    shim->spec_version      = LLAMA_ROBOT_SPEC_VERSION;
    shim->name              = semvec_overlay_shim_name(site.name);
    shim->version           = "0";
    shim->effect            = "semvec overlay (runtime-set)";
    shim->target_bottleneck = site.name;
    shim->model             = model;
    shim->bottleneck_id     = bottleneck_id;
    shim->width             = site.width;
    shim->gate.kind         = llama_robot_shim_gate::GATE_ALWAYS;

    ggml_init_params ip = {
        /*.mem_size   =*/ ggml_tensor_overhead() * 2,
        /*.mem_buffer =*/ nullptr,
        /*.no_alloc   =*/ true,
    };
    shim->ctx.reset(ggml_init(ip));
    shim->t_steer = ggml_new_tensor_1d(shim->ctx.get(), GGML_TYPE_F32, site.width);
    ggml_set_name(shim->t_steer, "robot.shim.steer");
    shim->buf.reset(ggml_backend_alloc_ctx_tensors_from_buft(
            shim->ctx.get(), ggml_backend_cpu_buffer_type()));
    if (!shim->buf) {
        delete shim;
        return nullptr;
    }
    ggml_backend_tensor_set(shim->t_steer, steer.data(), 0, steer.size() * sizeof(float));
    return shim;
}

bool llama_robot_semvec_overlay_set(llama_context * ctx, int32_t site_id,
                                    const float * delta_s, float scale) {
    if (ctx == nullptr) {
        return false;
    }
    const llama_model * model = &ctx->get_model();
    const auto * iface = semvec_iface(model);
    const auto * s = semvec_site(model, site_id);
    if (iface == nullptr || s == nullptr) {
        return false;
    }
    const std::string name = semvec_overlay_shim_name(s->name);

    // detach + drop any existing overlay for this site (quietly if absent)
    auto & stp = ctx->robot_state;
    if (stp) {
        bool attached = false;
        for (const auto * sh : stp->shims) {
            if (sh->name == name) { attached = true; break; }
        }
        if (attached) {
            llama_robot_shim_detach(ctx, name.c_str());
        }
        auto & owned = stp->owned_shims;
        for (auto it = owned.begin(); it != owned.end(); ++it) {
            if ((*it)->name == name) {
                owned.erase(it);
                break;
            }
        }
    }
    if (delta_s == nullptr || scale == 0.0f) {
        return true;   // unset — identity restored, epoch already bumped by detach
    }

    const ggml_tensor * ov = iface->robot_ext_tensor("robot.semvec." + s->name + ".overlay");
    if (ov == nullptr) {
        LLAMA_LOG_ERROR("therobot: semvec site '%s' has no overlay tensor (read-only site)\n", s->name.c_str());
        return false;
    }
    const size_t D = iface->robot.semvec.dim();

    // steer = scale · (Δs · G) — a constant slice-space vector for this set call
    std::vector<float> steer(s->width, 0.0f);
    for (size_t j = 0; j < D; ++j) {
        const float ds = delta_s[j];
        if (ds == 0.0f) {
            continue;
        }
        for (uint32_t k = 0; k < s->width; ++k) {
            steer[k] += scale * ds * semvec_at(ov, (int64_t) j, (int64_t) k);
        }
    }

    llama_robot_shim * shim = semvec_make_steer_shim(model, *s, s->tap_id, steer);
    if (shim == nullptr) {
        return false;
    }
    if (!llama_robot_shim_attach(ctx, shim)) {
        delete shim;
        return false;
    }
    ctx->robot_state->owned_shims.emplace_back(shim);   // context owns its overlays
    return true;
}
