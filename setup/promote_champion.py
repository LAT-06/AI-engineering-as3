#!/usr/bin/env python3
"""promote_champion.py — Human Approval Gate (basic slice, own code).

Sets the `champion` alias to the latest model version ONLY when
APPROVE=1 in env (manual human decision). Otherwise records `pending`
and exits 0 so `dvc repro` stays green; the CI workflow enforces the
gate (auto = candidate only, manual approve = champion).
Writes artifacts/models/promotion.json
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MODEL_NAME = "pv-lstm-fleet"


def main() -> int:
    from mlflow.tracking import MlflowClient

    client = MlflowClient()
    versions = sorted(
        client.search_model_versions(f"name='{MODEL_NAME}'"),
        key=lambda v: int(v.version),
    )
    if not versions:
        print("no model versions yet — run train first")
        return 1
    latest = versions[-1]
    approved = os.environ.get("APPROVE", "") == "1"
    record = {
        "model": MODEL_NAME,
        "latest_version": str(latest.version),
        "approved": approved,
    }
    if approved:
        client.set_registered_model_alias(
            MODEL_NAME, "champion", str(latest.version))
        record["champion_version"] = str(latest.version)
        print(f"PROMOTED — champion -> v{latest.version} (human approved)")
    else:
        try:
            cur = client.get_model_version_by_alias(MODEL_NAME, "champion")
            record["champion_version"] = str(cur.version)
        except Exception:
            record["champion_version"] = None
        print(f"PENDING — champion={record['champion_version']} "
              f"(set APPROVE=1 to promote v{latest.version})")
    out = REPO_ROOT / "artifacts" / "models"
    out.mkdir(parents=True, exist_ok=True)
    (out / "promotion.json").write_text(json.dumps(record, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
