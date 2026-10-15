# IAM API must be enabled before service accounts can be created.
resource "google_project_service" "iam" {
  service = "iam.googleapis.com"

  # Keep the API enabled on destroy; other resources may still rely on it.
  disable_on_destroy = false
}

# Bucket is managed in 01-gcs-bucket (separate state), so look it up instead of creating it.
data "google_storage_bucket" "study" {
  name = "${var.project_id}-tf-study-01"
}

resource "google_service_account" "app" {
  account_id   = "study-app"
  display_name = "Study App"
  description  = "Managed by Terraform (02-iam)"

  depends_on = [google_project_service.iam]
}

# Additive grant: only adds this member, never removes existing ones.
resource "google_storage_bucket_iam_member" "app_reader" {
  bucket = data.google_storage_bucket.study.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.app.email}"
}
