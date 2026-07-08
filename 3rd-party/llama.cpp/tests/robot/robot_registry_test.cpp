// E8 accretion serving test (S6 DoD): 10 admitted modules hot-loaded and
// routed per-request without context teardown; dependency auto-include and
// conflict resolution honored; the zero-forgetting invariant (005 test 2) —
// routing to nothing restores core-path outputs bit-identical to a
// never-routed context; memory traces export for the consolidation pipeline.
#include "llama.h"
#include "llama-robot.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <sstream>
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

struct run_result {
    std::vector<float> logits;
    float tap0[8];
};

static run_result step(llama_model * model, llama_context * ctx) {
    llama_memory_clear(llama_get_memory(ctx), true);
    llama_token t = 5;
    llama_batch batch = llama_batch_get_one(&t, 1);
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
    run_result r;
    const int n_vocab = llama_vocab_n_tokens(llama_model_get_vocab(model));
    const float * lg = llama_get_logits(ctx);
    r.logits.assign(lg, lg + n_vocab);
    if (!llama_robot_tap_read(ctx, 0, r.tap0)) { fprintf(stderr, "tap read failed\n"); exit(1); }
    return r;
}

static float tap_shift(const run_result & r, const run_result & base) {
    // shims in these fixtures steer every slice channel equally
    return r.tap0[0] - base.tap0[0];
}

static float logit_diff(const run_result & a, const run_result & b) {
    float d = 0.0f;
    for (size_t i = 0; i < a.logits.size(); ++i) {
        d = std::fmax(d, std::fabs(a.logits[i] - b.logits[i]));
    }
    return d;
}

int main(int argc, char ** argv) {
    if (argc != 2) { fprintf(stderr, "usage: %s <fixture-dir>\n", argv[0]); return 1; }
    const std::string dir = argv[1];

    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file((dir + "/tiny-llama-taps.gguf").c_str(), mp);
    CHECK(model != nullptr, "model load");
    if (!model) { return 1; }

    llama_robot_registry * reg = llama_robot_registry_load(model, (dir + "/registry/registry.json").c_str());
    CHECK(reg != nullptr, "registry load");
    if (!reg) { return 1; }
    CHECK(llama_robot_registry_count(reg) == 10, "10 admitted modules (got %d)", llama_robot_registry_count(reg));
    CHECK(strcmp(llama_robot_registry_name(reg, 8), "r8") == 0, "registry names");
    CHECK(std::fabs(llama_robot_registry_selectivity(reg, 9) - 0.99f) < 1e-6f, "admission scores surfaced");

    llama_context * ctx = make_ctx(model);
    const auto base = step(model, ctx); // never routed

    // ---- per-request routing on one resident context ----
    {
        const char * tags[] = { "alpha" };
        CHECK(llama_robot_route(ctx, reg, tags, 1) == 4, "route(alpha) attaches r0-r3");
        const auto r = step(model, ctx);
        printf("route(alpha): tap shift %+g (expect +10)\n", tap_shift(r, base));
        CHECK(std::fabs(tap_shift(r, base) - (1 + 2 + 3 + 4)) < 1e-3f, "alpha steer sum");
    }
    {
        const char * tags[] = { "beta" };
        CHECK(llama_robot_route(ctx, reg, tags, 1) == 4, "hot-swap to beta (r4-r7)");
        const auto r = step(model, ctx);
        printf("route(beta):  tap shift %+g (expect +26)\n", tap_shift(r, base));
        CHECK(std::fabs(tap_shift(r, base) - (5 + 6 + 7 + 8)) < 1e-3f, "beta steer sum after hot-swap");
    }

    // ---- dependency auto-include + conflict resolution ----
    {
        const char * tags[] = { "gamma" };
        // gamma tags r8 (depends r0 → auto-included) and r9 (conflicts r8 → skipped)
        CHECK(llama_robot_route(ctx, reg, tags, 1) == 2, "route(gamma) = r8 + auto-dep r0");
        const auto r = step(model, ctx);
        CHECK(std::fabs(tap_shift(r, base) - (9 + 1)) < 1e-3f, "gamma effect = r8 + r0 (r9 conflicted out)");
    }
    {
        const char * tags[] = { "solo" };
        CHECK(llama_robot_route(ctx, reg, tags, 1) == 1, "route(solo) attaches r9 alone");
        const auto r = step(model, ctx);
        CHECK(std::fabs(tap_shift(r, base) - 10) < 1e-3f, "r9 attaches fine when r8 is not selected");
    }

    // ---- all 10 modules hot-loaded and routed across requests (S6 DoD) ----
    {
        const char * tags[] = { "alpha", "beta", "gamma" };
        // r0-r8 selected (r9 conflicts with r8) → 9 resident at once
        CHECK(llama_robot_route(ctx, reg, tags, 3) == 9, "wide route keeps 9 non-conflicting modules");
        const auto r = step(model, ctx);
        const float expect = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9;
        printf("route(all):   tap shift %+g (expect %+g), 9 resident, 10 loaded overall\n",
                tap_shift(r, base), expect);
        CHECK(std::fabs(tap_shift(r, base) - expect) < 1e-3f, "stacked steer sum across 9 modules");
        CHECK(llama_robot_shim_count(ctx) == 9, "attached count");
    }

    // ---- zero-forgetting (005 test 2): route(none) ≡ never routed ----
    {
        CHECK(llama_robot_route(ctx, reg, nullptr, 0) == 0, "route(none) detaches everything");
        const auto r = step(model, ctx);
        printf("zero-forgetting: max |logit diff| vs never-routed = %g\n", logit_diff(r, base));
        CHECK(logit_diff(r, base) == 0.0f, "core-path outputs must be bit-identical with routing off");
        CHECK(memcmp(r.tap0, base.tap0, sizeof(r.tap0)) == 0, "taps bit-identical too");
    }

    llama_free(ctx);
    llama_robot_registry_free(reg);
    llama_model_free(model);

    // ---- memory trace export (consolidation raw material) ----
    {
        llama_model * mem_model = llama_model_load_from_file((dir + "/tiny-llama-l2-mem.gguf").c_str(), mp);
        CHECK(mem_model != nullptr, "l2-mem load");
        llama_context * mem_ctx = make_ctx(mem_model);
        llama_token t = 5;
        llama_batch batch = llama_batch_get_one(&t, 1);
        CHECK(llama_decode(mem_ctx, batch) == 0, "decode");
        CHECK(llama_robot_memory_write(mem_ctx, 1.5f), "memory write");

        const std::string trace = "/tmp/robot-trace.json";
        CHECK(llama_robot_memory_export(mem_ctx, trace.c_str()), "memory export");

        std::ifstream f(trace);
        std::stringstream ss;
        ss << f.rdbuf();
        const std::string body = ss.str();
        CHECK(body.find("\"memories\"") != std::string::npos, "trace has memories");
        CHECK(body.find("\"salience\": 1.5") != std::string::npos, "trace carries salience");
        CHECK(body.find("\"model\"") != std::string::npos, "trace carries provenance");

        llama_free(mem_ctx);
        llama_model_free(mem_model);
    }

    if (failures) { printf("E8 REGISTRY TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E8 REGISTRY TEST: OK\n");
    return 0;
}
