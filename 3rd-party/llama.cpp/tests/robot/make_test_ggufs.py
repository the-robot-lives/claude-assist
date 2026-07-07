#!/usr/bin/env python3
"""Emit tiny therobot GGUF fixtures for smoke-testing the E1 spec loader."""
import sys
import numpy as np

sys.path.insert(0, sys.argv[1])  # path to gguf-py
import gguf  # noqa: E402

out_dir = sys.argv[2]


def base(writer):
    writer.add_uint32("therobot.spec_version", 1)
    writer.add_string("therobot.base_architecture", "qwen2")
    writer.add_string("therobot.donor.id", "Qwen/Qwen2-0.5B@main")
    writer.add_string("therobot.convert.lockfile_hash", "deadbeef")
    # a stand-in base tensor so the file has tensor data
    writer.add_tensor("token_embd.weight", np.zeros((4, 8), dtype=np.float32))


# 1) L0 passthrough: empty features
w = gguf.GGUFWriter(f"{out_dir}/l0-passthrough.gguf", "therobot")
base(w)
w.add_uint32("therobot.level", 0)
w.add_array("therobot.features", [])
w.write_header_to_file()
w.write_kv_data_to_file()
w.write_tensors_to_file()
w.close()

# 2) L2-style manifest: taps + state + modulator, with extension tensors
w = gguf.GGUFWriter(f"{out_dir}/l2-manifest.gguf", "therobot")
base(w)
w.add_uint32("therobot.level", 2)
w.add_array("therobot.features", ["taps", "state", "modulator"])
w.add_array("therobot.features_optional", ["memory", "holography"])
# taps
w.add_uint32("therobot.bottleneck.count", 1)
w.add_string("therobot.bottleneck.0.name", "subject")
w.add_uint32("therobot.bottleneck.0.layer", 10)
w.add_string("therobot.bottleneck.0.point", "resid_post")
w.add_uint32("therobot.bottleneck.0.offset", 0)
w.add_uint32("therobot.bottleneck.0.width", 32)
w.add_array("therobot.bottleneck.0.attributes", ["subject", "color", "size"])
w.add_float32("therobot.bottleneck.0.decodability", 0.91)
w.add_float32("therobot.bottleneck.0.selectivity", 0.85)
# state
w.add_uint32("therobot.state.bank_count", 2)
w.add_string("therobot.state.bank.0.name", "fast")
w.add_uint32("therobot.state.bank.0.width", 16)
w.add_string("therobot.state.bank.1.name", "glacial")
w.add_uint32("therobot.state.bank.1.width", 8)
w.add_array("therobot.state.layers", [0, 10])
# modulator
w.add_uint32("therobot.modulator.dim", 8)
w.add_array("therobot.modulator.channels", ["arousal", "valence", "attention"])
w.add_string("therobot.modulator.source", "glacial")
# extension tensors
w.add_tensor("robot.probe.0.subject.weight", np.zeros((32, 4), dtype=np.float32))
w.add_tensor("robot.mod.alpha", np.zeros((8,), dtype=np.float32))
w.add_tensor("blk.0.robot_state.alpha", np.zeros((16,), dtype=np.float32))
w.add_tensor("blk.10.robot_film.gamma.weight", np.zeros((8, 4), dtype=np.float32))
w.write_header_to_file()
w.write_kv_data_to_file()
w.write_tensors_to_file()
w.close()

# 3) unknown required feature
w = gguf.GGUFWriter(f"{out_dir}/bad-feature.gguf", "therobot")
base(w)
w.add_array("therobot.features", ["quantum"])
w.write_header_to_file()
w.write_kv_data_to_file()
w.write_tensors_to_file()
w.close()

# 4) shim module file
w = gguf.GGUFWriter(f"{out_dir}/shim.gguf", "therobot-shim")
w.add_uint32("therobot.spec_version", 1)
w.add_string("therobot.shim.name", "color-shift")
w.add_string("therobot.shim.version", "0.1.0")
w.add_string("therobot.shim.target_model", "deadbeef")
w.add_string("therobot.shim.target_bottleneck", "subject")
w.add_string("therobot.shim.effect", "misreport color without touching other values")
w.add_float32("therobot.shim.selectivity", 0.93)
w.add_string("therobot.shim.gate", "modulator:arousal>0.5")
w.add_tensor("robot.shim.steer.weight", np.zeros((32,), dtype=np.float32))
w.write_header_to_file()
w.write_kv_data_to_file()
w.write_tensors_to_file()
w.close()

print("wrote fixtures to", out_dir)
