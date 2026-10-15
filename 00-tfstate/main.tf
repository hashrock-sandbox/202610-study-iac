# Bucket that holds Terraform state for the other stacks.
# This stack itself keeps local state (chicken-and-egg), so it is the only one to bootstrap by hand.
resource "google_storage_bucket" "tfstate" {
  name     = "${var.project_id}-tfstate"
  location = var.region

  # Losing state is painful, so never delete this bucket via destroy.
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Keep old state versions so a broken apply can be rolled back.
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
