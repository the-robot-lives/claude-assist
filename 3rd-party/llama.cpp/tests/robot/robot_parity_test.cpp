// L0 parity gate: a therobot passthrough file must produce logits identical
// (<= 1e-4) to its stock donor twin on the same weights.
#include "llama.h"

#include <cmath>
#include <cstdio>
#include <vector>

static std::vector<float> eval_logits(const char * path, int & n_vocab_out) {
    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file(path, mp);
    if (!model) { fprintf(stderr, "failed to load %s\n", path); exit(1); }

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 64;
    cp.n_batch = 8;
    llama_context * ctx = llama_init_from_model(model, cp);
    if (!ctx) { fprintf(stderr, "failed to create context for %s\n", path); exit(1); }

    std::vector<llama_token> toks = { 1, 5, 9, 17, 3 };
    llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed for %s\n", path); exit(1); }

    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int n_vocab = llama_vocab_n_tokens(vocab);
    n_vocab_out = n_vocab;

    const float * logits = llama_get_logits(ctx);
    std::vector<float> out(logits, logits + n_vocab);

    llama_free(ctx);
    llama_model_free(model);
    return out;
}

int main(int argc, char ** argv) {
    if (argc != 3) { fprintf(stderr, "usage: %s <stock.gguf> <therobot.gguf>\n", argv[0]); return 1; }
    int nv1 = 0, nv2 = 0;
    const auto a = eval_logits(argv[1], nv1);
    const auto b = eval_logits(argv[2], nv2);
    if (nv1 != nv2) { fprintf(stderr, "vocab mismatch\n"); return 1; }
    float max_diff = 0.0f;
    for (int i = 0; i < nv1; ++i) {
        max_diff = std::fmax(max_diff, std::fabs(a[i] - b[i]));
    }
    printf("max |logit diff| = %g over %d logits\n", max_diff, nv1);
    if (max_diff > 1e-4f) { printf("PARITY FAIL\n"); return 1; }
    printf("PARITY OK\n");
    return 0;
}
