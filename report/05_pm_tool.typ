// 05 — Rubric: Use of Project Management Tool (8 pts) + NEW: Monitoring (Studio-9 core).
#heading(level: 1)[Monitoring]
This section is the heart of the Studio 9 brief: drift, performance and data
quality watched continuously, with every signal landing in centralised storage
as logs, artefacts and reports. Our layout mirrors the brief one-to-one
(coverage table at the end); the only deliberate deviation is replacing
`model.keras`/`.npy` artefacts with LSTM `checkpoint.pt` files, since the model
is a PyTorch LSTM, not a Keras net.

#heading(level: 2)[Directory layout]
#table(
  columns: 2,
  [*Path*], [*What lands there*],
  [`monitoring/logs/monitoring.log`], [one line per monitor run (drift flag, score, PSI)],
  [`monitoring/reports/drift_report.json`], [full monitor verdict incl. per-feature KS table],
  [`monitoring/alerts/alert_<UTC>.json`], [one file per drift event: severity, rule, action],
  [`logs/training.log`], [full retrain stdout, teed from the train stage],
  [`logs/drift_detection.log`], [one line per monitor run (drift, score, PSI, window sizes)],
  [`artifacts/metadata/{data,model}_version.txt`, `last_retrain.txt`], [data SHA + row count; model version; retrain timestamp],
  [`artifacts/metrics/{monitoring,evaluation}_metrics.json`], [live signals vs champion baseline],
  [`reports/{drift_report.json,performance_report.html,monitoring_dashboard.html}`], [machine + human-readable evidence],
)

#heading(level: 2)[Live logs]
The June demo batch wrote the exact trail the brief asks for — drift detected
at 12:04 UTC, alert filed, retraining triggered:

#figure(
  image("../figs/fig_logs.png", width: 95%),
  caption: [Live log trail: `logs/drift_detection.log` + `monitoring/logs/monitoring.log` drift lines, and `artifacts/metadata/` versions (data SHA 776f00bb95fa, model pv-lstm-fleet v7, retrain timestamp).],
) <fig-logs>

#heading(level: 2)[Alert history]
Every drift event files a structured alert so nothing is lost between runs:
```json
{"timestamp_utc": "20261107_120430", "severity": "high",
 "rule": "KS>=0.40 OR PSI>0.20", "drift_score": 0.4783,
 "target_psi": 1.229, "action": "trigger retraining pipeline"}
```

#heading(level: 2)[Monitoring dashboard]
`setup/gen_perf_report.py` renders `reports/monitoring_dashboard.html` from the
three live sources (drift report, promotion record, evaluation metrics) — one
page answering "is the model healthy right now?":

#figure(
  image("../figs/fig_dashboard.png", width: 85%),
  caption: [Monitoring dashboard: drift + promotion + champion-baseline signals on one page, regenerated every pipeline run.],
) <fig-dashboard>

#heading(level: 2)[Brief coverage]
#table(
  columns: 3,
  [*Studio 9 brief item*], [*Ours*], [*Status*],
  [`monitoring/{reports,logs,alerts}/`], [same three dirs, same purpose], [done],
  [`artifacts/metadata/` versions], [`data_version.txt`, `model_version.txt`, `last_retrain.txt`], [done],
  [`logs/{training,monitoring,drift_detection}.log`], [all three, `training.log` teed from train stage], [done],
  [`reports/{drift_report.json,performance_report.html,monitoring_dashboard.html}`], [all three, regenerated per run], [done],
  [`artifacts/models/model.keras`], [`checkpoint.pt` (PyTorch LSTM, not Keras)], [adapted],
  [`artifacts/data/*.npy` staged arrays], [`validated_new_data.csv` + windowed tensors built in-memory by trainer], [adapted],
)

#heading(level: 1)[Use of Project Management Tool]
The team runs Scrum in Jira (`cos40007-mlops.atlassian.net`, project SCRUM,
board 1): Sprints 0–4 map foundation → data/ML pipeline → serving → Task-3
retraining/monitoring → hardening/report. The basic slice lives under
*SCRUM-75 — Applied Project Task 3* (Sprint 3, due 26 Nov) as sub-tasks
SCRUM-61…66, all assigned to Lâm An Thịnh with evidence comments linking each
claim to its artefact (workflow runs, `dvc.yaml`, commit history, registry
metrics). Statuses are updated as work lands — via the Jira API where the
token allows — so the board below is a live snapshot, not a staged photo:

#figure(
  image("../figs/fig_jira_board.png", width: 90%),
  caption: [Sprint 3 board snapshot (live Jira statuses, 29 Oct 2026): 4 Done (trigger workflow, DVC pipeline, Actions setup, semantic commits), 2 In Progress (Jira upkeep, this report), rest scheduled seminar extras.],
) <fig-jira>

#table(
  columns: 3,
  [*Sub-task*], [*Status*], [*Evidence*],
  [SCRUM-61 trigger workflow], [Done], [CI green, 3 triggers],
  [SCRUM-62 DVC pipeline], [Done], [`dvc repro` green],
  [SCRUM-63 Actions setup], [Done], [demo run Success 5m25s],
  [SCRUM-64 semantic commits], [Done], [commits on `main`],
  [SCRUM-65 Jira active use], [In Progress], [this board],
  [SCRUM-66 Task 3 report], [In Progress], [this document],
)
Explore-side work (SCRUM-5/11 model pipeline, SCRUM-22 monitoring spec,
SCRUM-67…72 seminar panels) stays with its owners; the seminar extras
(Grafana, ECS, latency panels) remain To Do as stretch goals.
