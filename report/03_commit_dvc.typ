// 03 — Commits & DVC.
#heading(level: 1)[Commits & DVC Versioning]
Work lives in `LAT-06/AI-engineering-as3` (`main`), as small semantic commits
(12 commits, e.g. `b641500 feat(data)…`, `2c860d4 feat: Studio-9 DVC pipeline…`,
`574aed1 feat: commit minimal group-shared subset…`). Group-shared code is a
minimal import-traced subset (`src/retrain.py`, `src/evaluate.py`,
`jobs/{retrain,evaluate,common}_*` plus the CSV downloader); `pvdata/`,
ingest and drift stacks were pruned (full provenance in PROVENANCE).

#figure(
  image("../figs/fig_ev_commits.png", width: 90%),
  caption: [Semantic commit history on `main` — small reviewable steps (data, DVC, monitor, pipeline, vendor subset, CI).],
) <fig-commits>

#heading(level: 2)[Pipeline]
#figure(
  image("../figs/fig_pipeline.png", width: 90%),
  caption: [The five DVC stages. `promote` is the human approval gate between training and evaluation.],
) <fig-pipeline>

`dvc.yaml` defines `preprocess → train → promote → evaluate → monitor`.
Data remote is the team's own Supabase S3 (`processed_data` bucket);
`dvc push` versioned 12 outputs and `dvc status` reports everything up to date.
#figure(
  image("../figs/fig_ev_dvc.png", width: 70%),
  caption: [`dvc status` clean after `dvc repro` — all five stages reproducible.],
) <fig-dvcstatus>
Training data: 6 monthly CSVs (2024-01→06, 55,310 rows), chronological
70/15/15 split (4/1/1 months; windows 18,479/4,681/4,620).

#heading(level: 2)[Retraining history]
Six challengers were trained; each version is registered in MLflow and only
better-than-champion versions upload checkpoints — the loop visibly converges:

#figure(
  image("../figs/fig_rmse_versions.png", width: 85%),
  caption: [Test RMSE per version. v4 (0.09089) was best at the time; v6 (0.09454, R² 0.8427) is the current champion.],
) <fig-rmse>

#table(
  columns: 4,
  [*Ver*], [*Test RMSE*], [*Test R²*], [*Outcome*],
  [v1], [0.09320], [0.8471], [first model],
  [v2], [0.10032], [0.8228], [worse — skipped],
  [v3], [0.10257], [0.8148], [worse — skipped],
  [v4], [0.09089], [0.8546], [candidate + uploaded],
  [v5], [0.10221], [0.8161], [worse — skipped],
  [v6], [0.09454], [0.8427], [*champion*],
)
