// Part 2 snapshot (auto-built from report/02..06).

// 02 — Rubric: Automated Retraining Trigger (8 pts).
#heading(level: 1)[Automated Retraining Trigger]
A retrain is justified by two independent signals: *data drift* (the input
distribution shifted, so the model extrapolates) and *performance drift* (live
error exceeds the champion baseline by more than 15%). Either signal can start
the loop; both are checked automatically on every pipeline run — and the loop
itself fires on data push, on a weekly schedule, and on manual request.

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
`src/monitor.py` (basic) ports the same rule to the Studio-9 data layout —
reference `train/train.csv` vs current `data/new_data.csv` — and persists
machine-readable evidence (`reports/drift_report.json`,
`artifacts/metrics/monitoring_metrics.json`, `monitoring/logs/monitoring.log`,
plus the Studio-9 paths in §5). Exit codes follow the group convention:
0 stable, 2 drift, 1 error. On the demo sample:

#figure(
  image("figs/fig_drift.png", width: 85%),
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

#heading(level: 2)[Live demo: data push retrains by itself]
Following Studio 9 step C, a fresh June batch (last 50 rows of 2024-06) was
committed to `data/new_data.csv` and pushed — no manual trigger. GitHub Actions
detected the push and ran the full pipeline unassisted:

#figure(
  image("figs/fig_gh_demo_run.png", width: 90%),
  caption: [Push-triggered demo run: commit `data: add new June batch` → pipeline Success in 5m25s, reports artefact published.],
) <fig-demonstration>
#figure(
  image("figs/fig_ci_demo.png", width: 95%),
  caption: [Demo-run log: June batch scores drift 0.70; CI trains challenger (TEST_RMSE 0.09017, R² 0.8569) → `candidate`; gate stays PENDING without APPROVE=1; live eval holds (ratio 0.859).],
) <fig-demolog>

// 03 — Rubric: Commit Structure (4 pts) + DVC Usage (8 pts).
#heading(level: 1)[Commit Structure]
Work lives in `LAT-06/AI-engineering-as3` on `main` as small semantic commits —
each a reviewable step (sample data, DVC remote, monitor, pipeline, vendor
subset, CI, docs), spread across days so history reads as a logbook, not a
dump:

#figure(
  image("figs/fig_ev_commits.png", width: 90%),
  caption: [Semantic commit history on `main`: data → DVC → monitor → pipeline → vendor subset → CI → docs.],
) <fig-commits>

Group-shared code is committed as a minimal import-traced subset, not a blob:
`src/retrain.py` + `src/evaluate.py`, `jobs/{retrain,evaluate,common}_*`, the
CSV downloader, `config/pipeline.yaml`, `requirements.txt`. Tracing all three
entries showed 33 used files and zero `pvdata` imports, so the whole `pvdata/`
stack, ingest/drift pipelines and unused tools were pruned. Full provenance,
consent log and the two applied adaptations live in PROVENANCE.

#heading(level: 1)[DVC Usage]
#heading(level: 2)[Data]
Training data is six monthly exports (2024-01 → 2024-06, 55,310 rows × 40
columns) in the team's own Supabase bucket (`processed_data/processed/`),
plus committed samples for review: `train/train.csv` (rows 1–1000),
`test/test.csv` (rows 1001–1200), `data/new_data.csv` (latest batch, currently
the June demo rows). `src/preprocess_new_data.py` validates the incoming batch
against the train schema (fail-fast on mismatch) and stages
`artifacts/preprocessing/` + `artifacts/data/validated_new_data.csv`. The
trainer splits chronologically 70/15/15 — Train 2024-01→04 (36,027 rows), Val
2024-05 (10,013), Test 2024-06 (9,270) — into LSTM windows of size 6 (train
18,479 / val 4,681 / test 4,620).

#heading(level: 2)[DVC pipeline]
#figure(
  image("figs/fig_pipeline.png", width: 90%),
  caption: [The five DVC stages. `promote` is the human approval gate between training and evaluation.],
) <fig-pipeline>

`dvc.yaml` defines five stages with explicit deps/outs:

#table(
  columns: 3,
  [*Stage*], [*Runs*], [*Key outputs (DVC-tracked)*],
  [preprocess], [`src/preprocess_new_data.py`], [`artifacts/preprocessing/`, `artifacts/data/`, `artifacts/metadata/data_version.txt`],
  [train], [`src/retrain.py` + `setup/snapshot_train.py`], [`artifacts/models/checkpoint.pt`, `training_summary.json`, `artifacts/metadata/model_version.txt`, `last_retrain.txt`, `logs/training.log`],
  [promote], [`setup/promote_champion.py`], [`artifacts/models/promotion.json`],
  [evaluate], [`src/evaluate.py` + `setup/gen_perf_report.py`], [`reports/performance_report.html`, `reports/monitoring_dashboard.html`, `evaluation_metrics.json`],
  [monitor], [`src/monitor.py`], [`reports/drift_report.json`, `monitoring/reports/`, `monitoring/alerts/`, `logs/drift_detection.log`, `monitoring_metrics.json`],
)

The data remote is Supabase S3; `dvc push` versions every output and `dvc status`
is clean after `dvc repro`:

#figure(
  image("figs/fig_ev_dvc.png", width: 70%),
  caption: [`dvc status` clean after `dvc repro` — all five stages reproducible from scratch.],
) <fig-dvcstatus>

