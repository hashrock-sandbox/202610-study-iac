output "bucket_url" {
  value = google_storage_bucket.study.url
}

output "service_account_email" {
  value = google_service_account.app.email
}

output "run_url" {
  value = google_cloud_run_v2_service.hello.uri
}
