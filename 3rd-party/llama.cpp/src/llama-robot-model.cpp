// therobot runtime extension — model factory, extension tensors, taps (E1/E2)

#include "llama-robot-model.h"

#include "llama-graph.h"
#include "llama-hparams.h"
#include "llama-impl.h"
#include "llama-mmap.h"
#include "llama-model-loader.h"
#include "llama-robot-delta.h"
#include "llama-robot-shim.h"
#include "llama-robot-state.h"

#include "ggml-backend.h"

#include "models/models.h"

// cgraph internals (node array, hash set, use counts) for shim splicing
#include "../ggml/src/ggml-impl.h"

#include <cctype>
#include <cstring>
#include <sstream>
#include <stdexcept>

bool llama_robot_is_ext_tensor(const std::string & name) {
    // global extension tensors: robot.probe.*, robot.mod.*, robot.mem.*,
    // robot.delta.*, robot.settle.*, robot.shim.* (spec §1.2–§1.7, §4)
    if (name.compare(0, 6, "robot.") == 0) {
        return true;
    }
    // per-block extension tensors: blk.{L}.robot_state.*, blk.{L}.robot_film.*,
    // blk.{L}.robot_delta.*
    if (name.compare(0, 4, "blk.") == 0) {
        size_t pos = 4;
        while (pos < name.size() && std::isdigit((unsigned char) name[pos])) {
            pos++;
        }
        if (pos > 4 && pos + 7 <= name.size() && name.compare(pos, 7, ".robot_") == 0) {
            return true;
        }
    }
    return false;
}

ggml_tensor * llama_robot_model_iface::robot_ext_tensor(const std::string & name) const {
    const auto it = robot_ext_data.find(name);
    return it == robot_ext_data.end() ? nullptr : it->second;
}

void llama_robot_claim_ext_tensors(llama_model_loader & ml, std::vector<llama_robot_ext_tensor> & out) {
    for (const auto & it : ml.weights_map) {
        const std::string & name = it.first;
        if (!llama_robot_is_ext_tensor(name)) {
            continue;
        }

        const ggml_tensor * t = it.second.tensor;

        llama_robot_ext_tensor rec;
        rec.name   = name;
        rec.type   = t->type;
        for (int d = 0; d < GGML_MAX_DIMS; ++d) {
            rec.ne[d] = t->ne[d];
        }
        rec.nbytes = ggml_nbytes(t);
        out.push_back(std::move(rec));

        // mirror the loader's skip-unused-tensor bookkeeping so that
        // done_getting_tensors() and load_all_data() accounting stay exact
        ml.size_data -= rec.nbytes;
        ml.n_created++;

        LLAMA_LOG_INFO("therobot: claimed extension tensor %s (%s, %zu bytes)\n",
                name.c_str(), ggml_type_name(rec.type), rec.nbytes);
    }
}

void llama_robot_materialize_ext_tensors(llama_model_loader & ml, llama_robot_model_iface & iface) {
    if (iface.robot_ext_tensors.empty()) {
        return;
    }
    if (ml.files.empty()) {
        LLAMA_LOG_WARN("therobot: no open model files — extension tensors not materialized\n");
        return;
    }

    // create the tensors (no_alloc), back them with a CPU backend buffer —
    // host-readable for probe heads, graph-leaf-capable for E4 subgraphs
    ggml_init_params ip = {
        /*.mem_size   =*/ (iface.robot_ext_tensors.size() + 1) * ggml_tensor_overhead(),
        /*.mem_buffer =*/ nullptr,
        /*.no_alloc   =*/ true,
    };
    iface.robot_ext_ctx.reset(ggml_init(ip));
    if (!iface.robot_ext_ctx) {
        throw std::runtime_error("therobot: failed to allocate extension tensor context");
    }

    std::vector<ggml_tensor *> tensors;
    for (const auto & rec : iface.robot_ext_tensors) {
        int n_dims = 1;
        for (int d = GGML_MAX_DIMS - 1; d > 0; --d) {
            if (rec.ne[d] > 1) { n_dims = d + 1; break; }
        }
        ggml_tensor * t = ggml_new_tensor(iface.robot_ext_ctx.get(), rec.type, n_dims, rec.ne.data());
        if (t == nullptr) {
            throw std::runtime_error(format("therobot: failed to create extension tensor '%s'", rec.name.c_str()));
        }
        ggml_set_name(t, rec.name.c_str());
        tensors.push_back(t);
    }

    ggml_backend_dev_t cpu_dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
    if (cpu_dev == nullptr) {
        throw std::runtime_error("therobot: no CPU backend device found");
    }
    iface.robot_ext_buf.reset(ggml_backend_alloc_ctx_tensors_from_buft(iface.robot_ext_ctx.get(), ggml_backend_dev_buffer_type(cpu_dev)));
    if (!iface.robot_ext_buf) {
        throw std::runtime_error("therobot: failed to allocate extension tensor buffer");
    }

    // read straight from the (still open) model files — independent of the
    // mmap fragments that load_all_data may already have released
    std::vector<uint8_t> read_buf;
    for (size_t i = 0; i < iface.robot_ext_tensors.size(); ++i) {
        const auto & rec = iface.robot_ext_tensors[i];
        const auto & w = ml.require_weight(rec.name.c_str());
        const auto & file = ml.files.at(w.idx);
        read_buf.resize(rec.nbytes);
        file->seek(w.offs, SEEK_SET);
        file->read_raw(read_buf.data(), rec.nbytes);
        ggml_backend_tensor_set(tensors[i], read_buf.data(), 0, rec.nbytes);

        iface.robot_ext_data.emplace(rec.name, tensors[i]);
    }

    LLAMA_LOG_INFO("therobot: materialized %zu extension tensor(s) (CPU buffer)\n", iface.robot_ext_data.size());
}

