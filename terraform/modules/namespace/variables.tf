variable "namespace" {
  description = "Kubernetes namespace name (e.g. circleguard-dev, circleguard-stage, circleguard-master)"
  type        = string
}

variable "environment" {
  description = "Environment label (dev | stage | prod)"
  type        = string
}

variable "config_data" {
  description = "Plain config values (ConfigMap)"
  type        = map(string)
  default = {
    SPRING_PROFILES_ACTIVE  = "docker"
    POSTGRES_USER           = "admin"
    KAFKA_BOOTSTRAP_SERVERS = "kafka:9092"
    REDIS_HOST              = "redis"
    REDIS_PORT              = "6379"
    NEO4J_URI               = "bolt://neo4j:7687"
    NEO4J_USER              = "neo4j"
    AUTH_API_URL            = "http://circleguard-auth-service:8180"
  }
}

variable "secret_data" {
  description = "Sensitive values (Secret). In real envs inject via tfvars or external secret manager."
  type        = map(string)
  sensitive   = true
  default = {
    POSTGRES_PASSWORD = "password"
    NEO4J_PASSWORD    = "password"
    JWT_SECRET        = "my-super-secret-dev-key-32-chars-long-12345678"
    QR_SECRET         = "my-qr-secret-key-for-dev-1234567890"
  }
}
