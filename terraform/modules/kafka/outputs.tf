output "kafka_service" {
  value = kubernetes_service.kafka.metadata[0].name
}

output "kafka_port" {
  value = 9092
}

output "zookeeper_service" {
  value = kubernetes_service.zookeeper.metadata[0].name
}
