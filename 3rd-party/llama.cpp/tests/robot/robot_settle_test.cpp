// E7 settle test: the jacobi-ar canvas loop converges to exactly the greedy
// autoregressive output, rounds-to-settle track difficulty (004 test 2
// flavor: longer canvases need ≥ rounds), the m-schedule adds exactly its
// declared re-check rounds, and taps stay readable across settling.
#include "llama.h"
#include "llama-robot.h"

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
    cp.n_batch = 32;
    llama_context * ctx = llama_init_from_model(model, cp);
    if (!ctx) { fprintf(stderr, "context init failed\n"); exit(1); }
    return ctx;
}

// greedy autoregressive reference
static std::vector<llama_token> greedy(llama_model * model, llama_context * ctx,
        const std::vector<llama_token> & prompt, int32_t n_out) {
    llama_memory_clear(llama_get_memory(ctx), true);
    const int n_vocab = llama_vocab_n_tokens(llama_model_get_vocab(model));

    std::vector<llama_token> toks = prompt;
    llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }

    std::vector<llama_token> out;
    for (int32_t i = 0; i < n_out; ++i) {
        const float * lg = llama_get_logits(ctx);
        llama_token best = 0;
        for (int v = 1; v < n_vocab; ++v) {
            if (lg[v] > lg[best]) { best = v; }
        }
        out.push_back(best);
        llama_batch step = llama_batch_get_one(&best, 1);
        if (llama_decode(ctx, step) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
    }
    return out;
}

int main(int argc, char ** argv) {
    if (argc != 2) { fprintf(stderr, "usage: %s <fixture-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[1];

    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-settle.gguf").c_str(), mp);
    CHECK(model != nullptr, "settle fixture load");
    if (!model) { return 1; }

    const std::vector<llama_token> prompt = { 1, 5, 9, 17 };

    // ---- fixed point equals greedy AR, exactly ----
    int32_t steps8 = 0;
    {
        llama_context * ctx = make_ctx(model);
        const auto ref = greedy(model, ctx, prompt, 8);

        llama_token out[8] = { 0 };
        const int32_t n = llama_robot_settle(ctx, prompt.data(), (int32_t) prompt.size(), out, 8, &steps8);
        CHECK(n == 8, "settle returns the full canvas (got %d)", n);

        bool equal = true;
        for (int i = 0; i < 8; ++i) {
            equal &= (out[i] == ref[i]);
        }
        printf("jacobi-ar fixed point: %s greedy AR, settled in %d round(s)\n",
                equal ? "==" : "!=", steps8);
        CHECK(equal, "settled canvas must equal the greedy AR output");
        CHECK(steps8 >= 1 && steps8 <= 9, "rounds bounded by canvas length + 1 (got %d)", steps8);

        // taps stay readable across settling (the canvas is molten but tapped)
        float tap[8];
        CHECK(llama_robot_tap_read(ctx, 0, tap), "tap readable mid-/post-settle");

        llama_free(ctx);
    }

    // ---- rounds track difficulty: a longer canvas needs at least as many ----
    {
        llama_context * ctx = make_ctx(model);
        llama_token out[2];
        int32_t steps2 = 0;
        CHECK(llama_robot_settle(ctx, prompt.data(), (int32_t) prompt.size(), out, 2, &steps2) == 2, "settle n=2");
        printf("difficulty proxy: 2 tokens → %d round(s), 8 tokens → %d round(s)\n", steps2, steps8);
        CHECK(steps2 <= steps8, "shorter canvases must not need more rounds");

        // and the short answer must also match greedy
        const auto ref = greedy(model, ctx, prompt, 2);
        CHECK(out[0] == ref[0] && out[1] == ref[1], "short canvas matches greedy too");
        llama_free(ctx);
    }

    // ---- m-scheduled settling depth: anxious → exactly the scheduled extra rounds ----
    {
        // schedule [0, 1, 2, 4]: arousal 0 → +0 re-checks, arousal 3 → +4
        llama_context * ctx = make_ctx(model);
        llama_token out[8];
        int32_t steps_calm = 0;
        llama_robot_settle(ctx, prompt.data(), (int32_t) prompt.size(), out, 8, &steps_calm);

        float anxious[4] = { 3.0f, 0, 0, 0 };
        CHECK(llama_robot_mod_set(ctx, anxious), "prime arousal");
        int32_t steps_anxious = 0;
        llama_robot_settle(ctx, prompt.data(), (int32_t) prompt.size(), out, 8, &steps_anxious);

        printf("m-scheduled depth: calm %d round(s), anxious %d round(s)\n", steps_calm, steps_anxious);
        CHECK(steps_anxious == steps_calm + 4, "arousal 3 must add exactly its 4 scheduled re-check rounds");

        // re-check rounds are no-ops at the fixed point: output unchanged
        const auto ref = greedy(model, ctx, prompt, 8);
        bool equal = true;
        for (int i = 0; i < 8; ++i) {
            equal &= (out[i] == ref[i]);
        }
        CHECK(equal, "extra re-check rounds must not disturb the settled canvas");
        llama_free(ctx);
    }

    // ---- argument errors ----
    {
        llama_context * ctx = make_ctx(model);
        llama_token out[4];
        int32_t steps = -1;
        CHECK(llama_robot_settle(ctx, nullptr, 4, out, 4, nullptr) == -1, "null prompt rejected");
        CHECK(llama_robot_settle(ctx, prompt.data(), (int32_t) prompt.size(), out, 0, &steps) == 0 && steps == 0,
                "zero-length canvas is a no-op");
        llama_free(ctx);
    }

    llama_model_free(model);

    if (failures) { printf("E7 SETTLE TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E7 SETTLE TEST: OK\n");
    return 0;
}
