variable "name" {
  description = "Deployment + Service name (e.g. circleguard-auth-service)"
  type        = string
}

variable "namespace" {
  type = string
}

variable "container_name" {
  description = "Container name inside the pod"
  type        = string
}

variable "image" {
  description = "Docker image (built locally by the CI/CD pipeline)"
  type        = string
}

variable "image_pull_policy" {
  type    = string
  default = "IfNotPresent"
}

variable "port" {
  description = "Service and container port"
  type        = number
}

variable "replicas" {
  type    = number
  default = 1
}

variable "resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}

variable "env_from_config_map" {
  description = "Env vars sourced from circleguard-config ConfigMap"
  type = list(object({
    name = string
    key  = string
  }))
  default = []
}

variable "env_from_secret" {
  description = "Env vars sourced from circleguard-secret Secret"
  type = list(object({
    name = string
    key  = string
  }))
  default = []
}

variable "env_literal" {
  description = "Literal env vars (used for SPRING_DATASOURCE_URL, AUTH_API_URL with service discovery, etc.)"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "config_map_name" {
  type    = string
  default = "circleguard-config"
}

variable "secret_name" {
  type    = string
  default = "circleguard-secret"
}
