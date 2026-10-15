variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "hashrock-iac-study"
}

variable "region" {
  description = "Default region"
  type        = string
  default     = "asia-northeast1"
}

# The load balancer bills hourly even when idle (~$18/month), so it is meant to be
# turned on only while studying. Flip this via PR; CI creates or destroys the LB.
variable "enable_lb" {
  description = "Put Cloud Run behind an external HTTPS load balancer"
  type        = bool
  default     = false
}

variable "lb_domain" {
  description = "Domain served by the load balancer (A record managed in Cloudflare, DNS only)"
  type        = string
  default     = "iac-study.hashrock.info"
}
