# PROVENANCE — reused group code + own work

Studio-9 pipeline logic was built by the explore sub-team (Toàn & Khanh) in
`COS40007-2026-MinhHA10-Fall26/pv-forecasting`
(pin `b5a99bdca927b07d06a8d61863c8c48b551ba867`).
The basic slice (Thịnh) commits a **minimal running subset** below and adds
only Studio-9 integration around it.

## Reused (explore, committed here)
| This repo | Origin |
|---|---|
| `src/retrain.py` | `retrain.py` |
| `src/evaluate.py` | `evaluate.py` |
| `jobs/retrain_pipeline/`, `jobs/retrain_tools/` | same |
| `jobs/evaluate_pipeline/`, `jobs/evaluate_tools/` | same |
| `jobs/common/`, `jobs/__init__.py` | same |
| `jobs/ingest_tools/{__init__,supabase_storage}.py` | same (CSV download used by retrain) |
| `config/pipeline.yaml` | same |
| `requirements.txt` | same (CI dependency list) |

## Pruned 2026-10-28 (verified unused by import trace of all 3 entries)
Dropped: whole `pvdata/` (0 imports), `jobs/ingest_pipeline/`,
`jobs/drift_pipeline/` + `jobs/drift_tools/` (drift entry unused — same
KS≥0.40/PSI>0.20 rule re-implemented in own `src/monitor.py`),
`jobs/ingest_tools/{bootstrap,dvc_helpers,monthly_export,quality}.py`,
`jobs/*.py` root shims, `src/{drift,ingest}.py`.
(CI installs `requirements.txt`; see workflow).

## Consent (quyền reuse)
- Chủ code explore (bphuong) đồng ý reuse: `"Thoải mái m"`, `"làm theo đề là đc"`,
  `"cứ coi như m đang làm 1 bài bth"` (Discord 21:34–21:36).
- Điều kiện duy nhất: report viết khác phần explore Ass2 — nhấn mạnh
  pipeline/automation/DVC theo đề Studio 9, không trình bày như exploration.

## Adapted by basic slice (2 changes, applied in place)
1. `src/retrain.py`, `src/evaluate.py`: `repo_root = ...parent` →
   `...parents[1]` (entry points live in `src/`, not repo root).
2. (reverted with drift stack) `DRIFT_REFERENCE_DATE` no longer needed.

## Verified runs (own Supabase, 2024-01..06 sample)
- Full retrain w/ sqlite MLflow: TEST_RMSE≈0.09–0.10, R²≈0.80;
  versions registered `candidate`, human gate promotes `champion`.
- `evaluate`: compares live RMSE vs champion (×1.15 threshold).
- `src/monitor.py`: DRIFT DETECTED, exit 2 (score 0.48, psi 1.23).
- `dvc repro`: all 5 stages green; `dvc push` → own S3.

## Basic-slice new files (Thịnh)
`src/{monitor,preprocess_new_data}.py`, `setup/{promote_champion,snapshot_train,gen_perf_report}.py`,
`dvc.yaml`, `.github/workflows/retrain-on-push.yml`,
`train/`, `test/`, `data/`.