void llama_robot_validate_taps(const llama_robot_model_iface & iface, const llama_hparams & hparams) {
    if (!iface.robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS)) {
        return;
    }
    const uint32_t n_layer = hparams.n_layer();
    const uint32_t n_embd  = (uint32_t) hparams.n_embd;
    for (size_t i = 0; i < iface.robot.bottlenecks.size(); ++i) {
        const auto & bn = iface.robot.bottlenecks[i];
        if (bn.layer >= n_layer) {
            throw std::runtime_error(format("therobot: bottleneck %zu ('%s') layer %u out of range (n_layer = %u)",
                    i, bn.name.c_str(), bn.layer, n_layer));
        }
        if (bn.offset + bn.width > n_embd) {
            throw std::runtime_error(format("therobot: bottleneck %zu ('%s') slice [%u..%u) exceeds n_embd = %u",
                    i, bn.name.c_str(), bn.offset, bn.offset + bn.width, n_embd));
        }
    }
}

// spec §1.2 point → graph tensor base name (named by llama_context's graph cb
// as "<base>-<il>"). Note: some model families name both the FFN branch output
// and the post-residual sum "ffn_out"; ggml_graph_get_tensor returns the first
// occurrence, which is the branch output — the cleave-point semantics we want.
static const char * robot_tap_point_base(const std::string & point) {
    if (point == "resid_post") { return "l_out";    }
    if (point == "attn_out")   { return "attn_out"; }
    if (point == "ffn_out")    { return "ffn_out";  }
    return nullptr;
}

// adjust a cgraph use count (mirrors ggml_visit_parents' bookkeeping)
static void robot_graph_use_count_adjust(ggml_cgraph * gf, ggml_tensor * t, int32_t delta) {
    const size_t slot = ggml_hash_find(&gf->visited_hash_set, t);
    if (slot != GGML_HASHSET_FULL && ggml_bitset_get(gf->visited_hash_set.used, slot)) {
        gf->use_counts[slot] += delta;
    }
}

// Splice an edit into the donor graph: `out` must compute a replacement for
// node `src` (and depend on it). Expands `out` into the graph, re-points every
// downstream consumer of `src` at `out`, then moves the new nodes to sit
// directly after `src` so execution order stays topological.
void llama_robot_graph_splice_edit(ggml_cgraph * gf, ggml_tensor * src, ggml_tensor * out) {
    const int n0 = gf->n_nodes;
    ggml_build_forward_expand(gf, out);
    const int n1 = gf->n_nodes;
    GGML_ASSERT(n1 > n0 && gf->nodes[n1 - 1] == out);

    int isrc = -1;
    for (int i = 0; i < n0; ++i) {
        if (gf->nodes[i] == src) {
            isrc = i;
            break;
        }
    }
    GGML_ASSERT(isrc >= 0 && "shim source tensor is not a graph node");

    // re-point downstream consumers (the new chain [n0, n1) keeps reading src)
    for (int i = isrc + 1; i < n0; ++i) {
        ggml_tensor * node = gf->nodes[i];
        for (int s = 0; s < GGML_MAX_SRC; ++s) {
            if (node->src[s] == src) {
                node->src[s] = out;
                robot_graph_use_count_adjust(gf, src, -1);
                robot_graph_use_count_adjust(gf, out, +1);
            }
        }
    }

    // rotate the chain to sit right after src: [isrc+1, n0) shifts right
    const int len = n1 - n0;
    std::vector<ggml_tensor *> chain(gf->nodes + n0, gf->nodes + n1);
    memmove(gf->nodes + isrc + 1 + len, gf->nodes + isrc + 1, (size_t) (n0 - isrc - 1) * sizeof(ggml_tensor *));
    memcpy(gf->nodes + isrc + 1, chain.data(), (size_t) len * sizeof(ggml_tensor *));
}

