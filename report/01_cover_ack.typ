// 01 — Abstract + acknowledgment (expanded).
#heading(level: 1)[Abstract]
Solar output shifts with weather, season and panel condition, so a forecasting
model frozen at training time silently rots. This report presents the *basic*
Studio-9 slice of the AI-engineering AS3 project: an automated retraining
pipeline for the group's PV-LSTM solar forecasting model that fires on data
push, on a weekly schedule, and on manual request — and that refuses to promote
a new model without a human decision.

The work builds on the explore sub-team's model code (LSTM trainer, champion
evaluation, drift detectors; see PROVENANCE) and contributes the automation
around it: (1) a five-stage DVC pipeline
(`preprocess → train → promote → evaluate → monitor`) backed by the team's own
Supabase S3 bucket, with every output versioned by `dvc push`; (2) a
`retrain-on-push.yml` GitHub Actions workflow implementing all three triggers
plus a human approval gate wired to model promotion; (3) a lightweight monitor
(`src/monitor.py`) that applies the group's drift rule to the Studio-9 data
layout and exits non-zero to trigger retraining; and (4) this report with
end-to-end evidence. Key results: six challengers trained (test RMSE
0.09089–0.10257), champion v6 at RMSE 0.09454 / R² 0.8427; drift signals
(KS 0.4783, PSI 1.229) both above threshold, correctly firing the pipeline;
live evaluation within 5.3% of champion, correctly holding fire; `dvc repro`
green locally and CI green on a cold GitHub runner.

The remainder of the report is organised as follows: §2 details the retraining
triggers and the evidence behind each; §3 covers commits, data and DVC
versioning with the full retraining history; §4 walks through the CI/CD
workflow, secrets handling and training evidence; §5 records project-management
tracking; §6 splits contributions, indexes every evidence artefact, and notes
limitations and future work.

#heading(level: 1)[Acknowledgment]
Model, evaluation and drift-detection code by Toàn & Khanh (explore); PV data
pipeline, monthly exports and the `pvdata` stack by the group. The basic slice
— pipeline orchestration, DVC remote, CI/CD, monitoring integration, sample
data curation, all evidence figures and this report — by Lâm An Thịnh. Reuse of
explore code was approved by Bình Phương (Discord, Oct 2026) with the single
condition that this report reads as pipeline work, not exploration: hence every
section below is framed around automation, versioning and triggers, and every
claim is backed by a runnable artefact or a linked run.
