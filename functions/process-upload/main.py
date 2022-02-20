import os
import subprocess
from pathlib import Path

import filetype
from google.cloud import storage

DATASETTE_BUCKET = os.environ.get("DATASETTE_BUCKET")

client = storage.Client()

def process(request):

    if not DATASETTE_BUCKET:
        raise RuntimeError(
            "No DATASETTE_BUCKET defined, nowhere to put data (check the environment variables!)"
        )

    data = request.get_json()
    print(f"Data: {data}")

    upload_file = data["event_file"]
    upload_bucket = data["event_bucket"]

    temp_file = f"/tmp/{upload_file}"
    generated_name = upload_file.replace(".", "-") + ".db"
    processed_file = f"/tmp/{generated_name}"

    print(f"Downloading {upload_file} from {upload_bucket}.")
    client.bucket(upload_bucket).blob(upload_file).download_to_filename(temp_file)

    kind = filetype.guess(temp_file)
    extension = kind.extention if kind else Path(upload_file).suffix

    print(f"Stored {temp_file} with extension {extension}.")

    if extension == "sqlite":
        print("Skipping processing. Detected an SQLite file already!")
        processed_file = temp_file

    elif extension == ".csv":
        print("Processing as CSV using csvs-to-sqlite")
        subprocess.check_call(["csvs-to-sqlite", temp_file, processed_file])

    elif extension in [".md", ".markdown"]:
        print("Processing as markdown using markdown-to-sqlite")
        subprocess.check_call(
            ["markdown-to-sqlite", processed_file, "markdown_data", temp_file]
        )

    elif extension in [".yml", ".yaml"]:
        print("Processing as YAML using yaml-to-sqlite")
        subprocess.check_call(
            ["yaml-to-sqlite", processed_file, "yaml_data", temp_file]
        )
    else:
        raise ValueError(f"Extension {extension} not supported.")

    print(f"Uploading {processed_file} to {DATASETTE_BUCKET}.")
    client.bucket(DATASETTE_BUCKET).blob(generated_name).upload_from_filename(processed_file)

    return "Processing complete."
