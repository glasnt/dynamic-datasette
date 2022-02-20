TODO process contents of data bucket, and update/create a metadata.json in that bucket

data to contain: processing date/time, hash?

# Update Metadata

(Re-)writes a `metadata.json` file with information about the data being served, to be displayed by Datasette. 

## Deploy

```
gcloud functions deploy update-metadata \
    --entry-point update \
    --runtime python39 \
    --trigger-http \
    --no-allow-unauthenticated
```