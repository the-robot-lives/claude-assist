#pragma once

// therobot runtime extension — the shared "iterate until quiet" executor
// (llamacpp-extensions.md §E6/§E7)
//
// E6 and E7 are one control structure: a loop with a change metric, a
// threshold, a step cap, and per-iteration hooks. E6 instantiates it across
// tokens (the decode loop itself is the iteration; each token's fire/hold
// decisions are the step — the degenerate one-step instance), E7 across
// settling rounds over a canvas. Implementing it once concentrates the
// custom-runtime risk exactly as the proposals README prescribes.
//
// therobot-fork-only code.

#include <cstdint>
#include <functional>

struct llama_robot_executor_params {
    int32_t max_steps    = 64;   // hard cap on iterations
    float   epsilon      = 0.0f; // quiet when the step's change metric ≤ ε
    int32_t extra_rounds = 0;    // re-check rounds after quiet (m-scheduled
                                 // settling depth: anxious → more re-checks)
};

// Run `step(i)` (returning its change metric) until quiet, then extra_rounds
// more, bounded by max_steps. Returns the number of steps executed; sets
// *converged (if given) when quiet was reached within the cap.
int32_t llama_robot_executor_run(
        const llama_robot_executor_params & params,
        const std::function<float(int32_t step)> & step,
        bool * converged = nullptr);
