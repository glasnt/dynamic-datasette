# Terraform can't create images, 
# so this repo opts to create the service directly in gcloud
# Cloud Run services can be created in Terraform as long as the image exists, 
# but this project's terraform config focuses on all other infrastrucutre. 


PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
REGION=${REGION:-us-central1}
DATASETTE_BUCKET=${DATASETTE_BUCKET:-datasette-${PROJECT_ID}}

echo "Provisioning service to ${PROJECT_ID} in ${REGION}, connecting to ${DATASETTE_BUCKET}..."

gcloud artifacts repositories create cloud-run-source-deploy \
	--repository-format docker \
	--location $REGION

# source is relative pathway
# beta required for gen2
gcloud beta run deploy datasette \
	--platform managed \
	--region $REGION \
	--source ../services/datasette-web \
    --execution-environment gen2 \
    --set-env-vars GCS_BUCKET=${DATASETTE_BUCKET} \
    --allow-unauthenticated