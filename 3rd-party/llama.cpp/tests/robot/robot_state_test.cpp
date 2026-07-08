// E4 state + modulator test: zero grafts are function-preserving (L0 parity),
// m primes behavior and relaxes by per-channel decay (planning M3), the leaky
// state carries across decodes, sessions checkpoint/restore exactly, and
// modulator-gated shims toggle on m.
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

// clear KV and decode one fixed token: identical inputs each call, so outputs
// differ only through the persistent robot state (m, banks) and shims
static std::vector<float> step(llama_model * model, llama_context * ctx, float * tap0 = nullptr) {
    llama_memory_clear(llama_get_memory(ctx), true);
    llama_token t = 5;
    llama_batch batch = llama_batch_get_one(&t, 1);
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
    const int n_vocab = llama_vocab_n_tokens(llama_model_get_vocab(model));
    const float * logits = llama_get_logits(ctx);
    if (tap0 != nullptr) {
        if (!llama_robot_tap_read(ctx, 0, tap0)) { fprintf(stderr, "tap read failed\n"); exit(1); }
    }
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
    if (argc != 3) { fprintf(stderr, "usage: %s <stock.gguf> <fixture-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[2];

    llama_model_params mp = llama_model_default_params();

    // ---- zero grafts = donor parity (the function-preserving invariant) ----
    {
        llama_model * m_stock = llama_model_load_from_file(argv[1], mp);
        llama_model * m_l2    = llama_model_load_from_file((dir + "/tiny-llama-l2.gguf").c_str(), mp);
        CHECK(m_stock && m_l2, "model loads");
        if (!m_stock || !m_l2) { return 1; }

        llama_context * c1 = make_ctx(m_stock);
        llama_context * c2 = make_ctx(m_l2);
        const auto l1 = step(m_stock, c1);
        const auto l2 = step(m_l2, c2);
        printf("zero-graft parity: max |logit diff| = %g\n", vec_diff(l1, l2));
        CHECK(vec_diff(l1, l2) == 0.0f, "zeroed grafts must reproduce donor logits");

        // and it must hold on the second decode too (state/m updated in between)
        const auto l1b = step(m_stock, c1);
        const auto l2b = step(m_l2, c2);
        CHECK(vec_diff(l1b, l2b) == 0.0f, "zero-graft parity must persist across decodes");

        llama_free(c1); llama_free(c2);
        llama_model_free(m_stock); llama_model_free(m_l2);
    }

    // ---- priming: induce a bias via m, watch it relax (planning M3) ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-film.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2-film load");
        if (!model) { return 1; }

        CHECK(llama_robot_mod_dim(model) == 4, "mod dim");
        CHECK(strcmp(llama_robot_mod_channel(model, 0), "arousal") == 0, "mod channel name");

        llama_context * ctx = make_ctx(model);
        const auto baseline = step(model, ctx);

        float m0[4] = { 0, 0, 0, 0 };
        CHECK(llama_robot_mod_get(ctx, m0), "mod_get");
        CHECK(m0[0] == 0.0f, "m starts at baseline 0");

        // induce: arousal = 5 → β = 5 at layer 0 → downstream shift
        float prime[4] = { 5.0f, 0, 0, 0 };
        CHECK(llama_robot_mod_set(ctx, prime), "mod_set");
        const auto primed = step(model, ctx);
        const float d0 = vec_diff(primed, baseline);
        CHECK(d0 > 0.0f, "priming must shift logits");

        // relax: α_m = σ(0) = 0.5 → m halves each decode; bias decays toward 0
        float md[4];
        CHECK(llama_robot_mod_get(ctx, md), "mod_get after decode");
        CHECK(std::fabs(md[0] - 2.5f) < 1e-5f, "m must decay 5 → 2.5 (got %g)", md[0]);

        // the fixture donor's activations are tiny (~0.02), so logit response
        // to β stays visible down to very small m — give the exponential decay
        // enough halvings to pass well below it
        float d_prev = d0;
        for (int i = 0; i < 26; ++i) {
            const auto cur = step(model, ctx);
            const float d = vec_diff(cur, baseline);
            CHECK(d <= d_prev + 1e-6f, "bias must relax monotonically (step %d: %g > %g)", i, d, d_prev);
            d_prev = d;
        }
        printf("priming: shift %g → %g after relaxation\n", d0, d_prev);
        CHECK(d_prev < 1e-3f, "bias must relax back to baseline (residual %g)", d_prev);

        llama_free(ctx);
        llama_model_free(model);
    }

    // ---- leaky state: carries across decodes; session checkpoint/restore ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-state.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2-state load");
        if (!model) { return 1; }

        llama_context * ctx = make_ctx(model);

        const auto s1 = step(model, ctx);
        // checkpoint the mind after step 1
        const size_t sz = llama_robot_session_size(ctx);
        CHECK(sz > 0, "session size");
        std::vector<uint8_t> blob(sz);
        CHECK(llama_robot_session_save(ctx, blob.data(), blob.size()) == sz, "session save");
        CHECK(llama_robot_session_save(ctx, blob.data(), 3) == 0, "undersized save buffer must fail");

        const auto s2 = step(model, ctx);
        CHECK(vec_diff(s1, s2) > 0.0f, "identical inputs must diverge through carried state");

        const auto s3 = step(model, ctx);
        CHECK(vec_diff(s2, s3) > 0.0f, "state keeps evolving");

        // rollback: restoring the checkpoint must reproduce step 2 exactly
        CHECK(llama_robot_session_load(ctx, blob.data(), blob.size()) == sz, "session load");
        const auto s2r = step(model, ctx);
        printf("state: step1→2 diff %g; rollback reproduces step2: max diff %g\n",
                vec_diff(s1, s2), vec_diff(s2, s2r));
        CHECK(vec_diff(s2, s2r) == 0.0f, "restored session must replay exactly");

        // malformed blob must be rejected without corrupting the state
        std::vector<uint8_t> bad(blob);
        bad[0] ^= 0xff;
        CHECK(llama_robot_session_load(ctx, bad.data(), bad.size()) == 0, "bad magic must fail");

        llama_free(ctx);
        llama_model_free(model);
    }

    // ---- modulator-gated shim: fires while m[arousal] > 2, then shuts off ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2 load for gated shim");
        if (!model) { return 1; }

        llama_robot_shim * shim = llama_robot_shim_init(model, (dir + "/shim-mod-gated.gguf").c_str());
        CHECK(shim != nullptr, "modulator-gated shim load");
        if (!shim) { return 1; }

        llama_context * ctx = make_ctx(model);
        float tap_base[8], tap_hi[8], tap_lo[8];
        step(model, ctx, tap_base); // no shim attached

        CHECK(llama_robot_shim_attach(ctx, shim), "attach mod-gated shim");

        float hi[4] = { 5.0f, 0, 0, 0 };
        llama_robot_mod_set(ctx, hi);
        step(model, ctx, tap_hi);

        float lo[4] = { 0.0f, 0, 0, 0 };
        llama_robot_mod_set(ctx, lo);
        step(model, ctx, tap_lo);

        float d_hi = 0.0f, d_lo = 0.0f;
        for (int k = 0; k < 8; ++k) {
            d_hi = std::fmax(d_hi, std::fabs(tap_hi[k] - (tap_base[k] + 1.0f)));
            d_lo = std::fmax(d_lo, std::fabs(tap_lo[k] - tap_base[k]));
        }
        printf("mod gate: |tap(hi) - (base+1)| = %g, |tap(lo) - base| = %g\n", d_hi, d_lo);
        CHECK(d_hi == 0.0f, "gate must fire while m[arousal] > 2");
        CHECK(d_lo == 0.0f, "gate must shut off at baseline m");

        llama_free(ctx);
        llama_robot_shim_free(shim);
        llama_model_free(model);
    }

    // ---- session reset clears the arrow of time (live leaky state) ----
    {
        llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-l2-state.gguf").c_str(), mp);
        CHECK(model != nullptr, "l2-state load for reset");
        if (!model) { return 1; }

        llama_context * ctx = make_ctx(model);
        const auto fresh = step(model, ctx);   // first decode from a clean session

        // evolve the leaky state and prime m so both diverge from baseline
        for (int i = 0; i < 5; ++i) { step(model, ctx); }
        float prime[4] = { 4.0f, 1.0f, 0, 0 };
        llama_robot_mod_set(ctx, prime);
        const auto evolved = step(model, ctx);
        CHECK(vec_diff(evolved, fresh) > 0.0f, "state/m must have drifted from the fresh baseline");

        // reset the arrow of time; m and banks must read back as baseline
        llama_robot_session_reset(ctx, /*forget_memory =*/ false);
        float m_after[4];
        CHECK(llama_robot_mod_get(ctx, m_after), "mod_get after reset");
        CHECK(m_after[0] == 0.0f && m_after[1] == 0.0f, "reset zeroes the modulator");

        // and a decode after reset must reproduce the fresh-session decode exactly
        const auto after = step(model, ctx);
        printf("reset: |evolved - fresh| = %g; |after-reset - fresh| = %g\n",
                vec_diff(evolved, fresh), vec_diff(after, fresh));
        CHECK(vec_diff(after, fresh) == 0.0f, "post-reset decode must equal a fresh session");

        llama_free(ctx);
        llama_model_free(model);
    }

    if (failures) { printf("E4 STATE TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E4 STATE TEST: OK\n");
    return 0;
}
