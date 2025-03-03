variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

# GKE cluster version data
data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = "1.31."
}

# GKE Cluster without a default node pool
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region

  networking_mode = "VPC_NATIVE"
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count       = 1  # Required, but not used since we won't have a default pool
  remove_default_node_pool = true # Prevents the default pool from being created

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  lifecycle {
    ignore_changes = [node_pool]
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version    = google_container_cluster.primary.min_master_version  # Add this line
  node_count = var.gke_num_nodes

  node_config {
    machine_type   = "e2-medium" # Cost-efficient for free tier
    disk_size_gb   = 30  # Keep SSD usage low to stay within free tier
    disk_type      = "pd-standard" # Use standard disks to reduce cost
    image_type     = "COS_CONTAINERD"  # Explicitly set to avoid errors

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    tags = ["gke-node", "${var.project_id}-gke"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    kubelet_config {
      cpu_cfs_quota      = true
      cpu_manager_policy = "static"
      pod_pids_limit     = 4096
    }
  }

  # Explicitly define upgrade settings (optional)
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

lifecycle {
    ignore_changes = [
      node_count,                        # Ignore node count changes to prevent recreation
      version,                           # Ignore version unless explicitly changed
      node_config[0].disk_size_gb,       # Ignore disk size changes
      node_config[0].machine_type,       # Ignore machine type changes
      node_config[0].image_type,         # Ignore image type changes
      node_config[0].oauth_scopes        # Ignore scope changes
    ]
  }

}
