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
import os

import numpy as np

from .config import Config, Lockfile
from .recordings import RecordingStore


def relabel(cfg: Config) -> None:
    """Regenerate the weak labels from the stored token ids without re-running
    the model (labelers change more often than recordings do)."""
    try:
        from transformers import AutoTokenizer  # noqa: PLC0415
    except ImportError as e:
        raise SystemExit(f"relabel needs the HF tokenizer (pip install 'robotgguf[hf]'): {e}")
    from .labelers import label_token_windows  # noqa: PLC0415

    tokens_path = os.path.join(cfg.recordings_dir, "tokens.npy")
    if not os.path.exists(tokens_path):
        raise SystemExit("relabel: recordings carry no tokens.npy — re-run `robotgguf record`")
    ids = np.load(tokens_path)
    window = int(np.load(os.path.join(cfg.recordings_dir, "window_size.npy"))[0])
    windows = [ids[lo:lo + window].tolist() for lo in range(0, len(ids), window)]

    tok = AutoTokenizer.from_pretrained(cfg.donor)
    labels = label_token_windows(tok, windows, cfg.attributes)
    for attr, y in labels.items():
        np.save(os.path.join(cfg.recordings_dir, "labels", f"{attr}.npy"), y[: len(ids)])
        print(f"relabel: labels[{attr}] regenerated ({len(np.unique(y))} classes present)")


def _decoder_layers(model):
    """Find the transformer block ModuleList regardless of wrapper layout
    (plain CausalLM, ConditionalGeneration, language_model nesting)."""
    import torch.nn as nn  # noqa: PLC0415
    for attr in ("model.layers", "model.model.layers",
                 "model.language_model.layers", "transformer.h"):
        obj = model
        try:
            for part in attr.split("."):
                obj = getattr(obj, part)
            if isinstance(obj, nn.ModuleList) and len(obj) >= 2:
                return obj
        except AttributeError:
            continue
    # fallback: largest ModuleList of decoder blocks
    best = None
    for _, mod in model.named_modules():
        if isinstance(mod, nn.ModuleList) and len(mod) >= 2:
            if best is None or len(mod) > len(best):
                best = mod
    if best is None:
        raise SystemExit("record: could not locate the decoder layer stack")
    return best


def _load_corpus(cfg: Config, tok, max_tokens: int):
    """Tokenize the corpus in ~1 MB text chunks and stop as soon as
    max_tokens is reached — so a 2M-token budget reads ~8 MB of a 300 MB
    corpus instead of tokenizing the whole thing. Prints progress."""
    import sys, time  # noqa: PLC0415
    ids: list = []
    t0 = time.time()
    for spec in cfg.corpus:
        path = cfg.resolve(spec)
        with open(path, encoding="utf-8", errors="ignore") as f:
            buf = []
            buf_len = 0
            for line in f:
                buf.append(line)
                buf_len += len(line)
                if buf_len >= 1_000_000:
                    ids.extend(tok("".join(buf)).input_ids)
                    buf, buf_len = [], 0
                    print(f"\rrecord: tokenizing… {len(ids):,} tokens", end="", file=sys.stderr, flush=True)
                    if len(ids) >= max_tokens:
                        break
            if buf and len(ids) < max_tokens:
                ids.extend(tok("".join(buf)).input_ids)
        if len(ids) >= max_tokens:
            break
    n = min(len(ids), max_tokens)
    print(f"\rrecord: tokenized {n:,} tokens in {time.time()-t0:.0f}s"
          + " " * 20, file=sys.stderr, flush=True)
    return ids[:max_tokens]


