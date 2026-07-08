#pragma once

// therobot runtime extension — episodic memory (E5, planning §F, spec §1.5)
//
// Pure runtime component, CPU-side, no ggml changes: a per-context store of
// {key, value, salience, timestamp} where keys/values are memory-head
// projections of the concatenated bottleneck summaries (the tap slices, in
// declaration order — requires the taps feature).
//
//   write gate:  salience = w₀·surprise + w₁·‖m‖, where surprise is the
//                −log p of the incoming token under the previous decode's
//                distribution. Auto-writes require salience > 0 and
//                salience ≥ quantile(threshold_quantile) over a running
//                window (after a short warmup). Explicit writes bypass the
//                gate (llama_robot_memory_write).
//   read:        query = key-projection of the current summary; entries score
//                cos(query, key) · 2^(−Δtokens / decay_halflife); the top-k
//                weighted mean of values is the recall vector.
//   inject:      recall (in modulator space — value_dim must equal the
//                modulator dim, checked at load) is added to the modulator
//                update's pre-activation on the *next* decode: past events
//                color present processing, one step behind, without any
//                weight update. Gated shims see it through m.
//   eviction:    capacity-bounded; the entry with the lowest
//                salience · 2^(−Δ/halflife) retention score is evicted.
//
// The store is session state, never file content; it rides the
// llama_robot_session_* checkpoint blob.
//
// therobot-fork-only code.

#include <cstdint>
#include <vector>

struct llama_ubatch;
class  llm_graph_result;
struct llama_robot_context_state;
struct llama_robot_model_iface;

// true if the model carries the memory feature
bool llama_robot_memory_enabled(const llama_robot_model_iface & iface);

// Σ declared bottleneck widths — the summary (memory-head input) dimension
uint32_t llama_robot_memory_summary_dim(const llama_robot_model_iface & iface);

// load-time validation of memory-head tensors (called from validate_grafts)
void llama_robot_memory_validate(const llama_robot_model_iface & iface);

// Per-decode update, called from the capture hook after m/banks are pulled:
// summarizes the decode's tap outputs, runs the salience gate (auto-write),
// refreshes the recall vector for the next decode, and advances the token
// clock. No-op when the model has no memory feature.
void llama_robot_memory_update(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st,
        llm_graph_result * res,
        const llama_ubatch * ubatch);

// Explicit write of the latest summary with the given salience (bypasses the
// gate — the caller decides this moment is noteworthy). False if no decode
// has produced a summary yet.
bool llama_robot_memory_write_now(
        const llama_robot_model_iface & iface,
        llama_robot_context_state & st,
        float salience);
