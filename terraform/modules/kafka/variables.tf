variable "namespace" {
  description = "Target Kubernetes namespace"
  type        = string
}

variable "zookeeper_image" {
  type    = string
  default = "confluentinc/cp-zookeeper:7.6.0"
}

variable "kafka_image" {
  type    = string
  default = "confluentinc/cp-kafka:7.6.0"
}

variable "replicas" {
  description = "Replicas (Kafka and Zookeeper share this knob for academic simplicity)"
  type        = number
  default     = 1
}

variable "replication_factor" {
  description = "Internal topic replication factor (offsets/transaction state log)"
  type        = number
  default     = 1
}

variable "resources_kafka" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "1Gi" }
  }
}

variable "resources_zookeeper" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}
