output "minio_service_type" {
  value = var.service_type
}

output "minio_endpoint_in_cluster" {
  description = "Endpoint usable by workloads INSIDE the cluster"
  value       = "http://minio.${var.namespace}.svc.cluster.local:9000"
}

output "bucket_name" {
  value = var.bucket_name
}

output "access_key_id" {
  description = "Use as AWS_ACCESS_KEY_ID when running 'terraform init' in environments"
  value       = var.minio_root_user
  sensitive   = true
}

output "secret_access_key" {
  description = "Use as AWS_SECRET_ACCESS_KEY when running 'terraform init' in environments"
  value       = var.minio_root_password
  sensitive   = true
}

output "note" {
  description = "For LoadBalancer: run 'kubectl get svc minio -n terraform-backend' to get the external IP, then update backend.tf endpoints in environments/"
  value       = "After apply: kubectl get svc minio -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
