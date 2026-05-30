output "service_name" {
  value = kubernetes_service.this.metadata[0].name
}

output "deployment_name" {
  value = kubernetes_deployment.this.metadata[0].name
}

output "port" {
  value = var.port
}
