// 02 — Retraining trigger (expanded): rule origins, per-signal evidence, design.
#heading(level: 1)[Retraining Trigger]
A retrain is justified by two independent signals: *data drift* (the input
distribution shifted, so the model extrapolates) and *performance drift* (live
error exceeds the champion baseline by more than 15%). Either signal can start
the loop; both are checked automatically on every pipeline run.

#heading(level: 2)[The rule and where it comes from]
Thresholds are inherited from the explore team's detector so basic and explore
stay consistent: KS drift-score $>= 0.40$ (fraction of tested features whose
Kolmogorov–Smirnov p-value $< 0.05$) and target PSI $> 0.20$ computed on
`target_norm` with 10 equal-width bins. The full detector compares the last 7
days against the preceding 30 days of monthly exports and found 15/20 features
drifted (score 0.75), led by seasonal terms (`doy_sin`, `doy_cos`) and weather
inputs (`dhi_fc`, `temp_fc`, `wind_fc`) — exactly the shift (June vs May) that
motivates retraining before summer patterns dominate.

#heading(level: 2)[Data drift on the Studio-9 layout]
`src/monitor.py` (basic, 120 lines) ports the same rule to the Studio-9 data
layout — reference `train/train.csv` (1,000 rows) vs current
`data/new_data.csv` (latest 50 rows) — and persists machine-readable evidence
(`reports/drift_report.json`, `artifacts/metrics/monitoring_metrics.json`,
`monitoring/logs/monitoring.log`). Exit codes follow the group convention:
0 stable, 2 drift, 1 error. On the demo sample:

#figure(
  image("../figs/fig_drift.png", width: 85%),
  caption: [Drift signals vs thresholds: KS score 0.4783 (thr 0.40), target PSI 1.229 (thr 0.20). Both exceeded — exit code 2, retrain triggered.],
) <fig-drift>

#table(
  columns: 3,
  [*Signal*], [*Value*], [*Threshold*],
  [KS drift score (11/23 feats)], [0.4783], [0.40],
  [Target PSI (`target_norm`)], [1.229], [0.20],
  [Top drifted features], [seasonal + irradiance/temperature], [—],
  [Decision], [DRIFT DETECTED], [exit 2],
)

#heading(level: 2)[Performance check holds fire correctly]
`src/evaluate.py` loads the champion from the MLflow registry and scores it on
a live window (last 500 rows of 2024-05/06, 2024-06-29 → 2024-06-30). Against
champion v6 (RMSE 0.09454) the live RMSE is 0.09959 — ratio 1.053, inside the
1.15 band — so the verdict is *RETRAIN NOT NEEDED*: the model still holds and
the pipeline correctly does not retrain on noise. The gate is not toothless,
however: an earlier evaluation against the v1 baseline measured live RMSE
0.15772 (+49%), which demanded — and got — further retraining rounds, landing
on v4 (0.09089) and v6. Drift starts the loop; performance confirms it.
