#!/usr/bin/env python3
"""monitor.py — Studio-9 monitoring entry point (basic slice, Thinh).

Same decision logic as explore `drift.py` (KS drift_score >= 0.40 OR
target PSI > 0.20), but adapted to the Studio-9 local layout:
reference = train/train.csv, current = data/new_data.csv.

Reads
    train/train.csv   (reference window)
    data/new_data.csv (current batch)
Writes
    reports/drift_report.json
    artifacts/metrics/monitoring_metrics.json
    monitoring/logs/monitoring.log
Exit codes (same convention as src/drift.py):
    0 = NO SIGNIFICANT DRIFT, 2 = DRIFT DETECTED, 1 = error.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

BASE_FEATURES = [
    "ghi_fc", "dni_fc", "dhi_fc", "temp_fc", "cloud_fc", "wind_fc", "wx_source",
    "solar_zenith", "solar_azimuth", "ghi_clear", "kt_fc",
    "poa_fc", "temp_cell_fc", "p_phys_norm",
    "kwp", "technology_code", "tracking_code", "tilt_deg", "surface_azimuth_pvlib",
    "hour_sin", "hour_cos", "doy_sin", "doy_cos",
]
TARGET_COL = "target_norm"

KS_ALPHA = float(os.environ.get("DRIFT_KS_ALPHA", "0.05"))
KS_DRIFT_THRESHOLD = float(os.environ.get("DRIFT_KS_DRIFT_THRESHOLD", "0.40"))
PSI_THRESHOLD = float(os.environ.get("DRIFT_PSI_THRESHOLD", "0.20"))
PSI_BINS = int(os.environ.get("DRIFT_PSI_BINS", "10"))


def _psi(expected, actual, bins=PSI_BINS) -> float:
    import numpy as np

    breaks = np.histogram_bin_edges(expected, bins=bins)
    e_counts, _ = np.histogram(expected, bins=breaks)
    a_counts, _ = np.histogram(actual, bins=breaks)
    e_perc = e_counts / max(e_counts.sum(), 1)
    a_perc = a_counts / max(a_counts.sum(), 1)
    eps = 1e-4
    e_perc = e_perc + eps
    a_perc = a_perc + eps
    return float(((a_perc - e_perc) * __import__("numpy").log(a_perc / e_perc)).sum())


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="python src/monitor.py")
    ap.add_argument("--reference", default=str(REPO_ROOT / "train" / "train.csv"))
    ap.add_argument("--current", default=str(REPO_ROOT / "data" / "new_data.csv"))
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    log = logging.getLogger("monitor")

    try:
        import numpy as np
        import pandas as pd
        from scipy.stats import ks_2samp
    except ImportError as exc:
        log.error("missing dependency: %s (pip install pandas scipy numpy)", exc)
        return 1

    ref = pd.read_csv(args.reference)
    cur = pd.read_csv(args.current)
    feats = [c for c in BASE_FEATURES if c in ref.columns and c in cur.columns]
    ks_rows = []
    for col in feats:
        r = pd.to_numeric(ref[col], errors="coerce").dropna().to_numpy()
        c = pd.to_numeric(cur[col], errors="coerce").dropna().to_numpy()
        if len(r) == 0 or len(c) == 0:
            continue
        p = float(ks_2samp(r, c).pvalue)
        ks_rows.append({"feature": col, "p_value": p, "drifted": p < KS_ALPHA})
    drifted = sum(1 for k in ks_rows if k["drifted"])
    drift_score = drifted / max(len(ks_rows), 1)

    psi_val = None
    if TARGET_COL in ref.columns and TARGET_COL in cur.columns:
        r = pd.to_numeric(ref[TARGET_COL], errors="coerce").dropna().to_numpy()
        c = pd.to_numeric(cur[TARGET_COL], errors="coerce").dropna().to_numpy()
        if len(r) and len(c):
            psi_val = _psi(r, c)

    ks_triggered = drift_score >= KS_DRIFT_THRESHOLD
    psi_triggered = psi_val is not None and psi_val > PSI_THRESHOLD
    drift = bool(ks_triggered or psi_triggered)

    report = {
        "reference": os.path.basename(args.reference),
        "current": os.path.basename(args.current),
        "n_reference": int(len(ref)),
        "n_current": int(len(cur)),
        "ks": {"alpha": KS_ALPHA, "threshold": KS_DRIFT_THRESHOLD,
               "drifted": drifted, "tested": len(ks_rows),
               "drift_score": round(drift_score, 4), "triggered": ks_triggered,
               "per_feature": ks_rows},
        "psi": {"target": TARGET_COL, "threshold": PSI_THRESHOLD,
                "value": round(psi_val, 4) if psi_val is not None else None,
                "triggered": psi_triggered},
        "drift_detected": drift,
    }
    out_dir = REPO_ROOT / "reports"
    met_dir = REPO_ROOT / "artifacts" / "metrics"
    log_dir = REPO_ROOT / "monitoring" / "logs"
    out_dir.mkdir(parents=True, exist_ok=True)
    met_dir.mkdir(parents=True, exist_ok=True)
    log_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "drift_report.json").write_text(json.dumps(report, indent=2))
    (met_dir / "monitoring_metrics.json").write_text(json.dumps({
        "drift_score": report["ks"]["drift_score"],
        "target_psi": report["psi"]["value"],
        "drift_detected": drift,
    }, indent=2))
    with open(log_dir / "monitoring.log", "a") as fh:
        fh.write(f"drift={drift} score={drift_score:.2f} psi={psi_val}\n")

    status = "DRIFT DETECTED" if drift else "NO SIGNIFICANT DRIFT"
    print(f"{status}  (score={drift_score:.2f}, psi={psi_val})")
    return 2 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
