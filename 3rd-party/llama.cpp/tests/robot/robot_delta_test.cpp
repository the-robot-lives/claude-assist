// E6 delta executor test: off by default; always-firing delta matches dense;
// with high thresholds the fire schedule is exactly the heartbeat and the
// compute trace records it; heartbeats bound divergence; the modulator's
// excitability lowers effective thresholds (the 002 priming coupling).
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

// continuous stream (no KV clearing): decode each token, collect logits rows
static std::vector<std::vector<float>> stream(llama_model * model, llama_context * ctx,
        const std::vector<llama_token> & toks) {
    const int n_vocab = llama_vocab_n_tokens(llama_model_get_vocab(model));
    std::vector<std::vector<float>> out;
    for (llama_token t : toks) {
        llama_batch batch = llama_batch_get_one(&t, 1);
        if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
        const float * logits = llama_get_logits(ctx);
        out.emplace_back(logits, logits + n_vocab);
    }
    return out;
}

static float stream_diff(const std::vector<std::vector<float>> & a, const std::vector<std::vector<float>> & b) {
    float d = 0.0f;
    for (size_t i = 0; i < a.size(); ++i) {
        for (size_t j = 0; j < a[i].size(); ++j) {
            d = std::fmax(d, std::fabs(a[i][j] - b[i][j]));
        }
    }
    return d;
}

static const std::vector<llama_token> TOKS = { 1, 5, 9, 17, 3, 7, 2, 11, 5, 13, 9, 4 };

