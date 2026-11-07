#!/usr/bin/env python3
"""model.py — Studio-9 training entry point (basic slice).

Brief-named alias for the training stage: delegates to src/retrain.py
(the PV LSTM retrain pipeline). `python src/model.py [--dry-run] [-v]`
behaves exactly like `python src/retrain.py` with the same flags.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def main(argv=None) -> None:
    spec = importlib.util.spec_from_file_location(
        "retrain_entry", Path(__file__).resolve().parent / "retrain.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules["retrain_entry"] = mod
    spec.loader.exec_module(mod)
    mod.main(argv)


if __name__ == "__main__":
    main()
