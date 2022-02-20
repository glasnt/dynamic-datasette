data "google_cloud_run_service" "datasette" {
  name = "datasette"
  location = var.region
  project = var.project
  depends_on = [google_project_service.services]
}


locals { 
    suggest_script = <<EOF

    ✨ Nearly there! ✨


    You have deployed **most** of what's required, but you don't have the Datasette service!

    You can test the deployment so far: 

    gsutil cp ../sample_data/namecity.csv gs://${local.upload_bucket}

    This *should* work through to the 'getService' step.. but that doesn't exist yet!


    Here's what's left to run: 

    PROJECT_ID=${var.project}
    REGION=${var.region}
    DATASETTE_BUCKET=${local.datasette_bucket}
    source create_service.sh

    EOF
}

# If the service doesn't exist, suggest to run that process separately. 
output "result" { 
    value = "${data.google_cloud_run_service.datasette.status == null ? local.suggest_script : "All updated!"}"
    #value = data.google_cloud_run_service.datasette.status
}