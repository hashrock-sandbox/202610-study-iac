terraform {
  backend "gcs" {
    bucket = "hashrock-iac-study-tfstate"
    prefix = "02-iam"
  }
}
