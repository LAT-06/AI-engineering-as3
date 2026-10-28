#!/usr/bin/env python3
"""preprocess_new_data.py — validate + stage the incoming batch (basic slice).

Checks data/new_data.csv against the train schema, then stages:
  artifacts/preprocessing/feature_columns.json
  artifacts/preprocessing/row_counts.json
  artifacts/data/validated_new_data.csv
Exit 1 on schema mismatch (fails the pipeline early, before training).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    import pandas as pd

    train_p = REPO_ROOT / "train" / "train.csv"
    new_p = REPO_ROOT / "data" / "new_data.csv"
    train = pd.read_csv(train_p)
    new = pd.read_csv(new_p)

    missing = [c for c in train.columns if c not in new.columns]
    if missing:
        print(f"SCHEMA MISMATCH — missing in new_data: {missing}")
        return 1
    if len(new) == 0:
        print("EMPTY new_data.csv — nothing to stage")
        return 1

    prep = REPO_ROOT / "artifacts" / "preprocessing"
    data = REPO_ROOT / "artifacts" / "data"
    prep.mkdir(parents=True, exist_ok=True)
    data.mkdir(parents=True, exist_ok=True)

    (prep / "feature_columns.json").write_text(
        json.dumps({"columns": list(train.columns)}, indent=2))
    (prep / "row_counts.json").write_text(json.dumps(
        {"train_rows": len(train), "new_rows": len(new)}, indent=2))
    new.to_csv(data / "validated_new_data.csv", index=False)
    print(f"preprocess OK — train={len(train)} new={len(new)} "
          f"cols={len(train.columns)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
