resource "kubernetes_deployment" "neo4j" {
  metadata {
    name      = "neo4j"
    namespace = var.namespace
    labels    = { app = "neo4j" }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "neo4j" }
    }
    template {
      metadata {
        labels = { app = "neo4j" }
      }
      spec {
        enable_service_links = false

        container {
          name              = "neo4j"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port { container_port = 7474 }
          port { container_port = 7687 }

          env {
            name  = "NEO4J_AUTH"
            value = var.auth
          }
          env {
            name  = "NEO4J_PLUGINS"
            value = var.plugins
          }
          env {
            name  = "NEO4J_server_config_strict__validation_enabled"
            value = "false"
          }

          resources {
            requests = var.resources.requests
            limits   = var.resources.limits
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "neo4j" {
  metadata {
    name      = "neo4j"
    namespace = var.namespace
  }
  spec {
    selector = { app = "neo4j" }
    port {
      name        = "http"
      port        = 7474
      target_port = 7474
    }
    port {
      name        = "bolt"
      port        = 7687
      target_port = 7687
    }
  }
}
