terraform {
  backend "gcs" {
    bucket = "hashrock-iac-study-tfstate"
    prefix = "04-github-wif"
  }
}