// Build one shim edit over the (full-width) interface tensor `t_in`:
//   y     = gain ⊙ x + steer + B(A·x)   on the slice x
//   delta = g · (y − x),  g = step(w·x + b_eff)  (or 1 for `always`)
//   out   = t_in + pad(delta)
// Returns `out`, spliced in as the new interface tensor.
// Build one shim edit over the (full-width) interface tensor `t_in`:
//   y     = gain ⊙ x + steer + B(A·x)   on the slice x
//   delta = g · (y − x),  g from the gate (1 for `always`; in-graph step() for
//           `probe:` on the pre-edit slice and `modulator:` on a channel of m)
//   out   = t_in + pad(delta)
// Returns `out`, spliced in as the new interface tensor.
static ggml_tensor * robot_graph_apply_shim(
        llm_graph_context * g,
        const llama_robot_bottleneck & bn,
        const llama_robot_shim * shim,
        ggml_tensor * t_in,
        ggml_tensor * m_in) {
    ggml_context * ctx0 = g->ctx0;

    const int64_t W = bn.width;
    const int64_t T = t_in->ne[1];

    ggml_tensor * xs = ggml_cont(ctx0, ggml_view_2d(ctx0, t_in,
            W, T, t_in->nb[1], (size_t) bn.offset * t_in->nb[0]));

    ggml_tensor * y = xs;
    if (shim->t_gain != nullptr) {
        y = ggml_mul(ctx0, y, shim->t_gain);
    }
    if (shim->t_steer != nullptr) {
        y = ggml_add(ctx0, y, shim->t_steer);
    }
    if (shim->t_a != nullptr && shim->t_b != nullptr) {
        ggml_tensor * h = ggml_mul_mat(ctx0, shim->t_a, xs); // [rank, T]
        y = ggml_add(ctx0, y, ggml_mul_mat(ctx0, shim->t_b, h)); // [W, T]
    }

    ggml_tensor * delta = ggml_sub(ctx0, y, xs);

    if (shim->gate.kind == llama_robot_shim_gate::GATE_PROBE) {
        ggml_tensor * p = ggml_mul_mat(ctx0, shim->t_gate_w, xs); // [1, T]
        p = ggml_add(ctx0, p, shim->t_gate_b);
        ggml_tensor * gate = ggml_step(ctx0, p); // 0/1 per position
        delta = ggml_mul(ctx0, delta, gate);     // broadcast [1,T] → [W,T]
    } else if (shim->gate.kind == llama_robot_shim_gate::GATE_MODULATOR) {
        GGML_ASSERT(m_in != nullptr); // enforced at load: modulator feature required
        ggml_tensor * mc = ggml_view_1d(ctx0, m_in, 1, (size_t) shim->gate_channel * m_in->nb[0]);
        if (shim->gate.op == "<" || shim->gate.op == "<=") {
            mc = ggml_neg(ctx0, mc);
        }
        ggml_tensor * p = ggml_add(ctx0, mc, shim->t_gate_b); // ±m[c] + b_eff
        ggml_tensor * gate = ggml_step(ctx0, p);              // one scalar for the whole ubatch
        delta = ggml_mul(ctx0, delta, gate);                  // broadcast [1] → [W,T]
    }

    ggml_tensor * delta_full = ggml_pad_ext(ctx0, delta,
            (int) bn.offset, (int) (t_in->ne[0] - bn.offset - W), 0, 0, 0, 0, 0, 0);

    ggml_tensor * out = ggml_add(ctx0, t_in, delta_full);
    ggml_format_name(out, "robot_shim_out-%s", shim->name.c_str());

    llama_robot_graph_splice_edit(g->gf, t_in, out);

    return out;
}

