// therobot runtime extension — shared iterate-until-quiet executor

#include "llama-robot-executor.h"

int32_t llama_robot_executor_run(
        const llama_robot_executor_params & params,
        const std::function<float(int32_t step)> & step,
        bool * converged) {
    int32_t steps = 0;
    int32_t extra_left = -1; // -1: not yet quiet

    while (steps < params.max_steps) {
        const float change = step(steps);
        steps++;

        if (extra_left < 0) {
            if (change <= params.epsilon) {
                extra_left = params.extra_rounds; // quiet — begin re-check rounds
            }
        } else if (change > params.epsilon) {
            extra_left = -1; // a re-check round found new change: back to settling
        }

        if (extra_left == 0) {
            break;
        }
        if (extra_left > 0) {
            extra_left--;
        }
    }

    if (converged != nullptr) {
        *converged = extra_left >= 0;
    }
    return steps;
}
