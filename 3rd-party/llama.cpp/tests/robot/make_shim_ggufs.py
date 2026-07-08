#!/usr/bin/env python3
"""Emit therobot-shim module fixtures (spec §4) targeting the 'subject'
bottleneck (width 8) of tiny-llama-taps.gguf. Used by robot_shim_test."""
import sys
import numpy as np

sys.path.insert(0, sys.argv[1])  # gguf-py
import gguf  # noqa: E402

out_dir = sys.argv[2]

W = 8  # width of the 'subject' bottleneck in tiny-llama-taps.gguf


def shim(path, name, gate="always", depends=None, conflicts=None,
         steer=None, gain=None, gate_w=None, gate_b=None):
    w = gguf.GGUFWriter(path, "therobot-shim")
    w.add_uint32("therobot.spec_version", 1)
    w.add_string("therobot.shim.name", name)
    w.add_string("therobot.shim.version", "0.1.0")
    w.add_string("therobot.shim.target_model", "deadbeef")  # mismatch → warn only
    w.add_string("therobot.shim.target_bottleneck", "subject")
    w.add_string("therobot.shim.effect", f"test shim {name}")
    w.add_float32("therobot.shim.selectivity", 0.99)
    w.add_string("therobot.shim.gate", gate)
    w.add_array("therobot.shim.depends", depends or [])
    w.add_array("therobot.shim.conflicts", conflicts or [])
    if steer is not None:
        w.add_tensor("robot.shim.steer", np.full((W,), steer, dtype=np.float32))
    if gain is not None:
        w.add_tensor("robot.shim.gain", np.full((W,), gain, dtype=np.float32))
    if gate_w is not None:
        w.add_tensor("robot.shim.gate.weight", np.full((W,), gate_w, dtype=np.float32))
    if gate_b is not None:
        w.add_tensor("robot.shim.gate.bias", np.array([gate_b], dtype=np.float32))
    w.write_header_to_file()
    w.write_kv_data_to_file()
    w.write_tensors_to_file()
    w.close()
    print("wrote", path)


# additive edit, always on: y = x + 1
shim(f"{out_dir}/shim-steer-up.gguf", "steer-up", steer=1.0)

# multiplicative edit behind a deterministic probe gate:
#   score = 0·x + 1.0; gate "probe:energy>0.5" → step(1.0 − 0.5) = 1 (always fires)
shim(f"{out_dir}/shim-gated-on.gguf", "gated-on", gate="probe:energy>0.5",
     gain=2.0, gate_w=0.0, gate_b=1.0)

#   score = 0·x + 1.0; gate "probe:energy>1.5" → step(1.0 − 1.5) = 0 (never fires)
shim(f"{out_dir}/shim-gated-off.gguf", "gated-off", gate="probe:energy>1.5",
     gain=2.0, gate_w=0.0, gate_b=1.0)

# registry metadata fixtures
shim(f"{out_dir}/shim-dependent.gguf", "dependent", depends=["steer-up"], steer=0.5)
shim(f"{out_dir}/shim-conflicting.gguf", "conflicting", conflicts=["steer-up"], steer=-1.0)

# E4: additive edit gated on the modulator bus (fires while m[arousal] > 2)
shim(f"{out_dir}/shim-mod-gated.gguf", "mod-gated", gate="modulator:arousal>2", steer=1.0)

# E8: a 10-module registry (integer steers so stacked effects are float-exact)
import json
import os

reg_dir = f"{out_dir}/registry"
os.makedirs(reg_dir, exist_ok=True)

reg_entries = []


def reg_shim(i, tags, depends=None, conflicts=None):
    name = f"r{i}"
    shim(f"{reg_dir}/{name}.gguf", name, depends=depends, conflicts=conflicts,
         steer=float(i + 1))
    reg_entries.append({
        "name": name,
        "file": f"{name}.gguf",
        "tags": tags,
        "selectivity": 0.90 + 0.01 * i,
        "depends": depends or [],
        "conflicts": conflicts or [],
    })


reg_shim(0, ["alpha", "core"])
reg_shim(1, ["alpha"])
reg_shim(2, ["alpha"])
reg_shim(3, ["alpha"])
reg_shim(4, ["beta"])
reg_shim(5, ["beta"])
reg_shim(6, ["beta"])
reg_shim(7, ["beta"])
reg_shim(8, ["gamma"], depends=["r0"])            # dependency auto-include
reg_shim(9, ["gamma", "solo"], conflicts=["r8"])  # first-admitted r8 wins on gamma

with open(f"{reg_dir}/registry.json", "w") as f:
    json.dump({"spec_version": 1, "model": "deadbeef", "shims": reg_entries}, f, indent=2)
print("wrote", f"{reg_dir}/registry.json")