// E3 shims + E2 tap for one bottleneck, on the current interface tensor
static ggml_tensor * robot_graph_apply_bottleneck(
        llm_graph_context * g,
        const llama_robot_model_iface & iface,
        size_t bn_id,
        const llama_robot_context_state * st,
        ggml_tensor * m_in,
        ggml_tensor * cur) {
    const auto & bn = iface.robot.bottlenecks[bn_id];

    GGML_ASSERT(cur->type == GGML_TYPE_F32);
    GGML_ASSERT((int64_t) bn.offset + bn.width <= cur->ne[0]);

    // attached shims stack on this bottleneck in attach order; each edit
    // becomes the interface tensor the next one (and the tap) reads
    if (st != nullptr) {
        for (const llama_robot_shim * shim : st->shims) {
            if (shim->bottleneck_id == (int32_t) bn_id) {
                cur = robot_graph_apply_shim(g, bn, shim, cur, m_in);
            }
        }
    }

    // slice channels [offset, offset+width) across all positions, make
    // contiguous, and mark as a named graph output (post-shim view)
    ggml_tensor * view = ggml_view_2d(g->ctx0, cur,
            bn.width, cur->ne[1],
            cur->nb[1],
            (size_t) bn.offset * cur->nb[0]);
    ggml_tensor * tap = ggml_cont(g->ctx0, view);
    ggml_set_name(tap, format("robot_tap-%zu", bn_id).c_str());
    ggml_set_output(tap);
    ggml_build_forward_expand(g->gf, tap);

    return cur;
}

// E4 FiLM: out = (γ_w·m + γ_b) ⊙ h + (β_w·m + β_b), spliced at the layer stream
static ggml_tensor * robot_graph_apply_film(
        llm_graph_context * g,
        const llama_robot_model_iface & iface,
        int L,
        ggml_tensor * m_in,
        ggml_tensor * cur) {
    ggml_context * ctx0 = g->ctx0;

    ggml_tensor * gw = iface.robot_ext_tensor(format("blk.%d.robot_film.gamma.weight", L));
    ggml_tensor * gb = iface.robot_ext_tensor(format("blk.%d.robot_film.gamma.bias",   L));
    ggml_tensor * bw = iface.robot_ext_tensor(format("blk.%d.robot_film.beta.weight",  L));
    ggml_tensor * bb = iface.robot_ext_tensor(format("blk.%d.robot_film.beta.bias",    L));

    ggml_tensor * gamma = ggml_mul_mat(ctx0, gw, m_in); // [n_embd, 1]
    if (gb != nullptr) {
        gamma = ggml_add(ctx0, gamma, gb);
    }
    ggml_tensor * out = ggml_mul(ctx0, cur, gamma); // broadcast over positions

    if (bw != nullptr) {
        ggml_tensor * beta = ggml_mul_mat(ctx0, bw, m_in); // [n_embd, 1]
        if (bb != nullptr) {
            beta = ggml_add(ctx0, beta, bb);
        }
        out = ggml_add(ctx0, out, beta);
    } else if (bb != nullptr) {
        out = ggml_add(ctx0, out, bb);
    }

    ggml_format_name(out, "robot_film_out-%d", L);
    llama_robot_graph_splice_edit(g->gf, cur, out);
    return out;
}

