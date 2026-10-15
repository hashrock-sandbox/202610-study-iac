# External HTTPS load balancer in front of Cloud Run.
# Request path: forwarding rule -> target proxy -> URL map -> backend service -> serverless NEG -> Cloud Run

locals {
  lb_count = var.enable_lb ? 1 : 0
}

resource "google_compute_global_address" "lb" {
  count = local.lb_count
  name  = "study-lb-ip"

  depends_on = [google_project_service.this["compute.googleapis.com"]]
}

# Serverless NEG: the adapter that lets an LB backend point at a Cloud Run service.
resource "google_compute_region_network_endpoint_group" "run" {
  count                 = local.lb_count
  name                  = "study-hello-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.hello.name
  }

  depends_on = [google_project_service.this["compute.googleapis.com"]]
}

resource "google_compute_backend_service" "run" {
  count                 = local.lb_count
  name                  = "study-hello-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.run[0].id
  }
}

resource "google_compute_url_map" "lb" {
  count           = local.lb_count
  name            = "study-lb"
  default_service = google_compute_backend_service.run[0].id
}

# Google-managed cert: provisions only after the domain's A record points at the LB IP.
resource "google_compute_managed_ssl_certificate" "lb" {
  count = local.lb_count
  name  = "study-lb-cert"

  managed {
    domains = [var.lb_domain]
  }

  depends_on = [google_project_service.this["compute.googleapis.com"]]
}

resource "google_compute_target_https_proxy" "lb" {
  count            = local.lb_count
  name             = "study-lb-https-proxy"
  url_map          = google_compute_url_map.lb[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb[0].id]
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = local.lb_count
  name                  = "study-lb-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb[0].id
  port_range            = "443"
  target                = google_compute_target_https_proxy.lb[0].id
}
