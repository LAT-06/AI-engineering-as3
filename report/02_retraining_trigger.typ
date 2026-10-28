// 02 — Retraining trigger: drift + performance evidence.
#heading(level: 1)[Retraining Trigger]
A retrain is justified by two independent signals: *data drift* (the input
distribution shifted) and *performance drift* (live error exceeds the champion
baseline by a factor of 1.15).

#heading(level: 2)[Data drift]
`src/monitor.py` applies the group's rule — KS drift-score $>= 0.40$ or target
PSI $> 0.20$ — to the Studio-9 layout (`train/train.csv` vs `data/new_data.csv`).
On the demo sample it reports:

#figure(
  image("../figs/fig_drift.png", width: 85%),
  caption: [Drift signals vs thresholds: KS score 0.4783 (thr 0.40), target PSI 1.229 (thr 0.20). Both exceeded — exit code 2, retrain triggered.],
) <fig-drift>

#table(
  columns: 3,
  [*Signal*], [*Value*], [*Threshold*],
  [KS drift score (11/23 feats)], [0.4783], [0.40],
  [Target PSI (`target_norm`)], [1.229], [0.20],
  [Decision], [DRIFT DETECTED], [exit 2],
)

#heading(level: 2)[Performance check]
`src/evaluate.py` loads the champion from the MLflow registry and scores it on
the live window (last 500 rows of 2024-05/06). Latest result: live RMSE 0.09959
vs champion v6 RMSE 0.09454 (ratio 1.053 $<= 1.15$) — *RETRAIN NOT NEEDED*,
i.e. the current champion still holds. The gate therefore fires retrains from
drift, not from noise.
