#!/usr/bin/env bash
# Fetch explore vendor code (pinned) + apply basic-slice patches.
# Usage: bash setup/fetch-vendor.sh [dest]  (default: repo root)
set -euo pipefail
DEST="${1:-$(dirname "$0")/..}"
PIN="b5a99bdca927b07d06a8d61863c8c48b551ba867"
SRC="https://github.com/COS40007-2026-MinhHA10-Fall26/pv-forecasting.git"
TMP="$(mktemp -d)"
git clone -q --depth 1 "$SRC" "$TMP" 2>/dev/null || git clone -q "$SRC" "$TMP"
(cd "$TMP" && git fetch -q origin "$PIN" && git checkout -q "$PIN")
mkdir -p "$DEST/src" "$DEST/config"
cp "$TMP/drift.py" "$TMP/evaluate.py" "$TMP/ingest.py" "$TMP/retrain.py" "$DEST/src/"
cp -r "$TMP/jobs" "$DEST/"
cp -r "$TMP/pvdata" "$DEST/" 2>/dev/null || true
cp "$TMP/config/pipeline.yaml" "$DEST/config/"
cp "$TMP/requirements.txt" "$DEST/" 2>/dev/null || true
for p in "$(dirname "$0")"/vendor-patches/*.patch; do
  (cd "$DEST" && patch -p1 < "$p")
done
rm -rf "$TMP"
echo "vendor ready at $DEST (pin $PIN)"
