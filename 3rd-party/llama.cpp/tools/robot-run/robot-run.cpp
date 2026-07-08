// llama-robot-run — generate text from a converted therobot model while
// surfacing the extensions live. Display modes:
//   -i / --interactive  split-pane REPL — type text on the left, model output
//                       streams below it, and the right pane shows live internal
//                       state (modulator channels, per-tap probe classes, memory
//                       count, delta keep-rate), repainted every token
//   --dashboard         one-shot full-screen state panel over a single prompt
//   --probe             one-shot inline per-token probe read-outs (pipe-friendly)
//
// Also supports routing shims (--registry/--route) and priming the modulator
// (--arousal). With no flags the model runs identically to the stock donor.
// This is the reference for how include/llama-robot.h is used at inference.
//
// Usage:
//   llama-robot-run -m <model.gguf> [-i] [-p prompt] [-n N]
//       [--probe | --dashboard] [--probe-tap id]
//       [--registry registry.json] [--route tag,tag] [--arousal X]
#include "llama.h"
#include "llama-robot.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

#include <sys/ioctl.h>
#include <unistd.h>

static void usage(const char * a0) {
    fprintf(stderr,
        "usage: %s -m <model.gguf> [-p prompt] [-n N]\n"
        "          [-i|--interactive]     split-pane REPL: input+output left, live state right\n"
        "          [--probe|--dashboard]  one-shot inline probes / full-screen state panel\n"
        "          [--probe-tap id] [--registry registry.json] [--route tag,tag] [--arousal X]\n"
        "  interactive commands:  /arousal X   /reset   /quit\n", a0);
}

static std::vector<llama_token> tokenize(const llama_vocab * v, const std::string & s, bool bos) {
    int n = -llama_tokenize(v, s.c_str(), (int) s.size(), nullptr, 0, bos, true);
    std::vector<llama_token> out(n);
    llama_tokenize(v, s.c_str(), (int) s.size(), out.data(), n, bos, true);
    return out;
}

static std::string piece(const llama_vocab * v, llama_token t) {
    char buf[256];
    int n = llama_token_to_piece(v, t, buf, sizeof(buf), 0, true);
    return std::string(buf, n > 0 ? n : 0);
}

static llama_token argmax(const float * lg, int n) {
    llama_token best = 0;
    for (int i = 1; i < n; ++i) if (lg[i] > lg[best]) best = i;
    return best;
}

// top class + confidence for one probe
static bool probe_top(llama_context * ctx, const llama_model * m, int tap,
                      const char * attr, int * cls, float * conf) {
    int dim = llama_robot_probe_dim(m, tap, attr);
    if (dim <= 0) return false;
    std::vector<float> out(dim);
    if (!llama_robot_probe_eval(ctx, tap, attr, out.data())) return false;
    float mx = out[0]; for (float v : out) mx = std::fmax(mx, v);
    double z = 0; for (float v : out) z += std::exp((double)(v - mx));
    int c = 0; for (int i = 1; i < dim; ++i) if (out[i] > out[c]) c = i;
    *cls = c; *conf = (float)(std::exp((double)(out[c] - mx)) / z);
    return true;
}

static void print_probes_inline(llama_context * ctx, const llama_model * m, int only_tap) {
    for (int t = 0; t < llama_robot_tap_count(m); ++t) {
        if (only_tap >= 0 && t != only_tap) continue;
        for (int a = 0; a < llama_robot_tap_attr_count(m, t); ++a) {
            const char * attr = llama_robot_tap_attr(m, t, a);
            int cls; float conf;
            if (probe_top(ctx, m, t, attr, &cls, &conf))
                printf(" %s.%s=%d(%.2f)", llama_robot_tap_name(m, t), attr, cls, conf);
        }
    }
}

// ---- live dashboard (ANSI) ----
static std::string bar(float v, float lo, float hi, int w) {
    float f = (v - lo) / (hi - lo);
    if (f < 0) f = 0; if (f > 1) f = 1;
    int n = (int)(f * w);
    std::string s;
    for (int i = 0; i < w; ++i) s += (i < n ? '#' : '.');
    return s;
}

