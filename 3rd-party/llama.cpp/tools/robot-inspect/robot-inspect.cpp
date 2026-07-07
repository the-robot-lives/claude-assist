// robot-inspect — dump the therobot extension manifest of a GGUF file (E1)
//
// Usage:
//   llama-robot-inspect <model.gguf> [--load]
//
// Reads the `therobot.*` KV contract (gguf-extension-spec.md v1) straight from
// the GGUF metadata and prints the manifest: identity, negotiated features,
// per-feature sections, and the extension tensors present in the file. Also
// understands `therobot-shim` module files (spec §4). With --load, it
// additionally runs the full runtime load path (feature negotiation included)
// to verify the file is accepted by this build.

#include "../../src/llama-robot-hparams.h"
#include "../../src/llama-robot-model.h"

#include "llama.h"
#include "gguf.h"
#include "ggml.h"

#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static void print_usage(const char * argv0) {
    fprintf(stderr, "usage: %s <model.gguf> [--load]\n", argv0);
    fprintf(stderr, "  --load  additionally verify the file loads through the runtime (negotiation enforced)\n");
}

static std::string kv_str(const gguf_context * ctx, const char * key, const char * dflt = "") {
    const int id = gguf_find_key(ctx, key);
    if (id < 0 || gguf_get_kv_type(ctx, id) != GGUF_TYPE_STRING) {
        return dflt;
    }
    return gguf_get_val_str(ctx, id);
}

static void print_str_list(const std::vector<std::string> & v) {
    if (v.empty()) {
        printf("(none)");
    }
    for (size_t i = 0; i < v.size(); ++i) {
        printf("%s%s", i ? ", " : "", v[i].c_str());
    }
    printf("\n");
}

static int inspect_shim(const gguf_context * ctx) {
    printf("file type          : therobot-shim module (spec section 4)\n");
    printf("shim.name          : %s\n", kv_str(ctx, "therobot.shim.name").c_str());
    printf("shim.version       : %s\n", kv_str(ctx, "therobot.shim.version").c_str());
    printf("shim.target_model  : %s\n", kv_str(ctx, "therobot.shim.target_model").c_str());
    printf("shim.target_bneck  : %s\n", kv_str(ctx, "therobot.shim.target_bottleneck").c_str());
    printf("shim.effect        : %s\n", kv_str(ctx, "therobot.shim.effect").c_str());
    printf("shim.gate          : %s\n", kv_str(ctx, "therobot.shim.gate", "always").c_str());
    const int sel = gguf_find_key(ctx, "therobot.shim.selectivity");
    if (sel >= 0 && gguf_get_kv_type(ctx, sel) == GGUF_TYPE_FLOAT32) {
        printf("shim.selectivity   : %.4f\n", gguf_get_val_f32(ctx, sel));
    }
    return 0;
}

