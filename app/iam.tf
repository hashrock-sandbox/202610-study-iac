resource "google_service_account" "app" {
  account_id   = "study-app"
  display_name = "Study App"
  description  = "Managed by Terraform (app)"

  depends_on = [google_project_service.this["iam.googleapis.com"]]
}

# Additive grant: only adds this member, never removes existing ones.
resource "google_storage_bucket_iam_member" "app_reader" {
  bucket = google_storage_bucket.study.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.app.email}"
}
