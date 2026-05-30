module "namespace" {
  source      = "../namespace"
  namespace   = var.namespace
  environment = var.environment
}

module "postgres" {
  source    = "../postgres"
  namespace = module.namespace.namespace
  replicas  = var.infra_replicas
  resources = var.postgres_resources

  depends_on = [module.namespace]
}

module "neo4j" {
  source    = "../neo4j"
  namespace = module.namespace.namespace
  replicas  = var.infra_replicas

  depends_on = [module.namespace]
}

module "kafka" {
  source             = "../kafka"
  namespace          = module.namespace.namespace
  replicas           = var.infra_replicas
  replication_factor = var.kafka_replication_factor

  depends_on = [module.namespace]
}

module "redis" {
  source    = "../redis"
  namespace = module.namespace.namespace
  replicas  = var.infra_replicas

  depends_on = [module.namespace]
}

# -----------------------------------------------------------------------------
# Microservices
# -----------------------------------------------------------------------------

module "auth_service" {
  source         = "../microservice"
  name           = "circleguard-auth-service"
  container_name = "auth"
  image          = "circleguard-auth-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8180
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
    { name = "SPRING_DATASOURCE_USERNAME", key = "POSTGRES_USER" },
  ]
  env_from_secret = [
    { name = "SPRING_DATASOURCE_PASSWORD", key = "POSTGRES_PASSWORD" },
    { name = "JWT_SECRET", key = "JWT_SECRET" },
    { name = "QR_SECRET", key = "QR_SECRET" },
  ]
  env_literal = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres:5432/circleguard_auth" },
  ]

  depends_on = [module.postgres]
}

module "identity_service" {
  source         = "../microservice"
  name           = "circleguard-identity-service"
  container_name = "identity"
  image          = "circleguard-identity-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8083
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
    { name = "SPRING_DATASOURCE_USERNAME", key = "POSTGRES_USER" },
  ]
  env_from_secret = [
    { name = "SPRING_DATASOURCE_PASSWORD", key = "POSTGRES_PASSWORD" },
    { name = "JWT_SECRET", key = "JWT_SECRET" },
  ]
  env_literal = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres:5432/circleguard_identity" },
    { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka:9092" },
  ]

  depends_on = [module.postgres, module.kafka]
}

module "form_service" {
  source         = "../microservice"
  name           = "circleguard-form-service"
  container_name = "form"
  image          = "circleguard-form-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8086
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
    { name = "SPRING_DATASOURCE_USERNAME", key = "POSTGRES_USER" },
  ]
  env_from_secret = [
    { name = "SPRING_DATASOURCE_PASSWORD", key = "POSTGRES_PASSWORD" },
  ]
  env_literal = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres:5432/circleguard_form" },
    { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka:9092" },
  ]

  depends_on = [module.postgres, module.kafka]
}

module "promotion_service" {
  source         = "../microservice"
  name           = "circleguard-promotion-service"
  container_name = "promotion"
  image          = "circleguard-promotion-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8088
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
    { name = "SPRING_DATASOURCE_USERNAME", key = "POSTGRES_USER" },
    { name = "SPRING_NEO4J_AUTHENTICATION_USERNAME", key = "NEO4J_USER" },
  ]
  env_from_secret = [
    { name = "SPRING_DATASOURCE_PASSWORD", key = "POSTGRES_PASSWORD" },
    { name = "SPRING_NEO4J_AUTHENTICATION_PASSWORD", key = "NEO4J_PASSWORD" },
    { name = "JWT_SECRET", key = "JWT_SECRET" },
  ]
  env_literal = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres:5432/circleguard_promotion" },
    { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka:9092" },
    { name = "SPRING_DATA_REDIS_HOST", value = "redis" },
    { name = "SPRING_DATA_REDIS_PORT", value = "6379" },
    { name = "SPRING_NEO4J_URI", value = "bolt://neo4j:7687" },
  ]

  depends_on = [module.postgres, module.kafka, module.redis, module.neo4j]
}

module "notification_service" {
  source         = "../microservice"
  name           = "circleguard-notification-service"
  container_name = "notification"
  image          = "circleguard-notification-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8082
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
  ]
  env_from_secret = [
    { name = "JWT_SECRET", key = "JWT_SECRET" },
    { name = "QR_SECRET", key = "QR_SECRET" },
  ]
  env_literal = [
    { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka:9092" },
    { name = "AUTH_API_URL", value = "http://circleguard-auth-service:8180" },
  ]

  depends_on = [module.kafka, module.auth_service]
}

module "gateway_service" {
  source         = "../microservice"
  name           = "circleguard-gateway-service"
  container_name = "gateway"
  image          = "circleguard-gateway-service:${var.image_tag}"
  namespace      = module.namespace.namespace
  port           = 8087
  replicas       = var.service_replicas
  resources      = var.service_resources

  env_from_config_map = [
    { name = "SPRING_PROFILES_ACTIVE", key = "SPRING_PROFILES_ACTIVE" },
  ]
  env_from_secret = [
    { name = "JWT_SECRET", key = "JWT_SECRET" },
    { name = "QR_SECRET", key = "QR_SECRET" },
  ]
  env_literal = [
    { name = "SPRING_DATA_REDIS_HOST", value = "redis" },
    { name = "SPRING_DATA_REDIS_PORT", value = "6379" },
  ]

  depends_on = [module.redis]
}
