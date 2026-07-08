#pragma once

// therobot runtime extension — the standardized readout layer (semvec)
//
// Implements the optional `semvec` feature (convert/docs/semvec-runtime-spec.md,
// extraction-v1 §4.4/§4.5): per admitted site, an encoder E (proj: residual
// slice → the versioned, donor-independent semantic vector), per-axis
// calibration, and a write-calibrated decoder G (overlay: semvec deltas →
// slice deltas).
//
//   read:    s  = h_slice · E + calib_bias          (one host-side matvec)
//   query:   cos(s_block, q)                        (host-side, any text via
//                                                    the frozen embedder+basis)
//   overlay: h_slice' = h_slice + scale · (Δs · G)  (compiled to an ephemeral
//                                                    steer-only shim, spliced
//                                                    by the E3 machinery)
//
// Δs = 0 (or no overlay set) is exactly the identity — the graft invariant.
// Sites resolve onto the E2 tap machinery at spec-load time
// (llama-robot-hparams.cpp), so the read path adds no graph code at all.
//
// therobot-fork-only code; not included by stock translation units.

#include "llama-robot-hparams.h"

#include <cstdint>

struct llama_model;
struct llama_robot_model_iface;
struct llama_hparams;

// validate materialized semvec tensors against the declared sites:
// proj [d, D], calib [D, 2] with scale ∈ {0,1} and zeroed unadmitted proj
// columns; overlay [D, d] (optional) with G·E == I on writable rows (±1e-3).
// Throws std::runtime_error on violations. Called from the model wrapper's
// load_tensors, after llama_robot_materialize_ext_tensors.
void llama_robot_validate_semvec(const llama_robot_model_iface & iface, const llama_hparams & hparams);
