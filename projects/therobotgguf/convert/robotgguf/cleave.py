"""R2 — Cleave: discover typed bottlenecks in the frozen donor (§D).

For each candidate site × attribute, train a small linear probe on the
recordings and score:

  decodability — held-out accuracy
  selectivity  — margin over the same probe trained on a random equal-width
                 slice at the same layer (approximated with a shuffled-feature
                 control when no sibling slice was recorded)
  stability    — 1 − accuracy std across corpus shards

Sites clear the config's bars for at least one attribute → bottleneck entries
+ admission scores land in the lockfile, and the winning probes are kept as
extension-tensor material for R7 (identity-checkable by the runtime's
llama_robot_probe_eval). No core fine-tuning: attributes that aren't decodable
in the frozen donor are dropped and recorded as findings.
"""
from __future__ import annotations

import os

import numpy as np

from .config import Config, Lockfile
from .recordings import RecordingStore


def _softmax(z: np.ndarray) -> np.ndarray:
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def train_probe(x: np.ndarray, y: np.ndarray, l2: float = 1e-3,
                epochs: int = 200, lr: float = 0.5, seed: int = 0):
    """Multinomial logistic regression by full-batch gradient descent.
    Returns (W [D, C], b [C], heldout accuracy)."""
    rng = np.random.default_rng(seed)
    x = np.asarray(x, dtype=np.float32)
    n, d = x.shape
    classes = int(y.max()) + 1

    # standardize (folded back into W/b so exported probes act on raw slices)
    mu, sd = x.mean(0), x.std(0) + 1e-6
    xs = (x - mu) / sd

    idx = rng.permutation(n)
    split = max(1, int(0.8 * n))
    tr, te = idx[:split], idx[split:]

    w = np.zeros((d, classes), dtype=np.float32)
    b = np.zeros(classes, dtype=np.float32)
    onehot = np.eye(classes, dtype=np.float32)[y[tr]]
    for _ in range(epochs):
        p = _softmax(xs[tr] @ w + b)
        g = xs[tr].T @ (p - onehot) / len(tr) + l2 * w
        w -= lr * g
        b -= lr * (p - onehot).mean(0)

    acc = float((np.argmax(xs[te] @ w + b, axis=1) == y[te]).mean()) if len(te) else 0.0

    # unfold standardization: probe(raw) = ((raw − mu)/sd)·W + b
    w_raw = (w / sd[:, None]).astype(np.float32)
    b_raw = (b - mu / sd @ w).astype(np.float32)
    return w_raw, b_raw, acc


def _shard_accuracy(x, y, w, b, shards) -> list:
    accs = []
    for lo, hi in zip(shards[:-1], shards[1:]):
        if hi > lo:
            pred = np.argmax(np.asarray(x[lo:hi], dtype=np.float32) @ w + b, axis=1)
            accs.append(float((pred == y[lo:hi]).mean()))
    return accs


def run(cfg: Config) -> None:
    store = RecordingStore(cfg.recordings_dir)
    if not store.exists():
        raise SystemExit(f"no recordings at {cfg.recordings_dir} — run `robotgguf record` first")
    man = store.manifest
    lock = Lockfile(cfg.lockfile_path)
    rng = np.random.default_rng(1)

    probe_dir = os.path.join(cfg.workdir, "probes")
    os.makedirs(probe_dir, exist_ok=True)

    bottlenecks, findings = [], []
    for name, site in man.sites.items():
        x = store.activations(name)
        admitted_attrs, scores = [], {}
        for attr in man.attributes:
            y = store.labels(attr)
            w, b, acc = train_probe(x, y)

            # selectivity control: same probe capacity on a class-decorrelated
            # (row-shuffled) copy of the slice
            perm = rng.permutation(len(y))
            _, _, acc_ctl = train_probe(np.asarray(x)[perm], y)
            sel = acc - acc_ctl

            stab = 1.0 - float(np.std(_shard_accuracy(x, y, w, b, man.shards)))

            if acc >= cfg.min_decodability and sel >= cfg.min_selectivity:
                admitted_attrs.append(attr)
                scores[attr] = {"decodability": round(acc, 4),
                                "selectivity": round(sel, 4),
                                "stability": round(stab, 4)}
                np.save(os.path.join(probe_dir, f"{name}.{attr}.weight.npy"), w.T)  # [C, D] rows
                np.save(os.path.join(probe_dir, f"{name}.{attr}.bias.npy"), b)
            else:
                findings.append({"site": name, "attribute": attr,
                                 "decodability": round(acc, 4),
                                 "selectivity": round(sel, 4),
                                 "verdict": "not decodable in the frozen donor — dropped"})

        if admitted_attrs:
            bn = dict(site)
            bn["name"] = name
            bn["attributes"] = admitted_attrs
            bn["decodability"] = max(s["decodability"] for s in scores.values())
            bn["selectivity"] = max(s["selectivity"] for s in scores.values())
            bn["scores"] = scores
            bottlenecks.append(bn)

    bottlenecks.sort(key=lambda b: -b["decodability"])
    bottlenecks = bottlenecks[: cfg.max_bottlenecks]

    lock.update("cleave", {
        "recordings": {"model": man.model, "corpus": man.corpus},
        "bottlenecks": bottlenecks,
        "findings": findings,
        "probe_dir": os.path.relpath(probe_dir, cfg.root),
    })
    print(f"cleave: admitted {len(bottlenecks)} bottleneck(s), "
          f"{len(findings)} attribute/site pair(s) dropped as findings")
    for bn in bottlenecks:
        print(f"  {bn['name']}: layer {bn['layer']} {bn['point']} "
              f"[{bn['offset']}..{bn['offset'] + bn['width']}) "
              f"attrs={bn['attributes']} decod={bn['decodability']}")
