#!/usr/bin/env python3
"""Stream a diverse calibration corpus from Hugging Face for R2.

Streams (no full dataset download) a mix chosen to give the seven v0
attributes real class variation:
  - FineWeb (English web text) → topic / register / sentiment / entity spread
  - FineWeb-2 slices (a few non-English languages) → the `language` attribute
    actually varies (a monolingual corpus makes cleave drop it, as we saw)

Writes corpus/mixed-text.txt. Keep the synthetic corpus/behavioral-suites.txt
from tools/make_corpus.py for the sharp axes web text underrepresents
(imperative commands, threat-salience, register extremes).

Usage:
  pip install 'datasets>=2.19'
  python3 tools/fetch_corpus.py corpus 300   # ~300 MB target
"""
import os
import sys

from datasets import load_dataset

OUT = sys.argv[1] if len(sys.argv) > 1 else "corpus"
TARGET_MB = int(sys.argv[2]) if len(sys.argv) > 2 else 300
os.makedirs(OUT, exist_ok=True)

# (dataset, config, split, text-field, share of the byte budget)
SOURCES = [
    ("HuggingFaceFW/fineweb",   "sample-10BT",  "train", "text", 0.70),  # English
    ("HuggingFaceFW/fineweb-2", "fra_Latn",     "train", "text", 0.10),  # French
    ("HuggingFaceFW/fineweb-2", "deu_Latn",     "train", "text", 0.05),  # German
    ("HuggingFaceFW/fineweb-2", "rus_Cyrl",     "train", "text", 0.08),  # Russian (Cyrillic)
    ("HuggingFaceFW/fineweb-2", "jpn_Jpan",     "train", "text", 0.07),  # Japanese (CJK)
]

target_bytes = TARGET_MB * 1024 * 1024
out_path = os.path.join(OUT, "mixed-text.txt")
written = 0

with open(out_path, "w", encoding="utf-8") as f:
    for repo, cfg, split, field, share in SOURCES:
        budget = int(target_bytes * share)
        got = 0
        print(f"streaming {repo}:{cfg} (~{budget/1024/1024:.0f} MB) ...", flush=True)
        try:
            ds = load_dataset(repo, name=cfg, split=split, streaming=True)
        except Exception as e:  # config name drift across dataset versions
            print(f"  skip {repo}:{cfg} ({e})")
            continue
        for row in ds:
            doc = (row.get(field) or "").strip()
            if len(doc) < 200:
                continue
            f.write(doc + "\n\n")
            n = len(doc.encode("utf-8")) + 2
            got += n
            written += n
            if got >= budget:
                break
        print(f"  wrote {got/1024/1024:.0f} MB from {repo}:{cfg}")

print(f"corpus: {out_path} — {written/1024/1024:.0f} MB total")

# explicit verdict: require a meaningful fraction of the requested budget
ok = written >= 0.5 * target_bytes
if ok:
    print("FETCH_CORPUS: OK")
else:
    print(f"FETCH_CORPUS: FAILED (only {written/1024/1024:.0f} MB of "
          f"{TARGET_MB} MB target — check HF_TOKEN / dataset access)")

# datasets' streaming backend (fsspec/aiohttp) leaves daemon threads alive,
# which stalls a normal interpreter exit even though every write is already
# flushed above. Hard-exit past them — nothing is left to clean up.
sys.stdout.flush()
os._exit(0 if ok else 1)
