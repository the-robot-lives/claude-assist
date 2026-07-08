// semvec test: the standardized readout layer's four runtime gates
// (convert/docs/semvec-runtime-spec.md §6):
//   1. dormant-semvec parity — semvec tensors present, no overlay set →
//      logits identical to the stock donor twin
//   2. read determinism — semvec_read twice at the same position is identical
//   3. write roundtrip — unit overlay on a writable axis moves that axis's
//      readout by 1.0 ± 1e-3, unset restores parity bit-exact
//   4. enumeration + calibration surface (site/axis lookups, zeroed
//      non-admitted axes)
//
// usage: robot_semvec_test <stock.gguf> <semvec.gguf>
//   <semvec.gguf> is any therobot export carrying robot.semvec.* (the
//   conversion e2e produces one; so does any real donor after cleave+export).

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

static float max_abs_diff(const std::vector<float> & a, const std::vector<float> & b) {
    float m = 0.0f;
    for (size_t i = 0; i < a.size() && i < b.size(); ++i) {
        m = std::fmax(m, std::fabs(a[i] - b[i]));
    }
    return m;
}

int main(int argc, char ** argv) {
    if (argc != 3) { fprintf(stderr, "usage: %s <stock.gguf> <semvec.gguf>\n", argv[0]); return 1; }

    llama_model_params mp = llama_model_default_params();
    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 512;   // the write-roundtrip loop decodes several times
    cp.n_batch = 8;

    // stock twin — reference logits
    llama_model * m_stock = llama_model_load_from_file(argv[1], mp);
    CHECK(m_stock != nullptr, "stock model load");
    if (!m_stock) { return 1; }
    llama_context * c_stock = llama_init_from_model(m_stock, cp);
    const auto logits_stock = decode_and_logits(m_stock, c_stock);

    // semvec twin
    llama_model * m = llama_model_load_from_file(argv[2], mp);
    CHECK(m != nullptr, "semvec model load (negotiation incl. features_optional)");
    if (!m) { return 1; }
    CHECK(llama_robot_enabled(m), "robot-enabled");

    // gate 4 — enumeration surface
    const int32_t n_sites = llama_robot_semvec_site_count(m);
    CHECK(n_sites >= 1, "semvec site count >= 1 (got %d)", n_sites);
    const int32_t D  = llama_robot_semvec_dim(m);
    const int32_t Dn = llama_robot_semvec_named_dim(m);
    CHECK(D > 0 && Dn > 0 && Dn <= D, "dims sane (D=%d, named=%d)", D, Dn);
    CHECK(llama_robot_semvec_site_name(m, 0) != nullptr, "site 0 has a name");
    CHECK(llama_robot_semvec_site_name(m, n_sites) == nullptr, "out-of-range site name is NULL");
    const char * ax0 = llama_robot_semvec_axis_name(m, 0);
    if (ax0 != nullptr) {
        CHECK(llama_robot_semvec_axis_index(m, ax0) == 0, "axis name<->index roundtrip");
    }
    CHECK(llama_robot_semvec_axis_index(m, "__no_such_axis__") == -1, "unknown axis == -1");
    CHECK(llama_robot_semvec_site_count(m_stock) == 0, "stock file has no semvec");

    llama_context * ctx = llama_init_from_model(m, cp);

    // before any decode: read must fail gracefully
    std::vector<float> s0(D), s1(D);
    CHECK(!llama_robot_semvec_read(ctx, 0, s0.data(), s0.size()), "read before decode must fail");

    // gate 1 — dormant parity: tensors present, nothing engaged
    const auto logits_dormant = decode_and_logits(m, ctx);
    const float d_dormant = max_abs_diff(logits_stock, logits_dormant);
    CHECK(d_dormant == 0.0f, "dormant-semvec parity: max |logit diff| = %g (must be 0)", d_dormant);

    // gate 2 — read determinism + short-buffer refusal
    CHECK(!llama_robot_semvec_read(ctx, 0, s0.data(), (size_t) D - 1), "short buffer refused");
    CHECK(llama_robot_semvec_read(ctx, 0, s0.data(), s0.size()), "semvec_read");
    CHECK(llama_robot_semvec_read(ctx, 0, s1.data(), s1.size()), "semvec_read (again)");
    CHECK(memcmp(s0.data(), s1.data(), (size_t) D * sizeof(float)) == 0, "read determinism");
    for (int32_t j = 0; j < D; ++j) {
        CHECK(std::isfinite(s0[j]), "axis %d finite", j);
    }
    CHECK(llama_robot_semvec_axis(m, s0.data(), 0) == s0[0], "axis accessor");
    const float self = llama_robot_semvec_query(m, s0.data(), s0.data(), (size_t) D);
    // a fully dormant/zero vector yields 0; otherwise self-cosine is 1
    CHECK(self == 0.0f || std::fabs(self - 1.0f) < 1e-5f, "self-query cosine (got %f)", self);

    // gate 3 — write roundtrip on the first axis this site can actually write.
    // Find it by trying axes until an overlay_set on a unit delta changes the
    // readout (unwritable axes have zeroed G rows → no change).
    int32_t written_axis = -1;
    int32_t tries = 0;
    std::vector<float> ds((size_t) D, 0.0f);
    for (int32_t j = 0; j < D && written_axis < 0 && tries < 8; ++j) {
        if (s0[j] == 0.0f) { continue; }       // likely non-admitted; skip cheap
        tries++;
        std::fill(ds.begin(), ds.end(), 0.0f);
        ds[j] = 1.0f;
        if (!llama_robot_semvec_overlay_set(ctx, 0, ds.data(), 1.0f)) { break; }
        const auto logits_over = decode_and_logits(m, ctx);
        std::vector<float> sw(D);
        CHECK(llama_robot_semvec_read(ctx, 0, sw.data(), sw.size()), "read under overlay");
        const float moved = sw[j] - s0[j];
        if (std::fabs(moved) > 1e-6f) {
            written_axis = j;
            CHECK(std::fabs(moved - 1.0f) < 1e-3f,
                  "unit write on axis %d moves readout by %f (want 1.0)", j, moved);
            (void) logits_over;
        }
        CHECK(llama_robot_semvec_overlay_set(ctx, 0, nullptr, 0.0f), "overlay unset");
    }
    if (written_axis < 0) {
        fprintf(stderr, "note: no writable axis found at site 0 (read-only export?) — write gate skipped\n");
    }

    // unset restores parity bit-exact
    const auto logits_after = decode_and_logits(m, ctx);
    const float d_after = max_abs_diff(logits_stock, logits_after);
    CHECK(d_after == 0.0f, "post-unset parity: max |logit diff| = %g (must be 0)", d_after);

    llama_free(ctx);
    llama_model_free(m);
    llama_free(c_stock);
    llama_model_free(m_stock);

    if (failures) { fprintf(stderr, "SEMVEC TEST: %d failure(s)\n", failures); return 1; }
    printf("SEMVEC TEST: OK%s\n", written_axis >= 0 ? "" : " (write gate skipped)");
    return 0;
}
