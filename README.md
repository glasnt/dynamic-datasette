# Datasette Workflows

This project is a demonstration of hosting Datasette in Cloud Run that serves a series of SQLite database files from a Cloud Storage bucket. 

The "Extended" section also shows a Workflow to take uploaded CSV, JSON, and [other](https://github.com/glasnt/dynamic-datasette) files and convert them to SQLite for hosting.

## Local demonstration

* Create a virtual environment, install datasette, and serve the sample data:
    ```
    python -m venv venv
    source venv/bin/activate
    pip install -U datasette
    datasette serve sample_data
    ```

## Deployment

Deployment for this project is multi-stage: first with Infrastructure-as-Code, then with command-line driven service deployment. 

Use the provided Terraform files to deploy the Cloud Functions, Workflow, and associated Cloud Storage buckets. 

Terraform is provided within [Cloud Shell](https://cloud.google.com/shell), or you will have to install it yourself. 


Once Terraform is available: 

```
cd terraform
terraform init
terraform apply
```

Terraform will prompt for a Google Cloud Project ID, and will end with the command required to deploy the Cloud Run service (in the `/terraform/create_service.sh` file). Terraform doesn't build containers, so this demo chooses to use `gcloud run deploy --source` to deploy the service in one additional command once Terraform is complete.

## Limited setup

If you want to just deploy the simple service and backing bucket, you can perform the following steps:

* Create a Google Cloud project with billing enabled (refered to as `PROJECT_ID`)
* Create a Cloud Storage bucket to store data uploads: 
    ```
    DATA_BUCKET=data-${PROJECT_ID}
    gsutil mb gs://${DATA_BUCKET}
    ```
* Upload some sample data: 
    ```
    gsutil cp sample_data/*.sqlite gs://${DATA_BUCKET}
    ```
* Deploy the Cloud Run service
    ```
    gcloud beta run deploy datasette \
        --region us-central1 \
        --platform managed \
        --source services/datasette-web \
        --allow-unauthenticated \
        --execution-environment=gen2 \
        --set-env-vars GCS_BUCKET=${DATA_BUCKET}
    ```
    (This command will ask you to enable a number of APIs. Type "y" each time to continue. )

A hosted version of Datasette will now be available at `https://datasette-HASH-REGION.a.run.app`, serving the sample data.

*Note*: this demo chooses not to use `datasette publish cloudrun`, as there are additional Dockerfile alterations required. This is an open if you wish to deploy a single hosted database in datasette to Cloud Run.


