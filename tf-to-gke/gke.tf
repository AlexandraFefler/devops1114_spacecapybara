variable "gke_username" { # not needed, unused and replacement is gke-gcloud-auth-plugin
  default     = ""
  description = "gke username"
}

variable "gke_password" { # not needed, unused and replacement is gke-gcloud-auth-plugin
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" { # declaring to the .tf - "I expect this variable to exist somewhere". Allows mentioning the var further on here
  default     = 2
  description = "number of gke nodes"
}

variable "zone" { # declaring to the .tf - "I expect this variable to exist somewhere". Allows mentioning the var further on here
  description = "GKE cluster zone"
}

# GKE cluster version data
data "google_container_engine_versions" "gke_version" {
  location       = var.zone # goes to tfvars, but if not found - there's a default defined upper here
  version_prefix = "1.31."
}

# GKE Cluster without a default node pool
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.zone

  networking_mode = "VPC_NATIVE"
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count       = 1  # Required, but not used since I won't have a default pool
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
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  # Next line sets the k8s version inside the nodes to match/align the version of the cluster's control plane (master) 
  # GCP auto-upgrades the master in the cluster and the nodes. Terraform doesn't manage here the master so it's all by gcp 
  # If the node version would be specific, terraform would ensure it stays while the master is drifting to further versions -> gonna break 
  node_count = var.gke_num_nodes

  node_config {
    machine_type   = "e2-medium" # Cost-efficient for free tier
    disk_size_gb   = 30  # Keep SSD usage low to stay within free tier
    disk_type      = "pd-standard" # Use standard disks to reduce cost
    image_type     = "COS_CONTAINERD"  # Explicitly set to avoid errors

    # give the GKE nodes permission to write logs and metrics into GCP’s monitoring stack
    # In 2025 this approach is more replaced by IAM roles on the node's service account 
    # But this scopes setting is still mentioned in examples & tf modules just for minimal logging/monitoring
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    # organizing stuff for filtering in gcp and so on 
    labels = {
      env = var.project_id
    }

    # network-level markers for VMs 
    # In GCP, firewall rules use tags to decide which VMs they apply to (like allow port 443 for all VMs w/ tag 'gke-node')
    tags = ["gke-node", "${var.project_id}-gke"]

    # disables the legacy instance metadata server endpoints which are less secure,
    # forces using the modern metadata server (/v1/) - chat says it's good practice ig 
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # tweaks how the kubelet manages resources and processes, it's an agent on each node in gke 
    kubelet_config {
      cpu_cfs_quota      = true # Enables the Completely Fair Scheduler (CFS) CPU quota in Linux cgroups (=control groups of processes, limiting/isolating/etc. resource usage)
      cpu_manager_policy = "static" # kubelet pins whole CPU resources exclusively to a pod that needs consistent cpu performance (like DBs). Default policy is 'none' which allows CPU sharing
      pod_pids_limit     = 4096 # max number of process IDs per pod (default in gke is 1024, so 4096 allows heavier apps to run)
    }
  }

  # Explicitly define rolling upgrade settings (optional)
  # Safest upgrade strategy here - 0 downtime
  upgrade_settings {
    max_surge       = 1 # gke can add one temp extra node, above the desired node count. Lets pods drain off from the old node to the surge (extra) node 
    max_unavailable = 0 # 0 nodes can be taken down before a surge node (replacement for them) is ready
  }

lifecycle {
    ignore_changes = [
      node_count,                  # Ignore manual scaling
      version,                      # Prevent version drift
      node_config[0].machine_type,   # Avoid unwanted updates to machine type
      node_config[0].disk_size_gb,   # Ignore disk size changes
      node_config[0].image_type,     # Prevent conflicts with Terraform-managed updates
      node_config[0].tags,           # Ignore auto-applied changes to tags
      node_config[0].resource_labels # Avoid unnecessary label updates
    ]
  }

}
