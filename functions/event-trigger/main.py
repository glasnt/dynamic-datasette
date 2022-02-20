import os
import json

from google.cloud.workflows.executions_v1.services.executions import ExecutionsClient
from google.cloud.workflows.executions_v1.types import Execution

client = ExecutionsClient()

GOOGLE_CLOUD_PROJECT = os.environ.get(
    "GOOGLE_CLOUD_PROJECT"
)  # this must be manually set
WORKFLOW_REGION = os.environ.get("WORKFLOW_REGION", "us-central1")
WORKFLOW_NAME = os.environ.get("WORKFLOW_NAME", "datasette_workflow")

DATASETTE_BUCKET = os.environ.get("DATASETTE_BUCKET")

urls = {}

for url in ["GCF_PROCESS_UPLOAD", "GCP_UPDATE_METADATA"]:
    urls[url] = os.environ.get(url)

def trigger(event, context):

    if not DATASETTE_BUCKET:
        raise RuntimeError(
            "No DATASETTE_BUCKET defined, nowhere to put data (Check the environment variables!)"
        )

    if not GOOGLE_CLOUD_PROJECT:
        raise RuntimeError(
            "No GOOGLE_CLOUD_PROJECT defined! This needs to be defined manually. https://cloud.google.com/functions/docs/configuring/env-var#newer_runtimes"
        )

    if "GCF_PROCESS_UPLOAD" not in urls:
        raise RuntimeError(
            "No GCF_PROCESS_UPLOAD defined! I need to know where to process things!"
        )

    if "GCP_UPDATE_METADATA" not in urls:
        raise RuntimeError(
            "No GCP_UPDATE_METADATA defined! I need to know where to update status messages!"
        )

    event_file = event["name"]
    event_bucket = event["bucket"]
    event_type = context.event_type

    if event_type == 'google.storage.object.finalize': 
        print(f"New file event received: {event_file} from {event_bucket}")
    elif event_type == 'google.storage.object.delete': 
        print(f"Delete file event received: {event_file} from {event_bucket}")
        if event_file == "metadata.json":
            print("That's a metata.json update! I ignore those.")
            return "Ignore metadata.json updates", 204
    else: 
        raise RuntimeError(f"Invalid event received: {event_type}")

    print(f"Workflow path: {GOOGLE_CLOUD_PROJECT}, {WORKFLOW_REGION}, {WORKFLOW_NAME}.")
    parent = f"projects/{GOOGLE_CLOUD_PROJECT}/locations/{WORKFLOW_REGION}/workflows/{WORKFLOW_NAME}"
    arguments = {
        "event_type": event_type,
        "event_file": event_file,
        "event_bucket": event_bucket,
        "datasette_bucket": DATASETTE_BUCKET,
        "urls": urls,
    }
    execution = Execution(argument=json.dumps(arguments))

    print(f"Creating execution of workflow with arguments {arguments}")
    response = client.create_execution(parent=parent, execution=execution)
    print("Response:", response.name)

    return "Workflow fired", 201
