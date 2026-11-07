// 06 — Rubric: Contribution (6 pts) + Appendix (evidence, limitations, refs).
#heading(level: 1)[Contribution]
*Basic — Lâm An Thịnh (105508512):* `src/{monitor,preprocess_new_data}.py`,
`setup/{promote_champion,snapshot_train,gen_perf_report}.py` (incl. dashboard),
`dvc.yaml` (5 stages), own Supabase-S3 DVC remote + round-trip verification,
`retrain-on-push.yml` (3 triggers, approval gate, cold-runner bootstrap),
sample-data curation (train/test/new_data + 6 monthly CSVs), vendor pruning by
import trace (33 files kept), June data-push live demo, all evidence figures,
this report — Studio-9 paths `monitoring/`, `logs/`, `artifacts/metadata/`
added per brief.
*Explore — Toàn, Khanh (+ group):* LSTM architecture and trainer, champion
evaluation pipeline, drift detectors and thresholds, monthly exports, Supabase
project setup — reused as a traced, credited subset (PROVENANCE, consent
logged). This report differs from the Ass2 exploration by construction: it
documents the basic monitoring/retraining loop, not model exploration.

#heading(level: 1)[Appendix]
#heading(level: 2)[Evidence index]
Every claim above resolves to an artefact:
#list(
  [Repo `github.com/LAT-06/AI-engineering-as3`, branch `main` — semantic commits (@fig-commits).],
  [DVC remote Supabase S3 `processed_data`; `dvc push` 10+ files per run; `dvc status` clean (@fig-dvcstatus).],
  [MLflow registry `mlruns/mlflow.db`, model `pv-lstm-fleet` v1→v8; champion v6, RMSE 0.09454, R² 0.8427 (@fig-rmse, @fig-train, @fig-mlruns, @fig-mlreg).],
  [Checkpoints `artifacts/<run_id>/checkpoint.pt` in Supabase; local copy `artifacts/models/checkpoint.pt`.],
  [CI `Retrain on Push (Studio 9)` — push/schedule/manual, approval gate, cold-runner green (@fig-ci); live data-push demo (@fig-demonstration, @fig-demolog).],
  [Drift evidence `reports/drift_report.json` (score 0.4783, PSI 1.229, exit 2, @fig-drift).],
  [Eval evidence `evaluation_metrics.json` + `performance_report.html` (live 0.09959 vs 0.09454, hold).],
  [Monitoring trail: `logs/training.log`, `logs/drift_detection.log`, `monitoring/logs/monitoring.log`, `monitoring/alerts/` (@fig-logs); dashboard `monitoring_dashboard.html` (@fig-dashboard).],
  [PM: Jira SCRUM-61…66 under SCRUM-75 (@fig-jira); repo issues #1–#9 (@fig-ghrepo).],
)

#heading(level: 2)[Limitations & future work]
The demo trains on six months (Jan–Jun 2024), so seasonal coverage is partial
and the drift anchor (`DRIFT_REFERENCE_DATE`) is fixed for reproducibility
rather than live `today`. The registry travels via CI cache, which is
best-effort — a Postgres-backed MLflow store (already supported by the explore
code via `SQL_ALCHEMY_DATABASE_URL`) would make champion continuity durable.
`src/ingest.py` (live DKASC/Open-Meteo fetch) was pruned as unused; reconnecting
it gives a true new-data-per-day loop.

#heading(level: 2)[References]
#list(
  [Studio 9 brief: ML retraining pipeline — `retrain-on-push.yml`, `dvc.yaml`, `artifacts/`, `monitoring/`, three triggers.],
  [Group repo `COS40007-2026-MinhHA10-Fall26/pv-forecasting` @ `b5a99bd` — explore model/drift/evaluate code.],
  [Supabase Storage S3 API; DVC S3 remotes; MLflow Model Registry aliases (`candidate`/`champion`); GitHub Actions `workflow_dispatch` inputs and caches.],
)
