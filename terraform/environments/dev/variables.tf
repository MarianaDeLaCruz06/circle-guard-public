variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubeconfig_context" {
  type    = string
  default = "docker-desktop"
}

variable "namespace" {
  type    = string
  default = "circleguard-dev"
}

variable "image_tag" {
  description = "Tag for all circleguard-* service images"
  type        = string
  default     = "local"
}

variable "replicas" {
  description = "Replicas applied to every microservice"
  type        = number
  default     = 1
}
