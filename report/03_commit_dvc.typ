// 03 — Commits, data & DVC (expanded).
#heading(level: 1)[Commits & DVC Versioning]
Work lives in `LAT-06/AI-engineering-as3` on `main` as small semantic commits —
each a reviewable step (sample data, DVC remote, monitor, pipeline, vendor
subset, CI, report), spread across days so history reads as a logbook, not a
dump:

#figure(
  image("../figs/fig_ev_commits.png", width: 90%),
  caption: [Semantic commit history on `main`: data → DVC → monitor → pipeline → vendor subset → CI → report.],
) <fig-commits>

Group-shared code is committed as a minimal import-traced subset, not a blob:
`src/retrain.py` + `src/evaluate.py`, `jobs/{retrain,evaluate,common}_*`, the
CSV downloader, `config/pipeline.yaml`, `requirements.txt`. Tracing all three
entries showed 33 used files and zero `pvdata` imports, so the whole `pvdata/`
stack, ingest/drift pipelines and unused tools were pruned (396 KB kept of the
original tree). Full provenance, consent log and the two applied adaptations
live in PROVENANCE.

#heading(level: 2)[Data]
Training data is six monthly exports (2024-01 → 2024-06, 55,310 rows × 40
columns) in the team's own Supabase bucket (`processed_data/processed/`),
plus committed samples for review: `train/train.csv` (rows 1–1000),
`test/test.csv` (rows 1001–1200), `data/new_data.csv` (last 50 rows).
`src/preprocess_new_data.py` validates the incoming batch against the train
schema (fail-fast on mismatch) and stages `artifacts/preprocessing/` +
`artifacts/data/validated_new_data.csv`. The trainer splits chronologically
70/15/15 — Train 2024-01→04 (36,027 rows), Val 2024-05 (10,013), Test 2024-06
(9,270) — into LSTM windows of size 6 (train 18,479 / val 4,681 / test 4,620).

#heading(level: 2)[DVC pipeline]
#figure(
  image("../figs/fig_pipeline.png", width: 90%),
  caption: [The five DVC stages. `promote` is the human approval gate between training and evaluation.],
) <fig-pipeline>

`dvc.yaml` defines five stages with explicit deps/outs:

#table(
  columns: 3,
  [*Stage*], [*Runs*], [*Key outputs (DVC-tracked)*],
  [preprocess], [`src/preprocess_new_data.py`], [`artifacts/preprocessing/`, `artifacts/data/`],
  [train], [`src/retrain.py` + `setup/snapshot_train.py`], [`artifacts/models/checkpoint.pt`, `training_summary.json`],
  [promote], [`setup/promote_champion.py`], [`artifacts/models/promotion.json`],
  [evaluate], [`src/evaluate.py` + `setup/gen_perf_report.py`], [`reports/performance_report.html`, `evaluation_metrics.json`],
  [monitor], [`src/monitor.py`], [`reports/drift_report.json`, `monitoring_metrics.json`],
)

The data remote is Supabase S3; `dvc push` versioned 12 outputs and `dvc status`
is clean after `dvc repro`:

#figure(
  image("../figs/fig_ev_dvc.png", width: 70%),
  caption: [`dvc status` clean after `dvc repro` — all five stages reproducible from scratch.],
) <fig-dvcstatus>

A deliberate design point: the mutable `mlruns/mlflow.db` registry is *not* a
DVC output (the promote step edits it in place, which would dirty `train`
forever). Instead the train stage snapshots the immutable artefacts —
downloaded `checkpoint.pt` plus `training_summary.json` — while the registry
itself travels between CI runs via cache (see §4).

#heading(level: 2)[Retraining history]
Six challengers were trained; each version registers in MLflow, and only
better-than-champion versions upload checkpoints — the loop visibly converges
instead of churning:

#figure(
  image("../figs/fig_rmse_versions.png", width: 85%),
  caption: [Test RMSE per version. v4 (0.09089) was best at the time; v6 (0.09454, R² 0.8427) is the current champion.],
) <fig-rmse>

#table(
  columns: 4,
  [*Ver*], [*Test RMSE*], [*Test R²*], [*Outcome*],
  [v1], [0.09320], [0.8471], [first model → candidate],
  [v2], [0.10032], [0.8228], [worse — upload skipped],
  [v3], [0.10257], [0.8148], [worse — upload skipped],
  [v4], [0.09089], [0.8546], [better → candidate + uploaded],
  [v5], [0.10221], [0.8161], [worse — upload skipped],
  [v6], [0.09454], [0.8427], [*champion* (human-approved)],
)
Skipped uploads are not failures — the pipeline compares every challenger to
the champion and only persists improvements, which is why storage holds exactly
the checkpoints that mattered.
