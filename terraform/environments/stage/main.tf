module "circleguard" {
  source = "../../modules/circleguard-stack"

  namespace                = var.namespace
  environment              = "stage"
  image_tag                = var.image_tag
  service_replicas         = var.replicas
  infra_replicas           = 1
  kafka_replication_factor = 1

  service_resources = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "1Gi" }
  }

  postgres_resources = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "1Gi" }
  }
}