def run(cfg: Config, max_tokens: int = 200_000, window: int = 512) -> None:
    try:
        import torch  # noqa: PLC0415
        from transformers import AutoModelForCausalLM, AutoTokenizer  # noqa: PLC0415
    except ImportError as e:
        raise SystemExit(f"R1 needs the HF stack (pip install 'robotgguf[hf]'): {e}")

    lock = Lockfile(cfg.lockfile_path)
    survey = lock.section("survey")
    # candidate sites: prefer the survey (R0's measured output), fall back to
    # the config so record works without a full HF ingest pass
    site_list = survey.get("candidate_sites") or cfg.candidate_sites
    if not site_list:
        raise SystemExit("record: no candidate_sites in the lockfile survey or the config")
    sites = {s["name"]: {k: s[k] for k in ("layer", "point", "offset", "width")}
             for s in site_list}

    tok = AutoTokenizer.from_pretrained(cfg.donor)

    # device: prefer CUDA, then Apple MPS (the M-series GPU), else CPU. MPS
    # moves the dense matmuls (most of the cost) onto the GPU; any GDN op
    # without an MPS kernel falls back to CPU when PYTORCH_ENABLE_MPS_FALLBACK
    # is set (we set it below), so the run never errors — it just runs those
    # ops on CPU. Set ROBOT_DEVICE=cpu to force CPU.
    os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
    forced = os.environ.get("ROBOT_DEVICE", "").strip().lower()
    if forced in ("cpu", "mps", "cuda"):
        device = forced
    elif torch.cuda.is_available():
        device = "cuda"
    elif getattr(torch.backends, "mps", None) is not None and torch.backends.mps.is_available():
        device = "mps"
    else:
        device = "cpu"

    # fp16 on GPU (MPS/CUDA fp16 is well supported); bf16 on CPU for range
    dtype = torch.float16 if device in ("cuda", "mps") else torch.bfloat16
    kw = dict(low_cpu_mem_usage=True)
    try:
        model = AutoModelForCausalLM.from_pretrained(cfg.donor, dtype=dtype, **kw)
    except TypeError:  # older transformers use torch_dtype
        model = AutoModelForCausalLM.from_pretrained(cfg.donor, torch_dtype=dtype, **kw)
    model.eval().to(device)
    print(f"record: device={device} dtype={dtype}")

    ids = _load_corpus(cfg, tok, max_tokens)
    corpus_hash = hashlib.sha256(bytes(str(ids[:1024]), "utf-8")).hexdigest()[:16]

    # forward hooks capture the residual stream after each covered block
    captured: dict[str, list] = {name: [] for name in sites}
    layers = _decoder_layers(model)  # robust to wrapper layouts (Qwen3.5 etc.)

    def make_hook(name, off, width):
        def hook(_mod, _inp, out):
            h = out[0] if isinstance(out, tuple) else out
            captured[name].append(h[0, :, off:off + width].detach().float().to(torch.float16).cpu())
        return hook

    handles = [layers[s["layer"]].register_forward_hook(
                   make_hook(n, s["offset"], s["width"]))
               for n, s in sites.items()]

    import gc, sys, time  # noqa: PLC0415
    win_ids = []
    starts = list(range(0, len(ids) - window, window))
    total = len(starts) * window
    print(f"record: {len(starts)} forward window(s) of {window} tokens on {device}", file=sys.stderr, flush=True)
    t0 = time.time()
    with torch.no_grad():
        for wi, lo in enumerate(starts):
            chunk_ids = ids[lo:lo + window]
            win_ids.append(chunk_ids)
            # use_cache=False: recording is stateless per window; the GDN/attn
            # cache would otherwise accumulate and OOM on long corpora
            model(torch.tensor([chunk_ids], device=device), use_cache=False)
            gc.collect()
            if wi % 5 == 0 or wi == len(starts) - 1:
                done = (wi + 1) * window
                el = time.time() - t0
                rate = done / el if el > 0 else 0.0
                eta = (total - done) / rate if rate > 0 else 0.0
                print(f"\rrecord: forward {done:,}/{total:,} tokens "
                      f"({100.0*done/total:.0f}%)  {rate:.0f} tok/s  ETA {eta/60:.1f} min   ",
                      end="", file=sys.stderr, flush=True)
    print(f"\rrecord: forward pass done — {total:,} tokens in {(time.time()-t0)/60:.1f} min"
          + " " * 20, file=sys.stderr, flush=True)
    for h in handles:
        h.remove()

    acts = {n: torch.cat(c, dim=0).numpy() for n, c in captured.items()}

    # weak labels over the same token stream, sentence-granular (labelers.py;
    # a teacher-LLM pass can overwrite labels/<attr>.npy later — same contract)
    from .labelers import label_token_windows  # noqa: PLC0415
    labels = label_token_windows(tok, win_ids, cfg.attributes)

    store = RecordingStore(cfg.recordings_dir)
    store.write(model=cfg.config_hash(), corpus=corpus_hash, sites=sites,
                acts=acts, labels=labels)
    # keep the token ids so labels can be regenerated without re-running the model
    np.save(os.path.join(cfg.recordings_dir, "tokens.npy"),
            np.concatenate([np.asarray(w, dtype=np.int64) for w in win_ids]))
    np.save(os.path.join(cfg.recordings_dir, "window_size.npy"),
            np.asarray([window], dtype=np.int64))

    lock.update("record", {"n_samples": int(len(next(iter(acts.values())))),
                           "corpus_hash": corpus_hash,
                           "sites": sorted(sites),
                           "labeler": "heuristic-v0"})
    for attr in cfg.attributes:
        vals, counts = np.unique(labels[attr], return_counts=True)
        dist = ", ".join(f"{v}:{c}" for v, c in zip(vals.tolist(), counts.tolist()))
        print(f"record: labels[{attr}] class counts: {dist}")
    print(f"record: {len(acts)} site(s) recorded to {cfg.recordings_dir}")
