output "bucket_url" {
  value = google_storage_bucket.study.url
}

output "service_account_email" {
  value = google_service_account.app.email
}

output "run_url" {
  value = google_cloud_run_v2_service.hello.uri
}

output "image_repository" {
  value = "${google_artifact_registry_repository.apps.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}"
}
