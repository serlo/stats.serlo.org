resource "kubernetes_secret" "kpi_secret" {
  metadata {
    name      = "kpi-secret"
    namespace = var.namespace
  }

  data = {
    "datasources.yaml"                  = data.template_file.datasources_template.rendered
    "athene-database-password-readonly" = var.athene2_database_password_readonly
    "kpi-database-password-default"     = var.kpi_database_password_default
    "config.yaml"                       = data.template_file.mysql_importer_config_template.rendered
  }

  type = "Opaque"
}
