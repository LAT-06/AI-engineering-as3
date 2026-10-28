// 06 — Contribution split + appendix (evidence index).
#heading(level: 1)[Contribution & Appendix]
*Basic (Lâm An Thịnh)*: `src/{monitor,preprocess_new_data}.py`,
`setup/{promote_champion,snapshot_train,gen_perf_report}.py`, `dvc.yaml`,
Supabase-S3 DVC remote, `retrain-on-push.yml`, sample data curation,
all evidence figures, this report.
*Explore (Toàn, Khanh + group)*: LSTM model, retrain/evaluate pipelines,
drift detectors, `pvdata` stack, monthly exports — reused as a traced subset
(PROVENANCE).

#heading(level: 2)[Evidence index]
#list(
  [Repo: `github.com/LAT-06/AI-engineering-as3`, branch `main`.],
  [DVC remote: Supabase S3 `processed_data`; `dvc push` = 12 files; `dvc status` clean.],
  [MLflow registry: `mlruns/mlflow.db`, model `pv-lstm-fleet` v1→v6, champion v6 (RMSE 0.09454).],
  [Checkpoints: `artifacts/<run_id>/checkpoint.pt` in Supabase; local copy `artifacts/models/checkpoint.pt`.],
  [CI: workflow `Retrain on Push (Studio 9)` — push/schedule/manual, cold-runner green.],
  [Metrics: `artifacts/metrics/{evaluation,monitoring}_metrics.json`, `reports/drift_report.json`, `reports/performance_report.html`.],
)

#heading(level: 2)[References]
#list(
  [Studio 9 brief: ML retraining pipeline with `retrain-on-push.yml`, `dvc.yaml`, `artifacts/`, `monitoring/`.],
  [Group repo: `COS40007-2026-MinhHA10-Fall26/pv-forecasting` @ `b5a99bd`.],
  [Supabase Storage S3 API; DVC S3 remote; MLflow Model Registry aliases (`candidate`/`champion`); GitHub Actions `workflow_dispatch` inputs.],
)