int main(int argc, char ** argv) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char * fname = argv[1];
    bool do_load = false;
    for (int i = 2; i < argc; ++i) {
        if (strcmp(argv[i], "--load") == 0) {
            do_load = true;
        } else {
            print_usage(argv[0]);
            return 1;
        }
    }

    ggml_context * meta_ctx = nullptr;
    gguf_init_params gparams = {
        /*.no_alloc = */ true,
        /*.ctx      = */ &meta_ctx,
    };
    gguf_context * ctx = gguf_init_from_file(fname, gparams);
    if (ctx == nullptr) {
        fprintf(stderr, "error: failed to read GGUF metadata from '%s'\n", fname);
        return 1;
    }

    const std::string arch = kv_str(ctx, "general.architecture", "(missing)");
    printf("== therobot extension manifest ==\n");
    printf("file               : %s\n", fname);

    if (arch == "therobot-shim") {
        const int rc = inspect_shim(ctx);
        gguf_free(ctx);
        ggml_free(meta_ctx);
        return rc;
    }

    if (arch != "therobot") {
        printf("file type          : stock '%s' file — no therobot extensions\n", arch.c_str());
        gguf_free(ctx);
        ggml_free(meta_ctx);
        if (do_load) {
            printf("\n-- runtime load check (stock path) --\n");
            llama_model_params mparams = llama_model_default_params();
            llama_model * model = llama_model_load_from_file(fname, mparams);
            if (model == nullptr) {
                fprintf(stderr, "load check FAILED\n");
                return 2;
            }
            printf("load check OK\n");
            llama_model_free(model);
        }
        return 0;
    }

    llama_robot_hparams robot;
    try {
        // negotiate=false: dump manifests even for files this build cannot run yet
        llama_robot_hparams_load_gguf(robot, ctx, /*negotiate =*/ false);
    } catch (const std::exception & e) {
        fprintf(stderr, "error: malformed therobot contract: %s\n", e.what());
        gguf_free(ctx);
        ggml_free(meta_ctx);
        return 1;
    }

    printf("file type          : therobot model\n");
    printf("spec_version       : %u (runtime implements %u)\n", robot.spec_version, LLAMA_ROBOT_SPEC_VERSION);
    printf("base_architecture  : %s\n", robot.base_architecture.c_str());
    printf("level              : L%u%s\n", robot.level, robot.is_passthrough() ? " (passthrough)" : "");
    printf("features (required): ");
    print_str_list(robot.features_required_raw);
    if (!robot.donor_id.empty()) {
        printf("donor.id           : %s\n", robot.donor_id.c_str());
    }
    if (!robot.convert_lockfile_hash.empty()) {
        printf("convert.lockfile   : %s\n", robot.convert_lockfile_hash.c_str());
    }

    if (!robot.bottlenecks.empty()) {
        printf("\n-- bottlenecks / taps (%zu) --\n", robot.bottlenecks.size());
        for (size_t i = 0; i < robot.bottlenecks.size(); ++i) {
            const auto & bn = robot.bottlenecks[i];
            printf("  [%zu] %-16s layer=%u point=%s slice=[%u..%u) decodability=%.3f selectivity=%.3f\n",
                    i, bn.name.c_str(), bn.layer, bn.point.c_str(),
                    bn.offset, bn.offset + bn.width, bn.decodability, bn.selectivity);
            printf("       attributes: ");
            print_str_list(bn.attributes);
        }
    }

    if (!robot.state.banks.empty()) {
        printf("\n-- leaky state (%zu banks) --\n", robot.state.banks.size());
        for (const auto & bank : robot.state.banks) {
            printf("  bank %-8s width=%u\n", bank.name.c_str(), bank.width);
        }
        printf("  layers: ");
        for (size_t i = 0; i < robot.state.layers.size(); ++i) {
            printf("%s%u", i ? ", " : "", robot.state.layers[i]);
        }
        printf("\n");
    }

    if (robot.modulator.dim > 0) {
        printf("\n-- modulator --\n");
        printf("  dim=%u source=%s channels: ", robot.modulator.dim, robot.modulator.source.c_str());
        print_str_list(robot.modulator.channels);
    }

    if (robot.memory.key_dim > 0) {
        printf("\n-- episodic memory --\n");
        printf("  key_dim=%u value_dim=%u capacity=%u decay_halflife=%.1f salience_q=%.3f\n",
                robot.memory.key_dim, robot.memory.value_dim, robot.memory.capacity,
                robot.memory.decay_halflife, robot.memory.salience_threshold_quantile);
    }

    if (!robot.delta.granularity.empty()) {
        printf("\n-- delta inference --\n");
        printf("  granularity=%s heartbeat=%u target_keep_rate=%.3f\n",
                robot.delta.granularity.c_str(), robot.delta.heartbeat, robot.delta.target_keep_rate);
    }

    if (!robot.settle.objective.empty()) {
        printf("\n-- settling --\n");
        printf("  objective=%s mask_token_id=%u max_steps=%u epsilon=%g m_schedule=%zu entries\n",
                robot.settle.objective.c_str(), robot.settle.mask_token_id,
                robot.settle.max_steps, robot.settle.epsilon, robot.settle.m_schedule.size());
    }

    // extension tensors present in the file
    {
        size_t n_ext = 0, n_base = 0;
        printf("\n-- extension tensors --\n");
        for (ggml_tensor * t = ggml_get_first_tensor(meta_ctx); t != nullptr; t = ggml_get_next_tensor(meta_ctx, t)) {
            const std::string name = ggml_get_name(t);
            if (!llama_robot_is_ext_tensor(name)) {
                n_base++;
                continue;
            }
            n_ext++;
            printf("  %-48s %-8s [%" PRId64 ", %" PRId64 ", %" PRId64 ", %" PRId64 "]\n",
                    name.c_str(), ggml_type_name(t->type), t->ne[0], t->ne[1], t->ne[2], t->ne[3]);
        }
        printf("  %zu extension tensor(s), %zu base tensor(s)\n", n_ext, n_base);
    }

    gguf_free(ctx);
    ggml_free(meta_ctx);

    if (do_load) {
        printf("\n-- runtime load check --\n");
        llama_model_params mparams = llama_model_default_params();
        mparams.vocab_only = false;
        llama_model * model = llama_model_load_from_file(fname, mparams);
        if (model == nullptr) {
            fprintf(stderr, "load check FAILED: runtime refused the file (see log above)\n");
            return 2;
        }
        printf("load check OK: file accepted by this runtime\n");
        llama_model_free(model);
    }

    return 0;
}
