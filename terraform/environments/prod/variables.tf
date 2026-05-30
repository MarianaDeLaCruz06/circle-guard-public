variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubeconfig_context" {
  type    = string
  default = "docker-desktop"
}

variable "namespace" {
  description = "Production namespace (matches Jenkinsfile.master KUBE_NAMESPACE: circleguard-master)"
  type        = string
  default     = "circleguard-master"
}

variable "image_tag" {
  type    = string
  default = "local"
}

variable "replicas" {
  type    = number
  default = 3
}
