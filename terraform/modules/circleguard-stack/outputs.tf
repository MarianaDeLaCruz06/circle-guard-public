output "namespace" {
  value = module.namespace.namespace
}

output "services" {
  description = "Cluster-internal endpoints by service name"
  value = {
    auth         = "http://${module.auth_service.service_name}:${module.auth_service.port}"
    identity     = "http://${module.identity_service.service_name}:${module.identity_service.port}"
    form         = "http://${module.form_service.service_name}:${module.form_service.port}"
    promotion    = "http://${module.promotion_service.service_name}:${module.promotion_service.port}"
    notification = "http://${module.notification_service.service_name}:${module.notification_service.port}"
    gateway      = "http://${module.gateway_service.service_name}:${module.gateway_service.port}"
    dashboard    = "http://${module.dashboard_service.service_name}:${module.dashboard_service.port}"
    file         = "http://${module.file_service.service_name}:${module.file_service.port}"
  }
}

output "infrastructure" {
  description = "Cluster-internal endpoints for stateful components"
  value = {
    postgres = "${module.postgres.service_name}:${module.postgres.service_port}"
    neo4j    = "${module.neo4j.service_name}:${module.neo4j.bolt_port}"
    kafka    = "${module.kafka.kafka_service}:${module.kafka.kafka_port}"
    redis    = "${module.redis.service_name}:${module.redis.service_port}"
  }
}
