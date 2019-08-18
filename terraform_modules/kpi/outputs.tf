#####################################################################
# outputs for module kpi
#####################################################################
output "grafana_service_name" {
  value = kubernetes_service.grafana_service.metadata[0].name
}

output "grafana_service_port" {
  value = kubernetes_service.grafana_service.spec[0].port[0].port
}

output "kpi_database_password_default" {
  value = var.kpi_database_password_default
}

output "kpi_database_username_default" {
  value = var.kpi_database_username_default
}

output "kpi_database_username_readonly" {
  value = var.kpi_database_username_readonly
}

output "kpi_database_name" {
  value = var.kpi_database_name
}