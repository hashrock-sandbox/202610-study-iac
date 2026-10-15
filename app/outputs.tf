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

output "lb_ip" {
  description = "Point the lb_domain A record (DNS only) here"
  value       = var.enable_lb ? google_compute_global_address.lb[0].address : null
}

output "lb_url" {
  value = var.enable_lb ? "https://${var.lb_domain}" : null
}
