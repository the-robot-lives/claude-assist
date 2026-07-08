#pragma once

// therobot runtime extension — public C API (E2: bottleneck taps + probes)
//
// Taps are typed bottleneck slices (gguf-extension-spec.md §1.2) that the
// graph builder marks as outputs at each declared cleave point. After any
// llama_decode(), the slice values for the most recent position can be read
// back, and the file's probe heads can be evaluated on demand — probe heads
// execute only when asked (llamacpp-extensions.md §E2).

#include "llama.h"

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// true if the model is a therobot model (any level, including L0)
LLAMA_API bool llama_robot_enabled(const struct llama_model * model);

// number of declared bottleneck taps (0 for stock and L0 files)
LLAMA_API int32_t llama_robot_tap_count(const struct llama_model * model);

// tap metadata; name/point return NULL and width/layer return -1 on bad id
LLAMA_API const char * llama_robot_tap_name (const struct llama_model * model, int32_t tap_id);
LLAMA_API const char * llama_robot_tap_point(const struct llama_model * model, int32_t tap_id);
LLAMA_API int32_t      llama_robot_tap_width(const struct llama_model * model, int32_t tap_id);
LLAMA_API int32_t      llama_robot_tap_layer(const struct llama_model * model, int32_t tap_id);

// read the tap slice for the most recent decoded position into dst
// (llama_robot_tap_width() floats). false if the tap is unknown, disabled,
// or no graph has been computed yet.
LLAMA_API bool llama_robot_tap_read(struct llama_context * ctx, int32_t tap_id, float * dst);

// output dimension of the probe head for (tap, attr), or -1 if that probe is
// not present in the file
LLAMA_API int32_t llama_robot_probe_dim(const struct llama_model * model, int32_t tap_id, const char * attr);

// run the (tap, attr) probe head on the most recent decoded position's slice;
// dst receives llama_robot_probe_dim() floats
LLAMA_API bool llama_robot_probe_eval(struct llama_context * ctx, int32_t tap_id, const char * attr, float * dst);

//
// E3 — shims (slice-scoped behavior-override adapters, spec §4)
//
// Shims load from standalone `therobot-shim` GGUF module files, validate
// against the model's declared bottlenecks, and hot-attach/detach per context.
// Attach and detach take effect on the next decode (the graph is rebuilt).
// A shim must outlive every context it is attached to.
//

struct llama_robot_shim; // opaque

// load + validate a shim module against a therobot model; NULL on failure
LLAMA_API struct llama_robot_shim * llama_robot_shim_init(const struct llama_model * model, const char * path);

// free a shim (detach it from all contexts first)
LLAMA_API void llama_robot_shim_free(struct llama_robot_shim * shim);

// registry metadata (spec §4)
LLAMA_API const char * llama_robot_shim_name       (const struct llama_robot_shim * shim);
LLAMA_API const char * llama_robot_shim_version    (const struct llama_robot_shim * shim);
LLAMA_API const char * llama_robot_shim_effect     (const struct llama_robot_shim * shim);
LLAMA_API const char * llama_robot_shim_target     (const struct llama_robot_shim * shim); // target bottleneck name
LLAMA_API float        llama_robot_shim_selectivity(const struct llama_robot_shim * shim);

// attach: enforces registry metadata — every name in `depends` must already
// be attached, and `conflicts` are checked in both directions
LLAMA_API bool llama_robot_shim_attach(struct llama_context * ctx, const struct llama_robot_shim * shim);

// detach by name: refused while another attached shim depends on it
LLAMA_API bool llama_robot_shim_detach(struct llama_context * ctx, const char * name);

// number of currently attached shims
LLAMA_API int32_t llama_robot_shim_count(const struct llama_context * ctx);

//
// E4 — modulator bus m + session state (spec §1.3/§1.4, planning §A/§B)
//
// m and the leaky state banks update automatically on every decode. m can
// also be read and written directly — that is the priming lever (planning M3:
// induce a bias, watch it decay back toward baseline).
//

// modulator dimension (0 if the model has no modulator) and channel names
LLAMA_API int32_t      llama_robot_mod_dim    (const struct llama_model * model);
LLAMA_API const char * llama_robot_mod_channel(const struct llama_model * model, int32_t i);

// read / write the context's current m (llama_robot_mod_dim() floats).
// Writes take effect on the next decode.
LLAMA_API bool llama_robot_mod_get(struct llama_context * ctx, float * dst);
LLAMA_API bool llama_robot_mod_set(struct llama_context * ctx, const float * src);

// Session state checkpoint (the "mind": m + state banks + episodic store;
// 003 §4). Save returns bytes written (0 on error); size returns the buffer
// size needed; load restores a previously saved blob into a context of the
// same model.
LLAMA_API size_t llama_robot_session_size(struct llama_context * ctx);
LLAMA_API size_t llama_robot_session_save(struct llama_context * ctx, uint8_t * dst, size_t size);
LLAMA_API size_t llama_robot_session_load(struct llama_context * ctx, const uint8_t * src, size_t size);

//
// E5 — episodic memory (spec §1.5, planning §F)
//
// The store updates automatically each decode: bottleneck summaries are
// written when the salience gate fires (surprise + ‖m‖ against a
// quantile-normalized threshold), and a recency-weighted content-addressed
// recall vector is injected into the next decode's modulator update.
//

// number of stored episodic memories (0 for models without the feature)
LLAMA_API int32_t llama_robot_memory_count(const struct llama_context * ctx);

// explicitly write the latest decode's summary with the given salience
// (bypasses the gate — "this moment is noteworthy"); requires ≥1 prior decode
LLAMA_API bool llama_robot_memory_write(struct llama_context * ctx, float salience);

// drop every stored memory (recall fades to zero on the next decode)
LLAMA_API void llama_robot_memory_forget(struct llama_context * ctx);

// current recall vector (llama_robot_mod_dim() floats): what the past is
// whispering into the next decode's modulator update
LLAMA_API bool llama_robot_memory_recall(const struct llama_context * ctx, float * dst);

//
// E6 — delta executor (spec §1.6, proposal 002)
//
// Change-triggered execution at block granularity, batch-1 streaming. OFF by
// default; enabling/disabling takes effect on the next decode. Covered blocks
// compare their input against the input they last fired on; quiet blocks
// contribute their held output. A dense heartbeat sweep every
// `therobot.delta.heartbeat` tokens bounds drift. Fire flags are recorded per
// token — the compute trace 002's tests require.
//

// toggle delta mode on a context (false if the model has no delta feature)
LLAMA_API bool llama_robot_delta_enable(struct llama_context * ctx, bool enable);
LLAMA_API bool llama_robot_delta_enabled(const struct llama_context * ctx);

// number of delta-covered blocks in the model
LLAMA_API int32_t llama_robot_delta_block_count(const struct llama_model * model);

// compute trace: delta-mode tokens processed, per-block fire counts, and the
// keep rate (block executions that actually fired / (tokens · blocks))
LLAMA_API uint64_t llama_robot_delta_tokens(const struct llama_context * ctx);
LLAMA_API uint64_t llama_robot_delta_fires (const struct llama_context * ctx, int32_t block_idx);
LLAMA_API float    llama_robot_delta_keep_rate(const struct llama_context * ctx);

#ifdef __cplusplus
}
#endif
