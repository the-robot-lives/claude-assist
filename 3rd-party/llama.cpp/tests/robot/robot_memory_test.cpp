// E5 episodic memory test (Hypothesis 4): a one-shot write changes behavior
// on the very next decode without any weight update, and the change decays as
// designed (recency-weighted recall + modulator decay). Also: capacity-bounded
// decay eviction, salience-gated auto-writes, and checkpoint/restore of the
// full mind including the store.
#include "llama.h"
#include "llama-robot.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static int failures = 0;

#define CHECK(cond, ...) do { \
    if (!(cond)) { failures++; fprintf(stderr, "CHECK FAILED (%s:%d): ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } \
} while (0)

static llama_context * make_ctx(llama_model * model) {
    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 64;
    cp.n_batch = 8;
    llama_context * ctx = llama_init_from_model(model, cp);
    if (!ctx) { fprintf(stderr, "context init failed\n"); exit(1); }
    return ctx;
}

static std::vector<float> step(llama_model * model, llama_context * ctx, llama_token tok = 5) {
    llama_memory_clear(llama_get_memory(ctx), true);
    llama_batch batch = llama_batch_get_one(&tok, 1);
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
    const int n_vocab = llama_vocab_n_tokens(llama_model_get_vocab(model));
    const float * logits = llama_get_logits(ctx);
    return std::vector<float>(logits, logits + n_vocab);
}

static float vec_diff(const std::vector<float> & a, const std::vector<float> & b) {
    float d = 0.0f;
    for (size_t i = 0; i < a.size(); ++i) {
        d = std::fmax(d, std::fabs(a[i] - b[i]));
    }
    return d;
}

int main(int argc, char ** argv) {
    if (argc != 2) { fprintf(stderr, "usage: %s <fixture-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[1];

    llama_model_params mp = llama_model_default_params();

    // ---- one-shot behavior change that decays (Hypothesis 4 / S3 DoD) ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-mem.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2-mem load");
        if (!model) { return 1; }

        llama_context * ctx = make_ctx(model);
        CHECK(llama_robot_memory_count(ctx) == 0, "store starts empty");

        // silent salience channel: repeated decodes must not auto-write
        const auto baseline = step(model, ctx);
        for (int i = 0; i < 10; ++i) {
            step(model, ctx);
        }
        CHECK(llama_robot_memory_count(ctx) == 0, "zero salience weights must never auto-write");
        float recall[4];
        CHECK(llama_robot_memory_recall(ctx, recall), "recall readable");
        CHECK(recall[0] == 0.0f, "recall is zero with an empty store");

        // the noteworthy event: one explicit write of the current summary
        CHECK(!llama_robot_memory_write(ctx, -1.0f), "non-positive salience must be refused");
        CHECK(llama_robot_memory_write(ctx, 1.0f), "one-shot memory write");
        CHECK(llama_robot_memory_count(ctx) == 1, "one memory stored");
        CHECK(llama_robot_memory_recall(ctx, recall), "recall after write");
        CHECK(recall[0] != 0.0f, "recall must fire for the matching context");
        printf("one-shot: recall[arousal] = %g after write\n", recall[0]);

        // influence path: recall → next decode's modulator update → m → FiLM
        // on the decode after that (one-decode onset latency, documented)
        (void) step(model, ctx); // onset: recall enters m here
        const auto after = step(model, ctx);
        const float d0 = vec_diff(after, baseline);
        CHECK(d0 > 0.0f, "one-shot write must change behavior after onset");

        // the influence rises to a peak while recall is fresh (m accumulating),
        // then decays as designed (recency halflife 4 tokens + m decay)
        float d_prev = d0, d_peak = d0;
        bool decaying = false, monotone_after_peak = true;
        for (int i = 0; i < 40; ++i) {
            const auto cur = step(model, ctx);
            const float d = vec_diff(cur, baseline);
            if (decaying) {
                monotone_after_peak &= (d <= d_prev + 1e-6f);
            } else if (d < d_prev) {
                decaying = true;
            }
            d_peak = std::fmax(d_peak, d);
            d_prev = d;
        }
        printf("hypothesis 4: shift %g, peak %g, %g after decay\n", d0, d_peak, d_prev);
        CHECK(decaying, "influence must eventually start decaying");
        CHECK(monotone_after_peak, "behavior change must decay monotonically past its peak");
        CHECK(d_prev < 0.05f * d_peak, "behavior change must fade (residual %g of peak %g)", d_prev, d_peak);
        CHECK(llama_robot_memory_count(ctx) == 1, "the memory itself persists — only its influence fades");

        // forgetting zeroes recall immediately
        llama_robot_memory_forget(ctx);
        CHECK(llama_robot_memory_count(ctx) == 0, "forget empties the store");
        llama_robot_memory_recall(ctx, recall);
        CHECK(recall[0] == 0.0f, "forget zeroes recall");

        llama_free(ctx);
        llama_model_free(model);
    }

    // ---- checkpoint/restore carries the store; eviction is capacity-bounded ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-mem.gguf").c_str(), mp);
        llama_context * ctx = make_ctx(model);

        const auto baseline = step(model, ctx);
        CHECK(llama_robot_memory_write(ctx, 1.0f), "write");
        (void) step(model, ctx); // onset
        const auto primed = step(model, ctx);
        CHECK(vec_diff(primed, baseline) > 0.0f, "primed decode differs");

        // checkpoint the primed mind (m + banks + store + recall)
        const size_t sz = llama_robot_session_size(ctx);
        std::vector<uint8_t> blob(sz);
        CHECK(llama_robot_session_save(ctx, blob.data(), sz) == sz, "session save (v2)");

        // wipe and confirm the influence is gone, then restore and confirm it's back
        llama_robot_memory_forget(ctx);
        float zero_m[4] = { 0, 0, 0, 0 };
        llama_robot_mod_set(ctx, zero_m);
        const auto wiped = step(model, ctx);
        CHECK(llama_robot_session_load(ctx, blob.data(), sz) == sz, "session load (v2)");
        CHECK(llama_robot_memory_count(ctx) == 1, "restored store");
        const auto restored = step(model, ctx);
        printf("checkpoint: |restored - primed-continuation| = %g (wiped |diff| = %g)\n",
                vec_diff(restored, primed), vec_diff(wiped, baseline));
        CHECK(vec_diff(restored, wiped) > 0.0f, "restored mind must differ from the wiped one");

        // capacity 4: five writes must evict down to capacity, not grow
        for (int i = 0; i < 5; ++i) {
            step(model, ctx);
            CHECK(llama_robot_memory_write(ctx, 1.0f + i), "write %d", i);
        }
        CHECK(llama_robot_memory_count(ctx) == 4, "store is capacity-bounded (got %d)", llama_robot_memory_count(ctx));

        llama_free(ctx);
        llama_model_free(model);
    }

    // ---- salience-gated auto-writes (surprise + ‖m‖, quantile threshold) ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-mem-auto.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2-mem-auto load");
        llama_context * ctx = make_ctx(model);

        // warmup window: no writes during the first decodes
        for (int i = 0; i < 4; ++i) {
            step(model, ctx);
        }
        CHECK(llama_robot_memory_count(ctx) == 0, "no auto-writes during warmup");

        // after warmup, positive salience ≥ running median must start writing,
        // and the store must stay capacity-bounded
        for (int i = 0; i < 20; ++i) {
            step(model, ctx, (llama_token) (5 + (i % 3)));
        }
        const int n = llama_robot_memory_count(ctx);
        printf("auto-writes: %d stored after 24 decodes (capacity 4)\n", n);
        CHECK(n > 0, "salience gate must open after warmup");
        CHECK(n <= 4, "auto-writes respect capacity");

        llama_free(ctx);
        llama_model_free(model);
    }

    if (failures) { printf("E5 MEMORY TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E5 MEMORY TEST: OK\n");
    return 0;
}
