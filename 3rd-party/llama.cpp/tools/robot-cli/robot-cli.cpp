// llama-robot-cli — a fork of tools/cli/cli.cpp (llama-cli) that adds a live
// therobot status panel over the normal streaming chat. The panel occupies a
// fixed block of rows at the top of the terminal (held out of the scroll region
// via DECSTBM) and is repainted every streamed token; the CLI's own output
// flows normally below it. Everything else — sampler chain, chat templating,
// commands, readline, timings — is the stock llama-cli behavior.
//
// Panel content: modulator channels, per-tap probe classes, the episodic memory
// list (index / salience / age), recall magnitude, and delta keep-rate. Only
// enabled when the loaded model is a therobot model; otherwise this is llama-cli.
//
// ROBOT-FORK: this file is a therobot-owned copy; it does not replace upstream
// tools/cli/cli.cpp (which stays bit-identical to upstream).

#include "chat.h"
#include "common.h"
#include "arg.h"
#include "console.h"
#include "fit.h"
// #include "log.h"

#include "server-common.h"
#include "server-context.h"
#include "server-task.h"

#include "llama-robot.h"        // ROBOT-FORK

#include <array>
#include <atomic>
#include <algorithm>
#include <cmath>                // ROBOT-FORK (softmax/norm in the panel)
#include <cstring>              // ROBOT-FORK
#include <filesystem>
#include <fstream>
#include <thread>
#include <signal.h>

#include <sys/ioctl.h>          // ROBOT-FORK (terminal size)
#include <unistd.h>             // ROBOT-FORK

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#   define NOMINMAX
#endif
#include <windows.h>
#endif

const char * LLAMA_ASCII_LOGO = R"(
▄▄ ▄▄
██ ██
██ ██  ▀▀█▄ ███▄███▄  ▀▀█▄    ▄████ ████▄ ████▄
██ ██ ▄█▀██ ██ ██ ██ ▄█▀██    ██    ██ ██ ██ ██
██ ██ ▀█▄██ ██ ██ ██ ▀█▄██ ██ ▀████ ████▀ ████▀
                                    ██    ██
                                    ▀▀    ▀▀
)";

// ─────────────────────────── ROBOT-FORK: live panel ───────────────────────────
//
// A top status panel drawn with ANSI. We reserve `height` rows at the top of the
// screen and set the scroll region (DECSTBM) to start below them, so the CLI's
// streaming text never overwrites the panel and scrolling leaves it in place.
// Reads are cheap host-side snapshots of the robot context; they run on the main
// thread while the server's inference thread decodes — fine for a debug view.

struct robot_panel_state {
    bool                enabled = false;
    int                 height  = 6;
    int                 rows    = 24;
    int                 cols    = 100;
    llama_context *     ctx     = nullptr;
    const llama_model * model   = nullptr;
    std::string         probe_row = "probes:";   // cached; probe_eval only runs at idle
};
static robot_panel_state g_robot_panel;

static void robot_panel_term_size(int * rows, int * cols) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0) {
        *rows = ws.ws_row; *cols = ws.ws_col;
    } else { *rows = 24; *cols = 100; }
}

