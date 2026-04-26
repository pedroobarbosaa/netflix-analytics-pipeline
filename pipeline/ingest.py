"""
ingest.py — Netflix Analytics Pipeline
Upload local CSV files to Google Cloud Storage (bronze layer).

Usage:
    python ingest.py --data-dir ./data --credentials ./service-account.json

The script maps each local CSV to its expected filename in GCS so that
the BigQuery external tables keep working without any changes.
"""

import argparse
import os
import sys
from pathlib import Path

from google.cloud import storage
from google.oauth2 import service_account


# ── Configuration ────────────────────────────────────────────────────────────

BUCKET_NAME = "pedro-barbosa-netflix-data"
GCS_PREFIX  = "bronze"

# Maps local filename → destination filename in GCS
# Edit this if your local files have different names
FILE_MAP = {
    "movies.csv":                       "movies.csv",
    "user_rating_history.csv":          "user_rating_history.csv",
    "user_additional_rating.csv":       "ratings_for_additional_users.csv",
    "user_recommendation_history.csv":  "user_recommendation_history.csv",
    "movie_elicitation_set.csv":        "movie_elicitation_set.csv",
    "belief_data.csv":                  "belief_data.csv",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def sizeof_fmt(num_bytes: int) -> str:
    for unit in ["B", "KB", "MB", "GB"]:
        if num_bytes < 1024:
            return f"{num_bytes:.1f} {unit}"
        num_bytes /= 1024
    return f"{num_bytes:.1f} TB"


def upload_file(client: storage.Client, local_path: Path, gcs_blob_name: str) -> None:
    bucket = client.bucket(BUCKET_NAME)
    blob   = bucket.blob(gcs_blob_name)

    size = local_path.stat().st_size
    print(f"  uploading  {local_path.name}  →  gs://{BUCKET_NAME}/{gcs_blob_name}  ({sizeof_fmt(size)})")

    blob.upload_from_filename(str(local_path))
    print(f"  ✓ done\n")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Upload CSVs to GCS bronze layer.")
    parser.add_argument(
        "--data-dir",
        default="./data",
        help="Folder containing the CSV files (default: ./data)",
    )
    parser.add_argument(
        "--credentials",
        default="./service-account.json",
        help="Path to GCP service account JSON (default: ./service-account.json)",
    )
    args = parser.parse_args()

    data_dir    = Path(args.data_dir)
    credentials = Path(args.credentials)

    # ── Validate inputs ───────────────────────────────────────────────────────
    if not data_dir.is_dir():
        print(f"[error] data directory not found: {data_dir}")
        sys.exit(1)

    if not credentials.is_file():
        print(f"[error] credentials file not found: {credentials}")
        sys.exit(1)

    # ── Build GCS client ──────────────────────────────────────────────────────
    creds  = service_account.Credentials.from_service_account_file(str(credentials))
    client = storage.Client(credentials=creds)

    print(f"\n Netflix Analytics Pipeline — GCS Ingest")
    print(f" Bucket : gs://{BUCKET_NAME}/{GCS_PREFIX}/")
    print(f" Source : {data_dir.resolve()}\n")

    # ── Upload files ──────────────────────────────────────────────────────────
    uploaded = 0
    skipped  = 0

    for local_name, gcs_name in FILE_MAP.items():
        local_path = data_dir / local_name

        if not local_path.exists():
            print(f"  [skip] {local_name} not found in {data_dir}")
            skipped += 1
            continue

        gcs_blob_name = f"{GCS_PREFIX}/{gcs_name}"
        upload_file(client, local_path, gcs_blob_name)
        uploaded += 1

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"─────────────────────────────────────────")
    print(f" {uploaded} file(s) uploaded   {skipped} skipped")
    print(f"─────────────────────────────────────────\n")


if __name__ == "__main__":
    main()