// E4 leaky state branch at layer L: exact per-position EMA scan (unrolled over
// the ubatch; adds ~5·T nodes — v1 targets small-batch streaming), stream
// contribution through out_proj (zero at graft ⇒ exact donor parity), final
// state exposed as output `robot_state_out-<L>`.
static ggml_tensor * robot_graph_apply_state(
        llm_graph_context * g,
        const llama_robot_model_iface & iface,
        int L,
        ggml_tensor * s_in,
        ggml_tensor * cur,
        ggml_tensor ** s_final_out) {
    ggml_context * ctx0 = g->ctx0;

    ggml_tensor * aw = iface.robot_ext_tensor(format("blk.%d.robot_state.alpha", L));
    ggml_tensor * iw = iface.robot_ext_tensor(format("blk.%d.robot_state.in_proj.weight", L));
    ggml_tensor * ib = iface.robot_ext_tensor(format("blk.%d.robot_state.in_proj.bias", L));
    ggml_tensor * ow = iface.robot_ext_tensor(format("blk.%d.robot_state.out_proj.weight", L));
    ggml_tensor * ob = iface.robot_ext_tensor(format("blk.%d.robot_state.out_proj.bias", L));

    const int64_t S = aw->ne[0];
    const int64_t T = cur->ne[1];

    ggml_tensor * F = ggml_mul_mat(ctx0, iw, cur); // [S, T]
    if (ib != nullptr) {
        F = ggml_add(ctx0, F, ib);
    }

    ggml_tensor * a   = ggml_sigmoid(ctx0, aw);                  // σ(α)   [S]
    ggml_tensor * oma = ggml_sigmoid(ctx0, ggml_neg(ctx0, aw));  // σ(−α) = 1−σ(α)

    ggml_tensor * s = ggml_reshape_2d(ctx0, s_in, S, 1);
    ggml_tensor * states = nullptr; // [S, T]
    for (int64_t t = 0; t < T; ++t) {
        ggml_tensor * f_t = ggml_view_2d(ctx0, F, S, 1, F->nb[1], (size_t) t * F->nb[1]);
        s = ggml_add(ctx0, ggml_mul(ctx0, s, a), ggml_mul(ctx0, f_t, oma));
        states = states == nullptr ? s : ggml_concat(ctx0, states, s, 1);
    }

    ggml_tensor * O = ggml_mul_mat(ctx0, ow, states); // [n_embd, T]
    if (ob != nullptr) {
        O = ggml_add(ctx0, O, ob);
    }

    ggml_tensor * out = ggml_add(ctx0, cur, O);
    ggml_format_name(out, "robot_state_stream-%d", L);
    llama_robot_graph_splice_edit(g->gf, cur, out);

    // the final state is a node inside the spliced chain — name it and mark it
    // as an output so it survives scheduling and can be captured post-decode
    ggml_set_name(s, format("robot_state_out-%d", L).c_str());
    ggml_set_output(s);

    *s_final_out = s;
    return out;
}

// E6 delta blend at block L: fire = step(mean((x−held_in)²) − θ_eff) (+force),
// out = held_out + fire·(block_out − held_out); refreshed holds and the fire
// flag are named outputs for the capture hook / compute trace.
static ggml_tensor * robot_graph_apply_delta(
        llm_graph_context * g,
        const llama_robot_model_iface & iface,
        const llm_graph_input_robot::delta_inputs & din,
        ggml_tensor * force,
        ggml_tensor * m_in,
        ggml_tensor * x_in,
        ggml_tensor * cur) {
    ggml_context * ctx0 = g->ctx0;
    const uint32_t L = din.layer;

    ggml_tensor * theta = iface.robot_ext_tensor(format("blk.%u.robot_delta.theta_base", L)); // [1]

    // mean squared input change vs the held input
    ggml_tensor * diff = ggml_sub(ctx0, x_in, din.held_in); // [n_embd, 1]
    ggml_tensor * msq  = ggml_scale(ctx0, ggml_sum(ctx0, ggml_mul(ctx0, diff, diff)), 1.0f / (float) x_in->ne[0]);

    // θ_eff = θ_base + fatigue − excitability·m
    ggml_tensor * theta_eff = ggml_add(ctx0, theta, din.fatigue);
    if (m_in != nullptr) {
        if (ggml_tensor * ew = iface.robot_ext_tensor("robot.delta.excitability.weight")) {
            theta_eff = ggml_sub(ctx0, theta_eff, ggml_mul_mat(ctx0, ew, m_in)); // [1]
        }
    }

    ggml_tensor * fire = ggml_step(ctx0, ggml_sub(ctx0, msq, theta_eff)); // {0,1}
    fire = ggml_step(ctx0, ggml_add(ctx0, fire, force));                  // force is ±0.5-biased
    ggml_set_name(fire, format("robot_delta_fire-%u", L).c_str());
    ggml_set_output(fire);

    // blend: quiet blocks contribute their held output
    ggml_tensor * out = ggml_add(ctx0,
            ggml_mul(ctx0, ggml_sub(ctx0, cur, din.held_out), fire),
            din.held_out);
    ggml_set_name(out, format("robot_delta_hout-%u", L).c_str());
    ggml_set_output(out);
    llama_robot_graph_splice_edit(g->gf, cur, out);

    // refreshed held input (only moves when the block fired)
    ggml_tensor * hin = ggml_add(ctx0,
            ggml_mul(ctx0, ggml_sub(ctx0, x_in, din.held_in), fire),
            din.held_in);
    ggml_set_name(hin, format("robot_delta_hin-%u", L).c_str());
    ggml_set_output(hin);
    ggml_build_forward_expand(g->gf, hin);

    return out;
}

