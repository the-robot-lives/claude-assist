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

#ifdef __cplusplus
}
#endif
