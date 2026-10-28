#!/usr/bin/env python3
"""promote_champion.py — Human Approval Gate (basic slice, own code).

Sets the `champion` alias to the latest model version ONLY when
APPROVE=1 in env (manual human decision). Bootstrap exception: if NO
champion exists yet, the latest version is promoted automatically so a
cold runner (fresh CI cache) self-heals; the gate still guards every
REPLACEMENT of an existing champion.
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
    try:
        cur = client.get_model_version_by_alias(MODEL_NAME, "champion")
        current_champion = str(cur.version)
    except Exception:
        current_champion = None
    approved = os.environ.get("APPROVE", "") == "1"
    bootstrap = current_champion is None
    record = {
        "model": MODEL_NAME,
        "latest_version": str(latest.version),
        "approved": approved,
        "bootstrap": bootstrap,
    }
    if approved or bootstrap:
        client.set_registered_model_alias(
            MODEL_NAME, "champion", str(latest.version))
        record["champion_version"] = str(latest.version)
        how = "human approved" if approved else "BOOTSTRAP (first champion)"
        print(f"PROMOTED — champion -> v{latest.version} ({how})")
    else:
        record["champion_version"] = current_champion
        print(f"PENDING — champion=v{current_champion} "
              f"(set APPROVE=1 to promote v{latest.version})")
    out = REPO_ROOT / "artifacts" / "models"
    out.mkdir(parents=True, exist_ok=True)
    (out / "promotion.json").write_text(json.dumps(record, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
