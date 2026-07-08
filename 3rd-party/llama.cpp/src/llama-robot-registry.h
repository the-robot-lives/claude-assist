#pragma once

// therobot runtime extension — accretion serving (E8, proposal 005)
//
// The registry is the module economy's index: admitted shim modules with
// their admission scores, task tags, and the dependency graph, maintained by
// converter tooling as `registry.json` next to the module files:
//
//   {
//     "spec_version": 1,
//     "model": "<therobot.convert.lockfile_hash>",
//     "shims": [
//       { "name": "color-shift", "file": "shims/color-shift.gguf",
//         "tags": ["style", "color"], "selectivity": 0.93,
//         "depends": [], "conflicts": ["color-lock"] }
//     ]
//   }
//
// Per-request routing selects registry shims whose tags intersect the
// request's tags, auto-includes their dependencies, drops conflicting
// selections (first admitted wins), then hot-swaps the context's attached
// set — detaching in dependency-safe order, attaching dependencies first,
// lazily loading module files on first use. The core stays resident; shims
// stream. Manually attached (non-registry) shims are left untouched.
//
// The zero-forgetting invariant (005 test 2): routing to an empty tag set
// restores core-path outputs bit-identical to a never-routed context.
//
// Consolidation *training* happens in the offline Python pipeline — the
// runtime only exports raw material (llama_robot_memory_export) and loads
// its distilled products (shim modules) back through this registry.
//
// therobot-fork-only code; public API surface lives in llama-robot.h.

#include <string>
#include <vector>

struct llama_model;
struct llama_robot_shim;

struct llama_robot_registry {
    const llama_model * model = nullptr;
    std::string dir; // registry file directory (module paths resolve against it)

    struct entry {
        std::string name;
        std::string file;
        std::vector<std::string> tags;
        std::vector<std::string> depends;
        std::vector<std::string> conflicts;
        float selectivity = 0.0f;
        llama_robot_shim * shim = nullptr; // lazily loaded on first routing
    };
    std::vector<entry> entries;

    ~llama_robot_registry();
};