static void term_size(int * rows, int * cols) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0) {
        *rows = ws.ws_row; *cols = ws.ws_col;
    } else { *rows = 24; *cols = 100; }
}

// hard-wrap a string (honoring embedded newlines) into <=w-wide byte lines
static void wrap_into(std::vector<std::string> & out, const std::string & s, int w) {
    std::string cur;
    for (char c : s) {
        if (c == '\n') { out.push_back(cur); cur.clear(); continue; }
        cur += c;
        if ((int) cur.size() >= w) { out.push_back(cur); cur.clear(); }
    }
    out.push_back(cur);
}

// build the right-pane content: modulator bars, tap probes, memory, delta
static std::vector<std::string> state_lines(llama_context * ctx, const llama_model * m) {
    std::vector<std::string> L;
    char buf[256];
    L.push_back("therobot live state");
    L.push_back("");

    int md = llama_robot_mod_dim(m);
    if (md > 0) {
        std::vector<float> mv(md);
        llama_robot_mod_get(ctx, mv.data());
        L.push_back("modulator m:");
        for (int i = 0; i < md; ++i) {
            const char * name = llama_robot_mod_channel(m, i);
            snprintf(buf, sizeof(buf), "  %-9s %+5.2f %s",
                     name ? name : "?", mv[i], bar(mv[i], -4, 4, 12).c_str());
            L.push_back(buf);
        }
        L.push_back("");
    }

    int taps = llama_robot_tap_count(m);
    if (taps > 0) {
        L.push_back("probes (attr=class@conf):");
        for (int t = 0; t < taps; ++t) {
            std::string row = "  ";
            row += llama_robot_tap_name(m, t);
            for (int a = 0; a < llama_robot_tap_attr_count(m, t); ++a) {
                const char * attr = llama_robot_tap_attr(m, t, a);
                int cls; float conf;
                if (probe_top(ctx, m, t, attr, &cls, &conf)) {
                    snprintf(buf, sizeof(buf), " %s=%d@%.2f", attr, cls, conf);
                    row += buf;
                }
            }
            L.push_back(row);
        }
        L.push_back("");
    }

    int nmem = llama_robot_memory_count(ctx);
    snprintf(buf, sizeof(buf), "episodic memory: %d stored", nmem);
    L.push_back(buf);
    // list the most recent entries (newest first), salience + age in tokens
    const int show = nmem < 8 ? nmem : 8;
    for (int k = 0; k < show; ++k) {
        int idx = nmem - 1 - k;
        float sal; uint64_t age;
        if (llama_robot_memory_get(ctx, idx, &sal, nullptr, &age)) {
            snprintf(buf, sizeof(buf), "  #%-3d sal %6.2f  %llu tok ago",
                     idx, sal, (unsigned long long) age);
            L.push_back(buf);
        }
    }
    if (nmem > show) {
        snprintf(buf, sizeof(buf), "  … +%d older", nmem - show);
        L.push_back(buf);
    }
    L.push_back("");
    if (llama_robot_delta_enabled(ctx)) {
        snprintf(buf, sizeof(buf), "delta keep-rate: %.2f (%llu tok)",
                 llama_robot_delta_keep_rate(ctx),
                 (unsigned long long) llama_robot_delta_tokens(ctx));
        L.push_back(buf);
    }
    return L;
}

