locals {
  services = [
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "this" {
  for_each = toset(local.services)
  service  = each.value

  # Keep APIs enabled on destroy; other stacks may still rely on them.
  disable_on_destroy = false
}
