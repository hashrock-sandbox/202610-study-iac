# This stack is applied by hand only. CI never manages its own credentials.

locals {
  workflow_prefix = "${var.github_repository}/.github/workflows"
}

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

    # ref alone is not enough: issue_comment, schedule etc. also run with ref=main,
    # and anyone can comment on a public repo. Pin write access to a specific
    # workflow file on main *and* the events we expect, collapsed into one label.
    "attribute.deployer" = <<-EOT
      assertion.ref != 'refs/heads/main' ? 'none' :
      assertion.job_workflow_ref == '${local.workflow_prefix}/terraform.yml@refs/heads/main' && assertion.event_name == 'push' ? 'tf-apply' :
      assertion.job_workflow_ref == '${local.workflow_prefix}/deploy-hello-app.yml@refs/heads/main' && assertion.event_name in ['push', 'workflow_dispatch'] ? 'deploy' :
      'none'
    EOT
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
    "roles/artifactregistry.admin",
    "roles/serviceusage.serviceUsageAdmin",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Allow deploying Cloud Run as study-app only, not as every SA in the project.
data "google_service_account" "app" {
  account_id = "study-app"
}

resource "google_service_account_iam_member" "tf_apply_act_as_app" {
  service_account_id = data.google_service_account.app.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Only terraform.yml on main, triggered by push (see attribute.deployer).
resource "google_service_account_iam_member" "tf_apply_wif" {
  service_account_id = google_service_account.tf_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.deployer/tf-apply"
}

# serviceAccountAdmin includes setIamPolicy on every SA in the project, which lets
# the holder grant itself access to any other SA (privilege escalation).
# This role can manage SAs but never change who may use them.
resource "google_project_iam_custom_role" "sa_manager" {
  role_id     = "terraformServiceAccountManager"
  title       = "Terraform Service Account Manager"
  description = "Create/update/delete service accounts without setIamPolicy or key creation"
  permissions = [
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.disable",
    "iam.serviceAccounts.enable",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.update",
  ]
}

resource "google_project_iam_member" "tf_apply_sa_manager" {
  project = var.project_id
  role    = google_project_iam_custom_role.sa_manager.id
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# ---- deploy: push images and roll out new Cloud Run revisions, only from main ----

resource "google_service_account" "deploy" {
  account_id   = "github-deploy"
  display_name = "GitHub Actions app deploy"
}

resource "google_project_iam_member" "deploy" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/run.developer", # update services, but not change their IAM
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "deploy_act_as_app" {
  service_account_id = data.google_service_account.app.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "deploy_wif" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.deployer/deploy"
}

# ---- default service accounts ----

# GCP auto-creates the Compute Engine default SA with roles/editor. Nothing here
# uses it, and anyone who can act as it gets Editor, so strip that role.
# (google_project_default_service_accounts is a no-op unless the Compute API is
# enabled, which it is not in this project.)
data "google_project" "this" {}

resource "google_project_iam_member_remove" "compute_default_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
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
