locals {
  init_sql = join("\n", [for db in var.databases : "CREATE DATABASE ${db};"])
}

resource "kubernetes_config_map" "initdb" {
  metadata {
    name      = "postgres-initdb"
    namespace = var.namespace
  }
  data = {
    "init-db.sql" = local.init_sql
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
    labels    = { app = "postgres" }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "postgres" }
    }
    template {
      metadata {
        labels = { app = "postgres" }
      }
      spec {
        container {
          name              = "postgres"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = var.config_map_name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "POSTGRES_DB"
            value = "circleguard"
          }

          resources {
            requests = var.resources.requests
            limits   = var.resources.limits
          }

          volume_mount {
            name       = "postgres-initdb"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "postgres-initdb"
          config_map {
            name = kubernetes_config_map.initdb.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
  }
  spec {
    selector = { app = "postgres" }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
  }
}
