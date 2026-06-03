variable "namespace" {
  description = "Target Kubernetes namespace"
  type        = string
}

variable "config_map_name" {
  description = "Shared ConfigMap with POSTGRES_USER"
  type        = string
  default     = "circleguard-config"
}

variable "secret_name" {
  description = "Shared Secret with POSTGRES_PASSWORD"
  type        = string
  default     = "circleguard-secret"
}

variable "image" {
  description = "Postgres container image"
  type        = string
  default     = "postgres:16"
}

variable "replicas" {
  description = "Number of Postgres replicas"
  type        = number
  default     = 1
}

variable "databases" {
  description = "Databases created on init (used by circleguard services)"
  type        = list(string)
  default = [
    "circleguard_auth",
    "circleguard_identity",
    "circleguard_form",
    "circleguard_promotion",
    "circleguard_dashboard",
  ]
}

variable "resources" {
  description = "Container resource requests/limits"
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}
