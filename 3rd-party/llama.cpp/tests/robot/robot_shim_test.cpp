// E3 shim test: slice-scoped edits change the bottleneck (and downstream
// logits) exactly as declared, gates toggle the edit in-graph, detaching
// restores bit-exact parity, and registry metadata (depends/conflicts) is
// enforced at attach/detach.
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

struct run_result {
    std::vector<float> logits;
    float tap0[8];
};

// fresh context each run so KV state never leaks between scenarios
static run_result run(llama_model * model, const std::vector<const llama_robot_shim *> & shims,
        bool detach_before_decode = false) {
    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 64;
    cp.n_batch = 8;
    llama_context * ctx = llama_init_from_model(model, cp);
    if (!ctx) { fprintf(stderr, "context init failed\n"); exit(1); }

    for (const auto * s : shims) {
        if (!llama_robot_shim_attach(ctx, s)) { fprintf(stderr, "attach failed\n"); exit(1); }
    }
    if (detach_before_decode) {
        for (const auto * s : shims) {
            llama_robot_shim_detach(ctx, llama_robot_shim_name(s));
        }
    }

    std::vector<llama_token> toks = { 1, 5, 9, 17, 3 };
    llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }

    run_result r;
    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int n_vocab = llama_vocab_n_tokens(vocab);
    const float * logits = llama_get_logits(ctx);
    r.logits.assign(logits, logits + n_vocab);
    if (!llama_robot_tap_read(ctx, 0, r.tap0)) { fprintf(stderr, "tap_read failed\n"); exit(1); }

    llama_free(ctx);
    return r;
}

static float max_logit_diff(const run_result & a, const run_result & b) {
    float d = 0.0f;
    for (size_t i = 0; i < a.logits.size(); ++i) {
        d = std::fmax(d, std::fabs(a.logits[i] - b.logits[i]));
    }
    return d;
}