// top class + confidence for one probe (softmax over the head's logits)
static bool robot_panel_probe_top(llama_context * ctx, const llama_model * m, int tap,
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

// write one panel row (absolute position, cleared), truncated to terminal width
static void robot_panel_row(int row, const std::string & s) {
    std::string t = s;
    if ((int) t.size() > g_robot_panel.cols) t = t.substr(0, g_robot_panel.cols);
    printf("\x1b[%d;1H\x1b[2K%s", row, t.c_str());
}

// with_probes=false skips llama_robot_probe_eval (which runs a compute graph on
// the backend). NEVER pass true while the server's inference thread may be
// decoding — concurrent backend use corrupts the Metal command queue. Live
// per-token repaints pass false and reuse the cached probe row; probes are
// refreshed only at turn boundaries when the inference thread is idle.
static void robot_panel_draw(bool with_probes) {
    if (!g_robot_panel.enabled || !g_robot_panel.ctx) return;
    llama_context *     ctx = g_robot_panel.ctx;
    const llama_model * m   = g_robot_panel.model;
    char buf[512];

    printf("\x1b" "7");   // save cursor + attrs

    // row 1: reverse-video title bar
    {
        snprintf(buf, sizeof(buf), " therobot live state | memory: %d | %s",
                 llama_robot_memory_count(ctx),
                 llama_robot_delta_enabled(ctx) ? "delta ON" : "delta off");
        std::string s = "\x1b[7m";
        s += buf;
        for (int i = (int) strlen(buf); i < g_robot_panel.cols; ++i) s += ' ';
        s += "\x1b[0m";
        printf("\x1b[1;1H\x1b[2K%s", s.c_str());
    }

    // row 2: modulator channels
    {
        std::string s = "m:";
        int md = llama_robot_mod_dim(m);
        if (md > 0) {
            std::vector<float> mv(md);
            llama_robot_mod_get(ctx, mv.data());
            for (int i = 0; i < md; ++i) {
                const char * n = llama_robot_mod_channel(m, i);
                snprintf(buf, sizeof(buf), " %s=%+.2f", n ? n : "?", mv[i]);
                s += buf;
            }
        }
        robot_panel_row(2, s);
    }

    // row 3: tap probes (top class per attribute). Only re-evaluate (backend
    // compute) when idle; otherwise reuse the cached row from the last turn.
    if (with_probes) {
        std::string s = "probes:";
        for (int t = 0; t < llama_robot_tap_count(m); ++t) {
            snprintf(buf, sizeof(buf), " %s[", llama_robot_tap_name(m, t)); s += buf;
            for (int a = 0; a < llama_robot_tap_attr_count(m, t); ++a) {
                const char * attr = llama_robot_tap_attr(m, t, a);
                int c; float cf;
                if (robot_panel_probe_top(ctx, m, t, attr, &c, &cf)) {
                    snprintf(buf, sizeof(buf), "%s=%d@%.2f ", attr, c, cf); s += buf;
                }
            }
            if (!s.empty() && s.back() == ' ') s.pop_back();
            s += "]";
        }
        g_robot_panel.probe_row = s;
    }
    robot_panel_row(3, g_robot_panel.probe_row);

    // row 4: episodic memory list (newest first): #idx(salience@age)
    {
        int nmem = llama_robot_memory_count(ctx);
        std::string s = "mem:";
        int show = nmem < 6 ? nmem : 6;
        for (int k = 0; k < show; ++k) {
            int idx = nmem - 1 - k;
            float sal; uint64_t age;
            if (llama_robot_memory_get(ctx, idx, &sal, nullptr, &age)) {
                snprintf(buf, sizeof(buf), " #%d(%.1f@%llut)", idx, sal, (unsigned long long) age);
                s += buf;
            }
        }
        if (nmem > show) { snprintf(buf, sizeof(buf), " +%d older", nmem - show); s += buf; }
        if (nmem == 0)   s += " (none)";
        robot_panel_row(4, s);
    }

    // row 5: recall magnitude + delta keep-rate
    {
        std::string s = "recall:";
        int md = llama_robot_mod_dim(m);
        if (md > 0) {
            std::vector<float> r(md);
            if (llama_robot_memory_recall(ctx, r.data())) {
                float nr = 0; for (float v : r) nr += v * v; nr = std::sqrt(nr);
                snprintf(buf, sizeof(buf), " ||recall||=%.3f", nr); s += buf;
            }
        }
        if (llama_robot_delta_enabled(ctx)) {
            snprintf(buf, sizeof(buf), "   delta keep=%.2f (%llu tok)",
                     llama_robot_delta_keep_rate(ctx),
                     (unsigned long long) llama_robot_delta_tokens(ctx));
            s += buf;
        }
        robot_panel_row(5, s);
    }

    // row 6: separator
    {
        std::string s(g_robot_panel.cols, '-');
        printf("\x1b[6;1H\x1b[2K%s", s.c_str());
    }

    printf("\x1b" "8");   // restore cursor + attrs
    fflush(stdout);
}

// clear screen, park the panel at the top, and confine scrolling below it
static void robot_panel_enable(llama_context * ctx) {
    if (ctx == nullptr) return;
    const llama_model * m = llama_get_model(ctx);
    if (!llama_robot_enabled(m)) return;      // stock model → behave as llama-cli
    g_robot_panel.enabled = true;
    g_robot_panel.ctx     = ctx;
    g_robot_panel.model   = m;
    robot_panel_term_size(&g_robot_panel.rows, &g_robot_panel.cols);
    printf("\x1b[2J\x1b[H");                                       // clear
    printf("\x1b[%d;%dr", g_robot_panel.height + 1, g_robot_panel.rows); // scroll region
    printf("\x1b[%d;1H", g_robot_panel.height + 1);               // cursor into region
    robot_panel_draw(false);   // no decode has run yet — nothing to probe
    printf("\x1b[%d;1H", g_robot_panel.height + 1);
    fflush(stdout);
}

static void robot_panel_disable() {
    if (!g_robot_panel.enabled) return;
    printf("\x1b[r");                              // reset scroll region
    printf("\x1b[%d;1H", g_robot_panel.rows);      // cursor to bottom
    fflush(stdout);
    g_robot_panel.enabled = false;
}
// ─────────────────────────── end ROBOT-FORK panel ─────────────────────────────

static std::atomic<bool> g_is_interrupted = false;
static bool should_stop() {
    return g_is_interrupted.load();
}

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__)) || defined (_WIN32)
static void signal_handler(int) {
    if (g_is_interrupted.load()) {
        // second Ctrl+C - exit immediately
        // make sure to clear colors before exiting (not using LOG or console.cpp here to avoid deadlock)
        fprintf(stdout, "\033[0m\n");
        fflush(stdout);
        std::exit(130);
    }
    g_is_interrupted.store(true);
}
#endif

