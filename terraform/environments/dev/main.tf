module "circleguard" {
  source = "../../modules/circleguard-stack"

  namespace                = var.namespace
  environment              = "dev"
  image_tag                = var.image_tag
  service_replicas         = var.replicas
  infra_replicas           = 1
  kafka_replication_factor = 1

  service_resources = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }

  postgres_resources = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}
