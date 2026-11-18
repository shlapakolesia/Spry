terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Supply a valid dedicated project ID."
  }
}

variable "github" {
  type = object({
    repository_id = string
    owner_id      = string
  })
  default = null
  validation {
    condition     = var.github == null ? true : alltrue([for id in values(var.github) : can(regex("^[0-9]+$", id))])
    error_message = "Use numeric GitHub IDs."
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_project_service" "lab" {
  for_each = toset([
    "artifactregistry.googleapis.com", "firebase.googleapis.com",
    "firebasehosting.googleapis.com", "firebaserules.googleapis.com",
    "run.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "identity" {
  for_each = toset([
    "iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "lab" {
  for_each   = toset(["runtime", "terraform", "publisher"])
  account_id = "spry-lab-${each.key}"
  depends_on = [google_project_service.identity]
}

resource "google_project_iam_member" "role" {
  for_each = {
    runtime   = "roles/datastore.viewer"
    terraform = "roles/run.admin"
  }
  project = var.project_id
  role    = each.value
  member  = google_service_account.lab[each.key].member
}

resource "google_service_account_iam_member" "act_as_runtime" {
  service_account_id = google_service_account.lab["runtime"].name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.lab["terraform"].member
}

resource "google_project_service" "firestore" {
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_firestore_database" "lab" {
  name                              = "(default)"
  location_id                       = "us-central1"
  type                              = "FIRESTORE_NATIVE"
  deletion_policy                   = "DELETE"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  depends_on                        = [google_project_service.firestore]
}

resource "google_artifact_registry_repository" "lab" {
  repository_id = "spry-lab"
  location      = "us-central1"
  format        = "DOCKER"
  vulnerability_scanning_config {
    enablement_config = "DISABLED"
  }
  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "604800s"
    }
  }
  cleanup_policies {
    id     = "keep-newest-image"
    action = "KEEP"
    most_recent_versions {
      keep_count = 1
    }
  }
  depends_on = [google_project_service.lab]
}

resource "google_artifact_registry_repository_iam_member" "publisher" {
  location   = google_artifact_registry_repository.lab.location
  repository = google_artifact_registry_repository.lab.name
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.lab["publisher"].member
}

resource "google_artifact_registry_repository_iam_member" "deployer" {
  location   = google_artifact_registry_repository.lab.location
  repository = google_artifact_registry_repository.lab.name
  role       = "roles/artifactregistry.reader"
  member     = google_service_account.lab["terraform"].member
}

resource "google_iam_workload_identity_pool" "github" {
  count                     = var.github == null ? 0 : 1
  workload_identity_pool_id = "spry-lab-github"
  depends_on                = [google_project_service.identity]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.github == null ? 0 : 1
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.repository_id" = "assertion.repository_id"
  }
  attribute_condition = format("assertion.repository_owner_id == '%s' && assertion.repository_id == '%s' && assertion.ref == 'refs/heads/lab-gcp'", var.github.owner_id, var.github.repository_id)
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github" {
  count              = var.github == null ? 0 : 1
  service_account_id = google_service_account.lab["publisher"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository_id/${var.github.repository_id}"
}

output "terraform_service_account" {
  value = google_service_account.lab["terraform"].email
}

output "publisher_service_account" {
  value = google_service_account.lab["publisher"].email
}

output "image_repository" {
  value = "us-central1-docker.pkg.dev/${var.project_id}/spry-lab/api"
}

output "github_provider" {
  value = one(google_iam_workload_identity_pool_provider.github[*].name)
}
