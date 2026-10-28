// 06 — Contribution, evidence index, limitations (expanded).
#heading(level: 1)[Contribution & Appendix]

#heading(level: 2)[Who did what]
*Basic — Lâm An Thịnh (105508512):* `src/{monitor,preprocess_new_data}.py`,
`setup/{promote_champion,snapshot_train,gen_perf_report}.py`, `dvc.yaml` (5
stages), own Supabase-S3 DVC remote + round-trip verification,
`retrain-on-push.yml` (3 triggers, approval gate, cold-runner bootstrap),
sample-data curation (train/test/new_data + 6 monthly CSVs), vendor pruning by
import trace (33 files kept), all evidence figures, this report.
*Explore — Toàn, Khanh (+ group):* LSTM architecture and trainer, champion
evaluation pipeline, drift detectors and thresholds, `pvdata` stack, monthly
exports, Supabase project setup — reused as a traced, credited subset
(PROVENANCE, consent logged).

#heading(level: 2)[Evidence index]
Every claim above resolves to an artefact:
#list(
  [Repo `github.com/LAT-06/AI-engineering-as3`, branch `main` — 14 semantic commits.],
  [DVC remote Supabase S3 `processed_data`; `dvc push` = 12 files; `dvc status` clean (@fig-dvcstatus).],
  [MLflow registry `mlruns/mlflow.db`, model `pv-lstm-fleet` v1→v6; champion v6, RMSE 0.09454, R² 0.8427 (@fig-rmse, @fig-train).],
  [Checkpoints `artifacts/<run_id>/checkpoint.pt` in Supabase; local copy `artifacts/models/checkpoint.pt` (0.85 MB).],
  [CI `Retrain on Push (Studio 9)` — push/schedule/manual, approval gate, cold-runner green (@fig-ci).],
  [Drift evidence `reports/drift_report.json` (score 0.4783, PSI 1.229, exit 2, @fig-drift).],
  [Eval evidence `artifacts/metrics/evaluation_metrics.json` + `reports/performance_report.html` (live 0.09959 vs 0.09454, hold).],
  [Commit history @fig-commits; pipeline map @fig-pipeline.],
)

#heading(level: 2)[Limitations & future work]
The demo trains on six months (Jan–Jun 2024), so seasonal coverage is partial
and the drift anchor (`DRIFT_REFERENCE_DATE`) is fixed for reproducibility
rather than live `today`. The registry travels via CI cache, which is
best-effort — a Postgres-backed MLflow store (already supported by the explore
code via `SQL_ALCHEMY_DATABASE_URL`) would make champion continuity durable.
`src/ingest.py` (live DKASC/Open-Meteo fetch) was pruned as unused; reconnecting
it gives a true new-data-per-day loop. PM board screenshots (§5) complete the
process evidence.

#heading(level: 2)[References]
#list(
  [Studio 9 brief: ML retraining pipeline — `retrain-on-push.yml`, `dvc.yaml`, `artifacts/`, `monitoring/`, three triggers.],
  [Group repo `COS40007-2026-MinhHA10-Fall26/pv-forecasting` @ `b5a99bd` — explore model/drift/evaluate code.],
  [Supabase Storage S3 API; DVC S3 remotes; MLflow Model Registry aliases (`candidate`/`champion`); GitHub Actions `workflow_dispatch` inputs and caches.],
)
