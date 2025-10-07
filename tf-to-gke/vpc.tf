variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" { 
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24" # range of IPs for nodes in the cluster (primary)

  secondary_ip_range { # range of IPs for pods in the cluster (secondary)
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range { # range of IPs for pservices in the cluster (secondary)
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}
