terraform {
  backend "gcs" {
    bucket = "hashrock-iac-study-tfstate"
    prefix = "01-gcs-bucket"
  }
}
