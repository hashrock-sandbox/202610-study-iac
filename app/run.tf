resource "google_cloud_run_v2_service" "hello" {
  name     = "study-hello"
  location = var.region

  # Provider defaults to true; disable so `terraform destroy` works while studying.
  deletion_protection = false

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = 0 # scale to zero = no cost while idle
      max_instance_count = 1 # cap cost if the public URL gets hammered
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      # Changing the template creates a new revision, which requires actAs on study-app.
      env {
        name  = "STUDY_MESSAGE"
        value = "deployed by GitHub Actions"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true # bill CPU only while handling requests
      }
    }
  }

  depends_on = [google_project_service.this["run.googleapis.com"]]
}

# Allow unauthenticated access so the URL can be opened in a browser.
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.hello.name
  location = google_cloud_run_v2_service.hello.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
