variable "namespace" {
  description = "Target Kubernetes namespace"
  type        = string
}

variable "image" {
  description = "Neo4j container image"
  type        = string
  default     = "neo4j:5.26"
}

variable "auth" {
  description = "Neo4j auth string (user/password). Default replicates dev values."
  type        = string
  default     = "neo4j/password"
  sensitive   = true
}

variable "plugins" {
  description = "Neo4j plugins JSON array string"
  type        = string
  default     = "[\"apoc\"]"
}

variable "replicas" {
  description = "Number of Neo4j replicas"
  type        = number
  default     = 1
}

variable "resources" {
  description = "Container resource requests/limits"
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "1Gi" }
  }
}
