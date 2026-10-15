terraform {
  backend "gcs" {
    bucket = "hashrock-iac-study-tfstate"
    prefix = "app"
  }
}
