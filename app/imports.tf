# One-time migration from the former 01-gcs-bucket / 02-iam / 03-cloud-run stacks.
# Safe to delete after the first successful apply.

import {
  to = google_storage_bucket.study
  id = "hashrock-iac-study-tf-study-01"
}

import {
  to = google_project_service.this["iam.googleapis.com"]
  id = "hashrock-iac-study/iam.googleapis.com"
}

import {
  to = google_project_service.this["run.googleapis.com"]
  id = "hashrock-iac-study/run.googleapis.com"
}

import {
  to = google_service_account.app
  id = "projects/hashrock-iac-study/serviceAccounts/study-app@hashrock-iac-study.iam.gserviceaccount.com"
}

# IAM member import IDs are space-separated: "<resource> <role> <member>".
import {
  to = google_storage_bucket_iam_member.app_reader
  id = "b/hashrock-iac-study-tf-study-01 roles/storage.objectViewer serviceAccount:study-app@hashrock-iac-study.iam.gserviceaccount.com"
}

import {
  to = google_cloud_run_v2_service.hello
  id = "projects/hashrock-iac-study/locations/asia-northeast1/services/study-hello"
}

import {
  to = google_cloud_run_v2_service_iam_member.public
  id = "projects/hashrock-iac-study/locations/asia-northeast1/services/study-hello roles/run.invoker allUsers"
}
