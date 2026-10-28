// 04 — Actions: CI/CD workflow + training evidence.
#heading(level: 1)[Actions: Retrain on Push]
`.github/workflows/retrain-on-push.yml` implements the three required triggers:
(1) *push* — fires on `data/**`, `train/**`, `test/**`, `src/**`, `setup/**`,
`dvc.yaml`, `config/pipeline.yaml`; (2) *schedule* — weekly cron
(`0 18 * * 0`); (3) *manual* — `workflow_dispatch` with an `approve` flag wired
to the promotion gate. Each run restores the MLflow registry from cache
(champion continuity), runs `dvc repro`, pushes outputs, and uploads
`studio9-reports` artifacts. Secrets (`SUPABASE_*`, `S3_*`) are GitHub Secrets,
never committed. CI passes on a cold runner (verified run green 2026-10-28;
a first-run bootstrap promotes the initial champion, while every *replacement*
still needs `approve=true`).

#figure(
  image("figs/fig_training_curve.png", width: 85%),
  caption: [Champion v6 training curve (CPU): best val loss 0.00596 at epoch 7, early stop at epoch 16. VAL_RMSE 0.07718, TEST_RMSE 0.09454.],
) <fig-train>
