terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


locals {
  datasette_bucket = "datasette-${var.project}"
  upload_bucket    = "upload-${var.project}"

  fnsource_bucket = "gcf-source-${var.project}"

  functions_folder = "../functions" #relative to this folder!
  workflows_folder = "../workflows"


  event_trigger      = "event-trigger"
  process_upload     = "process-upload"
  update_metadata    = "update-metadata"
  datasette_workflow = "datasette-workflow"

}

provider "google" {
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}

# Required Services

variable "gcp_services" {
  type = list(string)
  default = [
    "appengine.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "workflows.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each           = toset(var.gcp_services)
  service            = each.value
  disable_on_destroy = false
}

# Cloud Storage

resource "google_storage_bucket" "upload" {
  name                        = local.upload_bucket
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "datasette" {
  name                        = local.datasette_bucket
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}


resource "google_storage_bucket" "fnsource" {
  name     = local.fnsource_bucket
  location = var.region
}

# Cloud Functions
# The archive in Cloud Stoage uses the md5 of the zip file
# Code below ensures the functions are redeployed only when the source is changed.

## event-trigger 
data "archive_file" "event_trigger" {
  type        = "zip"
  output_path = "temp/${local.event_trigger}_${timestamp()}.zip"
  source_dir  = "${local.functions_folder}/${local.event_trigger}"
}

resource "google_storage_bucket_object" "event_trigger" {
  name   = "${local.functions_folder}_${local.event_trigger}_${data.archive_file.event_trigger.output_md5}.zip" # will delete old items
  bucket = google_storage_bucket.fnsource.name
  source = data.archive_file.event_trigger.output_path
}

resource "google_cloudfunctions_function" "event_trigger" {
  name    = local.event_trigger
  runtime = "python39"
  region  = var.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.fnsource.name
  source_archive_object = google_storage_bucket_object.event_trigger.name
  entry_point           = "trigger"

  environment_variables = {
    "GOOGLE_CLOUD_PROJECT" = var.project
    "WORKFLOWS_REGION"     = var.region
    "WORKFLOW_NAME"        = local.datasette_workflow
    "DATASETTE_BUCKET"     = local.datasette_bucket
    "GCF_PROCESS_UPLOAD" = google_cloudfunctions_function.process_upload.https_trigger_url
    "GCP_UPDATE_METADATA" = google_cloudfunctions_function.update_metadata.https_trigger_url
  }

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.upload.name
  }
}

# a second function for the second event to capture. 
resource "google_cloudfunctions_function" "event_trigger_delete" {
  name    = "${local.event_trigger}-delete"
  runtime = "python39"
  region  = var.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.fnsource.name
  source_archive_object = google_storage_bucket_object.event_trigger.name
  entry_point           = "trigger"

  environment_variables = {
    "GOOGLE_CLOUD_PROJECT" = var.project
    "WORKFLOWS_REGION"     = var.region
    "WORKFLOW_NAME"        = local.datasette_workflow
    "DATASETTE_BUCKET"     = local.datasette_bucket
    "GCF_PROCESS_UPLOAD" = google_cloudfunctions_function.process_upload.https_trigger_url
    "GCP_UPDATE_METADATA" = google_cloudfunctions_function.update_metadata.https_trigger_url
  }

  event_trigger {
    event_type = "google.storage.object.delete"
    resource   = google_storage_bucket.datasette.name
  }

  depends_on = [
    google_project_service.services
  ]
}

## process-upload
data "archive_file" "process_upload" {
  type        = "zip"
  output_path = "temp/${local.process_upload}_${timestamp()}.zip"
  source_dir  = "${local.functions_folder}/${local.process_upload}"
}

resource "google_storage_bucket_object" "process_upload" {
  name   = "${local.functions_folder}_${local.process_upload}_${data.archive_file.process_upload.output_md5}.zip" # will delete old items
  bucket = google_storage_bucket.fnsource.name
  source = data.archive_file.process_upload.output_path
}

resource "google_cloudfunctions_function" "process_upload" {
  name    = local.process_upload
  runtime = "python39"
  region  = var.region

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.fnsource.name
  source_archive_object = google_storage_bucket_object.process_upload.name
  entry_point           = "process"
  trigger_http          = true


  environment_variables = {
    "DATASETTE_BUCKET"     = local.datasette_bucket
  }

  depends_on = [
    google_project_service.services
  ]
}



## update_metadata
data "archive_file" "update_metadata" {
  type        = "zip"
  output_path = "temp/${local.update_metadata}_${timestamp()}.zip"
  source_dir  = "${local.functions_folder}/${local.update_metadata}"
}

resource "google_storage_bucket_object" "update_metadata" {
  name   = "${local.functions_folder}_${local.update_metadata}_${data.archive_file.update_metadata.output_md5}.zip" # will delete old items
  bucket = google_storage_bucket.fnsource.name
  source = data.archive_file.update_metadata.output_path
}

resource "google_cloudfunctions_function" "update_metadata" {
  name    = local.update_metadata
  runtime = "python39"
  region  = var.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.fnsource.name
  source_archive_object = google_storage_bucket_object.update_metadata.name
  entry_point           = "update"
  trigger_http          = true


  environment_variables = {
    "DATASETTE_BUCKET"     = local.datasette_bucket
  }

  depends_on = [
    google_project_service.services
  ]
}


# Workflows
resource "google_workflows_workflow" "datasette_workflow" {
  name            = local.datasette_workflow
  region          = var.region
  source_contents = file("${local.workflows_folder}/${local.datasette_workflow}.yaml")

  depends_on = [
    google_project_service.services
  ]
}

