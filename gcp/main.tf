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

variable "image_digest" {
  type = string
  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.image_digest))
    error_message = "Provide an immutable image digest beginning with sha256:."
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_cloud_run_v2_service" "api" {
  name                 = "spry-lab-api"
  location             = "us-central1"
  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = true
  scaling {
    max_instance_count = 1
  }

  template {
    service_account                  = "spry-lab-runtime@${var.project_id}.iam.gserviceaccount.com"
    timeout                          = "15s"
    max_instance_request_concurrency = 8
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
    containers {
      image = "us-central1-docker.pkg.dev/${var.project_id}/spry-lab/api@${var.image_digest}"
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = false
      }
      env {
        name  = "SPRY_GCP_PROJECT"
        value = var.project_id
      }
      startup_probe {
        http_get {
          path = "/healthz"
          port = 8080
        }
        period_seconds    = 3
        timeout_seconds   = 2
        failure_threshold = 10
      }
    }
  }
}

output "api_url" {
  value = google_cloud_run_v2_service.api.uri
}