A deliberate design point: the mutable `mlruns/mlflow.db` registry is *not* a
DVC output (the promote step edits it in place, which would dirty `train`
forever). Instead the train stage snapshots the immutable artefacts —
downloaded `checkpoint.pt` plus `training_summary.json` — while the registry
itself travels between CI runs via cache (see §4).

#heading(level: 2)[Retraining history]
Eight challengers trained; each version registers in MLflow, and only
better-than-champion versions upload checkpoints — the loop visibly converges
instead of churning:

#figure(
  image("figs/fig_rmse_versions.png", width: 85%),
  caption: [Test RMSE per challenger (v1–v8). v4 (0.09089) was best at the time; v6 (0.09454, R² 0.8427) is the current champion; v7/v8 stay candidates.],
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
  [v7], [0.09569], [0.8388], [worse — stays candidate],
  [v8], [0.09610], [0.8374], [worse — stays candidate],
)
Skipped uploads are not failures — the pipeline compares every challenger to
the champion and only persists improvements, which is why storage holds exactly
the checkpoints that mattered.

// 04 — Rubric: Final GitHub Actions Setup (12 pts).
#heading(level: 1)[Final GitHub Actions Setup]
`.github/workflows/retrain-on-push.yml` implements the three required triggers
in one workflow. *Push* fires on data or code changes (`data/**`, `train/**`,
`test/**`, `src/**`, `setup/**`, `dvc.yaml`, `config/pipeline.yaml`, the
workflow itself). *Schedule* runs the identical pipeline weekly
(`cron: 0 18 * * 0`) so drift is caught even with no new data. *Manual*
(`workflow_dispatch`) exposes an `approve` flag wired straight to the promotion
gate for live demos: run without approval to mint a candidate, re-run with
`approve=true` to crown it champion in front of the markers.

#heading(level: 2)[How a run works]
Each run checks out the repo (vendor code is committed — no private-repo
token needed), installs CPU-only torch plus the pinned requirements, restores
the MLflow registry from cache (champion continuity across ephemeral runners),
configures the DVC remote from secrets, runs `dvc repro`, pushes outputs back
to S3, re-saves the registry cache, and uploads a `studio9-reports` artefact
bundle. The drift gate writes its verdict to the job summary. Timeouts are
capped at 60 minutes; training itself takes ~2–3 minutes on CPU (early
stopping, patience 10).

#heading(level: 2)[Manual trigger proof]
A `workflow_dispatch` run with `approve=true` exercised the third trigger live:
the challenger (RMSE 0.10051) beat the runner's champion (0.10157) and the gate
promoted it on the spot — no push, no schedule involved:
#figure(
  image("figs/fig_promote.png", width: 95%),
  caption: [Manual dispatch with approval: challenger → `candidate` → `PROMOTED — champion -> v9 (human approved)`. The human gate works from the Actions UI, ready for the live demo.],
) <fig-promote>

#heading(level: 2)[Secrets]
Five GitHub Secrets, all read-only credentials for the team's *own* Supabase
project — never committed (`.env` and `.dvc/config.local` are git-ignored):
`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `S3_ACCESS_KEY_ID`,
`S3_SECRET_ACCESS_KEY`, `S3_ENDPOINT_URL`. Discord notification is
best-effort: unset webhook logs a warning and continues, so CI never depends
on chat infrastructure.

#heading(level: 2)[Cold-runner story]
The first CI run exposed a real bootstrap problem: a fresh runner has an empty
registry, so the first model becomes `candidate`, the gate (correctly) stays
shut, and `evaluate` fails with no champion. The fix keeps the gate honest —
`setup/promote_champion.py` auto-promotes only when *no champion exists yet*
and still requires `APPROVE=1` for every *replacement*. CI has been green since,
including on cold runners:

#figure(
  image("figs/fig_gh_run.png", width: 90%),
  caption: [Push-triggered run of `Retrain on Push (Studio 9)` — Success on `main`, reports artefact published. Address bar shows group repo `LAT-06/AI-engineering-as3`.],
) <fig-ci>
#figure(
  image("figs/fig_gh_repo.png", width: 90%),
  caption: [Group repo home: 9 PM issues (basic/explore labels) double as the board backlog.],
) <fig-ghrepo>

#heading(level: 2)[Training evidence]
#figure(
  image("figs/fig_training_curve.png", width: 85%),
  caption: [Champion v6 training curve (CPU): best val loss 0.00596 at epoch 7, early stop at epoch 16. VAL_RMSE 0.07718, TEST_RMSE 0.09454, R² 0.8427.],
) <fig-train>
The curve is textbook healthy: train and validation losses fall together, the
best checkpoint (not the last) is kept, and early stopping fires after 10 flat
epochs — no overfitting, no wasted compute.

#heading(level: 2)[Registry evidence]
The MLflow UI (`mlflow ui --backend-store-uri sqlite:///mlruns/mlflow.db`, viewed
at `localhost:5050`) shows the same history from the inside: eight runs in the
`pv-lstm-fleet` experiment, and the registry holding both aliases — `@candidate`
and `@champion` — on the winning version:
#figure(
  image("figs/fig_mlflow_runs.png", width: 90%),
  caption: [Experiment `pv-lstm-fleet`: one run per challenger (v1–v8).],
) <fig-mlruns>
#figure(
  image("figs/fig_mlflow_registry.png", width: 90%),
  caption: [Model registry: `@candidate` + `@champion` aliases on the winning version; the promotion gate in visible form.],
) <fig-mlreg>

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
  image("figs/fig_logs.png", width: 95%),
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
  image("figs/fig_dashboard.png", width: 85%),
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
  image("figs/fig_jira_board.png", width: 90%),
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

