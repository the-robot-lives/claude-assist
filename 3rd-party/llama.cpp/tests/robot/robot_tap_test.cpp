// E2 tap test: taps read back real slice values, probe heads evaluate on
// demand, and an L1 taps file stays logit-identical to its stock donor twin.
#include "llama.h"
#include "llama-robot.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

static int failures = 0;

#define CHECK(cond, ...) do { \
    if (!(cond)) { failures++; fprintf(stderr, "CHECK FAILED (%s:%d): ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } \
} while (0)

static std::vector<float> decode_and_logits(llama_model * model, llama_context * ctx) {
    std::vector<llama_token> toks = { 1, 5, 9, 17, 3 };
    llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
    if (llama_decode(ctx, batch) != 0) { fprintf(stderr, "decode failed\n"); exit(1); }
    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int n_vocab = llama_vocab_n_tokens(vocab);
    const float * logits = llama_get_logits(ctx);
    return std::vector<float>(logits, logits + n_vocab);
}

int main(int argc, char ** argv) {
    if (argc != 3) { fprintf(stderr, "usage: %s <stock.gguf> <taps.gguf>\n", argv[0]); return 1; }

    llama_model_params mp = llama_model_default_params();
    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 64;
    cp.n_batch = 8;

    // stock twin
    llama_model * m_stock = llama_model_load_from_file(argv[1], mp);
    CHECK(m_stock != nullptr, "stock model load");
    CHECK(!llama_robot_enabled(m_stock), "stock model must not be robot-enabled");
    llama_context * c_stock = llama_init_from_model(m_stock, cp);
    const auto logits_stock = decode_and_logits(m_stock, c_stock);

    // taps twin
    llama_model * m_taps = llama_model_load_from_file(argv[2], mp);
    CHECK(m_taps != nullptr, "taps model load");
    if (!m_taps) { return 1; }
    CHECK(llama_robot_enabled(m_taps), "taps model robot-enabled");
    CHECK(llama_robot_tap_count(m_taps) == 2, "tap count == 2 (got %d)", llama_robot_tap_count(m_taps));
    CHECK(strcmp(llama_robot_tap_name(m_taps, 0), "subject") == 0, "tap 0 name");
    CHECK(strcmp(llama_robot_tap_point(m_taps, 1), "ffn_out") == 0, "tap 1 point");
    CHECK(llama_robot_tap_width(m_taps, 0) == 8, "tap 0 width");
    CHECK(llama_robot_tap_layer(m_taps, 1) == 1, "tap 1 layer");
    CHECK(llama_robot_tap_count(m_stock) == 0, "stock tap count == 0");
    CHECK(llama_robot_probe_dim(m_taps, 0, "subject") == 8, "probe dim");
    CHECK(llama_robot_probe_dim(m_taps, 0, "nope") == -1, "missing probe dim == -1");

    llama_context * c_taps = llama_init_from_model(m_taps, cp);

    // before any decode: reads must fail gracefully
    float pre[8];
    CHECK(!llama_robot_tap_read(c_taps, 0, pre), "tap_read before decode must fail");

    const auto logits_taps = decode_and_logits(m_taps, c_taps);

    // parity: taps are pure outputs — logits must be bit-identical
    float max_diff = 0.0f;
    for (size_t i = 0; i < logits_stock.size(); ++i) {
        max_diff = std::fmax(max_diff, std::fabs(logits_stock[i] - logits_taps[i]));
    }
    printf("parity with taps active: max |logit diff| = %g\n", max_diff);
    CHECK(max_diff == 0.0f, "taps must not perturb the donor path");

    // tap reads: finite, not all zero
    for (int id = 0; id < 2; ++id) {
        float buf[8] = { 0 };
        CHECK(llama_robot_tap_read(c_taps, id, buf), "tap_read(%d)", id);
        bool finite = true, nonzero = false;
        for (float v : buf) { finite &= std::isfinite(v); nonzero |= (v != 0.0f); }
        CHECK(finite, "tap %d values finite", id);
        CHECK(nonzero, "tap %d values non-trivial", id);
        printf("tap %d (%s): [%g, %g, %g, ...]\n", id, llama_robot_tap_name(m_taps, id), buf[0], buf[1], buf[2]);
    }
    CHECK(!llama_robot_tap_read(c_taps, 7, pre), "bad tap id must fail");

    // probe head: identity weight + 0.5 bias → probe(x) == x + 0.5
    {
        float x[8], p[8];
        CHECK(llama_robot_tap_read(c_taps, 0, x), "tap_read for probe cross-check");
        CHECK(llama_robot_probe_eval(c_taps, 0, "subject", p), "probe_eval");
        float pd = 0.0f;
        for (int k = 0; k < 8; ++k) {
            pd = std::fmax(pd, std::fabs(p[k] - (x[k] + 0.5f)));
        }
        printf("probe identity check: max |probe - (tap + 0.5)| = %g\n", pd);
        CHECK(pd < 1e-6f, "identity probe must reproduce tap + bias");
        CHECK(!llama_robot_probe_eval(c_taps, 0, "nope", p), "missing probe must fail");
    }

    // a second decode must refresh the tap values
    {
        float a[8], b[8];
        llama_robot_tap_read(c_taps, 0, a);
        std::vector<llama_token> toks = { 2, 11, 23 };
        llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
        CHECK(llama_decode(c_taps, batch) == 0, "second decode");
        CHECK(llama_robot_tap_read(c_taps, 0, b), "tap_read after second decode");
        bool changed = false;
        for (int k = 0; k < 8; ++k) { changed |= (a[k] != b[k]); }
        CHECK(changed, "tap values must track the latest decode");
    }

    llama_free(c_taps);
    llama_free(c_stock);
    llama_model_free(m_taps);
    llama_model_free(m_stock);

    if (failures) { printf("E2 TAP TEST: %d FAILURE(S)\n", failures); return 1; }
    printf("E2 TAP TEST: OK\n");
    return 0;
}
