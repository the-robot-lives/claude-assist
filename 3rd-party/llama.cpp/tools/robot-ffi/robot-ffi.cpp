// robot-ffi — implementation. Wraps common_sampler (common/sampling.h).

#include "robot-ffi.h"

#include "common.h"
#include "sampling.h"
#include "ggml.h"

#include <cstdio>

struct robot_sampler {
    common_sampler * smpl = nullptr;
};

static void robot_noop_log(enum ggml_log_level, const char *, void *) {}

extern "C" {

void robot_silence_logs(void) {
    llama_log_set(robot_noop_log, nullptr);   // llama-side logs (incl. "therobot: ...")
    ggml_log_set(robot_noop_log, nullptr);    // ggml/Metal kernel-pipeline logs
}

void robot_log_to_file(const char * path) {
    if (path == nullptr) {
        return;
    }
    FILE * f = std::freopen(path, "a", stderr);
    (void) f;
}

robot_sampler_params robot_sampler_default_params(void) {
    robot_sampler_params p;
    p.seed           = LLAMA_DEFAULT_SEED;
    p.top_k          = 40;
    p.top_p          = 0.95f;
    p.min_p          = 0.05f;
    p.temp           = 0.7f;
    p.penalty_last_n = 64;
    p.penalty_repeat = 1.1f;
    return p;
}

robot_sampler * robot_sampler_init(const struct llama_model * model, robot_sampler_params params) {
    if (model == nullptr) {
        return nullptr;
    }
    common_params_sampling cps;   // start from common's defaults
    cps.seed           = params.seed;
    cps.top_k          = params.top_k;
    cps.top_p          = params.top_p;
    cps.min_p          = params.min_p;
    cps.temp           = params.temp;
    cps.penalty_last_n = params.penalty_last_n;
    cps.penalty_repeat = params.penalty_repeat;

    common_sampler * smpl = common_sampler_init(model, cps);
    if (smpl == nullptr) {
        return nullptr;
    }
    robot_sampler * s = new robot_sampler();
    s->smpl = smpl;
    return s;
}

void robot_sampler_free(robot_sampler * s) {
    if (s == nullptr) {
        return;
    }
    if (s->smpl != nullptr) {
        common_sampler_free(s->smpl);
    }
    delete s;
}

llama_token robot_sampler_sample(robot_sampler * s, struct llama_context * ctx, int32_t idx) {
    if (s == nullptr || s->smpl == nullptr || ctx == nullptr) {
        return -1;
    }
    return common_sampler_sample(s->smpl, ctx, idx);
}

void robot_sampler_accept(robot_sampler * s, llama_token id) {
    if (s == nullptr || s->smpl == nullptr) {
        return;
    }
    common_sampler_accept(s->smpl, id, /* accept_grammar = */ true);
}

void robot_sampler_reset(robot_sampler * s) {
    if (s == nullptr || s->smpl == nullptr) {
        return;
    }
    common_sampler_reset(s->smpl);
}

} // extern "C"