// paint two panes: `left` (conversation, tail shown) | `state` (internal detail).
// leaves the cursor on the last row for an input prompt drawn by the caller.
static void paint_split(const std::string & left, const std::vector<std::string> & state) {
    int rows, cols; term_size(&rows, &cols);
    int leftw = cols * 3 / 5;
    if (leftw < 24)          leftw = 24;
    if (leftw > cols - 16)   leftw = cols - 16;
    int rightw = cols - leftw - 3;
    if (rightw < 10) rightw = 10;

    std::vector<std::string> ll;
    wrap_into(ll, left, leftw);

    const int body = rows - 1;               // last row reserved for input
    int lstart = (int) ll.size() > body ? (int) ll.size() - body : 0;

    printf("\x1b[H\x1b[2J");                  // home + clear
    for (int r = 0; r < body; ++r) {
        std::string lt = (lstart + r < (int) ll.size()) ? ll[lstart + r] : "";
        if ((int) lt.size() < leftw) lt.append(leftw - lt.size(), ' ');
        else                         lt = lt.substr(0, leftw);
        std::string rt = r < (int) state.size() ? state[r] : "";
        if ((int) rt.size() > rightw) rt = rt.substr(0, rightw);
        printf("%s \x1b[90m\xe2\x94\x82\x1b[0m %s\n", lt.c_str(), rt.c_str());
    }
    fflush(stdout);
}

// split-pane, turn-based chat REPL. Each input is a *user turn*: the model's
// chat template formats the running conversation, only the new delta is fed to
// the context, and generation stops at the end-of-turn token — like llama.cpp's
// simple-chat, but with the live extension state painted in the right pane.
// (If the model carries no chat template, falls back to raw continuation.)
static int interactive_loop(llama_context * ctx, const llama_model * model,
                            const llama_vocab * vocab, int n_vocab,
                            int n_predict, float arousal) {
    const char * tmpl = llama_model_chat_template(model, nullptr);
    std::string transcript;
    if (!tmpl) transcript += "[no chat template — raw continuation mode]\n";
    if (arousal != 0.0f) transcript += "[arousal=" + std::to_string(arousal) + "]\n";

    std::vector<llama_chat_message> messages;         // owned strings (strdup)
    std::vector<char> fmt(llama_n_ctx(ctx));
    int  prev_len = 0;
    bool first    = true;

    auto free_msgs = [&]() {
        for (auto & m : messages) free((void *) m.content);
        messages.clear();
    };

    // stream one assistant turn from `prompt` (already template-formatted delta),
    // repainting both panes per token; returns the generated text
    auto generate = [&](const std::string & prompt) -> std::string {
        auto toks = tokenize(vocab, prompt, first);
        first = false;
        llama_batch b0 = llama_batch_get_one(toks.data(), (int) toks.size());
        if (llama_decode(ctx, b0)) { transcript += "[decode failed]\n"; return ""; }
        std::string resp;
        for (int i = 0; i < n_predict; ++i) {
            llama_token next = argmax(llama_get_logits_ith(ctx, -1), n_vocab);
            if (llama_vocab_is_eog(vocab, next)) break;
            std::string p = piece(vocab, next);
            resp += p;
            transcript += p;
            paint_split(transcript, state_lines(ctx, model));
            llama_batch b = llama_batch_get_one(&next, 1);
            if (llama_decode(ctx, b)) break;
        }
        return resp;
    };

    while (true) {
        int rows, cols; term_size(&rows, &cols); (void) cols;
        paint_split(transcript, state_lines(ctx, model));
        printf("\x1b[%d;1H\x1b[2K\x1b[1m> \x1b[0m", rows);   // input line
        fflush(stdout);

        std::string line;
        if (!std::getline(std::cin, line)) break;
        if (line == "/quit" || line == "/q") break;
        if (line == "/reset") {
            llama_robot_session_reset(ctx, true);
            llama_memory_clear(llama_get_memory(ctx), true);
            free_msgs(); prev_len = 0; first = true;
            transcript += "\n[session reset]\n";
            continue;
        }
        if (line.rfind("/arousal ", 0) == 0) {
            arousal = (float) atof(line.c_str() + 9);
            if (llama_robot_mod_dim(model) > 0) {
                std::vector<float> mm(llama_robot_mod_dim(model), 0.0f);
                mm[0] = arousal;
                llama_robot_mod_set(ctx, mm.data());
            }
            transcript += "\n[arousal=" + std::to_string(arousal) + "]\n";
            continue;
        }
        if (line.empty()) continue;

        transcript += "\nYou: " + line + "\nBot: ";

        std::string prompt;
        if (tmpl) {
            messages.push_back({ "user", strdup(line.c_str()) });
            int new_len = llama_chat_apply_template(tmpl, messages.data(), messages.size(),
                                                    true, fmt.data(), (int) fmt.size());
            if (new_len > (int) fmt.size()) {
                fmt.resize(new_len);
                new_len = llama_chat_apply_template(tmpl, messages.data(), messages.size(),
                                                    true, fmt.data(), (int) fmt.size());
            }
            if (new_len < 0) { transcript += "[template error]\n"; free((void *) messages.back().content); messages.pop_back(); continue; }
            prompt.assign(fmt.begin() + prev_len, fmt.begin() + new_len);
        } else {
            prompt = line;   // no chat template: raw continuation
        }

        std::string resp = generate(prompt);

        if (tmpl) {
            messages.push_back({ "assistant", strdup(resp.c_str()) });
            prev_len = llama_chat_apply_template(tmpl, messages.data(), messages.size(),
                                                 false, fmt.data(), (int) fmt.size());
            if (prev_len < 0) prev_len = 0;
        }
    }
    free_msgs();
    printf("\x1b[2J\x1b[H");
    return 0;
}

