#!/usr/bin/env python3
"""gen_perf_report.py — write Studio-9 evaluation files from MLflow (basic slice).

Reads the champion baseline (test_rmse) from the MLflow registry and writes:
  artifacts/metrics/evaluation_metrics.json
  reports/performance_report.html
Needs MLFLOW_TRACKING_URI env (same store the train stage used).
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
    try:
        mv = client.get_model_version_by_alias(MODEL_NAME, "champion")
    except Exception as exc:
        print(f"no champion alias yet: {exc}")
        return 1
    run = client.get_run(mv.run_id)
    baseline = run.data.metrics.get("test_rmse")

    summary = {
        "model": MODEL_NAME,
        "champion_version": str(mv.version),
        "champion_run_id": mv.run_id,
        "champion_test_rmse": baseline,
        "eval_threshold_ratio": float(os.environ.get("EVAL_DRIFT_THRESHOLD", "1.15")),
    }
    met = REPO_ROOT / "artifacts" / "metrics"
    rep = REPO_ROOT / "reports"
    met.mkdir(parents=True, exist_ok=True)
    rep.mkdir(parents=True, exist_ok=True)
    (met / "evaluation_metrics.json").write_text(json.dumps(summary, indent=2))
    (rep / "performance_report.html").write_text(
        "<html><body><h1>Performance report — champion baseline</h1>"
        f"<p>Model: {MODEL_NAME} v{mv.version}</p>"
        f"<p>Champion test RMSE: {baseline}</p>"
        f"<p>Eval drift threshold ratio: {summary['eval_threshold_ratio']}</p>"
        "</body></html>")
    print(f"perf report OK — champion v{mv.version} rmse={baseline}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
