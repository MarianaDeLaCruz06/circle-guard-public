variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context (e.g. docker-desktop, minikube, gke_...)"
  type        = string
  default     = "docker-desktop"
}

variable "namespace" {
  description = "Namespace for the Terraform state backend"
  type        = string
  default     = "terraform-backend"
}

variable "minio_root_user" {
  description = "MinIO root user (used as AWS_ACCESS_KEY_ID by Terraform backend)"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root password (used as AWS_SECRET_ACCESS_KEY by Terraform backend)"
  type        = string
  default     = "minioadmin123"
  sensitive   = true
}

variable "bucket_name" {
  description = "Bucket that stores environment tfstate files"
  type        = string
  default     = "terraform-state"
}

variable "service_type" {
  description = "Kubernetes service type for MinIO: NodePort (local) or LoadBalancer (cloud K8s such as GKE/EKS)"
  type        = string
  default     = "NodePort"
}

variable "api_node_port" {
  description = "NodePort for MinIO S3 API (only used when service_type = NodePort)"
  type        = number
  default     = 30900
}

variable "console_node_port" {
  description = "NodePort for MinIO web console (only used when service_type = NodePort)"
  type        = number
  default     = 30901
}