void llama_robot_graph_apply(const llama_robot_model_iface & iface, llm_graph_context * g,
        const llama_robot_context_state * st) {
    const auto & robot = iface.robot;

    const bool has_taps  = robot.has_feature(LLAMA_ROBOT_FEATURE_TAPS);
    const bool has_state = robot.has_feature(LLAMA_ROBOT_FEATURE_STATE);
    const bool has_mod   = robot.has_feature(LLAMA_ROBOT_FEATURE_MODULATOR);
    // delta subgraphs build only when enabled on this context and streaming
    // (T == 1 — prompt ubatches run dense; 002's v0 constraint)
    const bool has_delta = robot.has_feature(LLAMA_ROBOT_FEATURE_DELTA) &&
            st != nullptr && st->delta_enabled && g->n_tokens == 1;
    if (!has_taps && !has_state && !has_mod && !has_delta) {
        return;
    }

    ggml_context * ctx0 = g->ctx0;
    const int n_layer = (int) g->n_layer;

    // recurrent inputs: m, per-covered-layer state vectors, and delta holds
    // enter the graph as input tensors, pushed from host state at set_input
    llm_graph_input_robot * inp = nullptr;
    ggml_tensor * m_in = nullptr;
    if (has_state || has_mod || has_delta) {
        auto input = std::make_unique<llm_graph_input_robot>(&iface, st);
        if (has_mod) {
            m_in = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, robot.modulator.dim);
            ggml_set_name(m_in, "robot_mod_in");
            ggml_set_input(m_in);
            input->m_in = m_in;
        }
        if (robot.has_feature(LLAMA_ROBOT_FEATURE_MEMORY)) {
            ggml_tensor * r = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, robot.modulator.dim);
            ggml_set_name(r, "robot_mem_recall_in");
            ggml_set_input(r);
            input->recall_in = r;
        }
        if (has_state) {
            const int64_t S = llama_robot_state_width(iface);
            for (const uint32_t L : robot.state.layers) {
                ggml_tensor * s = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, S);
                ggml_set_name(s, format("robot_state_in-%u", L).c_str());
                ggml_set_input(s);
                input->s_in.emplace_back(L, s);
            }
        }
        if (has_delta) {
            input->delta_force = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, 1);
            ggml_set_name(input->delta_force, "robot_delta_force");
            ggml_set_input(input->delta_force);
            for (const auto & b : st->delta) {
                llm_graph_input_robot::delta_inputs din;
                din.layer    = b.layer;
                din.held_in  = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, g->n_embd);
                din.held_out = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, g->n_embd);
                din.fatigue  = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, 1);
                ggml_set_name(din.held_in,  format("robot_delta_hin_in-%u", b.layer).c_str());
                ggml_set_name(din.held_out, format("robot_delta_hout_in-%u", b.layer).c_str());
                ggml_set_name(din.fatigue,  format("robot_delta_fat_in-%u", b.layer).c_str());
                ggml_set_input(din.held_in);
                ggml_set_input(din.held_out);
                ggml_set_input(din.fatigue);
                input->delta_in.push_back(din);
            }
        }
        inp = static_cast<llm_graph_input_robot *>(g->res->add_input(std::move(input)));
    }

    // per-layer pipeline over the residual stream: delta → FiLM → state → shims/taps
    ggml_tensor * final_stream = nullptr; // pooled modulator source
    ggml_tensor * last_s_final = nullptr; // glacial modulator source
    std::vector<ggml_tensor *> layer_cur((size_t) n_layer, nullptr); // post-edit stream per layer

    const bool need_final = has_mod && robot.modulator.source == "pooled";

    for (int L = 0; L < n_layer; ++L) {
        const bool film_here  = has_mod &&
                iface.robot_ext_tensor(format("blk.%d.robot_film.gamma.weight", L)) != nullptr;
        bool state_here = false;
        ggml_tensor * s_in = nullptr;
        if (has_state && inp != nullptr) {
            for (const auto & [sl, t] : inp->s_in) {
                if ((int) sl == L) { state_here = true; s_in = t; break; }
            }
        }
        const llm_graph_input_robot::delta_inputs * din = nullptr;
        if (has_delta && inp != nullptr) {
            for (const auto & d : inp->delta_in) {
                if ((int) d.layer == L) { din = &d; break; }
            }
        }
        bool bn_here = false;
        if (has_taps) {
            for (const auto & bn : robot.bottlenecks) {
                if ((int) bn.layer == L && bn.point == "resid_post") { bn_here = true; break; }
            }
        }
        if (!film_here && !state_here && !bn_here && din == nullptr && !(need_final && L == n_layer - 1)) {
            continue;
        }

        ggml_tensor * cur = ggml_graph_get_tensor(g->gf, format("l_out-%d", L).c_str());
        if (cur == nullptr) {
            LLAMA_LOG_WARN("therobot: layer %d: tensor 'l_out-%d' not found in donor graph — extensions at this layer disabled\n", L, L);
            continue;
        }

        // E6 first: the delta decision compares the block's *input* (the
        // previous layer's final stream) and holds the raw block output
        if (din != nullptr) {
            ggml_tensor * x_in = L > 0 ? layer_cur[L - 1] : nullptr;
            if (x_in == nullptr) {
                x_in = ggml_graph_get_tensor(g->gf, format("l_out-%d", L - 1).c_str());
            }
            if (x_in != nullptr) {
                cur = robot_graph_apply_delta(g, iface, *din, inp->delta_force, m_in, x_in, cur);
            } else {
                LLAMA_LOG_WARN("therobot: delta block %d: input stream not found — block runs dense\n", L);
            }
        }

        if (film_here && m_in != nullptr) {
            cur = robot_graph_apply_film(g, iface, L, m_in, cur);
        }
        if (state_here) {
            ggml_tensor * s_final = nullptr;
            cur = robot_graph_apply_state(g, iface, L, s_in, cur, &s_final);
            last_s_final = s_final;
        }
        if (bn_here) {
            for (size_t i = 0; i < robot.bottlenecks.size(); ++i) {
                if ((int) robot.bottlenecks[i].layer == L && robot.bottlenecks[i].point == "resid_post") {
                    cur = robot_graph_apply_bottleneck(g, iface, i, st, m_in, cur);
                }
            }
        }
        layer_cur[L] = cur;
        if (L == n_layer - 1) {
            final_stream = cur;
        }
    }

    // bottlenecks at non-residual points (attn_out / ffn_out) — direct path
    if (has_taps) {
        for (size_t i = 0; i < robot.bottlenecks.size(); ++i) {
            const auto & bn = robot.bottlenecks[i];
            if (bn.point == "resid_post") {
                continue;
            }
            const char * base = robot_tap_point_base(bn.point);
            GGML_ASSERT(base != nullptr); // validated at spec parse
            ggml_tensor * cur = ggml_graph_get_tensor(g->gf, format("%s-%d", base, (int) bn.layer).c_str());
            if (cur == nullptr) {
                LLAMA_LOG_WARN("therobot: tap %zu ('%s'): tensor '%s-%d' not found in donor graph — tap and shims disabled\n",
                        i, bn.name.c_str(), base, (int) bn.layer);
                continue;
            }
            robot_graph_apply_bottleneck(g, iface, i, st, m_in, cur);
        }
    }

    // modulator update subgraph: p → z → c → m_out (per-channel decay)
    if (has_mod && inp != nullptr && m_in != nullptr) {
        ggml_tensor * p = nullptr;
        if (robot.modulator.source == "glacial") {
            GGML_ASSERT(last_s_final != nullptr && "glacial modulator source requires state layers");
            // glacial bank slice of the last covered layer's final state
            int64_t off = 0, wg = 0;
            for (const auto & bank : robot.state.banks) {
                if (bank.name == "glacial") { wg = bank.width; break; }
                off += bank.width;
            }
            GGML_ASSERT(wg > 0);
            p = ggml_view_1d(ctx0, last_s_final, wg, (size_t) off * last_s_final->nb[0]);
        } else {
            if (final_stream == nullptr) {
                LLAMA_LOG_WARN("therobot: pooled modulator source unavailable — modulator update disabled\n");
                return;
            }
            // mean over positions, weights pushed from set_input (1/n each)
            ggml_tensor * mean_w = ggml_new_tensor_1d(ctx0, GGML_TYPE_F32, final_stream->ne[1]);
            ggml_set_name(mean_w, "robot_mod_meanw");
            ggml_set_input(mean_w);
            inp->mean_w = mean_w;
            ggml_tensor * tr = ggml_cont(ctx0, ggml_transpose(ctx0, final_stream)); // [T*, n_embd]
            p = ggml_mul_mat(ctx0, tr, mean_w); // [n_embd, 1]
        }

        ggml_tensor * pw = iface.robot_ext_tensor("robot.mod.pool.weight");
        ggml_tensor * pb = iface.robot_ext_tensor("robot.mod.pool.bias");
        ggml_tensor * cw = iface.robot_ext_tensor("robot.mod.cell.weight");
        ggml_tensor * cb = iface.robot_ext_tensor("robot.mod.cell.bias");
        ggml_tensor * ma = iface.robot_ext_tensor("robot.mod.alpha");

        ggml_tensor * z = ggml_mul_mat(ctx0, pw, p); // [M, 1]
        if (pb != nullptr) {
            z = ggml_add(ctx0, z, pb);
        }
        z = ggml_add(ctx0, z, ggml_mul_mat(ctx0, cw, m_in)); // + cell·m
        if (cb != nullptr) {
            z = ggml_add(ctx0, z, cb);
        }
        if (inp->recall_in != nullptr) {
            z = ggml_add(ctx0, z, inp->recall_in); // + E5 episodic recall
        }
        ggml_tensor * c = ggml_tanh(ctx0, z); // candidate [M, 1]

        ggml_tensor * am  = ggml_sigmoid(ctx0, ma);                  // σ(α_m)
        ggml_tensor * omm = ggml_sigmoid(ctx0, ggml_neg(ctx0, ma));  // 1 − σ(α_m)

        // m_out = σ(α_m)⊙m + (1−σ(α_m))⊙c
        ggml_tensor * m_out = ggml_add(ctx0,
                ggml_mul(ctx0, c, omm),
                ggml_mul(ctx0, ggml_reshape_2d(ctx0, m_in, m_in->ne[0], 1), am));
        ggml_set_name(m_out, "robot_mod_out");
        ggml_set_output(m_out);
        ggml_build_forward_expand(g->gf, m_out);
    }
}

