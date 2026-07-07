// therobot runtime extension — tap read-back + probe evaluation (E2)
//
// Implements the public API in include/llama-robot.h. Tap tensors are named
// graph outputs (`robot_tap-<i>`, added by llama_robot_graph_add_taps); after
// a decode they are located by name in the most recent graph and their last
// position is copied out. Probe heads are small host-side linear layers over
// a tap slice, materialized at load by llama_robot_materialize_ext_tensors.

#include "llama-robot.h"

#include "llama-context.h"
#include "llama-graph.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-model.h"

#include "ggml.h"

#include <cstring>
#include <vector>

static const llama_robot_model_iface * robot_iface(const llama_model * model) {
    return dynamic_cast<const llama_robot_model_iface *>(model);
}

bool llama_robot_enabled(const llama_model * model) {
    return robot_iface(model) != nullptr;
}

int32_t llama_robot_tap_count(const llama_model * model) {
    const auto * iface = robot_iface(model);
    return iface == nullptr ? 0 : (int32_t) iface->robot.bottlenecks.size();
}

static const llama_robot_bottleneck * robot_tap(const llama_model * model, int32_t tap_id) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || tap_id < 0 || (size_t) tap_id >= iface->robot.bottlenecks.size()) {
        return nullptr;
    }
    return &iface->robot.bottlenecks[tap_id];
}

const char * llama_robot_tap_name(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? nullptr : bn->name.c_str();
}

const char * llama_robot_tap_point(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? nullptr : bn->point.c_str();
}

int32_t llama_robot_tap_width(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? -1 : (int32_t) bn->width;
}

int32_t llama_robot_tap_layer(const llama_model * model, int32_t tap_id) {
    const auto * bn = robot_tap(model, tap_id);
    return bn == nullptr ? -1 : (int32_t) bn->layer;
}

bool llama_robot_tap_read(llama_context * ctx, int32_t tap_id, float * dst) {
    const auto * bn = robot_tap(&ctx->get_model(), tap_id);
    if (bn == nullptr || dst == nullptr) {
        return false;
    }

    // make sure any in-flight (async) compute has finished
    ctx->synchronize();

    llm_graph_result * res = ctx->robot_last_res();
    if (res == nullptr) {
        return false;
    }
    ggml_cgraph * gf = res->get_gf();
    if (gf == nullptr) {
        return false;
    }

    ggml_tensor * tap = ggml_graph_get_tensor(gf, format("robot_tap-%d", tap_id).c_str());
    if (tap == nullptr || tap->buffer == nullptr) {
        return false; // tap disabled, or no graph computed yet
    }

    GGML_ASSERT(tap->type == GGML_TYPE_F32);
    GGML_ASSERT(tap->ne[0] == (int64_t) bn->width);

    const int64_t rows = tap->ne[1];
    if (rows <= 0) {
        return false; // e.g. a last-layer tap in a decode with no requested outputs
    }

    // most recent position = last row of the (contiguous) tap tensor
    const size_t row_bytes = (size_t) bn->width * sizeof(float);
    ggml_backend_tensor_get(tap, dst, (size_t) (rows - 1) * row_bytes, row_bytes);

    return true;
}

// probe head tensors for (tap, attr) — spec §1.2: robot.probe.{i}.{attr}.weight/.bias
static ggml_tensor * robot_probe_weight(const llama_robot_model_iface * iface, int32_t tap_id, const char * attr) {
    return iface->robot_ext_tensor(format("robot.probe.%d.%s.weight", tap_id, attr));
}

int32_t llama_robot_probe_dim(const llama_model * model, int32_t tap_id, const char * attr) {
    const auto * iface = robot_iface(model);
    if (iface == nullptr || attr == nullptr || robot_tap(model, tap_id) == nullptr) {
        return -1;
    }
    const ggml_tensor * w = robot_probe_weight(iface, tap_id, attr);
    return w == nullptr ? -1 : (int32_t) w->ne[1];
}

bool llama_robot_probe_eval(llama_context * ctx, int32_t tap_id, const char * attr, float * dst) {
    const llama_model * model = &ctx->get_model();
    const auto * iface = robot_iface(model);
    const auto * bn    = robot_tap(model, tap_id);
    if (iface == nullptr || bn == nullptr || attr == nullptr || dst == nullptr) {
        return false;
    }

    const ggml_tensor * w = robot_probe_weight(iface, tap_id, attr);
    if (w == nullptr) {
        LLAMA_LOG_WARN("therobot: no probe head 'robot.probe.%d.%s.*' in this model\n", tap_id, attr);
        return false;
    }
    if (w->ne[0] != (int64_t) bn->width) {
        LLAMA_LOG_ERROR("therobot: probe 'robot.probe.%d.%s.weight' input dim %lld != tap width %u\n",
                tap_id, attr, (long long) w->ne[0], bn->width);
        return false;
    }
    const ggml_tensor * b = iface->robot_ext_tensor(format("robot.probe.%d.%s.bias", tap_id, attr));

    std::vector<float> x(bn->width);
    if (!llama_robot_tap_read(ctx, tap_id, x.data())) {
        return false;
    }

    const int64_t n_in  = w->ne[0];
    const int64_t n_out = w->ne[1];

    // probe heads are small and quantization-exempt (spec §2): f32 or f16
    for (int64_t o = 0; o < n_out; ++o) {
        float acc = 0.0f;
        if (w->type == GGML_TYPE_F32) {
            const float * wrow = (const float *) ((const char *) w->data + o*w->nb[1]);
            for (int64_t k = 0; k < n_in; ++k) {
                acc += wrow[k] * x[k];
            }
        } else if (w->type == GGML_TYPE_F16) {
            const ggml_fp16_t * wrow = (const ggml_fp16_t *) ((const char *) w->data + o*w->nb[1]);
            for (int64_t k = 0; k < n_in; ++k) {
                acc += ggml_fp16_to_fp32(wrow[k]) * x[k];
            }
        } else {
            LLAMA_LOG_ERROR("therobot: probe weight type %s not supported (expected f32/f16)\n", ggml_type_name(w->type));
            return false;
        }
        if (b != nullptr) {
            if (b->type == GGML_TYPE_F32) {
                acc += ((const float *) b->data)[o];
            } else if (b->type == GGML_TYPE_F16) {
                acc += ggml_fp16_to_fp32(((const ggml_fp16_t *) b->data)[o]);
            }
        }
        dst[o] = acc;
    }

    return true;
}
