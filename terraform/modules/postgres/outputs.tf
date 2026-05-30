output "service_name" {
  description = "Postgres service DNS name (resolves inside the namespace)"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "service_port" {
  value = 5432
}