static llama_model * llama_robot_model_mapping(
        const llama_model_params & params,
        llama_robot_hparams robot) {
    // wrapped donor families. Adding a family is one line here — the wrapper
    // template does the rest (llamacpp-extensions.md §1: family, not enum
    // explosion). Keep in sync with docs/robot/patch-points.md.
    switch (robot.base_arch) {
        case LLM_ARCH_LLAMA:    return new llama_model_robot<llama_model_llama>   (params, std::move(robot));
        case LLM_ARCH_QWEN2:    return new llama_model_robot<llama_model_qwen2>   (params, std::move(robot));
        case LLM_ARCH_QWEN2MOE: return new llama_model_robot<llama_model_qwen2moe>(params, std::move(robot));
        case LLM_ARCH_QWEN3:    return new llama_model_robot<llama_model_qwen3>   (params, std::move(robot));
        case LLM_ARCH_QWEN35:   return new llama_model_robot<llama_model_qwen35>  (params, std::move(robot));
        case LLM_ARCH_MAMBA:    return new llama_model_robot<llama_model_mamba>   (params, std::move(robot));
        default:
            throw std::runtime_error(format(
                "therobot: base architecture '%s' is not wrapped by this runtime yet "
                "(supported: llama, qwen2, qwen2moe, qwen3, qwen35, mamba)",
                robot.base_architecture.c_str()));
    }
}

