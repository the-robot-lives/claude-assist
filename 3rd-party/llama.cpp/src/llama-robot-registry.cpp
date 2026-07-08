// therobot runtime extension — accretion serving implementation (E8)

#include "llama-robot-registry.h"

#include "llama-robot.h"

#include "llama-context.h"
#include "llama-impl.h"
#include "llama-model.h"
#include "llama-robot-model.h"
#include "llama-robot-shim.h"

#include <nlohmann/json.hpp>

#include <algorithm>
#include <fstream>
#include <set>

using json = nlohmann::ordered_json;

llama_robot_registry::~llama_robot_registry() {
    for (auto & e : entries) {
        llama_robot_shim_free(e.shim);
    }
}

//
// registry loading
//

llama_robot_registry * llama_robot_registry_load(const llama_model * model, const char * path) {
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(model);
    if (iface == nullptr) {
        LLAMA_LOG_ERROR("therobot: registries require a therobot model\n");
        return nullptr;
    }

    std::ifstream f(path);
    if (!f) {
        LLAMA_LOG_ERROR("therobot: cannot open registry '%s'\n", path);
        return nullptr;
    }

    json j;
    try {
        f >> j;
    } catch (const std::exception & e) {
        LLAMA_LOG_ERROR("therobot: registry '%s' is not valid JSON: %s\n", path, e.what());
        return nullptr;
    }

    try {
        if (j.value("spec_version", 0) != (int) LLAMA_ROBOT_SPEC_VERSION) {
            LLAMA_LOG_ERROR("therobot: registry spec_version %d, runtime implements %u\n",
                    j.value("spec_version", 0), LLAMA_ROBOT_SPEC_VERSION);
            return nullptr;
        }

        const std::string reg_model = j.value("model", "");
        if (!reg_model.empty() && !iface->robot.convert_lockfile_hash.empty() &&
            reg_model != iface->robot.convert_lockfile_hash) {
            LLAMA_LOG_WARN("therobot: registry admission scores were measured against model '%s', this model is '%s'\n",
                    reg_model.c_str(), iface->robot.convert_lockfile_hash.c_str());
        }

        auto reg = std::make_unique<llama_robot_registry>();
        reg->model = model;
        {
            const std::string p(path);
            const size_t slash = p.find_last_of("/\\");
            reg->dir = slash == std::string::npos ? "." : p.substr(0, slash);
        }

        for (const auto & js : j.at("shims")) {
            llama_robot_registry::entry e;
            e.name        = js.at("name").get<std::string>();
            e.file        = js.at("file").get<std::string>();
            e.selectivity = js.value("selectivity", 0.0f);
            for (const auto & t : js.value("tags",      json::array())) { e.tags.push_back(t.get<std::string>()); }
            for (const auto & t : js.value("depends",   json::array())) { e.depends.push_back(t.get<std::string>()); }
            for (const auto & t : js.value("conflicts", json::array())) { e.conflicts.push_back(t.get<std::string>()); }
            reg->entries.push_back(std::move(e));
        }

        LLAMA_LOG_INFO("therobot: registry '%s' — %zu admitted shim module(s)\n", path, reg->entries.size());
        return reg.release();
    } catch (const std::exception & e) {
        LLAMA_LOG_ERROR("therobot: registry '%s' is malformed: %s\n", path, e.what());
        return nullptr;
    }
}

void llama_robot_registry_free(llama_robot_registry * reg) {
    delete reg;
}

int32_t llama_robot_registry_count(const llama_robot_registry * reg) {
    return reg == nullptr ? 0 : (int32_t) reg->entries.size();
}

const char * llama_robot_registry_name(const llama_robot_registry * reg, int32_t i) {
    if (reg == nullptr || i < 0 || (size_t) i >= reg->entries.size()) {
        return nullptr;
    }
    return reg->entries[i].name.c_str();
}

float llama_robot_registry_selectivity(const llama_robot_registry * reg, int32_t i) {
    if (reg == nullptr || i < 0 || (size_t) i >= reg->entries.size()) {
        return 0.0f;
    }
    return reg->entries[i].selectivity;
}

//
// per-request routing
//

static llama_robot_registry::entry * robot_reg_find(llama_robot_registry & reg, const std::string & name) {
    for (auto & e : reg.entries) {
        if (e.name == name) {
            return &e;
        }
    }
    return nullptr;
}

