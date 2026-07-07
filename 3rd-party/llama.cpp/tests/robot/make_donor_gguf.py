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


def write_model(path, arch, robot, taps=False):
    global rng
    rng = np.random.default_rng(42)  # identical weights in all twins
    w = gguf.GGUFWriter(path, arch)
    # llama-family hparams (stock keys — with arch "llama" the writer emits
    # llama.*; for the therobot twin we must emit llama.* keys explicitly)
    prefix = "llama"
    w.add_uint32(f"{prefix}.context_length", N_CTX)
    w.add_uint32(f"{prefix}.embedding_length", N_EMBD)
    w.add_uint32(f"{prefix}.block_count", N_LAYER)
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
        if taps:
            w.add_uint32("therobot.level", 1)
            w.add_array("therobot.features", ["taps"])
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
        else:
            w.add_uint32("therobot.level", 0)
            w.add_array("therobot.features", [])

    # weights
    w.add_tensor("token_embd.weight", t(N_VOCAB, N_EMBD))
    w.add_tensor("output_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
    w.add_tensor("output.weight", t(N_VOCAB, N_EMBD))
    for i in range(N_LAYER):
        w.add_tensor(f"blk.{i}.attn_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
        w.add_tensor(f"blk.{i}.attn_q.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_k.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_v.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.attn_output.weight", t(N_EMBD, N_EMBD))
        w.add_tensor(f"blk.{i}.ffn_norm.weight", np.ones((N_EMBD,), dtype=np.float32))
        w.add_tensor(f"blk.{i}.ffn_gate.weight", t(N_FF, N_EMBD))
        w.add_tensor(f"blk.{i}.ffn_down.weight", t(N_EMBD, N_FF))
        w.add_tensor(f"blk.{i}.ffn_up.weight", t(N_FF, N_EMBD))

    if robot:
        # an extension tensor the wrapper must claim for accounting to balance
        w.add_tensor("robot.mod.alpha", np.zeros((8,), dtype=np.float32))
    if taps:
        # identity probe head with constant bias: probe(x) == x + 0.5
        w.add_tensor("robot.probe.0.subject.weight", np.eye(8, dtype=np.float32))
        w.add_tensor("robot.probe.0.subject.bias", np.full((8,), 0.5, dtype=np.float32))

    w.write_header_to_file()
    w.write_kv_data_to_file()
    w.write_tensors_to_file()
    w.close()
    print("wrote", path)


write_model(f"{out_dir}/tiny-llama-stock.gguf", "llama", robot=False)
write_model(f"{out_dir}/tiny-llama-therobot.gguf", "therobot", robot=True)
write_model(f"{out_dir}/tiny-llama-taps.gguf", "therobot", robot=True, taps=True)
