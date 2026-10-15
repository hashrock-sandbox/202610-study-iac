# Bucket names are globally unique, so prefix with the project ID.
resource "google_storage_bucket" "study" {
  name     = "${var.project_id}-tf-study-01"
  location = var.region

  # Allow `terraform destroy` to delete the bucket even if it contains objects.
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    managed_by = "terraform"
    purpose    = "study"
    owner      = "hashrock"
  }
}
