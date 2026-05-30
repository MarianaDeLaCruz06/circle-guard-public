output "service_name" {
  value = kubernetes_service.redis.metadata[0].name
}

output "service_port" {
  value = 6379
}