int32_t llama_robot_route(llama_context * ctx, llama_robot_registry * reg,
        const char ** tags, int32_t n_tags) {
    if (ctx == nullptr || reg == nullptr || reg->model != &ctx->get_model()) {
        LLAMA_LOG_ERROR("therobot: route: registry/context/model mismatch\n");
        return -1;
    }

    // 1. tag selection
    std::set<std::string> want;
    for (auto & e : reg->entries) {
        for (int32_t t = 0; t < n_tags; ++t) {
            if (tags[t] != nullptr &&
                std::find(e.tags.begin(), e.tags.end(), tags[t]) != e.tags.end()) {
                want.insert(e.name);
                break;
            }
        }
    }

    // 2. dependency closure (the registry's dependency graph)
    for (bool grew = true; grew; ) {
        grew = false;
        for (const auto & name : std::set<std::string>(want)) {
            const auto * e = robot_reg_find(*reg, name);
            if (e == nullptr) {
                continue;
            }
            for (const auto & dep : e->depends) {
                if (robot_reg_find(*reg, dep) == nullptr) {
                    LLAMA_LOG_ERROR("therobot: route: '%s' depends on '%s', which is not in the registry\n",
                            name.c_str(), dep.c_str());
                    return -1;
                }
                if (want.insert(dep).second) {
                    LLAMA_LOG_INFO("therobot: route: auto-including dependency '%s' (needed by '%s')\n",
                            dep.c_str(), name.c_str());
                    grew = true;
                }
            }
        }
    }

    // 3. conflict filter, in registry (admission) order — first admitted wins;
    //    dependents of a dropped module drop with it
    for (bool changed = true; changed; ) {
        changed = false;
        std::set<std::string> kept;
        for (const auto & e : reg->entries) {
            if (want.count(e.name) == 0) {
                continue;
            }
            bool conflicted = false;
            for (const auto & k : kept) {
                const auto * ke = robot_reg_find(*reg, k);
                if (std::find(e.conflicts.begin(), e.conflicts.end(), k) != e.conflicts.end() ||
                    (ke != nullptr && std::find(ke->conflicts.begin(), ke->conflicts.end(), e.name) != ke->conflicts.end())) {
                    LLAMA_LOG_WARN("therobot: route: skipping '%s' — conflicts with selected '%s'\n",
                            e.name.c_str(), k.c_str());
                    conflicted = true;
                    break;
                }
            }
            bool deps_ok = true;
            for (const auto & dep : e.depends) {
                deps_ok &= want.count(dep) > 0;
            }
            if (conflicted || !deps_ok) {
                want.erase(e.name);
                changed = true;
            } else {
                kept.insert(e.name);
            }
        }
    }

    // 4. hot-swap without context teardown: detach registry shims that fell
    //    out of the selection (dependency-safe order: retry until stable)
    if (ctx->robot_state) {
        for (bool progressed = true; progressed; ) {
            progressed = false;
            std::vector<std::string> to_detach;
            for (const auto * s : ctx->robot_state->shims) {
                const auto * e = robot_reg_find(*reg, s->name);
                if (e != nullptr && e->shim == s && want.count(s->name) == 0) {
                    to_detach.push_back(s->name);
                }
            }
            for (const auto & name : to_detach) {
                progressed |= llama_robot_shim_detach(ctx, name.c_str());
            }
            if (to_detach.empty()) {
                break;
            }
        }
    }

    // 5. attach the selection, dependencies first (retry until fixpoint);
    //    module files stream in lazily on first use — the core stays resident
    int32_t attached = 0;
    for (bool progressed = true; progressed && !want.empty(); ) {
        progressed = false;
        for (auto it = want.begin(); it != want.end(); ) {
            auto * e = robot_reg_find(*reg, *it);
            if (e->shim == nullptr) {
                const std::string path = reg->dir + "/" + e->file;
                e->shim = llama_robot_shim_init(reg->model, path.c_str());
                if (e->shim == nullptr) {
                    LLAMA_LOG_ERROR("therobot: route: failed to load module '%s'\n", path.c_str());
                    return -1;
                }
            }
            bool already = false;
            if (ctx->robot_state) {
                for (const auto * s : ctx->robot_state->shims) {
                    already |= (s == e->shim);
                }
            }
            if (already || llama_robot_shim_attach(ctx, e->shim)) {
                if (!already) {
                    attached++;
                }
                it = want.erase(it);
                progressed = true;
            } else {
                ++it; // likely waiting on a dependency later in the set
            }
        }
    }
    if (!want.empty()) {
        LLAMA_LOG_ERROR("therobot: route: %zu selected module(s) could not be attached\n", want.size());
        return -1;
    }

    const int32_t n_routed = ctx->robot_state ? (int32_t) ctx->robot_state->shims.size() : 0;
    LLAMA_LOG_INFO("therobot: routed %d module(s) (%d newly attached)\n", n_routed, attached);
    return n_routed;
}

//
// memory trace export — raw material for the offline consolidation pipeline
//

bool llama_robot_memory_export(llama_context * ctx, const char * path) {
    if (ctx == nullptr || path == nullptr || !ctx->robot_state) {
        return false;
    }
    const auto * iface = dynamic_cast<const llama_robot_model_iface *>(&ctx->get_model());
    if (iface == nullptr) {
        return false;
    }
    const auto & st = *ctx->robot_state;

    json j;
    j["spec_version"] = LLAMA_ROBOT_SPEC_VERSION;
    j["model"]        = iface->robot.convert_lockfile_hash;
    j["donor"]        = iface->robot.donor_id;
    j["clock"]        = st.mem_clock;
    j["key_dim"]      = iface->robot.memory.key_dim;
    j["value_dim"]    = iface->robot.memory.value_dim;
    j["m"]            = st.m;
    json entries = json::array();
    for (const auto & e : st.mem) {
        json je;
        je["salience"]  = e.salience;
        je["timestamp"] = e.timestamp;
        je["key"]       = e.key;
        je["value"]     = e.value;
        entries.push_back(std::move(je));
    }
    j["memories"] = std::move(entries);

    std::ofstream f(path);
    if (!f) {
        LLAMA_LOG_ERROR("therobot: cannot write memory trace '%s'\n", path);
        return false;
    }
    f << j.dump(2) << "\n";
    LLAMA_LOG_INFO("therobot: exported %zu memory trace entrie(s) to '%s'\n", st.mem.size(), path);
    return true;
}
