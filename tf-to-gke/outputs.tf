output "zone" {
  value       = var.zone
  description = "GCloud Zone"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

# Basically outputs only need a name, a value, and maybe a description 
# You can access a specific output by cli - terraform output <output_name>
# Plus outputs can be accessedd by other modules as well, as inputs 
