"""
supabase_storage.py — Upload and manage CSV files on Supabase Storage.

Uses the supabase-py client (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY).
Uploads upsert by default; use skip_if_exists=True to avoid re-uploading
files that are already present in the bucket.
"""

from __future__ import annotations

import io
import logging
import os
import time
from pathlib import Path

import pandas as pd

logger = logging.getLogger(__name__)

_RETRY_ATTEMPTS = 3
_RETRY_BACKOFF_S = 3.0


def _retry(fn, *args, attempts: int = _RETRY_ATTEMPTS, backoff: float = _RETRY_BACKOFF_S, **kwargs):
    """Call fn(*args, **kwargs) up to `attempts` times, retrying on SSL/network errors."""
    import ssl
    last_exc: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            return fn(*args, **kwargs)
        except (ssl.SSLError, OSError, ConnectionError) as exc:
            last_exc = exc
            if attempt < attempts:
                wait = backoff * attempt
                logger.warning(
                    "Network error (attempt %d/%d): %s — retrying in %.0fs …",
                    attempt, attempts, exc, wait,
                )
                time.sleep(wait)
            else:
                raise
    raise last_exc  # unreachable, but satisfies type checkers


def _get_client():
    """
    Build a Supabase client from environment variables.

    supabase-py's create_client expects a bare base URL (scheme + hostname),
    e.g. https://project.supabase.co — NOT https://project.supabase.co/rest/v1/.
    We strip any path component so the storage API resolves correctly:
      ✅  /storage/v1/object/...
      ❌  /rest/v1/storage/v1/object/...  (when URL has trailing path)
    """
    try:
        from supabase import create_client
    except ImportError as e:
        raise ImportError(
            "supabase-py is required: pip install supabase"
        ) from e

    from urllib.parse import urlparse
    raw_url = os.environ["SUPABASE_URL"]
    parsed = urlparse(raw_url)
    # Keep only scheme + hostname — drop /rest/v1/ or any other path
    base_url = f"{parsed.scheme}://{parsed.hostname}"

    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(base_url, key)


def _default_bucket() -> str:
    return os.environ["SUPABASE_RAW_DATA_BUCKET"]


def upload_csv(
    df: pd.DataFrame,
    bucket_path: str,
    bucket_name: str | None = None,
    skip_if_exists: bool = False,
) -> None:
    """
    Upload a DataFrame as CSV to Supabase Storage.

    Args:
        df:             DataFrame to upload.
        bucket_path:    Path inside the bucket, e.g. "processed/2026-09.csv".
        bucket_name:    Bucket name (default: SUPABASE_RAW_DATA_BUCKET env var).
        skip_if_exists: If True, skip upload when the file already exists on
                        Supabase (saves bandwidth for frozen past-month files).
    """
    bucket_name = bucket_name or _default_bucket()

    client = _get_client()
    storage = client.storage.from_(bucket_name)

    if skip_if_exists:
        folder, _, filename = bucket_path.rpartition("/")
        try:
            existing = _retry(storage.list, folder) or []
            if any(f.get("name") == filename for f in existing):
                logger.info("⏭️  Skipped (already on Supabase): %s", bucket_path)
                return
        except Exception as exc:
            logger.warning("Could not check existence of %s: %s — uploading anyway", bucket_path, exc)

    buf = io.BytesIO()
    df.to_csv(buf, index=False, encoding="utf-8")
    csv_bytes = buf.getvalue()

    logger.info(
        "Uploading %s → bucket '%s' (%s rows, %.1f KB)",
        bucket_path, bucket_name, len(df), len(csv_bytes) / 1024,
    )

    _retry(
        storage.upload,
        path=bucket_path,
        file=csv_bytes,
        file_options={
            "content-type": "text/csv; charset=utf-8",
            "upsert": "true",
        },
    )
    logger.info("✅ Uploaded: %s", bucket_path)


def list_files(
    prefix: str = "processed",
    bucket_name: str | None = None,
) -> list[str]:
    """
    List file names under a prefix in the Supabase Storage bucket.

    Returns:
        List of file names (not full paths), e.g. ["2026-09.csv", "2026-10.csv"].
    """
    bucket_name = bucket_name or _default_bucket()
    client = _get_client()
    folder = prefix.rstrip("/")
    response = _retry(client.storage.from_(bucket_name).list, folder)
    return [f["name"] for f in (response or [])]


def get_latest_month(
    prefix: str = "processed",
    bucket_name: str | None = None,
) -> str | None:
    """
    Return the latest YYYY-MM already uploaded to Supabase Storage.

    Scans filenames of the form YYYY-MM.csv under the given prefix.
    Returns None if the bucket is empty (triggers a full upload on first run).

    Example:
        ["2024-01.csv", ..., "2026-10.csv"]  →  "2026-10"
        []                                    →  None
    """
    files = list_files(prefix=prefix, bucket_name=bucket_name)
    months = [
        f.replace(".csv", "")
        for f in files
        if f.endswith(".csv") and len(f) == 11  # "YYYY-MM.csv" is exactly 11 chars
    ]
    if not months:
        logger.info("Supabase bucket empty — full upload on first run")
        return None
    latest = max(months)
    logger.info("Latest month already on Supabase: %s", latest)
    return latest

def get_latest_record_ts(
    prefix: str = "processed",
    bucket_name: str | None = None,
) -> tuple[str | None, "pd.Timestamp | None"]:
    """
    Find the latest record timestamp already on Supabase.

    Downloads the most recent monthly CSV and reads the max ts_utc_end value.

    Returns:
        (latest_month, latest_ts)  e.g. ("2026-10", Timestamp("2026-10-08 23:00:00+00:00"))
        (None, None)               if bucket is empty (first run)
    """
    import pandas as pd

    latest_month = get_latest_month(prefix=prefix, bucket_name=bucket_name)
    if latest_month is None:
        return None, None

    bucket_path = f"{prefix}/{latest_month}.csv"
    logger.info("Downloading %s to find latest record timestamp …", bucket_path)
    df = download_csv(bucket_path, bucket_name=bucket_name)

    ts_col = "ts_utc_end"
    if ts_col not in df.columns:
        logger.warning("%s has no '%s' column — falling back to month-level", bucket_path, ts_col)
        return latest_month, None

    latest_ts = pd.to_datetime(df[ts_col], utc=True).max()
    logger.info("Latest record on Supabase: %s  (in %s)", latest_ts, latest_month)
    return latest_month, latest_ts


def download_csv(
    bucket_path: str,
    bucket_name: str | None = None,
) -> pd.DataFrame:
    """
    Download a CSV file from Supabase Storage and return as a DataFrame.

    Args:
        bucket_path:  Path inside the bucket, e.g. "processed/2026-09.csv".
        bucket_name:  Bucket name (default: SUPABASE_RAW_DATA_BUCKET env var).
    """
    bucket_name = bucket_name or _default_bucket()
    client = _get_client()
    raw = _retry(client.storage.from_(bucket_name).download, bucket_path)
    return pd.read_csv(io.BytesIO(raw))
