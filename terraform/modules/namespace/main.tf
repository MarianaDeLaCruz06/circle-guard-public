resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of"  = "circleguard"
      "circleguard.io/environment" = var.environment
    }
  }
}

resource "kubernetes_config_map" "circleguard_config" {
  metadata {
    name      = "circleguard-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  data = var.config_data
}

resource "kubernetes_secret" "circleguard_secret" {
  metadata {
    name      = "circleguard-secret"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = var.secret_data
}
