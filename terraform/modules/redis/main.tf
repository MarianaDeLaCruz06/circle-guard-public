resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels    = { app = "redis" }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "redis" }
    }
    template {
      metadata {
        labels = { app = "redis" }
      }
      spec {
        container {
          name              = "redis"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          port { container_port = 6379 }

          resources {
            requests = var.resources.requests
            limits   = var.resources.limits
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
  }
  spec {
    selector = { app = "redis" }
    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
    }
  }
}
