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

# Numeric IDs never change, unlike names, so a deleted-and-recreated repo with
# the same name cannot inherit access.
variable "github_repository_id" {
  description = "GitHub repository ID allowed to authenticate"
  type        = string
  default     = "1420541405" # hashrock-sandbox/202610-study-iac
}
