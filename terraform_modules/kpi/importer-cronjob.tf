resource "kubernetes_deployment" "mysql-importer-cronjob" {
  metadata {
    name      = "mysql-importer-cronjob"
    namespace = var.namespace

    labels = {
      app = "importer"
    }
  }

  spec {
    replicas = "1"

    selector {
      match_labels = {
        app = "mysql-importer"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app  = "mysql-importer"
          name = "mysql-importer"
        }
      }

      spec {
        container {
          image             = var.mysql_importer_image
          name              = "mysql-importer-container"
          image_pull_policy = var.image_pull_policy

          env {
            name  = "CRON_PATTERN"
            value = "0 5 * * *"
          }
          resources {
            limits {
              cpu    = "50m"
              memory = "64M"
            }
            requests {
              cpu    = "25m"
              memory = "32M"
            }
          }

          volume_mount {
            mount_path = "/tmp/config.yaml"
            sub_path   = "config.yaml"
            name       = "mysql-importer-config"
          }
        }

        volume {
          name = "mysql-importer-config"

          secret {
            secret_name = kubernetes_secret.kpi_secret.metadata.0.name

            items {
              key  = "config.yaml"
              path = "config.yaml"
              mode = "0444"
            }
          }
        }
      }
    }
  }
}

data "template_file" "mysql_importer_config_template" {
  template = file("${path.module}/mysql-importer-config.yaml.tpl")

  vars = {
    mysql_importer_interval_in_min = var.mysql_importer_interval_in_min
    mysql_importer_log_level       = var.mysql_importer_log_level
    athene2_db_host                = var.athene2_database_host
    athene2_db_user                = var.athene2_database_username_readonly
    athene2_db_password            = var.athene2_database_password_readonly
    athene2_db_name                = var.athene2_database_name
    kpi_database_host              = var.kpi_database_host
    kpi_database_port              = 5432
    kpi_database_name              = var.kpi_database_name
    kpi_database_username          = var.kpi_database_username_default
    kpi_database_password          = var.kpi_database_password_default
  }
}