struct cli_context {
    server_context ctx_server;
    json messages = json::array();
    std::vector<raw_buffer> input_files;
    task_params defaults;
    bool verbose_prompt;

    // thread for showing "loading" animation
    std::atomic<bool> loading_show;

    cli_context(const common_params & params) {
        defaults.sampling    = params.sampling;
        defaults.speculative = params.speculative;
        defaults.n_keep      = params.n_keep;
        defaults.n_predict   = params.n_predict;
        defaults.antiprompt  = params.antiprompt;

        defaults.stream = true; // make sure we always use streaming mode
        defaults.timings_per_token = true; // in order to get timings even when we cancel mid-way
        // defaults.return_progress = true; // TODO: show progress

        verbose_prompt = params.verbose_prompt;
    }

    std::string generate_completion(result_timings & out_timings) {
        server_response_reader rd = ctx_server.get_response_reader();
        auto chat_params = format_chat();
        {
            // TODO: reduce some copies here in the future
            server_task task = server_task(SERVER_TASK_TYPE_COMPLETION);
            task.id         = rd.get_new_id();
            task.index      = 0;
            task.params     = defaults;           // copy
            task.cli_prompt = chat_params.prompt; // copy
            task.cli_files  = input_files;        // copy
            task.cli        = true;

            // chat template settings
            task.params.chat_parser_params = common_chat_parser_params(chat_params);
            task.params.chat_parser_params.reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
            if (!chat_params.parser.empty()) {
                task.params.chat_parser_params.parser.load(chat_params.parser);
            }

            // Copy the preserved tokens into the sampling params
            const llama_vocab * vocab = llama_model_get_vocab(
                llama_get_model(ctx_server.get_llama_context()));
            for (const auto & token : chat_params.preserved_tokens) {
                auto ids = common_tokenize(vocab, token, false, true);
                if (ids.size() == 1) {
                    task.params.sampling.preserved_tokens.insert(ids[0]);
                }
            }

            // reasoning budget sampler
            if (!chat_params.thinking_end_tag.empty()) {
                task.params.sampling.reasoning_budget_tokens = defaults.sampling.reasoning_budget_tokens;
                task.params.sampling.generation_prompt = chat_params.generation_prompt;

                if (!chat_params.thinking_start_tag.empty()) {
                    task.params.sampling.reasoning_budget_start =
                        common_tokenize(vocab, chat_params.thinking_start_tag, false, true);
                }
                task.params.sampling.reasoning_budget_end =
                    common_tokenize(vocab, chat_params.thinking_end_tag, false, true);
                task.params.sampling.reasoning_budget_forced =
                    common_tokenize(vocab, defaults.sampling.reasoning_budget_message + chat_params.thinking_end_tag, false, true);
            }

            rd.post_task({std::move(task)});
        }

        if (verbose_prompt) {
            console::set_display(DISPLAY_TYPE_PROMPT);
            console::log("%s\n\n", chat_params.prompt.c_str());
            console::set_display(DISPLAY_TYPE_RESET);
        }

        // wait for first result
        console::spinner::start();
        server_task_result_ptr result = rd.next(should_stop);

        while (true) {
            auto res_partial = dynamic_cast<server_task_result_cmpl_partial *>(result.get());
            if (res_partial && res_partial->is_begin) {
                // this is the "send 200 status to client" signal in streaming mode
                // skip, do not stop the spinner
                result = rd.next(should_stop);
            } else {
                console::spinner::stop();
                break;
            }
        }

        std::string curr_content;
        bool is_thinking = false;

        while (result) {
            if (should_stop()) {
                break;
            }
            if (result->is_error()) {
                json err_data = result->to_json();
                if (err_data.contains("message")) {
                    console::error("Error: %s\n", err_data["message"].get<std::string>().c_str());
                } else {
                    console::error("Error: %s\n", err_data.dump().c_str());
                }
                return curr_content;
            }
            auto res_partial = dynamic_cast<server_task_result_cmpl_partial *>(result.get());
            if (res_partial) {
                out_timings = std::move(res_partial->timings);
                for (const auto & diff : res_partial->oaicompat_msg_diffs) {
                    if (!diff.content_delta.empty()) {
                        if (is_thinking) {
                            console::log("\n[End thinking]\n\n");
                            console::set_display(DISPLAY_TYPE_RESET);
                            is_thinking = false;
                        }
                        curr_content += diff.content_delta;
                        console::log("%s", diff.content_delta.c_str());
                        console::flush();
                        robot_panel_draw(false);   // ROBOT-FORK: host-side state only (no backend compute mid-decode)
                    }
                    if (!diff.reasoning_content_delta.empty()) {
                        console::set_display(DISPLAY_TYPE_REASONING);
                        if (!is_thinking) {
                            console::log("[Start thinking]\n");
                        }
                        is_thinking = true;
                        console::log("%s", diff.reasoning_content_delta.c_str());
                        console::flush();
                        robot_panel_draw(false);   // ROBOT-FORK
                    }
                }
            }
            auto res_final = dynamic_cast<server_task_result_cmpl_final *>(result.get());
            if (res_final) {
                out_timings = std::move(res_final->timings);
                break;
            }
            result = rd.next(should_stop);
        }
        g_is_interrupted.store(false);
        // inference thread is now idle → safe to evaluate probes on the backend
        robot_panel_draw(true);   // ROBOT-FORK: full refresh incl. probes
        // server_response_reader automatically cancels pending tasks upon destruction
        return curr_content;
    }

