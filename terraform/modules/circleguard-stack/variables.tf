variable "namespace" {
  type = string
}

variable "environment" {
  description = "dev | stage | prod"
  type        = string
}

variable "image_tag" {
  type    = string
  default = "local"
}

variable "service_replicas" {
  description = "Replicas applied to every microservice"
  type        = number
  default     = 1
}

variable "infra_replicas" {
  description = "Replicas applied to infrastructure components (postgres, neo4j, kafka, redis)"
  type        = number
  default     = 1
}

variable "kafka_replication_factor" {
  type    = number
  default = 1
}

variable "service_resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}

variable "postgres_resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}
