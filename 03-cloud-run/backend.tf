terraform {
  backend "gcs" {
    bucket = "hashrock-iac-study-tfstate"
    prefix = "03-cloud-run"
  }
}
