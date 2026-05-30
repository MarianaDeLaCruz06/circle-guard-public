variable "namespace" {
  type = string
}

variable "image" {
  type    = string
  default = "redis:7.2"
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
    requests = { cpu = "50m", memory = "64Mi" }
    limits   = { cpu = "200m", memory = "256Mi" }
  }
}
