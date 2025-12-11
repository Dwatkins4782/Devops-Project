output "cluster_name" {
  value       = kind_cluster.devops_cluster.name
  description = "Name of the KinD cluster"
}

output "kubeconfig_path" {
  value       = kind_cluster.devops_cluster.kubeconfig_path
  description = "Path to the kubeconfig file"
}

output "registry_endpoint" {
  value       = "localhost:5000"
  description = "Local container registry endpoint"
}