int main(int argc, char ** argv) {
    std::string model_path, prompt = "The best way to write fast, reliable software is";
    std::string registry, route_tags;
    int n_predict = 64, probe_tap = -1;
    bool do_probe = false, dashboard = false, compare = false, interactive = false;
    float arousal = 0.0f; bool prime = false;

    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        auto next = [&](const char * name) -> const char * {
            if (i + 1 >= argc) { fprintf(stderr, "%s needs a value\n", name); exit(1); }
            return argv[++i];
        };
        if      (a == "-m" || a == "--model")     model_path = next("-m");
        else if (a == "-p" || a == "--prompt")    prompt = next("-p");
        else if (a == "-n" || a == "--n-predict") n_predict = atoi(next("-n"));
        else if (a == "-i" || a == "--interactive") interactive = true;
        else if (a == "--probe")                  do_probe = true;
        else if (a == "--dashboard")              dashboard = true;
        else if (a == "--compare")                compare = true;
        else if (a == "--probe-tap")            { do_probe = true; probe_tap = atoi(next("--probe-tap")); }
        else if (a == "--registry")               registry = next("--registry");
        else if (a == "--route")                  route_tags = next("--route");
        else if (a == "--arousal")              { arousal = atof(next("--arousal")); prime = true; }
        else if (a == "-h" || a == "--help")    { usage(argv[0]); return 0; }
        else { fprintf(stderr, "unknown arg: %s\n", a.c_str()); usage(argv[0]); return 1; }
    }
    if (model_path.empty()) { usage(argv[0]); return 1; }

    llama_backend_init();
    llama_model_params mp = llama_model_default_params();
    llama_model * model = llama_model_load_from_file(model_path.c_str(), mp);
    if (!model) { fprintf(stderr, "failed to load %s\n", model_path.c_str()); return 1; }

    fprintf(stderr, "therobot: %s, %d tap(s), modulator dim %d\n",
            llama_robot_enabled(model) ? "enabled" : "stock",
            llama_robot_tap_count(model), llama_robot_mod_dim(model));

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 2048; cp.n_batch = 2048;
    llama_context * ctx = llama_init_from_model(model, cp);
    const llama_vocab * vocab = llama_model_get_vocab(model);
    const int n_vocab = llama_vocab_n_tokens(vocab);

    if (!compare && !registry.empty() && !route_tags.empty()) {
        llama_robot_registry * reg = llama_robot_registry_load(model, registry.c_str());
        if (reg) {
            std::vector<std::string> tags; std::vector<const char *> tagp;
            for (size_t s = 0, e; s <= route_tags.size(); s = e + 1) {
                e = route_tags.find(',', s); if (e == std::string::npos) e = route_tags.size();
                tags.push_back(route_tags.substr(s, e - s));
            }
            for (auto & t : tags) tagp.push_back(t.c_str());
            int n = llama_robot_route(ctx, reg, tagp.data(), (int) tagp.size());
            fprintf(stderr, "therobot: routed %d shim module(s) for [%s]\n", n, route_tags.c_str());
            // registry must outlive ctx; leaked deliberately for this short tool
        }
    }
    if (prime && llama_robot_mod_dim(model) > 0) {
        std::vector<float> mm(llama_robot_mod_dim(model), 0.0f);
        mm[0] = arousal;
        llama_robot_mod_set(ctx, mm.data());
    }

    // -i: split-pane REPL. Input+output on the left, live internal state on the
    // right, repainted each token. Takes over until /quit or EOF.
    if (interactive) {
        int rc = interactive_loop(ctx, model, vocab, n_vocab, n_predict, arousal);
        llama_free(ctx); llama_model_free(model); llama_backend_free();
        return rc;
    }

    auto toks = tokenize(vocab, prompt, true);

    // --compare: generate the same prompt with the routed shims OFF then ON, so
    // the behavior change is visible side by side. Requires --registry/--route.
    if (compare && !registry.empty() && !route_tags.empty()) {
        auto gen_once = [&](const char * label) {
            llama_memory_clear(llama_get_memory(ctx), true);
            llama_batch b0 = llama_batch_get_one(toks.data(), (int) toks.size());
            llama_decode(ctx, b0);
            std::string g;
            for (int i = 0; i < n_predict; ++i) {
                llama_token next = argmax(llama_get_logits_ith(ctx, -1), n_vocab);
                if (llama_vocab_is_eog(vocab, next)) break;
                g += piece(vocab, next);
                llama_batch b = llama_batch_get_one(&next, 1);
                if (llama_decode(ctx, b)) break;
            }
            printf("\n\x1b[7m %s \x1b[0m %s%s\n", label, prompt.c_str(), g.c_str());
        };
        llama_robot_registry * rc = llama_robot_registry_load(model, registry.c_str());
        llama_robot_route(ctx, rc, nullptr, 0);   // OFF: nothing routed
        gen_once("shim OFF");
        std::vector<std::string> tags; std::vector<const char *> tagp;
        for (size_t s = 0, e; s <= route_tags.size(); s = e + 1) {
            e = route_tags.find(',', s); if (e == std::string::npos) e = route_tags.size();
            tags.push_back(route_tags.substr(s, e - s));
        }
        for (auto & t : tags) tagp.push_back(t.c_str());
        llama_robot_route(ctx, rc, tagp.data(), (int) tagp.size());
        gen_once("shim ON ");
        llama_free(ctx); llama_model_free(model); llama_backend_free();
        return 0;
    }

    llama_batch batch = llama_batch_get_one(toks.data(), (int) toks.size());
    if (llama_decode(ctx, batch)) { fprintf(stderr, "prompt decode failed\n"); return 1; }

    std::string gen;
    if (!dashboard) { printf("%s", prompt.c_str()); fflush(stdout); }
    for (int i = 0; i < n_predict; ++i) {
        llama_token next = argmax(llama_get_logits_ith(ctx, -1), n_vocab);
        if (llama_vocab_is_eog(vocab, next)) break;
        std::string p = piece(vocab, next);
        gen += p;
        if (dashboard) {
            paint_split(prompt + gen, state_lines(ctx, model));
        } else {
            if (do_probe) { printf("\n["); print_probes_inline(ctx, model, probe_tap); printf(" ] "); }
            printf("%s", p.c_str()); fflush(stdout);
        }
        llama_batch b = llama_batch_get_one(&next, 1);
        if (llama_decode(ctx, b)) break;
    }
    if (!dashboard) printf("\n");

    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    return 0;
}
