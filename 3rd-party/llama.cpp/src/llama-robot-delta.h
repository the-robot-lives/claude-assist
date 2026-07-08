#pragma once

// therobot runtime extension — delta executor (E6, proposal 002, spec §1.6)
//
// Change-triggered execution at block granularity, batch-1 single-sequence
// streaming (002's CPU/self-host target). Per token, each covered block
// compares its input against the input it last fired on:
//
//   fire  = step( mean((x − held_in)²) − θ_eff ),
//   θ_eff = θ_base + fatigue − excitability·m
//
// A firing block contributes its fresh output and refreshes its held
// input/output; a quiet block contributes its held output:
//
//   out = held_out + fire · (block(x) − held_out)
//
// A dense heartbeat sweep every `therobot.delta.heartbeat` tokens bounds
// drift (the force flag is pushed as a graph input, sign-biased so
// step(fire + force) needs no in-graph constants). Fire flags are read back
// per token — the compute trace that 002's tests require (per-block fire
// counts, keep rate = effective block-executions / (tokens · blocks)).
//
// v1 semantics note: blocks still *execute*; the fire flag gates whether
// their output enters the stream, which yields exact delta semantics, the
// full trace, and bounded-divergence behavior. Physically skipping the
// computation of quiet blocks is the shared `llama-robot-executor` work that
// E6/E7 converge on (llamacpp-extensions.md §E6/§E7) — same interface,
// deferred. Delta is OFF by default (002's risk table); prompt ubatches
// (T > 1) always run dense.
//
// Coverage is declared by tensor presence: blocks with
// `blk.{L}.robot_delta.theta_base` participate (L ≥ 1 — block 0's input is
// the embedding stream, out of scope for v1). Optional tensors:
// `blk.{L}.robot_delta.fatigue.rho/.gain` (leaky refractory pressure) and
// `robot.delta.excitability.weight` [M,1] (m lowers thresholds — the
// "anxious streams fire easier" coupling; requires the modulator).
//
// therobot-fork-only code.

#include <cstdint>

struct llama_context;
struct llama_hparams;
class  llm_graph_result;
struct llama_robot_model_iface;
struct llama_robot_context_state;

// true if the model carries the delta feature
bool llama_robot_delta_feature(const llama_robot_model_iface & iface);

// covered block ids (presence of blk.{L}.robot_delta.theta_base), ascending
int32_t llama_robot_delta_blocks(const llama_robot_model_iface & iface, uint32_t * layers, int32_t max);

// load-time validation (called from validate_grafts)
void llama_robot_delta_validate(const llama_robot_model_iface & iface, const llama_hparams & hparams);

// size the per-context delta state (called from state prepare)
void llama_robot_delta_prepare(const llama_robot_model_iface & iface, llama_robot_context_state & st, int64_t n_embd);

// post-decode: pull fire flags + refreshed holds, update fatigue, the
// heartbeat counter, and the compute trace (called from the capture hook)
void llama_robot_delta_capture(const llama_robot_model_iface & iface, llama_robot_context_state & st,
        llm_graph_result * res, uint32_t n_tokens);

// true when the next single-token decode must run a dense sweep
bool llama_robot_delta_force_dense(const llama_robot_model_iface & iface, const llama_robot_context_state & st);
