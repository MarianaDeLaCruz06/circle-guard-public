output "service_name" {
  value = kubernetes_service.neo4j.metadata[0].name
}

output "bolt_port" {
  value = 7687
}

output "http_port" {
  value = 7474
}
