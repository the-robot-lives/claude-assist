// robot_demo — load a converted therobot model and exercise the extensions:
//   1. print the model's tap/probe manifest
//   2. generate text, printing the live probe reading at each token (E2)
//   3. attach a steering shim from the registry and regenerate (E3)
//   4. prime the modulator and show it decay (E4)
//
// Usage:
//   robot_demo <model.gguf> [registry.json] [prompt]
//
// This is a demonstration, not a product — it shows how the C API in
// include/llama-robot.h is used against a real converted model.
#include "llama.h"
#include "llama-robot.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static std::vector<llama_token> tokenize(const llama_vocab * vocab, const std::string & text, bool bos) {
    int n = -llama_tokenize(vocab, text.c_str(), (int) text.size(), nullptr, 0, bos, true);
    std::vector<llama_token> out(n);
    llama_tokenize(vocab, text.c_str(), (int) text.size(), out.data(), n, bos, true);
    return out;
}

static std::string piece(const llama_vocab * vocab, llama_token t) {
    char buf[256];
    int n = llama_token_to_piece(vocab, t, buf, sizeof(buf), 0, true);
    return std::string(buf, n > 0 ? n : 0);
}

static llama_token argmax(const float * logits, int n) {
    llama_token best = 0;
    for (int i = 1; i < n; ++i) if (logits[i] > logits[best]) best = i;
    return best;
}

// pretty-print a probe's argmax class + confidence for tap 0's first attribute
static void print_probe(llama_context * ctx, const llama_model * model, int32_t tap) {
    // the manifest doesn't expose attribute names per tap via a list API here,
    // so we try a small set of the v0 attribute names and report the first hit
    static const char * attrs[] = {"topic", "safety_salience", "register",
                                   "sentiment", "speech_act", "entity_presence"};
    for (const char * a : attrs) {
        int32_t dim = llama_robot_probe_dim(model, tap, a);
        if (dim <= 0) continue;
        std::vector<float> out(dim);
        if (!llama_robot_probe_eval(ctx, tap, a, out.data())) continue;
        int cls = 0; for (int i = 1; i < dim; ++i) if (out[i] > out[cls]) cls = i;
        printf("   [tap%d %s=class%d]", tap, a, cls);
        return;
    }
}

static void generate(llama_model * model, llama_context * ctx,
                     const std::vector<llama_token> & prompt, int n_gen,
                     bool show_probe) {
    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int n_vocab = llama_vocab_n_tokens(vocab);

    llama_memory_clear(llama_get_memory(ctx), true);
    std::vector<llama_token> toks = prompt;
    llama_batch batch = llama_batch_get_one(toks.data(), (int) toks.size());
    if (llama_decode(ctx, batch)) { fprintf(stderr, "decode failed\n"); return; }

    for (int i = 0; i < n_gen; ++i) {
        llama_token next = argmax(llama_get_logits_ith(ctx, -1), n_vocab);
        if (llama_vocab_is_eog(vocab, next)) break;
        fputs(piece(vocab, next).c_str(), stdout);
        if (show_probe && llama_robot_tap_count(model) > 0) print_probe(ctx, model, 0);
        fflush(stdout);
        llama_batch b = llama_batch_get_one(&next, 1);
        if (llama_decode(ctx, b)) break;
    }
    printf("\n");
}

int main(int argc, char ** argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s <model.gguf> [registry.json] [prompt]\n", argv[0]); return 1; }
    const char * model_path = argv[1];
    const char * reg_path   = argc > 2 ? argv[2] : nullptr;
    std::string prompt      = argc > 3 ? argv[3] : "The best way to write fast software is";

    llama_backend_init();
    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file(model_path, mp);
    if (!model) { fprintf(stderr, "failed to load %s\n", model_path); return 1; }

    printf("=== therobot manifest ===\n");
    printf("robot-enabled : %s\n", llama_robot_enabled(model) ? "yes" : "no");
    printf("taps          : %d\n", llama_robot_tap_count(model));
    for (int32_t t = 0; t < llama_robot_tap_count(model); ++t) {
        printf("  tap %d: %-12s layer %d point %s width %d\n", t,
               llama_robot_tap_name(model, t), llama_robot_tap_layer(model, t),
               llama_robot_tap_point(model, t), llama_robot_tap_width(model, t));
    }
    printf("modulator dim : %d\n", llama_robot_mod_dim(model));

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 512;
    cp.n_batch = 512;
    llama_context * ctx = llama_init_from_model(model, cp);
    const llama_vocab * vocab = llama_model_get_vocab(model);
    auto prompt_toks = tokenize(vocab, prompt, true);

    printf("\n=== 1. baseline generation (live probe readings) ===\n%s", prompt.c_str());
    generate(model, ctx, prompt_toks, 48, /*show_probe=*/true);

    // 2. steering via a routed shim
    if (reg_path) {
        llama_robot_registry * reg = llama_robot_registry_load(model, reg_path);
        if (reg) {
            printf("\n=== 2. steered generation (route topic) ===\n");
            const char * tags[] = { "topic" };
            int n = llama_robot_route(ctx, reg, tags, 1);
            printf("(routed %d shim module[s] tagged 'topic')\n%s", n, prompt.c_str());
            generate(model, ctx, prompt_toks, 48, /*show_probe=*/false);
            llama_robot_route(ctx, reg, nullptr, 0); // detach
            llama_robot_registry_free(reg);
        }
    }

    // 3. priming the modulator
    if (llama_robot_mod_dim(model) > 0) {
        printf("\n=== 3. primed generation (arousal high) ===\n");
        std::vector<float> m(llama_robot_mod_dim(model), 0.0f);
        m[0] = 5.0f; // channel 0 = arousal in the qwen3.5 config
        llama_robot_mod_set(ctx, m.data());
        printf("%s", prompt.c_str());
        generate(model, ctx, prompt_toks, 48, /*show_probe=*/false);
        llama_robot_mod_get(ctx, m.data());
        printf("(arousal after generation: %.3f — decayed from 5.0)\n", m[0]);
    }

    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    return 0;
}
