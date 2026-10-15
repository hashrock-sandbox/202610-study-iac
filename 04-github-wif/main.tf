# This stack is applied by hand only. CI never manages its own credentials.

locals {
  services = [
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}

resource "google_project_service" "wif" {
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.repository_id" = "assertion.repository_id"
    "attribute.ref"           = "assertion.ref"
  }

  # Without this, ANY GitHub repository could exchange tokens with this pool.
  attribute_condition = "assertion.repository_id == '${var.github_repository_id}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  pool_name = google_iam_workload_identity_pool.github.name
}

# ---- plan: read-only, usable from any branch / PR in the repo ----

resource "google_service_account" "tf_plan" {
  account_id   = "github-tf-plan"
  display_name = "GitHub Actions terraform plan"
}

resource "google_project_iam_member" "tf_plan" {
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer", # read IAM policies on buckets / services
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_plan.email}"
}

resource "google_service_account_iam_member" "tf_plan_wif" {
  service_account_id = google_service_account.tf_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository_id/${var.github_repository_id}"
}

# ---- apply: write access, only from the main branch ----

resource "google_service_account" "tf_apply" {
  account_id   = "github-tf-apply"
  display_name = "GitHub Actions terraform apply"
}

resource "google_project_iam_member" "tf_apply" {
  for_each = toset([
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser", # deploy Cloud Run as study-app
    "roles/serviceusage.serviceUsageAdmin",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# PR runs get ref "refs/pull/N/merge", so they can never match this.
resource "google_service_account_iam_member" "tf_apply_wif" {
  service_account_id = google_service_account.tf_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.ref/refs/heads/main"
}

# ---- state bucket: both need it (plan takes a lock too) ----

data "google_storage_bucket" "tfstate" {
  name = "${var.project_id}-tfstate"
}

resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = {
    plan  = google_service_account.tf_plan.email
    apply = google_service_account.tf_apply.email
  }
  bucket = data.google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${each.value}"
}
