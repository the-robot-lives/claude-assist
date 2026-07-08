#!/usr/bin/env python3
"""Emit a tiny but fully loadable llama-family donor model, both as a stock
`llama` file and as its `therobot` L0 twin (same weights, extension keys, plus
one claimed extension tensor). Used to smoke-test the E1 runtime load path."""
import sys
import numpy as np

sys.path.insert(0, sys.argv[1])  # gguf-py
import gguf  # noqa: E402

out_dir = sys.argv[2]

N_VOCAB = 32
N_EMBD = 32
N_LAYER = 2
N_HEAD = 4
N_HEAD_KV = 4
N_FF = 64
N_CTX = 128

rng = np.random.default_rng(42)


def t(*shape):
    return (rng.standard_normal(shape) * 0.02).astype(np.float32)


def write_model(path, arch, robot, taps=False, l2=None, delta=None, n_layer=N_LAYER):
    """l2: None, or dict(film=bool, state=bool, mem=None|'manual'|'auto').
    delta: None, or dict(theta=float, heartbeat=int) — delta-covered blocks
    1..n_layer-1 with the given base threshold, plus a modulator bus wired to
    excitability on channel 0."""
    global rng
    rng = np.random.default_rng(42)  # identical weights in all twins
    w = gguf.GGUFWriter(path, arch)
    # llama-family hparams (stock keys — with arch "llama" the writer emits
    # llama.*; for the therobot twin we must emit llama.* keys explicitly)
    prefix = "llama"
    w.add_uint32(f"{prefix}.context_length", N_CTX)
    w.add_uint32(f"{prefix}.embedding_length", N_EMBD)
    w.add_uint32(f"{prefix}.block_count", n_layer)
    w.add_uint32(f"{prefix}.feed_forward_length", N_FF)
    w.add_uint32(f"{prefix}.attention.head_count", N_HEAD)
    w.add_uint32(f"{prefix}.attention.head_count_kv", N_HEAD_KV)
    w.add_float32(f"{prefix}.attention.layer_norm_rms_epsilon", 1e-5)
    w.add_uint32(f"{prefix}.rope.dimension_count", N_EMBD // N_HEAD)
    w.add_uint32(f"{prefix}.vocab_size", N_VOCAB)

    # minimal llama (SPM-style) tokenizer
    tokens = ["<unk>", "<s>", "</s>"] + [f"<tok{i}>" for i in range(N_VOCAB - 3)]
    scores = [0.0] * N_VOCAB
    toktypes = [2, 3, 3] + [1] * (N_VOCAB - 3)  # UNKNOWN, CONTROL, CONTROL, NORMAL...
    w.add_tokenizer_model("llama")
    w.add_token_list(tokens)
    w.add_token_scores(scores)
    w.add_token_types(toktypes)
    w.add_bos_token_id(1)
    w.add_eos_token_id(2)
    w.add_unk_token_id(0)

    if robot:
        w.add_uint32("therobot.spec_version", 1)
        w.add_string("therobot.base_architecture", "llama")
        w.add_string("therobot.donor.id", "local/tiny-llama-fixture@0")
        if l2 is not None:
            mem = l2.get("mem")  # None | "manual" | "auto"
            if mem:
                w.add_uint32("therobot.level", 2)
                w.add_array("therobot.features", ["taps", "state", "modulator", "memory"])
                w.add_uint32("therobot.memory.key_dim", 8)
                w.add_uint32("therobot.memory.value_dim", 4)  # == modulator dim
                w.add_uint32("therobot.memory.capacity", 4)
                w.add_float32("therobot.memory.decay_halflife", 4.0)
                w.add_float32("therobot.memory.salience.threshold_quantile", 0.5)
            else:
                w.add_uint32("therobot.level", 2)
                w.add_array("therobot.features", ["taps", "state", "modulator"])
            # state: fast + glacial banks on layer 0 (layer 1 is output-filtered)
            w.add_uint32("therobot.state.bank_count", 2)
            w.add_string("therobot.state.bank.0.name", "fast")
            w.add_uint32("therobot.state.bank.0.width", 4)
            w.add_string("therobot.state.bank.1.name", "glacial")
            w.add_uint32("therobot.state.bank.1.width", 4)
            w.add_array("therobot.state.layers", [0])
            # modulator: 4 named channels, pooled source
            w.add_uint32("therobot.modulator.dim", 4)
            w.add_array("therobot.modulator.channels", ["arousal", "valence", "attention", "energy"])
            w.add_string("therobot.modulator.source", "pooled")
        elif taps:
            w.add_uint32("therobot.level", 1)
            w.add_array("therobot.features", ["taps"])
        elif delta is not None:
            w.add_uint32("therobot.level", 3)
            w.add_array("therobot.features", ["delta", "modulator"])
            w.add_string("therobot.delta.granularity", "block")
            w.add_uint32("therobot.delta.heartbeat", delta["heartbeat"])
            w.add_float32("therobot.delta.target_keep_rate", 0.5)
            w.add_uint32("therobot.modulator.dim", 4)
            w.add_array("therobot.modulator.channels", ["arousal", "valence", "attention", "energy"])
            w.add_string("therobot.modulator.source", "pooled")
        else:
            w.add_uint32("therobot.level", 0)
            w.add_array("therobot.features", [])
        if taps or l2 is not None:
            w.add_uint32("therobot.bottleneck.count", 2)
            # tap 0: mid-layer residual slice with an identity probe head
            w.add_string("therobot.bottleneck.0.name", "subject")
            w.add_uint32("therobot.bottleneck.0.layer", 0)
            w.add_string("therobot.bottleneck.0.point", "resid_post")
            w.add_uint32("therobot.bottleneck.0.offset", 4)
            w.add_uint32("therobot.bottleneck.0.width", 8)
            w.add_array("therobot.bottleneck.0.attributes", ["subject"])
            w.add_float32("therobot.bottleneck.0.decodability", 1.0)
            w.add_float32("therobot.bottleneck.0.selectivity", 1.0)
            # tap 1: last-layer ffn branch output (exercises output-row filtering)
            w.add_string("therobot.bottleneck.1.name", "style")
            w.add_uint32("therobot.bottleneck.1.layer", 1)
            w.add_string("therobot.bottleneck.1.point", "ffn_out")
            w.add_uint32("therobot.bottleneck.1.offset", 0)
            w.add_uint32("therobot.bottleneck.1.width", 8)
            w.add_array("therobot.bottleneck.1.attributes", ["style"])

    # weights
    w.add_tensor("token_embd.weight", t(N_VOCAB, N_EMBD))
    w.add_tensor("output_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
    w.add_tensor("output.weight", t(N_VOCAB, N_EMBD))
    for i in range(n_layer):
        w.add_tensor(f"blk.{i}.attn_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
        w.add_tensor(f"blk.{i}.attn_q.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_k.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_v.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_output.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.ffn_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
        w.add_tensor(f"blk.{i}.ffn_gate.weight", t(N_FF, N_EMBD))
        w.add_tensor(f"blk.{i}.ffn_down.weight", t(N_EMBD, N_FF))
        w.add_tensor(f"blk.{i}.ffn_up.weight", t(N_FF, N_EMBD))

    if robot and l2 is None and delta is None:
        # an extension tensor the wrapper must claim for accounting to balance
        w.add_tensor("robot.mod.alpha", np.zeros((8,), dtype=np.float32))
    if taps or l2 is not None:
        # identity probe head with constant bias: probe(x) == x + 0.5
        w.add_tensor("robot.probe.0.subject.weight", np.eye(8, dtype=np.float32))
        w.add_tensor("robot.probe.0.subject.bias", np.full((8,), 0.5, dtype=np.float32))
    if l2 is not None:
        S, M = 8, 4
        # state grafts on layer 0: alpha logits 0 → decay 0.5 per position
        w.add_tensor("blk.0.robot_state.alpha", np.zeros((S,), dtype=np.float32))
        if l2.get("state"):
            in_proj = (np.random.default_rng(7).standard_normal((S, N_EMBD)) * 0.1).astype(np.float32)
            out_proj = (np.random.default_rng(8).standard_normal((N_EMBD, S)) * 0.1).astype(np.float32)
        else:
            in_proj = np.zeros((S, N_EMBD), dtype=np.float32)
            out_proj = np.zeros((N_EMBD, S), dtype=np.float32)  # zero at graft ⇒ parity
        w.add_tensor("blk.0.robot_state.in_proj.weight", in_proj)
        w.add_tensor("blk.0.robot_state.out_proj.weight", out_proj)
        # modulator grafts: alpha logits 0 → m halves per decode; pool/cell zero
        # so m moves only via decay (and llama_robot_mod_set)
        w.add_tensor("robot.mod.alpha", np.zeros((M,), dtype=np.float32))
        w.add_tensor("robot.mod.pool.weight", np.zeros((M, N_EMBD), dtype=np.float32))
        w.add_tensor("robot.mod.cell.weight", np.zeros((M, M), dtype=np.float32))
        # FiLM heads on layer 0: identity at graft (gamma bias 1, all else 0);
        # the primed variant sets beta.weight so β = m[0] uniformly
        w.add_tensor("blk.0.robot_film.gamma.weight", np.zeros((N_EMBD, M), dtype=np.float32))
        w.add_tensor("blk.0.robot_film.gamma.bias", np.ones((N_EMBD,), dtype=np.float32))
        beta_w = np.zeros((N_EMBD, M), dtype=np.float32)
        if l2.get("film"):
            beta_w[:, 0] = 1.0  # β_j = m[0] for every channel j
        w.add_tensor("blk.0.robot_film.beta.weight", beta_w)
    if delta is not None:
        M = 4
        for L in range(1, n_layer):
            w.add_tensor(f"blk.{L}.robot_delta.theta_base",
                         np.array([delta["theta"]], dtype=np.float32))
        # excitability: m[arousal] lowers thresholds by 1e6 per unit
        exc = np.zeros((1, M), dtype=np.float32)
        exc[0, 0] = 1.0e6
        w.add_tensor("robot.delta.excitability.weight", exc)
        # modulator grafts (pool/cell zero: m moves only via mod_set + decay)
        w.add_tensor("robot.mod.alpha", np.zeros((M,), dtype=np.float32))
        w.add_tensor("robot.mod.pool.weight", np.zeros((M, N_EMBD), dtype=np.float32))
        w.add_tensor("robot.mod.cell.weight", np.zeros((M, M), dtype=np.float32))
    if l2 is not None:
        mem = l2.get("mem")
        if mem:
            D = 16  # Σ bottleneck widths (8 + 8)
            key_w = (np.random.default_rng(9).standard_normal((8, D)) * 0.5).astype(np.float32)
            w.add_tensor("robot.mem.summary.key.weight", key_w)
            val_w = np.zeros((4, D), dtype=np.float32)
            val_w[0, :] = 0.05  # recall arousal = 0.05 · Σ summary
            w.add_tensor("robot.mem.summary.value.weight", val_w)
            if mem == "manual":
                # silent salience channel: only explicit writes store memories
                w.add_tensor("robot.mem.salience.weight", np.zeros((2,), dtype=np.float32))
            else:
                w.add_tensor("robot.mem.salience.weight", np.ones((2,), dtype=np.float32))

    w.write_header_to_file()
    w.write_kv_data_to_file()
    w.write_tensors_to_file()
    w.close()
    print("wrote", path)


write_model(f"{out_dir}/tiny-llama-stock.gguf", "llama", robot=False)
write_model(f"{out_dir}/tiny-llama-therobot.gguf", "therobot", robot=True)
write_model(f"{out_dir}/tiny-llama-taps.gguf", "therobot", robot=True, taps=True)
write_model(f"{out_dir}/tiny-llama-l2.gguf", "therobot", robot=True, l2={})                    # zero grafts ⇒ parity
write_model(f"{out_dir}/tiny-llama-l2-film.gguf", "therobot", robot=True, l2={"film": True})   # β = m[0]
write_model(f"{out_dir}/tiny-llama-l2-state.gguf", "therobot", robot=True, l2={"state": True}) # live leaky state
write_model(f"{out_dir}/tiny-llama-l2-mem.gguf", "therobot", robot=True,
            l2={"film": True, "mem": "manual"})  # memory via explicit writes; β = m[0] makes recall visible
write_model(f"{out_dir}/tiny-llama-l2-mem-auto.gguf", "therobot", robot=True,
            l2={"film": True, "mem": "auto"})    # salience-gated auto-writes
# E6 delta fixtures (3 layers → blocks 1 and 2 covered)
write_model(f"{out_dir}/tiny-llama-delta-lo.gguf", "therobot", robot=True, n_layer=3,
            delta={"theta": 0.0, "heartbeat": 4})      # θ=0: every block always fires
write_model(f"{out_dir}/tiny-llama-delta-hi.gguf", "therobot", robot=True, n_layer=3,
            delta={"theta": 1.0e6, "heartbeat": 4})    # fires only on heartbeat/excitability
write_model(f"{out_dir}/tiny-llama-delta-nohb.gguf", "therobot", robot=True, n_layer=3,
            delta={"theta": 1.0e6, "heartbeat": 1000}) # effectively no heartbeat