llama_model * llama_robot_model_create(llama_model_loader & ml, const llama_model_params & params) {
    llama_robot_hparams robot;
    llama_robot_hparams_load(robot, ml);

    const llm_arch base_arch = robot.base_arch;

    {
        std::ostringstream feats;
        for (const auto f : robot.features) {
            feats << ' ' << llama_robot_feature_name(f);
        }
        LLAMA_LOG_INFO("therobot: spec v%u, base architecture '%s', level L%u, features:%s\n",
                robot.spec_version, robot.base_architecture.c_str(), robot.level,
                robot.features.empty() ? " (none — L0 passthrough)" : feats.str().c_str());
        if (!robot.donor_id.empty()) {
            LLAMA_LOG_INFO("therobot: donor '%s'\n", robot.donor_id.c_str());
        }
    }

    // Rebind the loader's per-arch KV formatting to the donor family: all base
    // hparams/tensors in a therobot file use the donor's stock keys/names
    // unchanged (spec §1.1).
    ml.arch_name = llm_arch_name(base_arch);
    ml.llm_kv    = LLM_KV(base_arch);

    llama_model * model = llama_robot_model_mapping(params, std::move(robot));

    // mirror llama_model_create(arch, params): the model runs *as* the donor
    // arch internally — that is what makes the superset/parity invariant hold
    model->arch = base_arch;

    const auto & devices = model->devices;
    if (!devices.empty() && devices[0].is_meta && !llm_arch_supports_sm_tensor(base_arch)) {
        throw std::runtime_error(std::string("LLAMA_SPLIT_MODE_TENSOR not implemented for architecture '") + llm_arch_name(base_arch) + "'");
    }

    return model;
}
