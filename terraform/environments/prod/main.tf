module "circleguard" {
  source = "../../modules/circleguard-stack"

  namespace                = var.namespace
  environment              = "prod"
  image_tag                = var.image_tag
  service_replicas         = var.replicas
  infra_replicas           = 1
  kafka_replication_factor = 1

  service_resources = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "2000m", memory = "2Gi" }
  }

  postgres_resources = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "2000m", memory = "2Gi" }
  }
}