int main(int argc, char ** argv) {
    if (argc != 3) { fprintf(stderr, "usage: %s <taps.gguf> <shim-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[2];

    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file(argv[1], mp);
    CHECK(model != nullptr, "model load");
    if (!model) { return 1; }

    auto * sh_steer    = llama_robot_shim_init(model, (dir + "/shim-steer-up.gguf").c_str());
    auto * sh_gated_on  = llama_robot_shim_init(model, (dir + "/shim-gated-on.gguf").c_str());
    auto * sh_gated_off = llama_robot_shim_init(model, (dir + "/shim-gated-off.gguf").c_str());
    auto * sh_dep      = llama_robot_shim_init(model, (dir + "/shim-dependent.gguf").c_str());
    auto * sh_conf     = llama_robot_shim_init(model, (dir + "/shim-conflicting.gguf").c_str());
    CHECK(sh_steer && sh_gated_on && sh_gated_off && sh_dep && sh_conf, "shim loads");
    if (failures) { return 1; }
    CHECK(strcmp(llama_robot_shim_target(sh_steer), "subject") == 0, "shim target metadata");
    CHECK(llama_robot_shim_selectivity(sh_steer) > 0.98f, "shim selectivity metadata");

    const auto base = run(model, {});

    // steer shim: tap must read exactly base + 1, logits must move downstream
    {
        const auto r = run(model, { sh_steer });
        float td = 0.0f;
        for (int k = 0; k < 8; ++k) {
            td = std::fmax(td, std::fabs(r.tap0[k] - (base.tap0[k] + 1.0f)));
        }
        printf("steer shim: max |tap - (base + 1)| = %g, logit shift = %g\n", td, max_logit_diff(r, base));
        CHECK(td == 0.0f, "tap must read the post-shim slice exactly");
        CHECK(max_logit_diff(r, base) > 0.0f, "slice edit must propagate downstream");
    }

    // attach-then-detach before decode: bit-exact parity with baseline
    {
        const auto r = run(model, { sh_steer }, /*detach_before_decode =*/ true);
        printf("detach parity: max |logit diff| = %g\n", max_logit_diff(r, base));
        CHECK(max_logit_diff(r, base) == 0.0f, "detached shim must leave no trace");
    }

    // gated shims: firing gate doubles the slice, non-firing gate is a no-op
    {
        const auto on  = run(model, { sh_gated_on });
        const auto off = run(model, { sh_gated_off });
        float td_on = 0.0f, td_off = 0.0f;
        for (int k = 0; k < 8; ++k) {
            td_on  = std::fmax(td_on,  std::fabs(on.tap0[k] - 2.0f*base.tap0[k]));
            td_off = std::fmax(td_off, std::fabs(off.tap0[k] - base.tap0[k]));
        }
        printf("gate on : max |tap - 2*base| = %g\n", td_on);
        printf("gate off: max |tap - base|   = %g (logit diff %g)\n", td_off, max_logit_diff(off, base));
        CHECK(td_on == 0.0f, "firing gate must apply the gain edit");
        CHECK(td_off == 0.0f, "non-firing gate must be a no-op on the tap");
        CHECK(max_logit_diff(off, base) == 0.0f, "non-firing gate must be a no-op on logits");
        CHECK(max_logit_diff(on, base) > 0.0f, "firing gate must move logits");
    }

    // shims stack in attach order: steer then gated-on → 2·(x + 1)
    {
        const auto r = run(model, { sh_steer, sh_gated_on });
        float td = 0.0f;
        for (int k = 0; k < 8; ++k) {
            td = std::fmax(td, std::fabs(r.tap0[k] - 2.0f*(base.tap0[k] + 1.0f)));
        }
        printf("stacked shims: max |tap - 2*(base+1)| = %g\n", td);
        CHECK(td == 0.0f, "stacked shims must compose in attach order");
    }

    // hot attach/detach mid-session on one context: the epoch bump must defeat
    // graph reuse so the very next decode reflects the change
    {
        llama_context_params cp = llama_context_default_params();
        cp.n_ctx = 64;
        cp.n_batch = 8;
        llama_context * ctx = llama_init_from_model(model, cp);

        // clear the KV state before every step so each decode is identical
        // except for the attached shim set
        auto step = [&](llama_token t) {
            llama_memory_clear(llama_get_memory(ctx), true);
            llama_batch batch = llama_batch_get_one(&t, 1);
            CHECK(llama_decode(ctx, batch) == 0, "mid-session decode");
            float tap[8];
            CHECK(llama_robot_tap_read(ctx, 0, tap), "mid-session tap read");
            return tap[0];
        };

        (void) step(5);                        // warm up (graph built, reuse primed)
        const float before = step(5);          // reused graph, no shim
        CHECK(llama_robot_shim_attach(ctx, sh_steer), "mid-session attach");
        const float with_shim = step(5);       // must rebuild and include the edit
        CHECK(llama_robot_shim_detach(ctx, "steer-up"), "mid-session detach");
        const float after = step(5);           // must rebuild again without it

        printf("hot swap: tap[0] before=%g with=%g after=%g\n", before, with_shim, after);
        CHECK(with_shim == before + 1.0f, "attach must take effect on the next decode");
        CHECK(after == before, "detach must take effect on the next decode");
        llama_free(ctx);
    }

    // registry metadata enforcement
    {
        llama_context_params cp = llama_context_default_params();
        cp.n_ctx = 64;
        llama_context * ctx = llama_init_from_model(model, cp);

        CHECK(!llama_robot_shim_attach(ctx, sh_dep), "dependent shim must refuse without its dependency");
        CHECK(llama_robot_shim_attach(ctx, sh_steer), "attach steer-up");
        CHECK(llama_robot_shim_attach(ctx, sh_dep), "dependent shim attaches once dependency present");
        CHECK(!llama_robot_shim_attach(ctx, sh_conf), "conflicting shim must refuse");
        CHECK(!llama_robot_shim_detach(ctx, "steer-up"), "detach must refuse while depended on");
        CHECK(llama_robot_shim_detach(ctx, "dependent"), "detach dependent");
        CHECK(llama_robot_shim_detach(ctx, "steer-up"), "then detach steer-up");
        CHECK(llama_robot_shim_attach(ctx, sh_conf), "conflicting shim attaches once steer-up is gone");
        CHECK(llama_robot_shim_count(ctx) == 1, "attached count");
        CHECK(!llama_robot_shim_attach(ctx, sh_conf), "double attach must refuse");

        llama_free(ctx);
    }

    llama_robot_shim_free(sh_steer);
    llama_robot_shim_free(sh_gated_on);
    llama_robot_shim_free(sh_gated_off);
    llama_robot_shim_free(sh_dep);
    llama_robot_shim_free(sh_conf);
    llama_model_free(model);

    if (failures) { printf("E3 SHIM TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E3 SHIM TEST: OK\n");
    return 0;
}
