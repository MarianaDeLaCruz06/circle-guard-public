resource "kubernetes_deployment" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = var.namespace
    labels    = { app = "zookeeper" }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "zookeeper" }
    }
    template {
      metadata {
        labels = { app = "zookeeper" }
      }
      spec {
        container {
          name  = "zookeeper"
          image = var.zookeeper_image
          port { container_port = 2181 }
          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = "2181"
          }
          env {
            name  = "ZOOKEEPER_TICK_TIME"
            value = "2000"
          }
          resources {
            requests = var.resources_zookeeper.requests
            limits   = var.resources_zookeeper.limits
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = var.namespace
  }
  spec {
    selector = { app = "zookeeper" }
    port {
      name        = "zookeeper"
      port        = 2181
      target_port = 2181
    }
  }
}

resource "kubernetes_deployment" "kafka" {
  metadata {
    name      = "kafka"
    namespace = var.namespace
    labels    = { app = "kafka" }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "kafka" }
    }
    template {
      metadata {
        labels = { app = "kafka" }
      }
      spec {
        enable_service_links = false

        container {
          name  = "kafka"
          image = var.kafka_image
          port { container_port = 9092 }

          env {
            name  = "KAFKA_BROKER_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "zookeeper:2181"
          }
          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092"
          }
          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka:9092"
          }
          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "PLAINTEXT:PLAINTEXT"
          }
          env {
            name  = "KAFKA_INTER_BROKER_LISTENER_NAME"
            value = "PLAINTEXT"
          }
          env {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = tostring(var.replication_factor)
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"
            value = tostring(var.replication_factor)
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"
            value = tostring(var.replication_factor)
          }
          env {
            name  = "KAFKA_LOG_DIRS"
            value = "/tmp/kafka-logs"
          }

          resources {
            requests = var.resources_kafka.requests
            limits   = var.resources_kafka.limits
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.zookeeper]
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = var.namespace
  }
  spec {
    selector = { app = "kafka" }
    port {
      name        = "kafka"
      port        = 9092
      target_port = 9092
    }
  }
}
