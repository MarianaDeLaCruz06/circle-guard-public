output "namespace" {
  description = "Created namespace name"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "config_map_name" {
  description = "Name of the shared ConfigMap"
  value       = kubernetes_config_map.circleguard_config.metadata[0].name
}

output "secret_name" {
  description = "Name of the shared Secret"
  value       = kubernetes_secret.circleguard_secret.metadata[0].name
}
