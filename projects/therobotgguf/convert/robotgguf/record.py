"""R1 — Record: run the calibration corpus through the frozen donor with
forward hooks on candidate sites; store slices only, fp16. [needs the HF
stack; untested in-repo until a GPU/checkpoint environment runs it]

The recordings + weak labels are the training substrate for everything
downstream: probes (R2), thresholds (R4), shims (R5), and later accreted
modules. Weak labels come from configured labelers — label once, reuse
forever.
"""
from __future__ import annotations

import hashlib

import numpy as np

from .config import Config, Lockfile
from .recordings import RecordingStore


def _load_corpus(cfg: Config, tok, max_tokens: int):
    texts = []
    for spec in cfg.corpus:
        with open(cfg.resolve(spec)) as f:
            texts.append(f.read())
    ids = []
    for t in texts:
        ids.extend(tok(t).input_ids)
        if len(ids) >= max_tokens:
            break
    return ids[:max_tokens]


def run(cfg: Config, max_tokens: int = 200_000, window: int = 512) -> None:
    try:
        import torch  # noqa: PLC0415
        from transformers import AutoModelForCausalLM, AutoTokenizer  # noqa: PLC0415
    except ImportError as e:
        raise SystemExit(f"R1 needs the HF stack (pip install 'robotgguf[hf]'): {e}")

    lock = Lockfile(cfg.lockfile_path)
    survey = lock.require("survey", "ingest")
    sites = {s["name"]: {k: s[k] for k in ("layer", "point", "offset", "width")}
             for s in survey["candidate_sites"]}

    tok = AutoTokenizer.from_pretrained(cfg.donor)
    model = AutoModelForCausalLM.from_pretrained(cfg.donor, torch_dtype=torch.float16)
    model.eval()

    ids = _load_corpus(cfg, tok, max_tokens)
    corpus_hash = hashlib.sha256(bytes(str(ids[:1024]), "utf-8")).hexdigest()[:16]

    # forward hooks capture the residual stream after each covered block
    captured: dict[str, list] = {name: [] for name in sites}
    layers = model.model.layers  # llama/qwen-family layout

    def make_hook(name, off, width):
        def hook(_mod, _inp, out):
            h = out[0] if isinstance(out, tuple) else out
            captured[name].append(h[0, :, off:off + width].detach().to(torch.float16).cpu())
        return hook

    handles = [layers[s["layer"]].register_forward_hook(
                   make_hook(n, s["offset"], s["width"]))
               for n, s in sites.items()]

    with torch.no_grad():
        for lo in range(0, len(ids) - window, window):
            chunk = torch.tensor([ids[lo:lo + window]])
            model(chunk)
    for h in handles:
        h.remove()

    acts = {n: torch.cat(c, dim=0).numpy() for n, c in captured.items()}

    # weak labels over the same token stream (config.labelers: name → callable
    # spec resolved by the project; heuristic labelers ship separately)
    labels = {}
    for attr in cfg.attributes:
        labels[attr] = np.zeros(len(next(iter(acts.values()))), dtype=np.int64)
        print(f"record: WARNING attribute '{attr}' has placeholder labels — "
              f"run the weak-labeler pass before cleave")

    RecordingStore(cfg.recordings_dir).write(
        model=cfg.config_hash(), corpus=corpus_hash, sites=sites,
        acts=acts, labels=labels)
    lock.update("record", {"n_samples": int(len(next(iter(acts.values())))),
                           "corpus_hash": corpus_hash,
                           "sites": sorted(sites)})
    print(f"record: {len(acts)} site(s) recorded to {cfg.recordings_dir}")
