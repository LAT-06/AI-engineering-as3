// 04 — Actions / CI-CD (expanded).
#heading(level: 1)[Actions: Retrain on Push]
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
capped at 60 minutes; training itself takes ~1 minute on CPU (early stopping,
patience 10).

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
  image("../figs/fig_gh_run.png", width: 90%),
  caption: [Latest push-triggered run of `Retrain on Push (Studio 9)` — Success on `main` (8bb29c2), 2m46s, reports artefact published. Address bar shows group repo `LAT-06/AI-engineering-as3`.],
) <fig-ci>
#figure(
  image("../figs/fig_gh_repo.png", width: 90%),
  caption: [Group repo home: 9 PM issues (basic/explore labels) double as the board backlog.],
) <fig-ghrepo>

#heading(level: 2)[Training evidence]
#figure(
  image("../figs/fig_training_curve.png", width: 85%),
  caption: [Champion v6 training curve (CPU): best val loss 0.00596 at epoch 7, early stop at epoch 16. VAL_RMSE 0.07718, TEST_RMSE 0.09454, R² 0.8427.],
) <fig-train>
The curve is textbook healthy: train and validation losses fall together, the
best checkpoint (not the last) is kept, and early stopping fires after 10 flat
epochs — no overfitting, no wasted compute.

#heading(level: 2)[Registry evidence]
The MLflow UI (`mlflow ui --backend-store-uri sqlite:///mlruns/mlflow.db`, viewed
at `localhost:5050`) shows the same history from the inside: six runs in the
`pv-lstm-fleet` experiment, and the registry holding both aliases — `@candidate`
and `@champion` — on the winning version:
#figure(
  image("../figs/fig_mlflow_runs.png", width: 90%),
  caption: [Experiment `pv-lstm-fleet`: six runs, one per challenger (v1–v6).],
) <fig-mlruns>
#figure(
  image("../figs/fig_mlflow_registry.png", width: 90%),
  caption: [Model registry: `@candidate` + `@champion` aliases on the winning version; the promotion gate in visible form.],
) <fig-mlreg>