    // TODO: support remote files in the future (http, https, etc)
    std::string load_input_file(const std::string & fname, bool is_media) {
        std::ifstream file = fs_open_ifstream(fname, std::ios::binary);
        if (!file) {
            return "";
        }
        if (is_media) {
            raw_buffer buf;
            buf.assign((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
            input_files.push_back(std::move(buf));
            return get_media_marker();
        } else {
            std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
            return content;
        }
    }

    common_chat_params format_chat() {
        auto meta = ctx_server.get_meta();
        auto & chat_params = meta.chat_params;

        auto caps = common_chat_templates_get_caps(chat_params.tmpls.get());

        common_chat_templates_inputs inputs;
        inputs.messages              = common_chat_msgs_parse_oaicompat(messages);
        inputs.tools                 = {}; // TODO
        inputs.tool_choice           = COMMON_CHAT_TOOL_CHOICE_NONE;
        inputs.json_schema           = ""; // TODO
        inputs.grammar               = ""; // TODO
        inputs.use_jinja             = chat_params.use_jinja;
        inputs.parallel_tool_calls   = caps["supports_parallel_tool_calls"];
        inputs.add_generation_prompt = true;
        inputs.reasoning_format      = COMMON_REASONING_FORMAT_DEEPSEEK;
        inputs.force_pure_content    = chat_params.force_pure_content;
        inputs.enable_thinking       = chat_params.enable_thinking ? common_chat_templates_support_enable_thinking(chat_params.tmpls.get()) : false;

        // Apply chat template to the list of messages
        return common_chat_templates_apply(chat_params.tmpls.get(), inputs);
    }
};

// TODO?: Make this reusable, enums, docs
static const std::array<std::string_view, 8> cmds = {
    "/audio ",
    "/clear",
    "/exit",
    "/glob ",
    "/image ",
    "/read ",
    "/regen",
    "/video ",
};

static std::vector<std::pair<std::string, size_t>> auto_completion_callback(std::string_view line, size_t cursor_byte_pos) {
    std::vector<std::pair<std::string, size_t>> matches;
    std::string cmd;

    if (line.length() > 1 && line.front() == '/' && !std::any_of(cmds.begin(), cmds.end(), [line](std::string_view prefix) {
        return string_starts_with(line, prefix);
    })) {
        auto it = cmds.begin();

        while ((it = std::find_if(it, cmds.end(), [line](std::string_view cmd_line) {
            return string_starts_with(cmd_line, line);
        })) != cmds.end()) {
            matches.emplace_back(*it, it->length());
            ++it;
        }
    } else {
        auto it = std::find_if(cmds.begin(), cmds.end(), [line](std::string_view prefix) {
            return prefix.back() == ' ' && string_starts_with(line, prefix);
        });

        if (it != cmds.end()) {
            cmd = *it;
        }
    }

    if (!cmd.empty() && cmd != "/glob " && line.length() >= cmd.length() && cursor_byte_pos >= cmd.length()) {
        const std::string path_prefix  = std::string(line.substr(cmd.length(), cursor_byte_pos - cmd.length()));
        const std::string path_postfix = std::string(line.substr(cursor_byte_pos));
        auto cur_dir = std::filesystem::current_path();
        std::string cur_dir_str = cur_dir.string();
        std::string expanded_prefix = path_prefix;

#if !defined(_WIN32)
        if (string_starts_with(path_prefix, '~')) {
            const char * home = std::getenv("HOME");
            if (home && home[0]) {
                expanded_prefix = home + path_prefix.substr(1);
            }
        }
        if (string_starts_with(expanded_prefix, '/')) {
#else
        if (std::isalpha(expanded_prefix[0]) && expanded_prefix.find(':') == 1) {
#endif
            cur_dir = std::filesystem::path(expanded_prefix).parent_path();
            cur_dir_str.clear();
        } else if (!path_prefix.empty()) {
            cur_dir /= std::filesystem::path(path_prefix).parent_path();
        }

        std::error_code ec;
        for (const auto & entry : std::filesystem::directory_iterator(cur_dir, ec)) {
            if (ec) {
                break;
            }
            if (!entry.exists(ec)) {
                ec.clear();
                continue;
            }

            const std::string path_full = entry.path().string();
            std::string path_entry = !cur_dir_str.empty() && string_starts_with(path_full, cur_dir_str) ? path_full.substr(cur_dir_str.length() + 1) : path_full;

            if (entry.is_directory(ec)) {
                path_entry.push_back(std::filesystem::path::preferred_separator);
            }

            if (expanded_prefix.empty() || string_starts_with(path_entry, expanded_prefix)) {
                const std::string updated_line = cmd + path_entry;
                matches.emplace_back(updated_line + path_postfix, updated_line.length());
            }

            if (ec) {
                ec.clear();
            }
        }

        if (matches.empty()) {
            const std::string updated_line = cmd + path_prefix;
            matches.emplace_back(updated_line + path_postfix, updated_line.length());
        }

        // Add the longest common prefix
        if (!expanded_prefix.empty() && matches.size() > 1) {
            const std::string_view match0(matches[0].first);
            const std::string_view match1(matches[1].first);
            auto it = std::mismatch(match0.begin(), match0.end(), match1.begin(), match1.end());
            size_t len = it.first - match0.begin();

            for (size_t i = 2; i < matches.size(); ++i) {
                const std::string_view matchi(matches[i].first);
                auto cmp = std::mismatch(match0.begin(), match0.end(), matchi.begin(), matchi.end());
                len = std::min(len, static_cast<size_t>(cmp.first - match0.begin()));
            }

            const std::string updated_line = std::string(match0.substr(0, len));
            matches.emplace_back(updated_line + path_postfix, updated_line.length());
        }

        std::sort(matches.begin(), matches.end(), [](const auto & a, const auto & b) {
            return a.first.compare(0, a.second, b.first, 0, b.second) < 0;
        });
    }

    return matches;
}

static constexpr size_t FILE_GLOB_MAX_RESULTS = 100;

// satisfies -Wmissing-declarations
int llama_robot_cli(int argc, char ** argv);

int llama_robot_cli(int argc, char ** argv) {
    common_params params;

    params.verbosity = LOG_LEVEL_ERROR; // by default, less verbose logs

    common_init();

    if (!common_params_parse(argc, argv, params, LLAMA_EXAMPLE_CLI)) {
        return 1;
    }

    // TODO: maybe support it later?
    if (params.conversation_mode == COMMON_CONVERSATION_MODE_DISABLED) {
        console::error("--no-conversation is not supported by llama-cli\n");
        console::error("please use llama-completion instead\n");
    }

    // struct that contains llama context and inference
    cli_context ctx_cli(params);

    llama_backend_init();
    llama_numa_init(params.numa);

    // TODO: avoid using atexit() here by making `console` a singleton
    console::init(params.simple_io, params.use_color);
    atexit([]() { console::cleanup(); });

    console::set_display(DISPLAY_TYPE_RESET);
    console::set_completion_callback(auto_completion_callback);

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
    struct sigaction sigint_action;
    sigint_action.sa_handler = signal_handler;
    sigemptyset (&sigint_action.sa_mask);
    sigint_action.sa_flags = 0;
    sigaction(SIGINT, &sigint_action, NULL);
    sigaction(SIGTERM, &sigint_action, NULL);
#elif defined (_WIN32)
    auto console_ctrl_handler = +[](DWORD ctrl_type) -> BOOL {
        return (ctrl_type == CTRL_C_EVENT) ? (signal_handler(SIGINT), true) : false;
    };
    SetConsoleCtrlHandler(reinterpret_cast<PHANDLER_ROUTINE>(console_ctrl_handler), true);
#endif

    console::log("\nLoading model... "); // followed by loading animation
    console::spinner::start();
    if (!ctx_cli.ctx_server.load_model(params)) {
        console::spinner::stop();
        console::error("\nFailed to load the model\n");
        return 1;
    }

    ctx_cli.defaults.sampling = params.sampling;

    console::spinner::stop();
    console::log("\n");

    std::thread inference_thread([&ctx_cli]() {
        ctx_cli.ctx_server.start_loop();
    });

    auto inf = ctx_cli.ctx_server.get_meta();
    std::string modalities = "text";
    if (inf.has_inp_image) {
        modalities += ", vision";
    }
    if (inf.has_inp_audio) {
        modalities += ", audio";
    }

    auto add_system_prompt = [&]() {
        if (!params.system_prompt.empty()) {
            ctx_cli.messages.push_back({
                {"role",    "system"},
                {"content", params.system_prompt}
            });
        }
    };
    add_system_prompt();

    // ROBOT-FORK: park the live status panel at the top of the terminal (no-op
    // for a stock model). Do this before printing the banner so the banner and
    // everything after it flow inside the scroll region, under the panel.
    robot_panel_enable(ctx_cli.ctx_server.get_llama_context());

    console::log("\n");
    console::log("%s\n", LLAMA_ASCII_LOGO);
    console::log("build      : %s\n", inf.build_info.c_str());
    console::log("model      : %s\n", inf.model_name.c_str());
    if (!inf.model_ftype.empty()) {
        console::log("ftype      : %s\n", inf.model_ftype.c_str());
    }
    console::log("modalities : %s\n", modalities.c_str());
    if (g_robot_panel.enabled) {
        console::log("therobot   : live panel ON (top of screen)\n");
    }
    if (!params.system_prompt.empty()) {
        console::log("using custom system prompt\n");
    }
    console::log("\n");
    console::log("available commands:\n");
    console::log("  /exit or Ctrl+C     stop or exit\n");
    console::log("  /regen              regenerate the last response\n");
    console::log("  /clear              clear the chat history\n");
    console::log("  /read <file>        add a text file\n");
    console::log("  /glob <pattern>     add text files using globbing pattern\n");
    if (inf.has_inp_image) {
        console::log("  /image <file>       add an image file\n");
    }
    if (inf.has_inp_audio) {
        console::log("  /audio <file>       add an audio file\n");
    }
    if (inf.has_inp_video) {
        console::log("  /video <file>       add a video file\n");
    }
    console::log("\n");

    // interactive loop
    std::string cur_msg;

    auto add_text_file = [&](const std::string & fname) -> bool {
        std::string marker = ctx_cli.load_input_file(fname, false);
        if (marker.empty()) {
            console::error("file does not exist or cannot be opened: '%s'\n", fname.c_str());
            return false;
        }
        if (inf.fim_sep_token != LLAMA_TOKEN_NULL) {
            cur_msg += common_token_to_piece(ctx_cli.ctx_server.get_llama_context(), inf.fim_sep_token, true);
            cur_msg += fname;
            cur_msg.push_back('\n');
        } else {
            cur_msg += "--- File: ";
            cur_msg += fname;
            cur_msg += " ---\n";
        }
        cur_msg += marker;
        console::log("Loaded text from '%s'\n", fname.c_str());
        return true;
    };

    while (true) {
        std::string buffer;
        console::set_display(DISPLAY_TYPE_USER_INPUT);
        robot_panel_draw(true);   // ROBOT-FORK: idle → full refresh incl. probes before prompting
        if (params.prompt.empty()) {
            console::log("\n> ");
            std::string line;
            bool another_line = true;
            do {
                another_line = console::readline(line, params.multiline_input);
                buffer += line;
            } while (another_line);
        } else {
            // process input prompt from args
            for (auto & fname : params.image) {
                std::string marker = ctx_cli.load_input_file(fname, true);
                if (marker.empty()) {
                    console::error("file does not exist or cannot be opened: '%s'\n", fname.c_str());
                    break;
                }
                console::log("Loaded media from '%s'\n", fname.c_str());
                cur_msg += marker;
            }
            buffer = params.prompt;
            if (buffer.size() > 500) {
                console::log("\n> %s ... (truncated)\n", buffer.substr(0, 500).c_str());
            } else {
                console::log("\n> %s\n", buffer.c_str());
            }
            params.prompt.clear(); // only use it once
        }
        console::set_display(DISPLAY_TYPE_RESET);
        console::log("\n");

        if (should_stop()) {
            g_is_interrupted.store(false);
            break;
        }

        // remove trailing newline
        if (!buffer.empty() &&buffer.back() == '\n') {
            buffer.pop_back();
        }

        // skip empty messages
        if (buffer.empty()) {
            continue;
        }

        bool add_user_msg = true;

        // process commands
        if (string_starts_with(buffer, "/exit")) {
            break;
        } else if (string_starts_with(buffer, "/regen")) {
            if (ctx_cli.messages.size() >= 2) {
                size_t last_idx = ctx_cli.messages.size() - 1;
                ctx_cli.messages.erase(last_idx);
                add_user_msg = false;
            } else {
                console::error("No message to regenerate.\n");
                continue;
            }
        } else if (string_starts_with(buffer, "/clear")) {
            ctx_cli.messages.clear();
            add_system_prompt();

            ctx_cli.input_files.clear();
            console::log("Chat history cleared.\n");
            continue;
        } else if (
                (string_starts_with(buffer, "/image ") && inf.has_inp_image) ||
                (string_starts_with(buffer, "/audio ") && inf.has_inp_audio) ||
                (string_starts_with(buffer, "/video ") && inf.has_inp_video)) {
            // just in case (bad copy-paste for example), we strip all trailing/leading spaces
            std::string fname = string_strip(buffer.substr(7));
            std::string marker = ctx_cli.load_input_file(fname, true);
            if (marker.empty()) {
                console::error("file does not exist or cannot be opened: '%s'\n", fname.c_str());
                continue;
            }
            cur_msg += marker;
            console::log("Loaded media from '%s'\n", fname.c_str());
            continue;
        } else if (string_starts_with(buffer, "/read ")) {
            std::string fname = string_strip(buffer.substr(6));
            add_text_file(fname);
            continue;
        } else if (string_starts_with(buffer, "/glob ")) {
            std::error_code ec;
            size_t count = 0;
            auto curdir = std::filesystem::current_path();
            std::string pattern = string_strip(buffer.substr(6));
            std::filesystem::path rel_path;

            auto startglob = pattern.find_first_of("![*?");
            if (startglob != std::string::npos && startglob != 0) {
                auto endpath = pattern.substr(0, startglob).find_last_of('/');
                if (endpath != std::string::npos) {
                    std::string rel_pattern = pattern.substr(0, endpath);
#if !defined(_WIN32)
                    if (string_starts_with(rel_pattern, '~')) {
                        const char * home = std::getenv("HOME");
                        if (home && home[0]) {
                            rel_pattern = home + rel_pattern.substr(1);
                        }
                    }
#endif
                    rel_path = rel_pattern;
                    pattern.erase(0, endpath + 1);
                    curdir /= rel_path;
                }
            }

            for (const auto & entry : std::filesystem::recursive_directory_iterator(curdir,
                    std::filesystem::directory_options::skip_permission_denied, ec)) {
                if (!entry.is_regular_file()) {
                    continue;
                }

                std::string rel = std::filesystem::relative(entry.path(), curdir, ec).string();
                if (ec) {
                    ec.clear();
                    continue;
                }
                std::replace(rel.begin(), rel.end(), '\\', '/');

                if (!glob_match(pattern, rel)) {
                    continue;
                }

                if (!add_text_file((rel_path / rel).string())) {
                    continue;
                }

                if (++count >= FILE_GLOB_MAX_RESULTS) {
                    console::error("Maximum number of globbed files allowed (%zu) reached.\n", FILE_GLOB_MAX_RESULTS);
                    break;
                }
            }
            continue;
        } else {
            // not a command
            cur_msg += buffer;
        }

        // generate response
        if (add_user_msg) {
            ctx_cli.messages.push_back({
                {"role",    "user"},
                {"content", cur_msg}
            });
            cur_msg.clear();
        }
        result_timings timings;
        std::string assistant_content = ctx_cli.generate_completion(timings);
        ctx_cli.messages.push_back({
            {"role",    "assistant"},
            {"content", assistant_content}
        });
        console::log("\n");

        if (params.show_timings) {
            console::set_display(DISPLAY_TYPE_INFO);
            console::log("\n");
            console::log("[ Prompt: %.1f t/s | Generation: %.1f t/s ]\n", timings.prompt_per_second, timings.predicted_per_second);
            console::set_display(DISPLAY_TYPE_RESET);
        }

        if (params.single_turn) {
            break;
        }
    }

    console::set_display(DISPLAY_TYPE_RESET);

    robot_panel_disable();   // ROBOT-FORK: release the scroll region

    console::log("\nExiting...\n");
    ctx_cli.ctx_server.terminate();
    inference_thread.join();

    // bump the log level to display timings
    common_log_set_verbosity_thold(LOG_LEVEL_INFO);
    common_memory_breakdown_print(ctx_cli.ctx_server.get_llama_context());

    return 0;
}
