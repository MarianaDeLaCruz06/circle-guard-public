resource "kubernetes_namespace" "tf_backend" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "circleguard-infra"
    }
  }
}

resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = kubernetes_namespace.tf_backend.metadata[0].name
  }
  type = "Opaque"
  data = {
    MINIO_ROOT_USER     = var.minio_root_user
    MINIO_ROOT_PASSWORD = var.minio_root_password
  }
}

resource "kubernetes_persistent_volume_claim" "minio_data" {
  metadata {
    name      = "minio-data"
    namespace = kubernetes_namespace.tf_backend.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "2Gi" }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.tf_backend.metadata[0].name
    labels    = { app = "minio" }
  }

  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector {
      match_labels = { app = "minio" }
    }
    template {
      metadata {
        labels = { app = "minio" }
      }
      spec {
        container {
          name  = "minio"
          image = "minio/minio:RELEASE.2024-09-22T00-33-43Z"
          args  = ["server", "/data", "--console-address", ":9001"]

          port { container_port = 9000 }
          port { container_port = 9001 }

          env {
            name = "MINIO_ROOT_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_credentials.metadata[0].name
                key  = "MINIO_ROOT_USER"
              }
            }
          }
          env {
            name = "MINIO_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_credentials.metadata[0].name
                key  = "MINIO_ROOT_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          readiness_probe {
            http_get {
              path = "/minio/health/ready"
              port = 9000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.tf_backend.metadata[0].name
  }
  spec {
    type     = var.service_type
    selector = { app = "minio" }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      # node_port is set automatically when service_type = NodePort
    }
    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
  }
}

# Job that creates the tfstate bucket using mc (MinIO client)
resource "kubernetes_job" "create_bucket" {
  metadata {
    name      = "minio-create-bucket"
    namespace = kubernetes_namespace.tf_backend.metadata[0].name
  }

  spec {
    backoff_limit = 6
    template {
      metadata {
        labels = { job = "minio-create-bucket" }
      }
      spec {
        restart_policy = "OnFailure"

        container {
          name    = "mc"
          image   = "minio/mc:RELEASE.2024-09-16T17-43-14Z"
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            until mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
              echo "waiting for minio..."; sleep 3;
            done
            mc mb --ignore-existing local/${var.bucket_name}
            mc version enable local/${var.bucket_name} || true
            echo "Bucket ${var.bucket_name} ready"
            EOT
          ]

          env {
            name = "MINIO_ROOT_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_credentials.metadata[0].name
                key  = "MINIO_ROOT_USER"
              }
            }
          }
          env {
            name = "MINIO_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_credentials.metadata[0].name
                key  = "MINIO_ROOT_PASSWORD"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.minio, kubernetes_service.minio]

  wait_for_completion = true
  timeouts {
    create = "5m"
  }
}
