"""Make ``import ithkuil`` work from a bare source checkout.

Allows ``pytest`` to run from ``python/`` without ``pip install -e .``.
Harmless when the package is properly installed.
"""

import sys
from pathlib import Path

_ROOT = str(Path(__file__).resolve().parent)
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)
