#!/usr/bin/env python3
"""snapshot_train.py — record train-stage outputs for DVC (basic slice).

Reads the latest model version from MLflow, downloads its checkpoint
from Supabase artifacts/ into artifacts/models/, and writes
artifacts/models/training_summary.json.
Keeps the mutable mlflow.db OUT of DVC tracking (promote stage edits it).
"""

from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MODEL_NAME = "pv-lstm-fleet"


def main() -> int:
    import os

    from mlflow.tracking import MlflowClient

    url = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    bucket = os.environ.get("SUPABASE_BUCKET", "processed_data")

    client = MlflowClient()
    versions = sorted(
        client.search_model_versions(f"name='{MODEL_NAME}'"),
        key=lambda v: int(v.version),
    )
    if not versions:
        print("no model versions — train first")
        return 1
    latest = versions[-1]
    run = client.get_run(latest.run_id)
    metrics = {k: run.data.metrics.get(k) for k in
               ("test_rmse", "test_mae", "test_r2", "val_rmse")}

    out = REPO_ROOT / "artifacts" / "models"
    out.mkdir(parents=True, exist_ok=True)
    ckpt = out / "checkpoint.pt"
    picked = None
    for v in reversed(versions):  # newest first; skip versions w/o upload
        rid = client.get_run(v.run_id).info.run_id
        for name in ("checkpoint.pt", "model.pt"):
            src = f"{url}/storage/v1/object/{bucket}/artifacts/{rid}/{name}"
            req = urllib.request.Request(
                src, headers={"apikey": key, "Authorization": f"Bearer {key}"},
                method="HEAD")
            try:
                urllib.request.urlopen(req)
                get = urllib.request.Request(
                    src, headers={"apikey": key,
                                  "Authorization": f"Bearer {key}"})
                with urllib.request.urlopen(get) as r, open(ckpt, "wb") as fh:
                    fh.write(r.read())
                picked = (str(v.version), name)
                break
            except Exception:
                continue
        if picked:
            break
    if picked:
        print(f"checkpoint <- v{picked[0]}/{picked[1]} ({ckpt.stat().st_size} B)")
    else:
        print("WARNING: no checkpoint found in Supabase artifacts/")

    summary = {"model": MODEL_NAME, "latest_version": str(latest.version),
               "run_id": latest.run_id, "metrics": metrics,
               "aliases": list(latest.aliases)}
    (out / "training_summary.json").write_text(json.dumps(summary, indent=2))
    print(f"train snapshot OK — v{latest.version} rmse={metrics['test_rmse']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