int main(int argc, char ** argv) {
    if (argc != 2) { fprintf(stderr, "usage: %s <fixture-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[1];

    llama_model_params mp = llama_model_default_params();

    // ---- θ = 0: every block fires every token → matches dense ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-delta-lo.gguf").c_str(), mp);
        CHECK(model != nullptr, "delta-lo load");
        if (!model) { return 1; }
        CHECK(llama_robot_delta_block_count(model) == 2, "two covered blocks");

        llama_context * c_dense = make_ctx(model);
        CHECK(!llama_robot_delta_enabled(c_dense), "delta is OFF by default");
        const auto dense = stream(model, c_dense, TOKS);

        llama_context * c_delta = make_ctx(model);
        CHECK(llama_robot_delta_enable(c_delta, true), "enable delta");
        CHECK(llama_robot_delta_enabled(c_delta), "enabled flag");
        const auto lo = stream(model, c_delta, TOKS);

        const float d = stream_diff(dense, lo);
        printf("always-fire parity: max |logit diff| = %g over %zu tokens\n", d, TOKS.size());
        CHECK(d < 1e-4f, "always-firing delta must match dense (blend round-off only)");
        CHECK(llama_robot_delta_tokens(c_delta) == TOKS.size(), "trace counts every delta token");
        CHECK(llama_robot_delta_fires(c_delta, 0) == TOKS.size(), "block 0 fired every token");
        CHECK(llama_robot_delta_keep_rate(c_delta) == 1.0f, "keep rate 1.0 when everything fires");
        CHECK(llama_robot_delta_tokens(c_dense) == 0, "disabled context records no trace");

        llama_free(c_dense); llama_free(c_delta);
        llama_model_free(model);
    }

    // ---- θ huge: fire schedule is exactly the heartbeat; trace + keep rate ----
    float div_hb = 0.0f;
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-delta-hi.gguf").c_str(), mp);
        CHECK(model != nullptr, "delta-hi load");

        llama_context * c_dense = make_ctx(model);
        const auto dense = stream(model, c_dense, TOKS);

        llama_context * c_delta = make_ctx(model);
        llama_robot_delta_enable(c_delta, true);
        const auto sparse = stream(model, c_delta, TOKS);

        // heartbeat 4 over 12 tokens: dense sweeps at t0, t4, t8 → 3 fires/block
        CHECK(llama_robot_delta_fires(c_delta, 0) == 3, "block 0 fires exactly on heartbeats (got %llu)",
                (unsigned long long) llama_robot_delta_fires(c_delta, 0));
        CHECK(llama_robot_delta_fires(c_delta, 1) == 3, "block 1 fires exactly on heartbeats");
        const float kr = llama_robot_delta_keep_rate(c_delta);
        printf("heartbeat schedule: keep rate = %.3f (expect 0.25)\n", kr);
        CHECK(std::fabs(kr - 0.25f) < 1e-6f, "keep rate = 3/12");

        div_hb = stream_diff(dense, sparse);
        printf("divergence with heartbeat 4: %g\n", div_hb);
        CHECK(std::isfinite(div_hb), "divergence finite");
        CHECK(div_hb > 0.0f, "held outputs must actually diverge from dense");

        llama_free(c_dense); llama_free(c_delta);
        llama_model_free(model);
    }

    // ---- heartbeats bound divergence: no-heartbeat run drifts at least as far ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-delta-nohb.gguf").c_str(), mp);
        CHECK(model != nullptr, "delta-nohb load");

        llama_context * c_dense = make_ctx(model);
        const auto dense = stream(model, c_dense, TOKS);

        llama_context * c_delta = make_ctx(model);
        llama_robot_delta_enable(c_delta, true);
        const auto frozen = stream(model, c_delta, TOKS);

        CHECK(llama_robot_delta_fires(c_delta, 0) == 1, "without heartbeats only the init sweep fires");
        const float div_nohb = stream_diff(dense, frozen);
        printf("divergence without heartbeat: %g (with: %g)\n", div_nohb, div_hb);
        CHECK(std::isfinite(div_nohb), "divergence finite");
        CHECK(div_hb <= div_nohb + 1e-6f, "heartbeat sweeps must bound divergence");

        llama_free(c_dense); llama_free(c_delta);
        llama_model_free(model);
    }

    // ---- excitability: m[arousal] lowers θ_eff → extra fires outside the schedule ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-delta-hi.gguf").c_str(), mp);
        llama_context * ctx = make_ctx(model);
        llama_robot_delta_enable(ctx, true);

        (void) stream(model, ctx, { 1, 5, 9 }); // t0 forced, t1-2 quiet
        const uint64_t before = llama_robot_delta_fires(ctx, 0);
        CHECK(before == 1, "quiet before priming (got %llu)", (unsigned long long) before);

        float hi_m[4] = { 2.0f, 0, 0, 0 }; // excitability 1e6/unit vs θ = 1e6
        CHECK(llama_robot_mod_set(ctx, hi_m), "mod_set");
        (void) stream(model, ctx, { 17 }); // t3: θ_eff = 1e6 − 2e6 < 0 → fires
        const uint64_t after = llama_robot_delta_fires(ctx, 0);
        printf("excitability: fires %llu → %llu after priming m\n",
                (unsigned long long) before, (unsigned long long) after);
        CHECK(after == before + 1, "primed m must fire a block outside the heartbeat schedule");

        llama_free(ctx);
        llama_model_free(model);
    }

    // ---- prompt ubatches run dense and don't pollute the trace ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-delta-hi.gguf").c_str(), mp);
        llama_context * ctx = make_ctx(model);
        llama_robot_delta_enable(ctx, true);

        std::vector<llama_token> prompt = { 1, 5, 9, 17, 3 };
        llama_batch batch = llama_batch_get_one(prompt.data(), (int32_t) prompt.size());
        CHECK(llama_decode(ctx, batch) == 0, "prompt decode with delta enabled");
        CHECK(llama_robot_delta_tokens(ctx) == 0, "prompt (T>1) is dense — no delta trace");

        (void) stream(model, ctx, { 7 }); // first streaming token: forced dense sweep
        CHECK(llama_robot_delta_tokens(ctx) == 1 && llama_robot_delta_fires(ctx, 0) == 1,
                "streaming resumes with a dense sweep after a prompt");

        llama_free(ctx);
        llama_model_free(model);
    }

    if (failures) { printf("E6 DELTA TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E6 DELTA TEST: OK\n");
    return 0;
}
