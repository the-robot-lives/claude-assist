// therobot runtime extension — settling decoder (E7, proposal 004)
//
// The canvas loop, built on the shared iterate-until-quiet executor:
//
//   1. decode the prompt once (its logits draft canvas position 0)
//   2. initialize the canvas with the mask token
//   3. each round: drop the canvas region from the KV state, re-decode the
//      whole canvas in one batch (all positions output logits), and re-draft
//      every position from the previous round's context
//   4. change metric = fraction of positions whose draft moved; quiet when
//      ≤ ε, then m-scheduled extra re-check rounds, under the step cap
//
// v1 objective `jacobi-ar`: position j re-drafts from the logits at position
// j−1 (causal next-token heads). This is Jacobi iteration on the greedy
// decoding fixed point — at convergence the canvas *equals* the greedy AR
// output, with the correct prefix growing at least one position per round.
// Difficulty shows up directly as rounds-to-settle (004 test 2).
//
// The context's therobot machinery stays live across rounds: taps are
// readable mid-settle, shims keep editing the molten canvas, the leaky
// state/modulator persist across iterations (the un-commit escape hatch),
// and episodic memory sees every round.

#include "llama-robot.h"

#include "llama-context.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-executor.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include <cmath>
#include <cstring>
#include <vector>

static int32_t robot_settle_extra_rounds(const llama_robot_model_iface & iface, llama_context * ctx) {
    const auto & sched = iface.robot.settle.m_schedule;
    if (sched.empty() || !ctx->robot_state || ctx->robot_state->m.empty()) {
        return 0;
    }
    // m-scheduled settling depth: index the schedule by the arousal channel
    const float arousal = ctx->robot_state->m[0];
    int32_t idx = (int32_t) std::floor(arousal);
    if (idx < 0) {
        idx = 0;
    }
    if ((size_t) idx >= sched.size()) {
        idx = (int32_t) sched.size() - 1;
    }
    return (int32_t) std::lround(sched[idx]);
}

int32_t llama_robot_settle(
        llama_context * ctx,
        const llama_token * prompt, int32_t n_prompt,
        llama_token * out, int32_t n_out,
        int32_t * steps_used) {
    if (ctx == nullptr || prompt == nullptr || n_prompt <= 0 || out == nullptr || n_out < 0) {
        return -1;
    }
    if (n_out == 0) {
        if (steps_used != nullptr) { *steps_used = 0; }
        return 0;
    }

    const llama_model * model = &ctx->get_model();
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(model);
    if (iface == nullptr || !iface->robot.has_feature(LLAMA_ROBOT_FEATURE_SETTLE)) {
        LLAMA_LOG_ERROR("therobot: model has no settle feature\n");
        return -1;
    }
    const auto & sp = iface->robot.settle;

    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int32_t n_vocab = llama_vocab_n_tokens(vocab);

    // m-scheduled settling depth reads the modulator at settle entry — the
    // prompt pass and every settling round will keep decaying m underneath
    const int32_t extra_rounds = robot_settle_extra_rounds(*iface, ctx);

    llama_memory_t mem = llama_get_memory(ctx);
    llama_memory_clear(mem, true);

    // 1. prompt pass — its last-position logits draft canvas position 0
    std::vector<float> prompt_logits(n_vocab);
    {
        std::vector<llama_token> ptoks(prompt, prompt + n_prompt);
        llama_batch batch = llama_batch_get_one(ptoks.data(), n_prompt);
        if (llama_decode(ctx, batch) != 0) {
            LLAMA_LOG_ERROR("therobot: settle prompt decode failed\n");
            return -1;
        }
        const float * lg = llama_get_logits(ctx);
        memcpy(prompt_logits.data(), lg, n_vocab * sizeof(float));
    }

    auto argmax = [n_vocab](const float * lg) -> llama_token {
        int32_t best = 0;
        for (int32_t v = 1; v < n_vocab; ++v) {
            if (lg[v] > lg[best]) { best = v; }
        }
        return best;
    };

    // 2. molten canvas, initialized with the mask token
    std::vector<llama_token> draft((size_t) n_out, (llama_token) sp.mask_token_id);
    draft[0] = argmax(prompt_logits.data()); // position 0 is fixed by the prompt

    llama_batch batch = llama_batch_init(n_out, 0, 1);

    // 3.+4. settle until quiet
    auto step = [&](int32_t /*round*/) -> float {
        // drop the canvas region; the prompt KV stays warm
        llama_memory_seq_rm(mem, 0, n_prompt, -1);

        batch.n_tokens = n_out;
        for (int32_t j = 0; j < n_out; ++j) {
            batch.token[j]     = draft[j];
            batch.pos[j]       = n_prompt + j;
            batch.n_seq_id[j]  = 1;
            batch.seq_id[j][0] = 0;
            batch.logits[j]    = 1; // every position drafts its successor
        }
        if (llama_decode(ctx, batch) != 0) {
            LLAMA_LOG_ERROR("therobot: settle round decode failed\n");
            return 0.0f; // reads as quiet — the loop terminates
        }

        int32_t changed = 0;
        // position 0 is prompt-drafted and never moves; j re-drafts from j−1
        for (int32_t j = 1; j < n_out; ++j) {
            const llama_token t = argmax(llama_get_logits_ith(ctx, j - 1));
            if (t != draft[j]) {
                draft[j] = t;
                changed++;
            }
        }
        return n_out > 1 ? (float) changed / (float) (n_out - 1) : 0.0f;
    };

    llama_robot_executor_params xp;
    xp.max_steps    = (int32_t) sp.max_steps;
    xp.epsilon      = sp.epsilon;
    xp.extra_rounds = extra_rounds;

    bool converged = false;
    const int32_t steps = llama_robot_executor_run(xp, step, &converged);

    llama_batch_free(batch);

    if (!converged) {
        LLAMA_LOG_WARN("therobot: settle hit the step cap (%d rounds) before going quiet\n", steps);
    }
    LLAMA_LOG_INFO("therobot: settled %d position(s) in %d round(s)%s\n",
            n_out, steps, xp.extra_rounds > 0 ? " (incl. m-scheduled re-checks)" : "");

    memcpy(out, draft.data(), (size_t) n_out * sizeof(llama_token));
    if (steps_used != nullptr) {
        *steps_used = steps;
    }
    return n_out;
}
