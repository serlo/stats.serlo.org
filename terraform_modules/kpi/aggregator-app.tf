resource "kubernetes_deployment" "aggregator-cronjob" {
  metadata {
    name      = "aggregator-cronjob"
    namespace = var.namespace

    labels = {
      app = "aggregator"
    }
  }

  spec {
    replicas = "1"

    selector {
      match_labels = {
        app = "aggregator"
      }
    }

    template {
      metadata {
        labels = {
          app  = "aggregator"
          name = "aggregator"
        }
      }

      spec {
        container {
          image = var.aggregator_image
          name  = "aggregator"

          image_pull_policy = var.image_pull_policy

          env {
            name  = "KPI_DATABASE_HOST"
            value = var.kpi_database_host
          }
          env {
            name  = "KPI_DATABASE_PORT"
            value = "5432"
          }
          env {
            name  = "KPI_DATABASE_USER"
            value = var.kpi_database_username_default
          }
          env {
            name  = "KPI_DATABASE_NAME"
            value = var.kpi_database_name
          }
          env {
            name = "KPI_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                key  = "kpi-database-password-default"
                name = kubernetes_secret.kpi_secret.metadata.0.name
              }
            }
          }

          resources {
            limits {
              cpu    = "100m"
              memory = "50M"
            }
          }
        }
      }
    }
  }
}
