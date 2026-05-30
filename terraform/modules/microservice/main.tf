resource "kubernetes_deployment" "this" {
  wait_for_rollout = false

  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app                         = var.name
      "app.kubernetes.io/part-of" = "circleguard"
      "app.kubernetes.io/name"    = var.name
    }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = var.name }
    }
    template {
      metadata {
        labels = { app = var.name }
      }
      spec {
        container {
          name              = var.container_name
          image             = var.image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = var.port
          }

          dynamic "env" {
            for_each = var.env_from_config_map
            content {
              name = env.value.name
              value_from {
                config_map_key_ref {
                  name = var.config_map_name
                  key  = env.value.key
                }
              }
            }
          }

          dynamic "env" {
            for_each = var.env_from_secret
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name = var.secret_name
                  key  = env.value.key
                }
              }
            }
          }

          dynamic "env" {
            for_each = var.env_literal
            content {
              name  = env.value.name
              value = env.value.value
            }
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

resource "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    selector = { app = var.name }
    port {
      name        = "http"
      port        = var.port
      target_port = var.port
    }
  }
}
