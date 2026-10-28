// 01 — Cover handled in main.typ (title/authors). This file: abstract + acknowledgment.
#heading(level: 1)[Abstract]
This report presents the *basic* Studio-9 slice of the AI-engineering AS3
project: a retraining pipeline for the PV-LSTM solar forecasting model that
fires on data push, on schedule, and on manual request. Built on the
explore sub-team's model code (see PROVENANCE), the basic contribution adds:
(1) a 5-stage DVC pipeline (`preprocess → train → promote → evaluate → monitor`)
with a Supabase-S3 remote, (2) a `retrain-on-push.yml` GitHub Actions workflow
with three triggers and a human approval gate, and (3) drift/evaluate evidence
that closes the loop from detection to retraining. All pipeline runs are
reproducible end-to-end: `dvc repro` is green and CI passes on a cold runner.

#heading(level: 1)[Acknowledgment]
Model, evaluation and drift-detection code by Toàn & Khanh (explore).
PV data pipeline and exports by the group. Basic slice — pipeline, DVC,
CI/CD, monitoring integration and this report — by Lâm An Thịnh.
Reuse of explore code was approved by Bình Phương (Discord, Oct 2026) with
the single condition that this report reads as pipeline work, not exploration.
