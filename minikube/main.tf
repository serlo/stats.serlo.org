#####################################################################
# settings for dev
#####################################################################
locals {
  environment = "dev"
  project     = "serlo-dev"

  ingress_tls_certificate_path = "~/.minikube/apiserver.crt"
  ingress_tls_key_path         = "~/.minikube/apiserver.key"
}

#####################################################################
# providers
#####################################################################

provider "kubernetes" {
  version                = "~> 1.8"
  config_context_cluster = "minikube"
}

#####################################################################
# namespaces
#####################################################################

resource "kubernetes_namespace" "athene2_namespace" {
  metadata {
    name = "athene2"
  }
}

resource "kubernetes_namespace" "kpi_namespace" {
  depends_on = [kubernetes_namespace.athene2_namespace]
  metadata {
    name = "kpi"
  }
}

#####################################################################
# mysql
#####################################################################

module "local_mysql" {
  source    = "./../modules/mysql"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name
}

#####################################################################
# postgres
#####################################################################

module "local_postgres" {
  source    = "./../modules/postgres"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name
}

module "athene2_dbsetup" {
  source                    = "./../modules/athene2_dbsetup"
  namespace                 = kubernetes_namespace.athene2_namespace.metadata.0.name
  database_username_default = "root"
  database_password_default = "admin"
  database_host             = "mysql.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  image_pull_policy         = "Never"
  gcloud_bucket_url         = ""

  feature_minikube = true
}


#####################################################################
# kpi
#####################################################################

module "kpi" {
  source = "./../modules/kpi"

  domain                 = "serlo.local"
  grafana_admin_password = "admin"

  athene2_database_host              = "mysql.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  athene2_database_username_readonly = "root"
  athene2_database_password_readonly = "admin"
  image_pull_policy                  = "Never"

  kpi_database_host              = "postgres.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  kpi_database_username_default  = "postgres"
  kpi_database_password_default  = "admin"
  kpi_database_username_readonly = "postgres"
  kpi_database_password_readonly = "admin"
  gcloud_ingress                 = false
}
