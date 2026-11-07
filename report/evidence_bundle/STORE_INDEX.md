# Artefact store index — files live in Supabase S3 (DVC remote), not in git
# Generated from dvc.lock. Teammate: `dvc pull` to materialize locally.

## stage `preprocess`
- `artifacts/data/` — 433191 B, md5 `5ff9d0064db7`…, present-locally=True
- `artifacts/metadata/data_version.txt` — 81 B, md5 `6b1ea461af49`…, present-locally=True
- `artifacts/preprocessing/` — 3618 B, md5 `21f5ee2d6269`…, present-locally=True

## stage `train`
- `artifacts/metadata/last_retrain.txt` — 33 B, md5 `12e58bdeaec8`…, present-locally=True
- `artifacts/metadata/model_version.txt` — 17 B, md5 `31fda1425f1f`…, present-locally=True
- `artifacts/metrics/training_history.json` — 214 B, md5 `fa4344780576`…, present-locally=True
- `artifacts/models/checkpoint.pt` — 848885 B, md5 `44cfe5d21d79`…, present-locally=True
- `artifacts/models/training_summary.json` — 286 B, md5 `8f8ba3280fcc`…, present-locally=True
- `logs/training.log` — 6395 B, md5 `4b76869df5a6`…, present-locally=True

## stage `promote`
- `artifacts/models/promotion.json` — 125 B, md5 `68bbdbfd196f`…, present-locally=True

## stage `evaluate`
- `artifacts/metrics/evaluation_metrics.json` — 190 B, md5 `a5fc826ad1d7`…, present-locally=True
- `reports/monitoring_dashboard.html` — 672 B, md5 `4ed7df97bbdc`…, present-locally=True
- `reports/performance_report.html` — 189 B, md5 `6802d08acc7a`…, present-locally=True

## stage `monitor`
- `artifacts/metrics/monitoring_metrics.json` — 77 B, md5 `c3f2b000816f`…, present-locally=True
- `logs/drift_detection.log` — 62 B, md5 `3fdf7a788f50`…, present-locally=True
- `logs/monitoring.log` — 46 B, md5 `4333817e2d65`…, present-locally=True
- `monitoring/alerts/` — 188 B, md5 `48e040132862`…, present-locally=True
- `monitoring/reports/drift_report.json` — 2977 B, md5 `2fa2ecce080d`…, present-locally=True
- `reports/drift_report.json` — 2977 B, md5 `2fa2ecce080d`…, present-locally=True
