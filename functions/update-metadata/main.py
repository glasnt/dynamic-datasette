import os
import json
from google.cloud import storage
from datetime import datetime

DATASETTE_BUCKET = os.environ.get("DATASETTE_BUCKET")

client = storage.Client()

def update(request):

    if not DATASETTE_BUCKET:
        raise RuntimeError("No DATASETTE_BUCKET defined, nowhere to put data (Check the environment variables!)")
    
    print(f"Updating metadata about ${DATASETTE_BUCKET}.")
    metadata_file = "metadata.json"
    metadata_fn = "/tmp/" + metadata_file

    now = datetime.now().strftime("%a %b %-d %Y, %H:%M:%S")

    metadata = {
        "title":"Dynamic Datasette",
        "description": f"Reading from source as at {now} UTC."
    }
    print("Metadata:", str(metadata))

    with open(metadata_fn, "w") as f:
        json.dump(metadata, f)

    print(f"Uploading {metadata_file} to {DATASETTE_BUCKET}.")
    client.bucket(DATASETTE_BUCKET).blob(metadata_file).upload_from_filename(metadata_fn)

    return "Metadata update complete."

