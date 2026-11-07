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
    drift, promo = {}, {}
    for p_, key in ((REPO_ROOT / "reports" / "drift_report.json", "drift"),
                     (REPO_ROOT / "artifacts" / "models" / "promotion.json", "promo")):
        try:
            (drift if key == "drift" else promo).update(json.loads(p_.read_text()))
        except Exception:
            pass
    rows = ""
    if drift:
        rows += (f"<tr><td>Drift detected</td><td>{drift.get('drift_detected')}</td></tr>"
                 f"<tr><td>KS drift score (thr 0.40)</td><td>{drift.get('ks', {}).get('drift_score')}</td></tr>"
                 f"<tr><td>Target PSI (thr 0.20)</td><td>{drift.get('psi', {}).get('value')}</td></tr>")
    if promo:
        rows += (f"<tr><td>Promotion action</td><td>{promo.get('action')}</td></tr>"
                 f"<tr><td>Champion</td><td>{promo.get('champion_version')}</td></tr>")
    rows += (f"<tr><td>Champion test RMSE</td><td>{baseline}</td></tr>"
             f"<tr><td>Eval threshold ratio</td><td>{summary['eval_threshold_ratio']}</td></tr>")
    (rep / "monitoring_dashboard.html").write_text(
        "<html><head><title>Monitoring dashboard</title></head><body>"
        f"<h1>Monitoring dashboard — {MODEL_NAME}</h1>"
        "<table border='1' cellpadding='6'>"
        "<tr><th>Signal</th><th>Value</th></tr>" + rows + "</table>"
        "<p>Sources: reports/drift_report.json, artifacts/models/promotion.json, "
        "artifacts/metrics/evaluation_metrics.json</p></body></html>")
    print(f"perf report OK — champion v{mv.version} rmse={baseline}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
