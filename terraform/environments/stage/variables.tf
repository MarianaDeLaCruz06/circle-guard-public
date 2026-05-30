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
  default = "circleguard-stage"
}

variable "image_tag" {
  type    = string
  default = "local"
}

variable "replicas" {
  type    = number
  default = 2
}
