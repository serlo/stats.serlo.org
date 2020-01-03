#####################################################################
# settings for dev
#####################################################################
locals {
  environment = "dev"
  project     = "serlo-dev"
  domain      = "serlo.local"

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
  source    = "git::https://github.com/serlo/infrastructure-modules-shared//mysql"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name
}

#####################################################################
# postgres
#####################################################################

module "local_postgres" {
  source    = "git::https://github.com/serlo/infrastructure-modules-shared//postgres"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name
}

module "athene2_dbsetup" {
  source                    = "git::https://github.com/serlo/infrastructure-modules-serlo.org//athene2_dbsetup?ref=athene2_dbsetup-cleanup"
  namespace                 = kubernetes_namespace.athene2_namespace.metadata.0.name
  database_username_default = "root"
  database_password_default = "admin"
  database_host             = "mysql.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  image_pull_policy         = "Never"

  feature_minikube            = true
  gcloud_service_account_name = "kpi-minikube@serlo-shared.iam.gserviceaccount.com"
  gcloud_service_account_key  = file("${path.module}/service_account.json")
}


#####################################################################
# kpi
#####################################################################

module "kpi" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//kpi?ref=master"

  grafana_image = "eu.gcr.io/serlo-shared/kpi-grafana:latest"

  domain                 = "${local.domain}"
  grafana_admin_password = "admin"
  grafana_serlo_password = "serlo"

  athene2_database_host              = "mysql.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  athene2_database_username_readonly = "root"
  athene2_database_password_readonly = "admin"
  image_pull_policy                  = "Never"

  kpi_database_host              = "postgres.${kubernetes_namespace.kpi_namespace.metadata.0.name}"
  kpi_database_username_default  = "postgres"
  kpi_database_password_default  = "admin"
  kpi_database_username_readonly = "postgres"
  kpi_database_password_readonly = "admin"
}

#####################################################################
# ingresses
#####################################################################

resource "kubernetes_ingress" "kpi_ingress_local" {
  count = 1
  metadata {
    name      = "kpi-ingress"
    namespace = kubernetes_namespace.kpi_namespace.metadata.0.name

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    tls {
      secret_name = "minikube-ingress-secret"
    }

    rule {
      host = "stats.${local.domain}"

      http {
        path {
          path = "/"

          backend {
            service_name = module.kpi.grafana_service_name
            service_port = module.kpi.grafana_service_port
          }
        }
      }
    }
  }
}
