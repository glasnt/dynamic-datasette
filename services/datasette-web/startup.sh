#!/bin/bash

if [ -z "${GCS_BUCKET}" ]; then
    echo "No GCS_BUCKET defined. Exiting."
    exit 1
fi

echo "Mounting Cloud Storage bucket $GCS_BUCKET $MNT_DIR"
gcsfuse --debug_gcs --debug_fuse $GCS_BUCKET $MNT_DIR

echo "Directory contents:"
ls $MNT_DIR

if test -f "$MNT_DIR/metadata.json"; then
   echo "Using $MNT_DIR/metadata.json"
   METADATA="--metadata $MNT_DIR/metadata.json"
else
   echo "No metadata.json found, not using."
fi

echo "Starting datasette on port $PORT, serving $MNT_DIR"
datasette serve --host 0.0.0.0 --port $PORT --cors --setting force_https_urls on $METADATA $MNT_DIR

