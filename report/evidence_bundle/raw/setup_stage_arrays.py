#!/usr/bin/env python3
"""stage_arrays.py — persist Studio-9 staged arrays (basic slice).

Rebuilds the exact window arrays the trainer uses (window_size=6) from the
local staged CSVs and saves the brief's artifacts/data/*.npy set plus the
fitted feature preprocessor (SimpleImputer -> StandardScaler):

  artifacts/data/X_train.npy, y_train.npy   (from train/train.csv)
  artifacts/data/X_test.npy,  y_test.npy    (from test/test.csv)
  artifacts/data/X_new.npy                  (from validated new_data)
  artifacts/preprocessing/scaler.pkl        (fitted StandardScaler step)
  artifacts/preprocessing/preprocessor.pkl  (full imputer+scaler pipeline)

No label encoder is written: the target is continuous (regression), so there
is nothing to encode. Run after preprocess (needs validated_new_data.csv +
feature_columns.json).
"""

from __future__ import annotations

import json
import pickle
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

TARGET_COL = "target_norm"
WINDOW = 6


def main() -> int:
    import numpy as np
    import pandas as pd
    from sklearn.impute import SimpleImputer
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    from jobs.retrain_tools.lstm_model import _build_windows
    from jobs.retrain_tools.data_loader import BASE_FEATURES

    feats = [c for c in BASE_FEATURES]
    (REPO_ROOT / "artifacts" / "preprocessing" / "model_features.json").write_text(
        json.dumps({"features": feats, "target": TARGET_COL,
                    "window_size": WINDOW}, indent=2))

    def windows(csv: str):
        df = pd.read_csv(REPO_ROOT / csv)
        return _build_windows(df, feats, TARGET_COL, WINDOW)

    X_tr_raw, y_tr = windows("train/train.csv")
    X_te_raw, y_te = windows("test/test.csv")
    X_new_raw, _ = windows("artifacts/data/validated_new_data.csv")

    n_tr, _, n_f = X_tr_raw.shape
    pre = Pipeline([("imputer", SimpleImputer(strategy="median")),
                    ("scaler", StandardScaler())])
    X_tr = pre.fit_transform(X_tr_raw.reshape(-1, n_f)).reshape(
        n_tr, WINDOW, n_f).astype(np.float32)
    X_te = pre.transform(X_te_raw.reshape(-1, n_f)).reshape(
        len(X_te_raw), WINDOW, n_f).astype(np.float32)
    X_new = pre.transform(X_new_raw.reshape(-1, n_f)).reshape(
        len(X_new_raw), WINDOW, n_f).astype(np.float32)

    data = REPO_ROOT / "artifacts" / "data"
    prep = REPO_ROOT / "artifacts" / "preprocessing"
    data.mkdir(parents=True, exist_ok=True)
    np.save(data / "X_train.npy", X_tr)
    np.save(data / "y_train.npy", y_tr)
    np.save(data / "X_test.npy", X_te)
    np.save(data / "y_test.npy", y_te)
    np.save(data / "X_new.npy", X_new)
    with open(prep / "preprocessor.pkl", "wb") as fh:
        pickle.dump(pre, fh)
    with open(prep / "scaler.pkl", "wb") as fh:
        pickle.dump(pre.named_steps["scaler"], fh)
    print(f"arrays OK — X_train{X_tr.shape} X_test{X_te.shape} "
          f"X_new{X_new.shape} + scaler.pkl")
    return 0


if __name__ == "__main__":
    sys.exit(main())
