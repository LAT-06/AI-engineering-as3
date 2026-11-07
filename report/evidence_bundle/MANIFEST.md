# Evidence bundle — numbers & captions for the report (do NOT edit Typst, paste from here)

Generated 2026-11-07. All figures are PNGs in this folder; all logs are .txt.
Cloud upload status: these exact files already live in the group Typst project
under `figs/` (uploaded 2026-11-07, diagnostics 0 errors).

## 1. Drift numbers — CURRENT (old report text is STALE, replace it)

- KS drift score: **0.6957** (16/23 features, threshold 0.40) — was 0.4783/11-23 on the old sample
- Target PSI (`target_norm`): **0.2716** (threshold 0.20) — was 1.229 on the old sample
- Verdict: DRIFT DETECTED, exit code 2
- Figure: `fig_drift.png` (REGENERATED to match these numbers)
- Source: `logs_monitoring.txt` (top section)
- Suggested caption: "Data drift on the June batch vs train: KS score 0.6957 (16/23 feats, thr 0.40), target PSI 0.2716 (thr 0.20). Both exceeded — exit 2, retrain triggered."

## 2. Retraining history — CURRENT (report table stops at v6, extend it)

| Ver | Test RMSE | Test R² | Outcome |
| v1 | 0.09320 | 0.8471 | first model → candidate |
| v2 | 0.10032 | 0.8228 | worse — upload skipped |
| v3 | 0.10257 | 0.8148 | worse — upload skipped |
| v4 | 0.09089 | 0.8546 | better → candidate + uploaded |
| v5 | 0.10221 | 0.8161 | worse — upload skipped |
| v6 | 0.09454 | 0.8427 | champion (human-approved, local registry) |
| v7 | 0.09569 | 0.8388 | worse — stays candidate |
| v8 | 0.09610 | 0.8374 | worse — stays candidate |

- Figure: `fig_rmse_versions.png` (REGENERATED, shows v1–v8, champion line at v6)
- Note: CI runners have their own registry copy (cache); there the champion is v9
  (promoted via manual approve demo, RMSE 0.10051). Local champion stays v6.

## 3. Live demo (push trigger) — run 42370904088, Success, 5m25s

- Figures: `fig_gh_demo_run.png` (run page + address bar), `fig_ci_demo.png` (log screenshot)
- Raw log: `ci_demo_run_log.txt` (9 lines: TEST_RMSE 0.09017 → candidate → PENDING → live eval hold ratio 0.859 → DRIFT 0.70)
- Commit: `data: add new June batch for retraining demo`

## 4. Manual trigger proof — run 42371968291, `workflow_dispatch` approve=true

- Figure: `fig_promote.png` (PROMOTED — champion -> v9 (human approved))
- Raw log: `ci_manual_approve_log.txt` (7 lines)
- Also fixed that day: cold-runner `mkdir -p logs` before tee; evaluate exit-2 no longer fails the pipeline

## 5. Monitoring trail (Studio-9 layout)

- Raw: `logs_monitoring.txt` — drift_detection.log tail, monitoring.log tail,
  artifacts/metadata/*.txt (data SHA, model version, last retrain), alerts list, training.log tail
- Figures: `fig_logs.png` (log trail screenshot), `fig_dashboard.png` (monitoring_dashboard.html)
- Brief coverage: monitoring/{reports,logs,alerts} ✓, metadata versions ✓,
  logs/{training,monitoring,drift_detection} ✓, reports/{drift,performance,dashboard} ✓,
  checkpoint.pt INSTEAD OF model.keras (PyTorch LSTM, deliberate), validated CSV INSTEAD OF .npy

## 6. Other figures (unchanged, already on cloud)

- `fig_pipeline.png`, `fig_ev_commits.png`, `fig_ev_dvc.png`, `fig_gh_run.png`,
  `fig_gh_repo.png`, `fig_training_curve.png`, `fig_mlflow_runs.png`,
  `fig_mlflow_registry.png`, `fig_jira_board.png`

## 7. Things the report should fix (found while reviewing the pasted draft)

1. Drift numbers + v1–v6-only table/figure text → replace with §1–2 above.
2. DVC stage table misses new outputs (metadata/*.txt, logs/training.log, dashboard, alerts).
3. `figs/github_action_interface.png` is referenced but was never uploaded by me — check it exists on the cloud project or remove the figure.
4. Commit counts ("15 commits") and run durations ("2m46s") are stale — recount at write time.
5. `4. Conclusion.typ` is still empty (explore team's part).
