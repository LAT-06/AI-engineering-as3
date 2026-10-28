# VENDOR.md — provenance of reused code

All pipeline logic below was built by the explore sub-team (Toan & Khanh) in
`pv-forecasting`. The basic slice (Thịnh) reuses it unchanged and adds only
Studio-9 integration around it (see `plan.md` in parent folder).

- Source repo: `COS40007-2026-MinhHA10-Fall26/pv-forecasting`
- Source commit: `b5a99bdca927b07d06a8d61863c8c48b551ba867`
  (`feat(task2): add GitHub Actions training pipeline (model.py + train.yml)`)

## Copied unchanged
| This repo | Origin | Built by |
|---|---|---|
| `src/ingest.py` | `ingest.py` | explore |
| `src/retrain.py` | `retrain.py` | explore |
| `src/evaluate.py` | `evaluate.py` | explore |
| `src/drift.py` | `drift.py` | explore |
| `jobs/` (whole tree, incl. `jobs/*.py` duplicates) | `jobs/` | explore |
| `pvdata/` | `pvdata/` | explore |
| `config/pipeline.yaml` | `config/pipeline.yaml` | explore |
| `requirements.txt` | `requirements.txt` | explore |

`jobs/*.py` top-level duplicates (`jobs/ingest.py`, …) are kept as-is for
reference; the live entry points are `src/*.py`.

## Consent (quyền reuse)
- Chủ code explore (bphuong) đồng ý reuse toàn bộ: 4 script + `jobs/ingest*`, `jobs/retrain*`, `jobs/evaluate*`, `jobs/drift*`; setup (DVC/workflow/config) tự làm riêng.
- Điều kiện duy nhất: trong report viết khác phần explore Ass2 một chút (4 jobs gốc config theo hướng exploration Ass2) — cơ bản: nhấn mạnh pipeline/automation/DVC theo đề Studio 9, không trình bày như exploration.
- Chat log: Discord, bphuong 21:34–21:36 (`"Thoải mái m"`, `"làm theo đề là đc"`, `"cứ coi như m đang làm 1 bài bth"`).

## Changed by basic slice
1. `src/*.py`: `repo_root = ...parent` → `...parents[1]` (entry points live in
   `src/`, not repo root). Without this, `jobs`/`pvdata` imports fail.
2. `jobs/drift_pipeline/pipeline.py`: new `DRIFT_REFERENCE_DATE` env (YYYY-MM-DD)
   to anchor windows to the sample range (demo data ends 2024-06-30, not today).
   Unset = today UTC (explore behaviour unchanged).

## Verified runs (own Supabase, 2024-01..06 sample)
- `retrain --dry-run` + full run w/ `sqlite` MLflow: TEST_RMSE=0.10555, R²=0.80,
  v1 registered as `candidate`, manually promoted to `champion` (bootstrap).
- `drift --dry-run` (`DRIFT_REFERENCE_DATE=2024-07-01`): DRIFT (15/20 feats).
- `evaluate --dry-run`: RETRAIN NEEDED (live RMSE 0.15772, +49% vs baseline).
- `monitor.py`: DRIFT DETECTED, exit 2.

## Basic-slice new files (Thịnh)
(none yet — `src/monitor.py`, `dvc.yaml`, `.github/workflows/retrain-on-push.yml`,
`train/`, `test/`, `data/`, `artifacts/`, `reports/` land in later steps)

Patches versioned at `setup/vendor-patches/`; reproduce via `bash setup/fetch-vendor.sh`.
